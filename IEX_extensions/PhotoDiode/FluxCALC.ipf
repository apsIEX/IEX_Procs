#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "APS Procs"
	Submenu "Extensions"
		Submenu "Photodiode"
			"Ca2Flux", print "Ca2Flux(ev, ca)"
			"Ca2Flux Waves", print "Ca2Flux_wv(ev_wv, ca_wv)"
		End
	End
End

Function LoadResponsivity()
	newdatafolder/o root:DiodeCurrent2Flux
	setdatafolder DiodeCurrent2Flux
	pathinfo Igor
	string where=SpecialDirPath("Igor Pro User Files", 0,0,0)+"User Procedures:IEX_Procs:IEX_extensions:PhotoDiode"
	NewPath/o Pathref where
	Loadwave/q/o/P=Pathref "Responsivity"
	Loadwave/q/o/P=Pathref "Energy"
	Loadwave/q/o/P=Pathref "Responsivity2"
	Loadwave/q/o/P=Pathref "Energy2"
	setdatafolder root:
end

Function Ca2Flux(ev, ca)
	variable ev, ca
	variable flux, eff, charge
	string dfn="DiodeCurrent2Flux"
	string df="root:"+dfn+":"
	wave energy = $(df + "energy"), energy2 = $(df + "energy2")
	wave responsivity = $(df + "responsivity"), responsivity2 = $(df + "responsivity2")
	charge = 1.6e-19
	if (ev < 1950)
		eff = interp(ev, energy, responsivity)
	else
		eff = interp(ev, energy2, responsivity2)
	endif
	flux = ca/(eff*ev*charge)
	return flux
end

Function Flux2Ca(ev, flux)
	variable ev, flux
	variable ca, eff, charge
	string dfn="DiodeCurrent2Flux"
	string df="root:"+dfn+":"
	wave energy = $(df + "energy"), energy2 = $(df + "energy2")
	wave responsivity = $(df + "responsivity"), responsivity2 = $(df + "responsivity2")
	charge = 1.6e-19
	if (ev < 1950)
		eff = interp(ev, energy, responsivity)
	else
		eff = interp(ev, energy2, responsivity2)
	endif
	ca = flux*(eff*ev*charge)
	return ca
end

Function Ca2Flux_wv(ev,ca)
	wave ca, ev
	duplicate/o ca $("flux"+nameofwave(ca))
	wave flux=$("flux"+nameofwave(ca))
	flux[]=ca2flux(ev[p],ca[p])
end

Function DiodeFlux_Panel()
	if(WinType("Diode2Flux")!=7)
		LoadResponsivity()
		DiodeFluxVariables()
		DiodeFluxPanel()
	else
		dowindow/f Diode2Flux
	endif
end

Function DiodeFluxVariables()
	string dfn="DiodeCurrent2Flux"
	string df="root:"+dfn+":"
	variable/g $(df+"CAset"), $(df+"CalcFlux"), $(df+"eVset"), $(df+"Fluxset"), $(df+"CalcCA")
	nvar CAset=$(df+"CAset"), CalcFlux=$(df+"CalcFlux"), eVset=$(df+"eVset"), Fluxset=$(df+"Fluxset"), CalcCa=$(df+"CalcCA")
End

Function DiodeFluxPanel()
	NewPanel /W=(655,329,936,405)
	DoWindow/C/T/R Diode2Flux,"Diode Current to Flux"
	string dfn="DiodeCurrent2Flux"
	string df="root:"+dfn+":"
	SetVariable setvarCAset,pos={6,50},size={120,13},title="CA", value=$(df+"CAset"), proc=DiodeFluxPanelProc
	SetVariable setvarCalcFlux,pos={145,50},size={120,13}, limits={-inf,inf,0},title="Flux=", value=$(df+"CalcFlux"),proc=DiodeFluxPanelProc
	SetVariable setvareVset,pos={70,7},size={100,13},title="Energy (eV)", value=$(df+"eVset"),proc=DiodeFluxPanelProc
	SetVariable setvarFluxset,pos={6,25},size={120,13},title="Flux", value=$(df+"Fluxset"),proc=DiodeFluxPanelProc
	SetVariable setvarCalcCA,pos={145,25},size={120,13}, limits={-inf,inf,0}, title="CA=", value=$(df+"CalcCA"),proc=DiodeFluxPanelProc
	SetDrawLayer UserBack
	DrawText 129,35,"->"
	DrawText 130,63,"->"
	
End
Function DiodeFluxPanelProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	string dfn="DiodeCurrent2Flux"
	string df="root:"+dfn+":"
	nvar CAset=$(df+"CAset"), CalcFlux=$(df+"CalcFlux"), eVset=$(df+"eVset"), Fluxset=$(df+"Fluxset"), CalcCa=$(df+"CalcCA")
	strswitch(varName)
		case "CAset":
			CalcFlux=Ca2Flux(eVset, CAset)
			break
		case "FluxSet":
			CalcCA=Flux2Ca(eVset, fluxSet)
		endswitch
End