#pragma rtGlobals=1		// Use modern global access method.
#include <KBColorizeTraces>

#include "JLM_FolderUtilities"
#include "JLM_GraphUtilities"
#include "JLM_MathConversions"
#include "JLM_WaveUtilities" //Wave Note Utilites , Scan Name Utilites

Menu "APS Procs"
	Submenu "Analysis Tools"		
		"FitFermiGraph",FitFermiGraph()
		"FFT to remove SES mesh", RemoveSESmesh_Dialog()
		"Set df and fit with cursors", print "FolderNFit(fittype)"
		"Normalize Spectra XPS_XAS", Spectra_Norm_fromGraph_Dialog()
	
	end
end

/////////////////////////////////////////////////////////////////////////
///////////////		Folder Procedures		 ////////////////////////////////
/////////////////////////////////////////////////////////////////////////
Function/s FolderListGet(dfr,matchstr)
// returns an alphabetical list of folder names located in datafolder reference dfr with
// a name matching matchstr; matchstr="*" for all folders"
	DFREF dfr
	string matchstr
	string fldlist=""
	variable i
	for (i=0;i<countobjectsdfr(dfr, 4);i+=1)
		string folder=GetIndexedObjNameDFR(dfr, 4, i )
		if(stringmatch(folder,matchstr)==1)
			fldlist=addlistitem(folder,fldlist, ";")
		endif
	endfor
	fldlist=sortlist(fldlist,";",16)
	return fldlist 
End

/////////////// 	---	Folder Panel  ---   //////////////////////////////////
Function ChangeFolder_Panel()
	if(WinType("ChangeFolderPanel")!=7)
		ChangeFolderPanel_Variables()
		ChangeFolderPanel_Setup() 
	else
		dowindow/f ChangeFolderPanel
	endif
end
Function ChangeFolderPanel_Variables()
	DFREF saveDFR = GetDataFolderDFR()
	NewDataFolder/o/s root:ChangeFolderPanel
	DFREF dfr=root:ChangeFolderPanel
	string/g dfr:parentDF, dfr:fldname, dfr:fldlist
	svar parentDF=dfr:parentDF, fldlist=dfr:fldlist, fldname=dfr:fldname
	parentDF=Getdatafolder(1)
	DFREF parentDFR=$parentDF
	fldlist=FolderListGet(parentDFR,"*")
	fldname=stringfromlist(0,fldname,";")
End
Function ChangeFolderPanel_Setup()
	DFREF dfr=root:ChangeFolderPanel
	svar fldlist=dfr:fldlist, fldname=dfr:fldname
	NewPanel /W=(514,454,779,535) 
	DoWindow/C/T/R ChangeFolderPanel,"ChangeFolderPanel"
	setwindow ChangeFolderPanel, hook(cursorhook)=ChangeFolderPanel_Hook, hookevents=3, hook=$""
	ModifyPanel cbRGB=(1,52428,52428)
	SetVariable ParentFolder pos={8,8},size={200,20},limits={-inf,inf,0},title="Parent Folder:"
	SetVariable ParentFolder,proc=ChangeFolderPanel_PopFolderList//, value= #("root:ChangeFolderPanel:ParentDF") 
	PopupMenu popupFolderList,pos={8,38},size={95,20},proc=ChangeFolderPanel_PopFolderList,title="Folder:"
	PopupMenu popupFolderList,mode=1,popvalue="---",value= #("root:ChangeFolderPanel:fldlist") 	
	Button buttonF title=">",pos={200,37},size={15,20},proc=ChangeFolderPanel_ButtonProcs
	Button buttonR title="<",pos={180,37},size={15,20},proc=ChangeFolderPanel_ButtonProcs
End
Function ChangeFolderPanel_PopFolderList(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	pa.blockReentry = 1
	DFREF dfr=root:ChangeFolderPanel
	svar fldlist=dfr:fldlist, fldname=dfr:fldname,parentDF=dfr:parentDF
	
	DFREF parentDFR = $parentDF
	fldlist=FolderListGet(parentDFR,"*")
	Variable popNum = pa.popNum
	String popStr = pa.popStr
	fldname=popStr
	PopupMenu popupFolderList popvalue=popStr
//	print parentDF,fldname
///
	SetDataFolder  $(parentDF+fldname)
	return 0
End
Function ChangeFolderPanel_ButtonProcs(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	DFREF dfr=root:ChangeFolderPanel
	svar fldlist=dfr:fldlist, fldname=dfr:fldname
	variable which=whichlistitem(fldname,fldlist,";")
	Switch(B_Struct.eventCode)
		case 2: 		//Mouse up
			variable i
			strSwitch(B_Struct.ctrlName)
				case "buttonF":
					i=1
					break
				case  "buttonR":
					i=-1
					break
			endswitch	
			if((which+i)>itemsinlist(fldlist,";"))
				which=0
			elseif((which+i)<0)
				which=itemsinlist(fldlist,";")
			else
				which=which+i
			endif
			fldname=stringfromlist(which,fldlist,";")
			STRUCT WMPopupAction pa
			pa.ctrlName="popupFolderList"
			pa.popStr=fldname
			pa.popNum=which
			ChangeFolderPanel_PopFolderList(pa)
			 PopupMenu popupFolderList,mode=1,popvalue=fldname//,value=fldlist 
		break
	endswitch
End


Function ChangeFolderPanel_Hook(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	string dfn=H_Struct.winName; string df="root:"+dfn+":"
	if(eventcode==2)
		dowindow /F $dfn
		JLM_FileLoaderModule#killallinfolder(df)
		killdatafolder $df
		return(-1)
	elseif(eventcode==3)
		FolderListGet(root:ChangeFolderPanel,"*")
	endif
end
End

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

Function DivideFermiFunction_Dialog()
	string wvname, wvcoef
	variable Edim
	Prompt wvname, "Data wave:", popup, "; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")+"; -- 1D --;"+WaveList("!*_CT",";","DIMS:1")
	Prompt wvcoef, "Fit coeffients:", popup, WaveList("*EF_coef",";","DIMS:1")+";"+WaveList("!*_CT",";","DIMS:1")
	Prompt Edim, "Dimension of energy axis"
	DoPrompt "Divide by Fermi function", wvname, wvcoef, Edim
	wave EF_coef=$wvcoef
	if(v_flag==0)
		Wave wv=$wvname
		DivideFermiFunction(wv,Edim,EF_coef[0],EF_coef[1],EF_coef[2],EF_coef[3],EF_coef[4])
		print "DivideFermiFunction("+wvname+","+num2str(EF_coef[0])+","+num2str(EF_coef[1])+","+num2str(EF_coef[2])+","+num2str(EF_coef[3])+","+num2str(EF_coef[4])+")"
	endif
End

Function DivideFermiFunction(wv,Edim,Ef,Ew,Af,y0,Ay)
	wave wv
	variable Edim,Ef,Ew,Af,y0,Ay
	duplicate/o wv $(nameofwave(wv)+"_Ediv")
	wave wv_E=$(nameofwave(wv)+"_Ediv")
	make/o/n=(dimsize(wv,Edim)) Fermi
	wave Fermi
	Fermi=y0+Ay*(x-Ef)*((x-Ef)<0)+Af*0.5*erfc((x-Ef)/(Ew/1.66511)) 	//G_step
	switch (wavedims(wv))
		case 1:
			break
		case 2:
			break
		case 3:
			break
		case 4:
			break
	endswitch
End

/////////////////////////////////////////////////////////////////////////
/////////////////////////// Normalize XPS, XAS /////////////////////////////
/////////////////////////////////////////////////////////////////////////
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
///////////////////////////ImageTool Add Ons///////////////////////////	
/////////////////////////////////////////////////////////////////////////

Function CmdLineCT(which)
	variable which
	selectCTList("",which,"") 
	//43 Purple-Yellow
	//42 Rainbow Light
End

Menu "2D"
	"Change color table from command line", print "CmdLineCT(which+1)"
end

Menu "APS Procs"
		Submenu "Graph Utilities"
			"--------------"
			"Export CT and Graph Main Img", ExportCTandGraphImg()
			"Change color table from command line", print "CmdLineCT(which+1)"
		End
	End
End


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