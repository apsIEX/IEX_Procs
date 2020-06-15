#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "SpectraLoadnView"
#include "JLM_tools"
#include "IEX_tools"
#include "JLM_ImageTool_Addons"


Menu "Analysis"
	Submenu "Packages"
		"PeakFitter",Execute/P "INSERTINCLUDE  \"Peak Fitter 2.1\"";Execute/P "COMPILEPROCEDURES ";Execute/Q/P "NewPF()"
	End
End

Menu "APS Procs"
	"<BLoader_Panel"
	"NewSpectraViewer"
	"-"
	Submenu "Extensions"
//		"NewShadowPanel"
		"Load Photodiode", MenuExten_Photodiode()
		"IEX commissioning Procs -- Mono and GasCell",  MenuExten_IEXcommis()
		"Rubin Visualize3D",  MenuExten_3D()
	end
end

Function MenuExten_Photodiode()
	Execute/P/Q/Z "INSERTINCLUDE \"FluxCALC\""
	Execute/P/Q/Z "COMPILEPROCEDURES "
	Execute/P/Q/Z  "LoadResponsivity(); DiodeFlux_Panel()"
End

Function MenuExten_IEXcommis()
	Execute/P/Q/Z "INSERTINCLUDE \"NewGasCell\""
	Execute/P/Q/Z  "INSERTINCLUDE \"Mono_Panel\""
	Execute/P/Q/Z "COMPILEPROCEDURES "
End
Function MenuExten_3D()
	Execute/P/Q/Z  "INSERTINCLUDE \"Visualize_3D\""
	Execute/P/Q/Z "COMPILEPROCEDURES "
End
end