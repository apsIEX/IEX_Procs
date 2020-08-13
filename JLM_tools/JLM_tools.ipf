#pragma rtGlobals=1		// Use modern global access method.
#include <KBColorizeTraces>

#include "JLM_FolderUtilities"
#include "JLM_GraphUtilities"
#include "JLM_MathConversions"
#include "JLM_WaveUtilities" //Wave Note Utilites , Scan Name Utilites

Menu "APS Procs"
	Submenu "Analysis Tools"
	//Submenu "ARPES Analysis Tools"	
		"Set df and fit with cursors", print "FolderNFit(fittype)"
		"---ARPES---"	
		"FitFermiGraph",FitFermiGraph()
		"Copy results from Batch Fitting to root folder",Extract_BatchResults_Dialog()	
		"Correct EF", Correct_EF_Dialog()
		"FFT to remove SES mesh", RemoveSESmesh_Dialog()
		"Determine VBM", Calc_VBM_graph_Dialog()
		
		"---------"
		"Normalize Spectra XPS_XAS", Spectra_Norm_fromGraph_Dialog()
	
	end
end

/////////////////////////////////////////////////////////////////////////
///////////////Folder management Template //////////////////////////////////
/////////////////////////////////////////////////////////////////////////
Function ExecuteToAllinFolder()
	variable n
	DFREF dfr=getdatafolderDFR()
	For(n=0;n<CountObjectsDFR(dfr,1);n+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, n)
		//do what you want here
	endfor			
end

/////////////////////////////////////////////////////////////////////////
//////////////////////////Vectorization////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function MakeVector2D_1D(wv)
	wave wv
	variable dx,dy
	dx=dimsize(wv,0)
	dy=dimsize(wv,1)
	variable i,j
	make/o/n=(dx*dy) $(nameofwave(wv)+"_v")
	wave v=$(nameofwave(wv)+"_v")
	For(j=0;j<dy;j+=1)
		For(i=0;i<dx;i+=1)
			v[i+j*dx]=wv[i][j]
		endfor
	endfor
end

Function MakeScalingVector1D(wv)
	wave wv
	variable dx,dy
	dx=dimsize(wv,0)
	dy=dimsize(wv,1)
	variable i,j
	make/o/n=(dx*dy) $(nameofwave(wv)+"_vx"), $(nameofwave(wv)+"_vy")
	wave vx=$(nameofwave(wv)+"_vx")
	setscale/p x, 0,1, waveunits(wv,0) vx
	wave vy=$(nameofwave(wv)+"_vy")
	setscale/p x, 0,1, waveunits(wv,1) vy
	For(j=0;j<dy;j+=1)
		For(i=0;i<dx;i+=1)
			vx[i+j*dx]=dimoffset(wv,0)+dimdelta(wv,0)*i
			vy[i+j*dx]=dimoffset(wv,1)+dimdelta(wv,1)*j
		endfor
	endfor
End
Function MakeVector1D_2D(wv,dx)
	wave wv
	variable dx
	variable dy=dimsize(wv,0)/dx
	print dimsize(wv,0), dx, dy
	variable i,j,k,l
	make/o/n=(dx*dy) $(nameofwave(wv)+"_v")
	wave v=$(nameofwave(wv)+"_v")
	For(j=0;j<dy;j+=1)
		For(i=0;i<dx;i+=1)
			wv[i][j]=v[i+j*i]
		endfor
	endfor
end
Function Histogram_img2D(npx, npy, img_v, img_vx, img_vy) //make and image
	variable npx, npy//number of points for output wave
	wave img_v, img_vx, img_vy
	variable xmax, xmin, ymax, ymin, zmax, zmin
	wavestats/q img_vx; xmax=v_max; xmin=v_min
	wavestats/q img_vy; ymax=v_max; ymin=v_min
	variable dx,dy,dz
	dx=selectnumber(npx==0,(xmax-xmin)/npx,0)
	dy=selectnumber(npy==0,(ymax-ymin)/npy,0)
	Make/n=(npx, npy)/o img_hist, img_norm
	img_hist=nan
	img_norm=nan
	wave img_hist
	setscale/i x, xmin, xmax, "x",  img_hist
	setscale/i y, ymin, ymax, "y",  img_hist
	wave img_norm
	img_norm=0
	//histogram
	variable i,j, px, py
	variable xval, yval
	For(i=0; i<dimsize(img_v,0);i+=1)
		xval=img_vx[i]; yval=img_vy[i]
		px=trunc((xval-xmin)/dx); py=trunc((yval-ymin)/dy)
		img_hist[px][py]=img_v[i]	
		img_norm[px][py]=img_norm[px][py]+1	
	endfor
	img_hist/=img_norm
end
Function VectorCrossProduct(a,b)
	Wave a, b
	if (dimsize(a,0)==3&&dimsize(b,0)==3&&wavedims(a)==1&&wavedims(b)==1)
		make/n=3/o tempc
		tempc={a[1]*b[2]-a[2]*b[1],-a[0]*b[2]+a[2]*b[0],a[0]*b[1]-a[1]*b[0]}
		return tempc
	else
		print "vector must be 3x1"
endif
end


///////////////////////////////////////////////////////////////////////////////
///////////////////////////////  	ARPES		////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


//n=0,1,2,3... zone center to zone center
//0.5,1.5,2.5.... X-point for square lattice in Gamma-X-Gamma direction or M-point or hexagonal lattice in Gamma-M-Gamma direction

Function WhichZone(theta1,theta2) //theta1< theta2; theta correspond to the same symmetry point
	variable theta1,theta2
	variable n
	n=1/(sind(theta2)/sind(theta1)-1)
	return n
end

Function k_n(n,theta,hv)
	variable n,theta,hv
	variable kn
	kn=0.5124/n*sqrt(hv)*sind(theta)
	return kn
end

Function theta_n(n,k,hv)
	variable n,k,hv
	variable thetan
	thetan=asind(k*n/0.5124/sqrt(hv))
	return thetan
end

Function hv_kzn(n,th,c,V0)
	variable n,th,c,V0
	variable hv
	hv=((n*2*pi/c/0.5124)^2-V0)/cosd(th)
	return hv
end


Function Calc_V0(KE2,th2,chi2,KE1,th1,chi1,a,m,n)
	variable m,KE2,th2,chi2,n,KE1,th1,chi1,a
	variable astar=2*pi/a
	th2=th2/180*pi
	chi2=chi2/180*pi
	th1=th1/180*pi
	chi1=chi1/180*pi
	variable V0
	variable c=0.5124
	V0=0.5*(astar/c)^2*(m^2+n^2)-0.5*(KE2*cos(th2)^2*cos(chi2)^2+KE1*cos(th1)^2*cos(chi1)^2)
	return V0
End

Function Calc_kz_n(KE2,th2,chi2,KE1,th1,chi1,a)	//assumes at kz2=(n+1)*astar; kz2=n*astar
	variable KE2,th2,chi2,KE1,th1,chi1,a
	variable astar=2*pi/a
	th2=th2/180*pi
	chi2=chi2/180*pi
	th1=th1/180*pi
	chi1=chi1/180*pi
	variable n
	variable c=0.5124
//	print KE2*cos(th2)^2*cos(chi2)^2
//	print KE1*cos(th1)^2*cos(chi1)^2
//	print 0.5*(c/astar)^2
	n=0.5*(c/astar)^2*abs(KE2*cos(th2)^2*cos(chi2)^2-KE1*cos(th1)^2*cos(chi1)^2)-1/2
	print "n="+num2str(n)
	return n
End

Function Calc_kz(KE,th,chi,V0)
	variable KE,th,chi,V0
	th=th/180*pi
	chi=chi/180*pi
	variable  c=0.5124
	variable kz=sqrt(c^2*KE*cos(th)^2*cos(chi)^2+c^2*V0)
	print "kz="+num2str(kz)
	return kz
end

/// Calculating the valance band maxima: put cursors on the leading edge of the valance ///
/// The function fits a line between the cursors, the VBM corresponds to when this line ///
/// crosses zero/background intensity                                                                                ///
Function Calc_VBM_graph_Dialog()
	variable bkg1,bkg2,cursAx,cursBx
	string wvname, Tname
	Tname=StringByKey("TNAME",CsrInfo(A))
	wave wv=TraceNameToWaveRef("", Tname )
	wvname=nameofwave(wv)
	cursAx=xcsr(A)
	cursBx=xcsr(B)
	string appStr
	Prompt wvname, "Wave:"
	Prompt cursAx, "VBM fitting range x1(xcrs(A)):"
	Prompt cursBx, "VBM Fitting ranges x2 (xcrs(B)):"
	Prompt bkg1, "background x1:"
	Prompt bkg2, "background x2:"
	Prompt appStr, "append to graph",popup "yes;no"
	DoPrompt "Calculate VBM" ,wvname, cursAx,cursBx,bkg1,bkg2,appStr
	if (v_flag==0)
		print "Calc_VBM("+Getwavesdatafolder(wv,4)+","+num2str(cursAx)+","+num2str(cursBx)+","+num2str(bkg1)+","+num2str(bkg2)+")"
		  Calc_VBM(wv,cursAx,cursBx,bkg1,bkg2)
		 if(cmpstr(appStr,"yes")==0)
	 		appendtograph
	 		wave VBM_y=$(GetWavesDataFolder(wv, 1 )+NameofWave(wv)+"_VBMy")
			wave VBM_x=$(GetWavesDataFolder(wv, 1 )+NameofWave(wv)+"_VBMx")
			appendtograph VBM_y vs VBM_x
		endif
	endif
End

Function Calc_VBM(wv,VBMx1,VBMx2,bkg1,bkg2)
	wave wv
	variable VBMx1,VBMx2,bkg1,bkg2
	CurveFit/q/NTHR=0 line  wv[x2pnt(wv, VBMx1 ),x2pnt(wv, VBMx2 )] /D
	wave fit_wv=$(GetWavesDataFolder(wv, 1 )+"fit_"+NameofWave(wv))
	string wvNote=note(fit_wv)
	string fitParms= StringByKey("W_coef",wvNote,"=","\r")
	fitParms=fitParms[1,strlen(fitParms)-2]
	variable a,b
	a=str2num(stringfromlist(0,fitParms,","))
	b=str2num(stringfromlist(1,fitParms,","))
	wavestats/q/r=(bkg1,bkg2) wv
	variable y0=V_avg
	make/o/n=2 $(GetWavesDataFolder(wv, 1 )+NameofWave(wv)+"_VBMy")
	make/o/n=2 $(GetWavesDataFolder(wv, 1 )+NameofWave(wv)+"_VBMx")
	wave VBM_y=$(GetWavesDataFolder(wv, 1 )+NameofWave(wv)+"_VBMy")
	wave VBM_x=$(GetWavesDataFolder(wv, 1 )+NameofWave(wv)+"_VBMx")
	VBM_x[0]=min(VBMx1,VBMx2)
	VBM_x[1]=(y0-a)/b
	VBM_y=a+b*VBM_x
	///updating wavenote
	wvNote=note(wv)
	variable VBM=NumberByKey("\rVBM",wvNote,":",";") 
	string output=num2str(VBM_x[1])+"; range:["+num2str(x2pnt(wv, VBMx1 ))+","+num2str(x2pnt(wv, VBMx2 ))+"]"
	if(numtype(VBM)!=0)
		Note wv, "VBM: "+num2str(VBM_x[1])+"; range:["+num2str(x2pnt(wv, VBMx1 ))+","+num2str(x2pnt(wv, VBMx2 ))+"]"
	else
		wvNote=Replacestringbykey("VBM",wvNote,output,":","\r")
		Note/k wv, wvNote
	endif
	print "VBM:"+output
	///Update cursors if on graph
	string Tname=StringByKey("TNAME",CsrInfo(A))
	wave wv_crs=TraceNameToWaveRef("", StringByKey("TNAME",CsrInfo(A)) )
	if(cmpstr(Getwavesdatafolder(wv_crs,4),Getwavesdatafolder(wv,4))==0)
		Cursor A $StringByKey("TNAME",CsrInfo(A)) VBMx1
		Cursor B $StringByKey("TNAME",CsrInfo(A)) VBMx2
	endif
	return VBM_x[1]
End

//////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////  	Remove Mesh via FFT	////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
Function/wave RemoveSESmesh_fft(wv,r0)
	wave wv
	variable r0
	duplicate/o wv slice
	setscale/p x 0,1,"pixels", slice
	setscale/p y 0,1,"pixels", slice	
	Redimension/s/N=(480,-1) slice//rowsize needs to be even
	fft/dest=flt slice
	wave/c flt
	flt*=cmplx(1*(exp(-(x^2+y^2)/r0)),0)
	ifft flt
	return flt
end
Function RemoveSESmesh(wv,r0) 
	wave wv
	variable r0
	//getscaling info
	duplicate/o wv $(nameofwave(wv)+"_f"), slice //wv_f is 3d-wave, slice is 2d-wave
	wave wv_f=$(nameofwave(wv)+"_f"), slice
	wv_f=nan
	redimension/n=(round(dimsize(wv,0)/2)*2,dimsize(wv,1)) slice//so that rows are even
	setscale/p x,0,1,"px", slice
	setscale/p y,0,1,"py", slice
	duplicate/o slice slice_f
	variable i
	if (wavedims(wv)==2)
		wave slice_f=RemoveSESmesh_fft(slice,r0)
		wv_f[][]=slice_f[p][q]
	elseif(wavedims(wv)==3)
		For(i=0;i<dimsize(wv,2);i+=1)
			slice[][]=wv[p][q][i]
			wave slice_f=RemoveSESmesh_fft(slice,r0)
			wv_f[][][i]=slice_f[p][q]
		endfor
	else 
		print "Only works for 2 or 3 dimensional waves"
	endif
end


Function RemoveSESmesh_Dialog()
	string wvname
	variable r0=2.5e-3 
	Prompt wvname, "Select wave to FFT:", popup, "; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	Prompt r0, "radius of filter:"
	DoPrompt "Remove SES mesh via FFT", wvname, r0
	if (v_flag==0)	
		wave wv=$wvname	
		Print "RemoveSESmesh("+wvname+","+num2str(r0)+")" 
		RemoveSESmesh(wv,r0) 
	endif
end	
	
/////////////////////////////////////////////////////////////////////////
///////////////////////////////Fermi level fits/////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function FitFermi1D(wv, x1, x2)
//use G_step from ImageTool4
	wave wv
	variable x1, x2
	make/o/n=5 EF_coef
	wave EF_coef
	//makeing guesses
	EdgeStats/Q/F=0.15/R=(x1, x2) wv
	variable slope=(V_edgeLvl1-V_edgeLvl0)/(V_edgeLoc1-x1)
	EF_coef={ V_edgeLoc2, V_edgeDloc3_1, -V_edgeAmp4_0, V_edgeLvl4, slope}
	//doing fit	
	FuncFit/Q/N G_step EF_coef wv(x1,x2) /D
	string nt= "Edge Position = "+num2str(EF_coef[0])+" eV"+"\r"
	nt=nt+"Edge Width = "+num2str(EF_coef[1])+" eV"//+"\r"
//	nt=nt+"Gaussian Width = "+num2str(EF_coef[2])+"\r"
	TextBox/C/N=fit_text0/A=MC  nt
end

Function FitFermiGraph()
	string TraceName
	string Tlist=TraceNamelist("",";",1)
	TraceName=stringfromlist(0,Tlist)
	variable x1,x2
	x1=xcsr(A,"")
	x2=xcsr(B,"")
	Prompt TraceName, "Wave to fit",popup, TraceNamelist("",";",1)	
	Prompt x1, "x1"
	Prompt x2, "x2"
	DoPrompt "Fit Fermi level for wave on top graph",TraceName, x1, x2 
	if(v_flag==0)
		Wave wv=TraceNameToWaveRef("",TraceName)
		FitFermi1D(wv,x1,x2)
		print "FitFermi1D("+NameofWave(wv)+","+num2str(x1)+","+num2str(x2)+")"
	endif
End

Function Fermi_Edge_InitalGuess(wv)
	wave wv
	//makeing guesses
	Variable x1=pcsr(A)
	Variable x2= pcsr(B)
	EdgeStats/Q/F=0.15/R=(x1,x2) wv
	variable slope=(V_edgeLvl1-V_edgeLvl0)/(V_edgeLoc1-x1)
	wave W_coef
	W_coef={ V_edgeLoc2, V_edgeDloc3_1, -V_edgeAmp4_0, V_edgeLvl4, slope}
End

Function Fermi_Edge(w,x) : FitFunc
	Wave w
	Variable x
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = y0+PreEdge*(x-EF)*((x-EF)<0)+EdgeJump*0.5*erfc((x-EF)/(Ewidth/1.66511))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = EF
	//CurveFitDialog/ w[1] = Ewidth
	//CurveFitDialog/ w[2] = EdgeJump
	//CurveFitDialog/ w[3] = y0
	//CurveFitDialog/ w[4] = PreEdge
	return w[3]+w[4]*(x-w[0])*((x-w[0])<0)+w[2]*0.5*erfc((x-w[0])/(w[1]/1.66511))
End

Function Extract_BatchResults_Dialog()
	variable colNum=2
	string ResultsMatrixFolder, newname="", ShowString
	string ResultsMatrixFolderList= ""
	variable i
	for( i=0;i<CountObjects("root:WMBatchCurveFitRuns:", 4 );i+=1)
		ResultsMatrixFolderList=AddListItem(GetIndexedObjName("root:WMBatchCurveFitRuns:", 4, i ),ResultsMatrixFolderList,";",inf)
	endfor
	Prompt ResultsMatrixFolder, "ResultsMatrix:", popup,ResultsMatrixFolderList
	Prompt colNum, "Column number for energy position:"
	Prompt newName, "New wave name, if empty string then default name"
	Prompt ShowString, "Display Results:",popup,"Both;Table;Graph;None"
	DoPrompt "Extract Batch Fitting position", ResultsMatrixFolder, colNum,newName,ShowString
	//print ResultsMatrixFolder
	wave WMBatchResultsMatrix=$("root:WMBatchCurveFitRuns:"+ResultsMatrixFolder+":WMBatchResultsMatrix")
	if (V_flag==0)
		print "Extract_WMBatchCurveFitResults("+GetWavesDataFolder(WMBatchResultsMatrix,2)+","+num2str(colNum)+","+newname+","+ShowString+")"
		Extract_WMBatchCurveFitResults(WMBatchResultsMatrix,colNum,newname,ShowString)
	endif
end


Function Extract_WMBatchCurveFitResults(WMBatchResultsMatrix,colNum,newname,ShowString) 
	variable colNum
	string newname,ShowString
	wave WMBatchResultsMatrix
	string dfn=stringfromlist( itemsinlist(GetWavesDataFolder(WMBatchResultsMatrix,1),":")-1,GetWavesDataFolder(WMBatchResultsMatrix,1),":")
	make/o/n=(dimsize(WMBatchResultsMatrix,0)) $("root:"+dfn+"_Results_"+num2str(colNum))
	wave wv_e= $("root:"+dfn+"_Results_"+num2str(colNum))
	wv_e[]=WMBatchResultsMatrix[p][colNum]
	wave/T wvname= $(GetWavesDataFolder(WMBatchResultsMatrix,1)+"WMbatchWaveNames")
	string txt = wvname[0]+"\r"
	txt+="batchCurveFitRun:"+GetWavesDataFolder(WMBatchResultsMatrix,2)+"\r"
	txt+="column: "+num2str(colNum)+"\r"
	note wv_e,txt	 
	wave org=$ wvname[0]
	setscale/p x,dimoffset(org,1),dimdelta(org,1),waveunits(org,1), wv_e
	/////Renaming the wave
	if (strlen(newname)>0)
		duplicate/o wv_e $newname
		wave wv_e=$newname
	else 
		duplicate/o wv_e  $(wvname[0]+"_Efit")
		wave wv_e=$(wvname[0]+"_Efit")
	endif
	////Displaying Results
	if (cmpstr(ShowString,"Table")*cmpstr(ShowString,"Both")==0)
		edit wv_e
	endif
	if(cmpstr(ShowString,"Graph")*cmpstr(ShowString,"Both")==0)
		display wv_e
	endif
end


Function Correct_EF(wv,Ewv,dimE,dimScan)
	wave wv, Ewv
	variable dimE,dimScan
	duplicate/o wv $(nameofwave(wv)+"_Ec")
	wave wv_Ec=$(nameofwave(wv)+"_Ec")
	//finding first valid energy point for offset
	variable i=0,E0
	wavestats/q Ewv
	E0=v_avg

	switch(wavedims(wv))
		case 2:	
			switch(dimE)
				case 0: //x-axis is Energy axis
					wv_Ec=interp2d(wv,x-(E0-Ewv[q]),y)
				break
				case 1: //y-axis is Energy axis
					wv_Ec=interp2d(wv,x,y-(E0-Ewv[p]))
				break
			endswitch
		break
		case 3:
			switch(dimE)
				case 0: //x-axis is Energy axis
					if(dimScan==1)
						wv_Ec=interp3d(wv,x-(E0-Ewv[q]),y,z)
					elseif(dimScan==2)
						wv_Ec=interp3d(wv,x-(E0-Ewv[r]),y,z)
					endif
				break
				case 1: //y-axis is Energy axis
					if(dimScan==0)
						wv_Ec=interp3d(wv,x,y-(E0-Ewv[p]),z)
					elseif(dimScan==2)
						wv_Ec=interp3d(wv,x,y-(E0-Ewv[r]),z)
					endif
				break
				case 2: //z-axis is Energy axis
					if(dimScan==0)
						wv_Ec=interp3d(wv,x,y,z-(E0-Ewv[p]))
					elseif(dimScan==1)
						wv_Ec=interp3d(wv,x,y,z-(E0-Ewv[q]))
					endif
				break
			endswitch
		break
		endswitch
		Note wv_Ec, "Energy correction wave:"+NameofWave(Ewv)
end	
Function Correct_EF_Dialog()
	string wvname, wvname_Efit
	variable dimE, dimScan
	Prompt wvname,"Wave to correct:",  popup "-2D-;"+WaveList("!*_CT",";","DIMS:2")+"-3D-;"+WaveList("!*_CT",";","DIMS:3")
	Prompt wvname_Efit, "Wave with energy positions", popup "-1D-;"+WaveList("!*_CT",";","DIMS:1")
	Prompt dimE, "Energy axis:",popup "x;y;z"
	Prompt dimScan, "Dependent axis",popup "x;y;z"
	DoPrompt "Correcting the Energy as a function, relative to the first value in the energy wave ", wvname, wvname_Efit, dimE,dimScan
	if(v_flag==0)
		wave wv=$wvname
		wave Ewv=$wvname_Efit
		print "Correct_EF("+wvname+","+wvname_Efit+","+num2str(dimE-1)+")"
		Correct_EF(wv,Ewv,dimE-1,dimScan-1)
	endif
End
/////////////////////////////////////////////////////////////////////////
/////////////////////////// Normalize XPS, XAS /////////////////////////////
/////////////////////////////////////////////////////////////////////////
Function/wave Norm2One(wv)
	wave wv
	duplicate/o wv $(nameofwave(wv)+"_n")
	wave wv_n=$(nameofwave(wv)+"_n")
	wavestats/q wv
	wv_n=(wv-v_min)/(v_max -v_min)
	return wv_n
End

Function Spectra_Norm_fromGraph_Dialog()
	string wvname
	variable p1,p2,ReplaceTraces,SRonly
	//get cusors from top graph
	p1=selectnumber(strlen(CsrInfo(A)),0,pcsr(A,""))
	p2=selectnumber(strlen(CsrInfo(B)),inf,pcsr(B,""))
	Prompt wvname, "Wave to normalize",popup,TraceNamelist("",";",1)+";--- All ---"
	Prompt p1, "Range: pnt1"
	Prompt p2, "Range: pnt2"
	Prompt SRonly, "Norm:" popup, "SRcurrent only; Max=1,Min=0; Max/Min set by cursors"
	Prompt ReplaceTraces,"Graph options:" popup,"Replace Traces;New Graph;none"
	DoPrompt "Normalize Spectra", wvname, p1,p2,SRonly,ReplaceTraces
	if(v_flag==0)
		if(cmpstr(wvname,"--- All ---")==0)
			wvname=TraceNamelist("",";",1)
		endif
		string wvlist=""
		variable i
		for(i=0;i<itemsinlist(wvname,";");i+=1)
			wave wv=TraceNameToWaveRef("",stringfromlist(i,wvname,";"))
			wvlist=addlistitem(GetWavesDataFolder($nameofwave(wv),2),wvlist,";",inf)
		endfor
		print "Spectra_Norm(\""+wvlist+"\","+num2str(p1)+","+num2str(p2)+","+num2str(SRonly-1)+")"
		Spectra_Norm(wvlist,p1,p2,SRonly)
		if(ReplaceTraces==1)
			for(i=0;i<itemsinlist(wvname,";");i+=1)
				ReplaceWave/Y trace=$stringfromlist(i,wvname) $stringfromlist(i,wvlist)+"_norm"
			endfor
		elseif(ReplaceTraces==2)
			display
			for(i=0;i<itemsinlist(wvname,";");i+=1)
				appendtograph $stringfromlist(i,wvlist)+"_norm"
			endfor
		endif
	endif
end

Function Spectra_Norm(wvlist,p1,p2,Method) //Method=0 divide by the ring curren only;Method=1normalize to max=1/min=0;Method=2  csr(A)=Min/csr(B)=Max
	string wvlist
	variable p1,p2,Method
	variable i,ymax,ymin
	for(i=0;i<itemsinlist(wvlist,";");i+=1)
		wave wv=$stringfromlist(i,wvlist,";")
		setdatafolder GetWavesDataFolderDFR(wv )
		duplicate/o wv $stringfromlist(i,wvlist,";")+"_norm"
		wave wv_norm= $stringfromlist(i,wvlist,";")+"_norm"
		variable I0=str2num(WaveNoteKeySearch(wv,"\r"+"Attr_RingCurrent")) 
		if (Method==0)
			wv_norm=wv/I0
		elseif(Method==1)
			wavestats/q/R=[p1,p2] wv_norm
			ymax=v_max
			ymin=v_min
			wv_norm=(wv_norm-ymin)/(ymax-ymin)
		elseif(Method==2)
			ymin=SelectNumber(wv[p1]<wv[p2],wv[p2],wv[p1])
			ymax=SelectNumber(wv[p1]>wv[p2],wv[p2],wv[p1])
			wv_norm=(wv_norm-ymin)/(ymax-ymin)
		endif
	endfor
end


Function XAS_Normalization(preEdge_xA, preEdge_xB, postEdge_xA, postEdge_xB,wv_TEY, wv_I0, wv_hv, DoPreEdge,DoPostEdge)
	variable preEdge_xA, preEdge_xB, postEdge_xA, postEdge_xB,DoPreEdge,DoPostEdge  //1=do, 0=skip
	wave wv_TEY, wv_I0, wv_hv
	
	variable range_xA, range_xB, a, b
	
	wave TEY_n= XAS_norm2one(wv_TEY)
	wave I0_n= XAS_norm2one(wv_I0)
	duplicate/o wv_TEY XAS
	wave XAS
	XAS=TEY_n/I0_n
	duplicate/o wv_hv XAS_hv 
	wave hv=XAS_hv
	
	//find XAS edge
	Differentiate XAS/X=hv/D=XAS_DIF
	wavestats/q XAS_DIF
	variable Edge_p=x2pnt(XAS_DIF,v_maxloc)
	variable Edge_x=hv[x2pnt(XAS_DIF,v_maxloc)]
	String EdgeNote=StringByKey("\rXAS_Edge",note(XAS),":",";") 
		if(strlen(EdgeNote)==0)
			Note XAS, "XAS_Edge: "+num2str(Edge_x)
		else
			string nt=Replacestringbykey("XAS_Edge",nt,num2str(Edge_x))
			Note/k XAS, nt
		endif

	//pre-edge subtraction	
	if(DoPreEdge ==1)
		range_xA=dimoffset(hv,0)
		range_xB=dimoffset(hv,0)+dimdelta(hv,0)*dimsize(hv,0)
		wave XAS_bkg=LinearBackgroundSubtract(range_xA,range_xB,preEdge_xA, preEdge_xB, XAS,hv)
		duplicate/o XAS_bkg XAS
		//adding/updating wavenotes
		String preEdge=StringByKey("\rXAS_preEdge",note(XAS),":",";") 
		if(strlen(preEdge)==0)
			Note XAS, "XAS_preEdge: "+num2str(a)+"; "+num2str(b)
		else
			nt=Replacestringbykey("XAS_preEdge",nt,num2str(a)+"; "+num2str(b),":","\r")
			Note/k XAS, nt
		endif
	endif
	
	//post-edge subtraction
	if(DoPostEdge ==1)
		range_xA=Edge_x
		range_xB=dimoffset(hv,0)+dimdelta(hv,0)*dimsize(hv,0)
		wave XAS_bkg=LinearBackgroundSubtract(range_xA,range_xB,postEdge_xA, postEdge_xB, XAS,hv)
		duplicate/o XAS_bkg XAS
		//adding/updating wavenotes
		String postEdge=StringByKey("\rXAS_postEdge",note(XAS),":",";") 
		if(strlen(postEdge)==0)
			Note XAS, "XAS_postEdge: "+num2str(a)+"; "+num2str(b)
		else
			nt=Replacestringbykey("XAS_postEdge",nt,num2str(a)+"; "+num2str(b),":","\r")
			Note/k XAS, nt
		endif
	endif
End
Function/wave XAS_norm2one(wv)
	wave wv
	duplicate/o wv $(nameofwave(wv)+"_n")
	wave wv_n=$(nameofwave(wv)+"_n")
	wavestats/q wv
	wv_n=(wv-v_min+.1*v_min)/(v_max -v_min)
	return wv_n
End

Function/wave LinearBackgroundSubtract(range_xA,range_xB,bkg_xA, bkg_xB, wv,wv_x)
	variable range_xA,range_xB,bkg_xA, bkg_xB
	wave wv,wv_x
	variable pA,pB, a,b,brkpnt_y
	pA=x2pnt(wv,bkg_xA)
	pB=x2pnt(wv,bkg_xB)
	string w_coef
	//Fitting a line
	CurveFit/q/NTHR=0 line  wv[pA,pB] /X=wv_x /D 
	wave fit_wv=$(GetWavesDataFolder(wv,1)+"fit_"+GetWavesDataFolder(wv,4))
	w_coef= StringByKey("W_coef",note(fit_wv),"=","\r")
	a=str2num(stringfromlist(0,w_coef[2,strlen(w_coef)-2],","))
	b=str2num(stringfromlist(1,w_coef[2,strlen(w_coef)-2],","))
	//Doing subtraction
	duplicate/o wv $(GetWavesDataFolder(wv,2)+"_bkg")
	wave wv_bkg=$(GetWavesDataFolder(wv,2)+"_bkg")
	//wv_bkg[x2pnt(wv,range_xA),x2pnt(wv,range_xB)]=wv[p]-(a+b*wv_x[p])+101.832//-wv[x2pnt(wv,range_xA)]
	print a,b,wv[x2pnt(wv,range_xA)], b*wv_x[x2pnt(wv,range_xA)]
	wv_bkg[x2pnt(wv,range_xA),x2pnt(wv,range_xB)]=wv[p]-b*wv_x[p]//+(a+wv[x2pnt(wv,range_xA)])
	wv_bkg[x2pnt(wv,range_xA),x2pnt(wv,range_xB)]=wv[p]-b*wv_x[p]+b*wv_x[x2pnt(wv,range_xA)]//+(a+wv[x2pnt(wv,range_xA)])
	//Comments	
	String BkgSub=StringByKey("\rBkgSub",note(wv),":",";") 
	if(strlen(BkgSub)==0)
		//Note wv_bkg, "BkgSub: "+num2str(a)+"; "+num2str(b)
	else
		//nt=Replacestringbykey("BkgSub:",nt,num2str(a)+"; "+num2str(b),":","\r")
		//Note/k wv_bkg, nt
	endif
	return wv_bkg
End

Function LinearBackgroundSubtract_Dialog()
	string range, bkg
	wave wv,wv_x
	string wv_name, wv_x_name
	Prompt wv_name, "Wave:", popup, waveList("*",";","DIMS:1")
	Prompt wv_x_name,"x-wave (empty string for wave scaling):",  popup, waveList("*",";","DIMS:1")
	Prompt range,"Range to apply background subtraction (xA,xB):"
	Prompt bkg, "Region to fit (xA,xB):"
	DoPrompt "Linear background subtraction parameters"wv_name, wv_x_name, range,bkg
	if (v_flag==0)
		print "LinearBackgroundSubtract("+range+","+bkg+","+wv_name+","+wv_x_name+")"
		wave wv=$wv_name
		wave wv_x=$(wv_x_name)
		variable range_xA=str2num(stringfromlist(0,range,","))
		variable range_xB=str2num(stringfromlist(1,range,","))
		variable bkg_xA=str2num(stringfromlist(0,bkg,","))
		variable bkg_xB=str2num(stringfromlist(1,bkg,","))
		LinearBackgroundSubtract(range_xA,range_xB,bkg_xA, bkg_xB, wv,wv_x)
	endif
End




/////////////////////////////////////////////////////////////////////////
//////////////////////Folder Fits//////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function SetFolder2csr()
	string trace=stringbykey("Tname",CsrInfo(A))
	wave wv=TraceNametoWaveRef("",trace)
	string df=GetWavesDataFolder(wv,1)
	setdatafolder $df
end

Function Fit2csr(fittype)//gauss,lor,line,[poly, 3]=third order polynomial
	string fittype
	string trace=stringbykey("Tname",CsrInfo(A))
	wave wv=TraceNametoWaveRef("",trace)
	execute "CurveFit/M=2/W=0/TBOX=(0x1d0) "+fittype+", "+nameofwave(wv)+"["+num2str(pcsr(A))+","+num2str(pcsr(B))+"]/D"	
end

Function FolderNFit(fittype)
	string fittype
	SetFolder2csr()
	Fit2csr(fittype)
end
	

/////////////////////////////////////////////////////////////////////////
///////////////////////////Average Image///////////////////////////	
/////////////////////////////////////////////////////////////////////////

Function ImAvgY_dialog()
//	prompt wv
//newname
	wave wv
	string newname
	string opt="/X/D=root:"+newname+"avgy"
	ImgAvg(wv,opt)
end

/////////////////////////////////////////////////////////////////////////
/////////////////////////// Transpose Wave Axes //////////////////////////	
/////////////////////////////////////////////////////////////////////////

Function TransposeWaveAxes_Dialog()
	string wvname, Axes_i, Axes_f
	Prompt wvname, "Wave:", popup, Wavelist("!*_CT",";","DIMS:2")+Wavelist("!*_CT",";","DIMS:3")
	Prompt Axes_i, "Initial axis order:", popup, "Degree/Energy/Rotation; Energy/Angle/Rotation"
	Prompt Axes_f, "Initial axis order:", popup, "Energy/Degree/Rotation;Angle/Energy/Rotation"
	DoPrompt "", wvname
	if (v_flag==0)
		wave wv=$wvname
		if((wavedims(wv)==2) & (stringmatch(Axes_i,Axes_f)==0)) //2d and change order of axes
			MatrixTranspose wv
		endif
		if(wavedims(wv)==3& (stringmatch(Axes_i,Axes_f)==0))
		MatrixOp/o wv=TransposeVol(wv,5)
		endif
	endif
end

/////////////////////////////////////////////////////////////////////////
/////////////////////////// Print  Wave Axes Units //////////////////////////	
/////////////////////////////////////////////////////////////////////////

Function  PrintWaveUnits_Dialog()
	string wvname
	Prompt wvname, "Wave:", popup, Wavelist("!*_CT",";","DIMS:4")+Wavelist("!*_CT",";","DIMS:3")+Wavelist("!*_CT",";","DIMS:2")
	DoPrompt "", wvname
	if(v_flag==0)
		PrintWaveUnits(wvname)
	endif
End

Function PrintWaveUnits(wvname)
	string wvname
	wave wv=$wvname
	variable i
	string txt=""
	For(i=0;i<wavedims(wv);i+=1)
		txt+= waveunits(wv,i)+" / "
	endfor
	txt=txt[0,strlen(txt)-4]
	print txt
end

Function Print_nc_hv(wvname)
	string wvname
	string  keysep=":",listsep=";"
	print JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_ActualPhotonEnergy",keysep,listsep) 
end

Function Print_nc_hv_Top()
	wave wv=ImageNameToWaveRef("",stringfromlist(0,ImageNameList("",";")))
	string wvname=nameofwave(wv)
	Print_nc_hv(wvname)
end


