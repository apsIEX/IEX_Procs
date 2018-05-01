#pragma rtGlobals=1		// Use modern global access method.
/// Written by J.L. McChesney 
/// Developement for the IEX Beamline (Sector 29 at the APS) June 2011
/// To modify for other beamline parameters put grating parameters in to MonoPanelAngles Procedure

//Uses Killallinfolder  // BL 7.0 ALS Tools:Image_Tool4031
Function Mono_Panel()
	If(WinType("MonoPanel")!=7)
		MonoPanelVariables()
		MonoPanelSetup()
	else 
		dowindow/f MonoPanel
	endif
	
End

function MonoPanelVariables()
	newdatafolder/o root:MonoPanel
	string df="root:MonoPanel:"
	variable/g $(df+"MPeV"), $(df+"MPbeta"), $(df+"MPalpha"), $(df+"MPgamma"), $(df+"MPtheta")
	variable/g $(df+"MPbeta_"), $(df+"MPalpha_"), $(df+"MPgamma_"), $(df+"MPtheta_")
	variable/g $(df+"w"), $(df+"f2"), $(df+"fg"), $(df+"MPx"), $(df+"MPm2x")
	string/g $(df+"MPwhich")
	svar MPwhich=$(df+"MPwhich")
	MPwhich="LEG"
	nvar MPeV=$(df+"MPeV")
	MPev=250
end

function MonoPanelSetVariableControl(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	MonoPanelAngles()
end

Function MonoPanelPopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	svar MPwhich =$("root:MonoPanel:MPwhich")
	MPwhich=popStr
	MonoPanelAngles()
End

function MonoPanelAngles()
	string df="root:MonoPanel:"
	nvar MPeV=$(df+"MPeV"), MPbeta=$(df+"MPbeta"), MPalpha=$(df+"MPalpha"), MPgamma=$(df+"MPgamma"), Mptheta=$(df+"MPtheta")
	nvar MPbeta_=$(df+"MPbeta_"), MPalpha_=$(df+"MPalpha_"), MPgamma_=$(df+"MPgamma_"), Mptheta_=$(df+"MPtheta_")
	svar MPwhich=$(df+"MPwhich")
	nvar w=$(df+"w"), f2=$(df+"f2"), fg=$(df+"fg"), MPx=$(df+"MPx"), MPm2x= $(df+"MPm2x")
//	variable/g  $(df+"k0"), $(df+"b2"), $(df+"b3"), $(df+"cff"), $(df+"m")
	variable k0, b2, b3, cff, m=-1, delta=0.4
	variable lambda=1240*10^(-6)/MPeV//in mm
	variable g=0 //0 for Ruben's orginial parameters, 1 for new JY parameters
	strswitch(MPwhich) //IEX parameters from JY
		case "HEG":
		k0=2400
		b2=5.44*10^-5
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
		b2=selectnumber(g,1.1*10^-4 ,1.1*10^-4)
		b3=selectnumber(g,4.00*10^-9,3.9*10^-9)
		cff=1.5
		break
		case "HEG_JY":
		k0=2400
		b2=.543*10^-4
		b3=2.3*10^-9
		cff=4.2
		break
		case "MEG_JY":
		k0=1200
		b2=6.9*10^-5
		b3=3.0*10^-9
		cff=2.2
		break
	endswitch
	/////
	if(0==0)
		variable ra=39700//IEX parameter ra= distance source grating 
		variable rb=20000 //IEX parameter rb= distance grating slit
		variable r=rb/ra
		variable A0=k0*lambda
		variable A2=-k0*lambda*rb*b2
		cff=sqrt((2*A2+4*(A2/A0)^2+(4+2*A2+A0^2)*r-4*(A2/A0*sqrt((1+r)^2+2*A2*(1+r)-A0^2*r)))/(-4+A0^2-4*A2+4*(A2/A0)^2))	
	endif
	/////
	variable ca2=1-cff^2, cb2=1-(1/cff^2)	
	MPalpha=asin(sqrt(1-(m*k0*lambda)^2/ca2+(m*k0*lambda/ca2)^2)-m*k0*lambda/ca2)*180/pi
	MPbeta=asin(-sqrt(1-(m*k0*lambda)^2/cb2+(m*k0*lambda/cb2)^2)-m*k0*lambda/cb2)*180/pi
//	MPbeta=acos(cff*cos(MPalpha/180*pi))*180/pi
	MPgamma=(MPalpha-MPbeta)/2+delta
	MPtheta=2*MPgamma-MPalpha
	MPbeta_=90+MPbeta
	MPalpha_=90-MPalpha
	MPgamma_=90-MPgamma
	MPtheta_=90-MPtheta	
	f2=w/sin(MPgamma_*pi/180) //footprint on M2
	fg=w/sin(MPalpha_*pi/180) //footprint on grating
	variable y=15  //beam offset in IEX mono (mm) 
	MPx=y/sin((180-2*MPgamma)*pi/180) //distance from M2 to grating in mm. The grating is fixed at 39700mm from source
	MPm2x=8400-sin((2*MPgamma-90)*pi/180)*MPx
end
Function RubenAngles(eV,k0,b2) 
	variable eV,k0,b2

	variable  lambda=1239.85*10^(-6)/eV//in mm
	variable ra=39700//IEX parameter ra= distance source grating 
	variable rb=20000 //IEX parameter rb= distance grating slit
	
	variable r=rb/ra
	variable A0=k0*lambda
	variable A2=-k0*lambda*rb*b2
	variable cff, a, b
	cff=sqrt((2*A2+4*(A2/A0)^2+(4+2*A2+A0^2)*r-4*(A2/A0*sqrt((1+r)^2+2*A2*(1+r)-A0^2*r)))/(-4+A0^2-4*A2+4*(A2/A0)^2))	
	a=asin(-A0/(cff^2-1)+sqrt(1+((cff*A0)/(cff^2-1))^2))
	b=acos(cff*cos(a))
	variable ad= a*180/pi
	variable bd= b*180/pi
	variable gd=(ad+bd)/2-.4
	print "alpha = ", ad
	print "beta = ", bd
	print "gamma =", gd
	print "M1 to M2", 8400-sind(2*gd-90)*15/sind(180-2*gd)
	print "M2tograting", 15/sind(180-2*gd)
	

end

function newmonoangles(m, lambda, k0, b2, ra, rb, MPdelta, y)
	variable m, lambda, k0, b2, ra, rb, MPdelta, y
	variable A0=m*k0*lambda
	variable A2=A0*b2*rb
	variable r=rb/ra
	
	variable cff=sqrt((2*A2+4*(A2/A0)^2+(4+2*A2+A0^2)*r-4*(A2/A0*sqrt((1+r)^2+2*A2*(1+r)-A0^2*r)))/(-4+A0^2-4*A2+4*(A2/A0)^2))
	variable MPalpha=asin(sqrt(1-(A0*cff/(1-cff^2))^2)-A0/(1-cff^2))*180/pi
	variable MPbeta=asin(-sqrt(1+(A0/(1-cff^2))^2)+A0*cff^2/(1-cff^2))*180/pi
	variable MPgamma=(MPalpha-MPbeta)/2+MPdelta
	
	variable i, t
	For(i=0;i<5;i+=1)
		t=MPgamma
		ra+=+y/sin(2*MPgamma/180*pi)*(1+cos(2*MPgamma/180*pi))
		r=rb/ra
		cff=sqrt((2*A2+4*(A2/A0)^2+(4+2*A2-A0^2)*r+4*A2/A0*sqrt((r+1)^2+2*A2*(r+1)-A0^2*r))/(-4+A0^2-4*A2+4*(A2/A0)^2) )
		MPalpha=asin(sqrt(1-(A0*cff/(1-cff^2))^2)-A0/(1-cff^2))*180/pi
		MPbeta=asin(-sqrt(1+(A0/(1-cff^2))^2)+A0*cff^2/(1-cff^2))*180/pi
		MPgamma=(MPalpha-MPbeta)/2+MPdelta		
	endfor
	variable dM2Gr=y/sin((180-2*MPgamma)*pi/180)
	variable dM1M2=8400-sin((2*MPgamma-90)*pi/180)*dM2Gr
end

Function MonoPanelSetup() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(333,182,821,438)
	DoWindow/C/T/R MonoPanel,"Mono Panel"
	setwindow MonoPanel, hook(cursorhook)=MonoPanelHook//, hookevents=3, hook=$""
	// Draw Mono
	GroupBox groupMono,pos={190,10},size={285,160}
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (21845,21845,21845)
	DrawPoly 222,41,1,1,{29,101,79,123,82,117,34,95,29,101}
	SetDrawEnv linethick= 2,linefgc= (52428,1,1)
	DrawLine 197,53,248,53
	SetDrawEnv linethick= 2,linefgc= (52428,1,1)
	DrawLine 248,53,299,100
	SetDrawEnv linethick= 2,linefgc= (52428,1,1),arrow= 1
	DrawLine 298,98,402,89
	SetDrawEnv fillfgc= (21845,21845,21845)
	DrawPoly 233.896551724138,93,2.44828,1,{62,157,118,170,114,180,60,167,62,157}
	SetDrawEnv fname= "Symbol"
	DrawText 240,69,"2g"
	SetDrawEnv dash= 1,arrow= 1
	DrawLine 297,100,317,33
	SetDrawEnv fname= "Symbol"
	DrawText 289,88,"a"
	SetDrawEnv fname= "Symbol"
	DrawText 307,93,"b"
	SetDrawEnv dash= 1,arrow= 1
	DrawLine 299,97,469,97
	SetDrawEnv fname= "Symbol"
	DrawText 408,98,"2d=0.8"
	SetDrawEnv fname= "Symbol"
	DrawText 316,29,"q"
	SetDrawEnv fsize= 8
	DrawText 33,124,"Surface Normal"
	SetDrawEnv fsize= 8
	DrawText 118,124,"Grazing"
	DrawText 36,28,"In-Focus VLS-PGM"
	SetDrawEnv fsize= 10
	DrawText 210,140,"M2 angle"
	SetDrawEnv fname= "Symbol"
	DrawText 195,140,"g="
	SetDrawEnv fname= "Symbol"
	DrawText 195,155,"q="
	SetDrawEnv fsize= 10
	DrawText 210,155,"grating angle"
	SetVariable setvarMPx title="dist from M2 to grating",size={175,20}
	SetVariable setvarMPx value=root:MonoPanel:MPx,limits={-inf,inf,0}, pos={290,135}
	SetVariable setvarMPm2x title="distance M1 to M2",size={175,20}
	SetVariable setvarMPm2x value=root:MonoPanel:MPm2x,limits={-inf,inf,0}, pos={290,150}	
	//Grating and Energy
	GroupBox group0,pos={5,30},size={180,65}
	SetVariable setvareV,pos={10,67},size={170,15},proc=MonoPanelSetVariableControl,title="Photon Energy (eV)"
	SetVariable setvareV,limits={-inf,inf,10},value= root:MonoPanel:MPeV
	PopupMenu popupwhich,pos={15,40},size={165,15},proc=MonoPanelPopupMenuAction,title="Select Grating "
	PopupMenu popupwhich,mode=2,popvalue="Select",value= #"\"LEG;MEG;HEG;MEG_JY;HEG_JY\""
	//Angles set variables
	GroupBox groupAngles,pos={10,100},size={160,115}
	SetVariable setvarAlpha,pos={20,125},size={85,15},title="Alpha"
	SetVariable setvarAlpha,limits={-inf,inf,0},value= root:MonoPanel:MPAlpha
	SetVariable setvarBeta,pos={20,145},size={85,15},title="Beta"
	SetVariable setvarBeta,limits={-inf,inf,0},value= root:MonoPanel:MPbeta
	SetVariable setvarGamma,pos={20,165},size={85,15},title="Gamma"
	SetVariable setvarGamma,limits={-inf,inf,0},value= root:MonoPanel:MPGamma
	SetVariable setvarTheta,pos={20,185},size={85,15},title="Theta"
	SetVariable setvarTheta,limits={-inf,inf,0},value= root:MonoPanel:MPtheta
	SetVariable setvarBeta1,pos={110,145},size={55,15},title=" "
	SetVariable setvarBeta1,limits={-inf,inf,0},value= root:MonoPanel:MPbeta_
	SetVariable setvarAlpha1,pos={110,125},size={55,15},title=" "
	SetVariable setvarAlpha1,limits={-inf,inf,0},value= root:MonoPanel:MPalpha_
	SetVariable setvarGamma1,pos={110,165},size={55,15},title=" "
	SetVariable setvarGamma1,limits={-inf,inf,0},value= root:MonoPanel:MPgamma_
	SetVariable setvarTheta1,pos={110,185},size={55,15},title=" "
	SetVariable setvarTheta1,limits={-inf,inf,0},value= root:MonoPanel:MPtheta_	
	Button CreateMonobutton, title="Create Angle Waves", proc=CreateMonoButtonProc
	Button CreateMonobutton pos={20,225},size={150,20}
	//Beam size
	GroupBox groupBeam,pos={230,175},size={230,70}
	SetVariable setvarwidth,pos={235,180},size={125,15},proc=MonoPanelSetVariableControl,title="Beam size (mm)"
	SetVariable setvarwidth,limits={-inf,inf,0.1},value= root:MonoPanel:w
	SetVariable setvarwidth1,pos={250,200},size={180,15},title="Footprint on M2  (mm)"
	SetVariable setvarwidth1,limits={-inf,inf,0},value= root:MonoPanel:f2
	SetVariable setvarwidth2,pos={250,220},size={180,15},title="Footprint on grating  (mm)"
	SetVariable setvarwidth2,limits={-inf,inf,0},value= root:MonoPanel:fg
EndMacro

Function CreateMonoButtonProc (ctrlName) : ButtonControl
	String ctrlName
	CreateMonoAngleWaves()
End

Function CreateMonoAngleWaves()
	string df="root:MonoPanel:"
	variable Emin=250, Emax=2500, Estep=50
	string MPwhich, norg
	prompt Emin, "Minimum Energy (eV)"
	prompt Emax, "Maximum Energy (eV)"
	prompt Estep, "Step size (eV)"
	prompt MPwhich, "Grating", popup "LEG;MEG;HEG"
	prompt norg, "Angle with respect to", popup "Normal;Grazing"
	DoPrompt "Make Grating Angles", MPwhich, Emin, Emax, Estep, norg
	If (V_flag)
		return -1
	endif
	variable size=round((Emax-Emin)/Estep)+1
	Make/o/n=(size) $(MPwhich+"_hv")
	wave wveV=$(MPwhich+"_hv")
	wveV=Emin+p*Estep
	duplicate/o wveV  $(MPwhich+"_Alpha"), $(MPwhich+"_Beta"), $(MPwhich+"_Gamma"), $(MPwhich+"_Theta")
	wave wvalpha=$(MPwhich+"_Alpha"), wvbeta=$(MPwhich+"_Beta"), wvGamma=$(MPwhich+"_Gamma"), wvTheta=$(MPwhich+"_Theta")
	variable i, eV
	nvar MPeV=$(df+"MPeV"), MPalpha=$(df+"MPalpha"), MPbeta=$(df+"MPbeta"), MPgamma=$(df+"MPgamma"), MPtheta=$(df+"MPtheta")	
	for (i=0;i<dimsize(wveV,0);i+=1)
		MPeV=wveV[i]
		MonoPanelAngles()
		wvalpha[i]=MPalpha
		wvbeta[i]=MPbeta
		wvgamma[i]=MPgamma
		wvtheta[i]=MPtheta
	endfor
	Edit wveV
	Appendtotable wvalpha, wvbeta, wvgamma, wvtheta
	If (stringmatch(norg, "Grazing"))
		wvalpha=90-wvalpha
		wvbeta+=90
		wvgamma=90-wvgamma
		wvtheta=90-wvtheta
	endif
End

Function MonoPanelHook(H_Struct)	
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	string dfn=H_Struct.winName; string df="root:"+dfn+":"
	if(eventcode==2)
		dowindow /F $dfn
		killallinfolder(df)
		killdatafolder $df
		return(-1)
	endif
end

