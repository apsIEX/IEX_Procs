#pragma rtGlobals=1		// Use modern global access method.
/// Written by J.L. McChesney based on procedures from BL 7.0 at the APS (JD Delinger, E Rotenberg, A Bostwick)
/// Developement for the IEX Beamline (Sector 29 at the APS) June 2011

//Uses Killallinfolder  // BL 7.0 ALS Tools:Image_Tool4031


Function newVLSPGM()
	string wh
	variable hvmin, hvmax , hvstep
	prompt wh, "Which grating", popup, "HEG;MEG;LEG"
	prompt hvmin, "E min"
	prompt hvmax, "E max"
	prompt hvstep, "step size (delta)"
	Doprompt "VLS PGM Inputs",  wh, hvmin, hvmax, hvstep
	grating_setup(wh, hvmin, hvmax, hvstep)
end

function grating_setup(which, hvmin, hvmax, hvstep)
	string which
	variable hvmin, hvmax, hvstep
	setdatafolder "root:"
	string dfn=uniquename("VLSPGM_",11,0)
	newdatafolder/o $dfn
	string df="root:"+dfn+":"
	string/g $(df+"which")
	svar wh=$(df+"which")
	wh=which
	variable/g $(df+"Emin"), $(df+"Emax"), $(df+"Estep")
	nvar Emin=$(df+"Emin"), Emax=$(df+"Emax"), Estep=$(df+"Estep")
	Emin=hvmin; Emax=hvmax; Estep=hvstep
	MakeGratingVariables(dfn)
	MakeEnergyVariables(dfn)
	Calc_Angles(dfn)
end


Function MakeEnergyVariables(dfn)
	string dfn
	string df="root:"+dfn+":"
	nvar Emin=$(df+"Emin"), Emax=$(df+"Emax"), Estep=$(df+"Estep")
	variable size=(Emax-Emin)/Estep
	Make/o/n=(size) $(df+"hv")
	wave hv=$(df+"hv")
	hv=Emin+Estep*p
end
	
Function Calc_Angles(dfn)
	string dfn
	string df="root:"+dfn+":"
	variable delta=0.4
	wave hv=$(df+"hv")
	duplicate/o hv $(df+"alpha_i"), $(df+"beta_i"), $(df+"lambda"), $(df+"g_mono"), $(df+"t_mono")
	wave  alpha_i=$(df+"alpha_i")
	wave  beta_i=$(df+"beta_i")
	wave lambda=$(df+"lambda")
	wave g_mono=$(df+"g_mono")
	wave t_mono=$(df+"t_mono")
	nvar k0=$(df+"k0"), b2=$(df+"b2"), b3=$(df+"b3"), cff=$(df+"cff"), m=$(df+"m")  
	lambda=0.5124*sqrt(hv)*10^-7 //in mm
	variable d=(cff^2-1)
//	beta_i=asin((-sqrt(d^2+(m*k0*lambda*cff)^2)+(m*k0*lambda*cff^2))/d)*180/pi
	beta_i=asin(-sqrt(1+(m*k0*lambda*cff/(1-cff^2))^2)-(m*k0*lambda*cff^2/(1-cff^2)))*180/pi
	alpha_i=acos(cos(beta_i*pi/180)/cff)*180/pi
	g_mono=(alpha_i-beta_i)/2+delta
	t_mono=2*g_mono-alpha_i
end	
Function Calc_hvKw(dfn)
	string dfn
	string df="root:"+dfn+":"
	nvar w=$(df+"w"), Kw=$(df+"Kw")
	nvar k0=$(df+"k0"), b2=$(df+"b2"), b3=$(df+"b3"), cff=$(df+"cff"), m=$(df+"m")
	Kw=k0*(1+2*b2*w+3*b3*w^2)
	duplicate/o $(df+"hv") $(df+"hv_kw")
	wave hv_kw=$(df+"hv_kw")
	wave  beta_i=$(df+"beta_i")
	hv_kw=((sqrt(1-(cos(beta_i/180*pi)/cff)^2)+sin(beta_i/180*pi))/m/kw/0.5124*10^7)^2
end
	

Function LoadReferenceWaves()
	newdatafolder/o root:IEXReferenceSpectra
	setdatafolder IEXReferenceSpectra
	string where=SpecialDirPath("Igor Pro User Files", 0,0,0)+"User Procedures:IEx_Procs:GasCellRef:"
	NewPath/o Pathref where
	Loadwave/o/P=Pathref "Ar_int"
	Loadwave/o/P=Pathref "Ar_hv"
	Loadwave/o/P=Pathref "N2_int"
	Loadwave/o/P=Pathref "N2_hv"	
	Loadwave/o/P=Pathref "Ne_int"
	Loadwave/o/P=Pathref "Ne_hv"
	Loadwave/o/P=Pathref "O2_int"
	Loadwave/o/P=Pathref "O2_hv"
	setdatafolder root:
end
////////////////////////////////
///////////////////////////////////
Function NewGasCell()
	SetupGasCell()
End

Function SetupGasCell()
	//GasCell Folder
	setdatafolder "root:"
	string dfn=uniquename("GasCell_",11,0)
	newdatafolder/o $dfn
	string df="root:"+dfn+":"
	MakeGratingVariables(dfn)
	//Load Reference Waves
	string dfnS="root:IEXReferenceSpectra"
	string dfS=dfnS+":"
	print exists(dfns), exists(dfS)
	If(exists(dfnS)!=1)
		LoadReferenceWaves()
		Make/n=(2,2) root:IEXReferenceSpectra:img
	endif
	wave img=$(dfS+"img")
	//Making Window
	Display /W=(40,40,600,550)
	DoWindow/C/T/R $dfn,dfn
	setwindow $dfn, hook(cursorhook)=GasCellHook, hookevents=3, hook=$""
	ControlBar 100
	ModifyGraph cbRGB= (1,52428,52428)
	TabControl tab0  tablabel(0)="Spectra",  tablabel(1)="VLS-PGM", tablabel(2)="Off-sets"
	TabControl tab0 proc=IEXtabproc, size={550,20}
	//Spectra Tab
	string refstr="Argon;Neon;Nitrogen;Oxygen;None"
	PopupMenu popupRef title="Reference Spectra ",bodyWidth=100, pos={15,75}, proc=ReferencePopupMenuAction
	execute "PopupMenu popupRef,mode=2,popvalue=\"Select\",value=\""+refstr+"\""
	string wvstr=Wavelist("!*_CT",";","DIMS:1")
	PopupMenu popupdata title="Spectra ",bodyWidth=100, pos={15,50}, proc=DataPopupMenuAction
	execute "PopupMenu popupdata,mode=2,popvalue=\"Select\",value=\""+wvstr+"\""
	//VLS-PGM Tab
	PopupMenu popupWhich title="Grating", bodyWidth=100, pos={15,50}, proc=GratingPopupMenuAction
	PopupMenu popupWhich popvalue="Select", value="Select;LEG;MEG;HEG", disable=1
	string  traces="Select;"+tracenamelist("",";",1)
	popupmenu popupKw title="Adjust kw", bodywidth=100, pos={375,50}, proc=KwPopupMenuAction, disable=1 
	execute "PopupMenu popupkw,mode=2,popvalue=\"Select\",value=\""+traces+"\""
	SetVariable setvarw title="w",size={75,20}, pos={280,75},disable=1
	execute "SetVariable setvarw, value="+df+"w"
	CheckBox checkwvscaling title="Use wave scaling",pos={460,50},size={90,15}, disable=1
	execute "CheckBox checkwvscaling variable="+df+"wvscaling"
	Button UpdatekwButton title="Update", size={75,20}, pos={390,75}, proc=UpdatekwButtonControl, disable=1
	Button AppendkwButton title="Append", size={75,20}, pos={475,75}, proc=AppendkwButtonControl, disable=1
	//Off-sets tab
	variable/g $(df+"xoff"), $(df+"yoff"), $(df+"yscale")
	nvar yscale=$(df+"yscale");yscale=1
	SetVariable setvarxoff title="xoffset", size={100,20}, pos={15,30}, disable=1,proc=SetOffsets,limits={-inf,inf,0.1}
	Execute "SetVariable setvarxoff value="+df+"xoff"
	SetVariable setvaryoff title="yoffset", size={100,20}, pos={15,50}, disable=1,proc=SetOffsets,limits={-inf,inf,0.1}
	Execute "SetVariable setvaryoff value="+df+"yoff"	
	SetVariable setvaryscale title="yscale", size={100,20}, pos={15,70}, disable=1,proc=SetOffsets,limits={-inf,inf,0.1}
	Execute "SetVariable setvaryscale value="+df+"yscale"
	popupmenu popupKw2 title="Spectra to adjust", bodywidth=100, pos={375,50}, proc=KwPopupMenuAction, disable=1 
	execute "PopupMenu popupkw2,mode=2,popvalue=\"Select\",value=\""+traces+"\""
	//Appending graphs
	ModifyGraph mirror=2
	Legend/C/N=text0/A=MC
	Legend/C/N=text0/J/X=35.00/Y=35.00
End

Function ReferencePopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string df="root:IEXReferenceSpectra:"
	string refspec=tracenamelist("",";",1)
	If(strsearch(refspec,"Ar_int",0)!=-1)
		removefromgraph Ar_int
	endif
	If(strsearch(refspec,"n2_int",0)!=-1)
		removefromgraph N2_int
	endif
	if(strsearch(refspec,"Ne_int",0)!=-1)
		removefromgraph Ne_int
	endif
	if(strsearch(refspec,"O2_int",0)!=-1)
		removefromgraph o2_int
	endif
	strswitch(popstr)
		case "Argon":
			wave Ar_int=$(df+"Ar_int"), Ar_hv=$(df+"Ar_hv")
			appendtograph Ar_int vs Ar_hv
			ModifyGraph rgb(Ar_int)=(0,0,65535)
		break
		case "Nitrogen":
			wave N2_int=$(df+"N2_int"), N2_hv=$(df+"N2_hv")
			appendtograph N2_int vs N2_hv
			ModifyGraph rgb(n2_int)=(0,0,65535)
		break
		case "Neon":
			wave Ne_int=$(df+"Ne_int"), Ne_hv=$(df+"Ne_hv")
			appendtograph Ne_int vs Ne_hv
			ModifyGraph rgb(ne_int)=(0,0,65535)
		break
		case "Oxygen":
			wave o2_int=$(df+"o2_int"), o2_hv=$(df+"o2_hv")
			appendtograph O2_int vs O2_hv
			ModifyGraph rgb(o2_int)=(0,0,65535)
		break
		case "None":
		break
	endswitch
	ModifyGraph mirror=2		
End

Function DataPopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	string wvstr=Wavelist("!*_CT",";","DIMS:1")
	print "select"
	execute "PopupMenu popupdata value=\""+wvstr+"\""
	wave wv=$popstr
	string wdf=getdatafolder(wv)
	appendtograph wv
	ModifyGraph rgb($popstr)=(0,0,0)
	duplicate/o wv $(df+"hv")
	wave hv=$(df+"hv")
	hv=dimoffset(wv,0)+p*dimdelta(wv,0)
End

Function GratingPopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar which=$(df+"which")
	which=popstr
	nvar k0=$(df+"k0"), b2=$(df+"b2"), b3=$(df+"b3"), cff=$(df+"cff") , m=$(df+"m")
	m=1
	strswitch(which)
		case "HEG":
		k0=2400
		b2=.544*10^-4
		b3=2.60*10^-9
		cff=4.2
		break
		case "MEG":
		k0=1200
		b2=.695*10^-4
		b3=2.97*10^-9
		cff=2.2		
		break
		case "LEG":
		k0=400
		b2=1.1*10^-4
		b3=4.00*10^-9
		cff=1.5		
		break
	endswitch
	nvar kw=$(df+"kw"), w=$(df+"w")
	Kw=k0*(1+2*b2*w+3*b3*w^2)
	Calc_Angles(dfn)
End

Function KwPopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr	
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar kwspectra=$(df+"kwspectra")
	kwspectra=popstr
	string traces=tracenamelist("",";",1)
	execute "popupmenu popupKw, value=\""+traces+"\""
	execute "popupmenu popupKw2, value=\""+traces+"\""
end


Function UpdatekwButtonControl (ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar wvscaling=$(df+"wvscaling")
	svar kwspectra=$(df+"kwspectra")
	wave wv=tracenametowaveref(winname(0,1),kwspectra)
	If(wvscaling)
		duplicate/o wv $(df+"hv")
		wave hv=$(df+"hv")
		hv=dimoffset(wv,0)+p*dimdelta(wv,0)
	Else
		string hvp
		prompt hvp, "path for hv file"
		Doprompt "hv input for "+kwspectra , hvp
		wave hv=$hvp
		duplicate hv $(df+"hv")
	endif
	Calc_Angles(dfn)
	Calc_hvKw(dfn)
end

Function AppendkwButtonControl (ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar wvscaling=$(df+"wvscaling")
	svar kwspectra=$(df+"kwspectra")
	wave wv=tracenametowaveref(winname(0,1),kwspectra)
	If(wvscaling)
		duplicate/o wv $(df+"hv")
		wave hv=$(df+"hv")
		hv=dimoffset(wv,0)+p*dimdelta(wv,0)
	Else
		string hvp
		prompt hvp, "path for hv file"
		Doprompt "hv input for "+kwspectra , hvp
		wave hv=$hvp
		duplicate hv $(df+"hv")
	endif
	wave hv_kw=$(df+"hv_kw")
	Calc_Angles(dfn)
	Calc_hvKw(dfn)
	Appendtograph wv vs hv_kw
end

Function SetOffsets (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar xoff=$(df+"xoff"), yoff=$(df+"yoff"), yscale=$(df+"yscale")
	svar kwspectra=$(df+"kwspectra")
	wave wv=tracenametowaveref(winname(0,1),kwspectra)
	Execute "ModifyGraph offset("+kwspectra+")={"+num2str(xoff)+","+num2str(yoff)+"},muloffset("+kwspectra+")={0,"+num2str(yscale)+"}"
//	ModifyGraph offset(kwspectra)={xoff,yoff},muloffset(kwspectra)={0,yscale}
End

Function IEXTabProc(name,tab)
	string name
	variable tab
	//Tab 0 -- Spectra
	PopupMenu popupRef, disable=(tab!=0) 
	PopupMenu popupdata, disable=(tab!=0)
	//Tab1 -- VLS-PGM
	PopupMenu popupWhich, disable=(tab!=1)
	popupmenu popupKw, disable=(tab!=1 )
	SetVariable setvarw	, disable=(tab!=1)
	CheckBox checkwvscaling, disable=(tab!=1)
	Button UpdatekwButton, disable=(tab!=1)
	Button AppendkwButton, disable=(tab!=1)
	//Tab2 -- Offsets
	SetVariable setvarxoff, disable=(tab!=2)
	SetVariable setvaryoff, disable=(tab!=2)
	SetVariable setvaryscale, disable=(tab!=2)
	popupmenu popupKw2, disable=(tab!=2)
End

Function GasCellHook(H_Struct)	
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	string dfn=H_Struct.winName; string df="root:"+dfn+":"
	if(eventcode==2)
		dowindow /F $dfn
		RemoveGasCell()
		killallinfolder(df)
		killdatafolder $df
		return(-1)
	endif
end
	
function MakeGratingVariables(dfn)
	string dfn
	string df="root:"+dfn+":"
	string/g $(df+"which"),  $(df+"kwspectra")
	variable/g $(df+"w"), $(df+"Kw"), $(df+"wvscaling")
	variable/g $(df+"Emin"), $(df+"Emax"), $(df+"Estep")
	variable/g  $(df+"k0"), $(df+"b2"), $(df+"b3"), $(df+"cff"), $(df+"m")
	nvar w=$(df+"w"), wvscaling=$(df+"wvscaling")
	w=0
	wvscaling=1
end

Function RemoveGasCell()
	string imglist=imagenamelist("",";"), tracelist=tracenamelist("",";",1)
	execute "removeimage/z "+ imglist[0,strlen(imglist)-2]			//remove all images
	execute "removefromgraph/z "+  tracelist[0,strlen(tracelist)-2]		//remove all traces
end