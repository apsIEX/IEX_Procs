#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// IEX_tools
// $Description: Procedures specific to IEX
// $Author: JLM$
// SVN History: $Revision: 0 $ on $Date:May 11, 2017 $

#include "SpectraLoadNView"
#include "JLM_FolderUtilities"
#include "JLM_WaveUtilities"

//last updated 2017_1

Menu "APS Procs"
	Submenu "IEX"
		Submenu "Wave note tools"	
			Submenu "MDA Tools"
				"Print IEX Extra PVs", IEX_ExtraPV_Dialog()
			end	
		end
		Submenu "ARPES - Analysis Tools"	
			"XAS_ARPES - normalize by diode ", XAS_diode_Dialog()
			"kplot - IEX data", IEX_kplot_dialog() 
		end
	End
End

Function IEX_ExtraPV_Dialog()
	string PV, dfn
	string dflistList=GetDataFolderList()
	Prompt PV, "PV info",popup, "Slits;Diagnostics;Mono;Mirror"
	Prompt dfn, "MDA scan folder", popup, dflistList
	DoPrompt "IEX Extra PVs", PV, dfn
	if(v_flag)
		abort
	endif
	DFREF saveDFR = GetDataFolderDFR()
	setdatafolder $dfn
	strswitch(PV)
		case "Slits":
			IEX_SlitsValues()
		break
		case "Diagnostics":
			IEX_DiagnosticPosition()
		break
		case "Mono":
			IEX_MonoVals()
		break
		case "Mirror":
			IEX_MirrorPositions()
		break
	endswitch
	setdatafolder saveDFR
end

Function IEX_SlitsValues()
	variable center_h=(ExtraPVval("29idb:m11.RBV")+ExtraPVval("29idb:m12.RBV"))/2
	variable center_v=(ExtraPVval("29idb:m9.RBV")+ExtraPVval("29idb:m12.RBV"))/2
	variable size_h=ExtraPVval("29idb:m11.RBV")-ExtraPVval("29idb:m10.RBV")
	variable size_v=ExtraPVval("29idb:m9.RBV")-ExtraPVval("29idb:m12.RBV")
	print "Slit1A: ("+num2str(size_h)+" x "+num2str(size_v)+") @ ("+num2str(center_h)+","+num2str(center_v)+")"
	
	center_h=(ExtraPVval("29idb:m14.RBV")+ExtraPVval("29idb:m13.RBV"))/2
	center_v=(ExtraPVval("29idb:m15.RBV")+ExtraPVval("29idb:m16.RBV"))/2
	size_h=ExtraPVval("29idb:m14.RBV")-ExtraPVval("29idb:m13.RBV")
	size_v=ExtraPVval("29idb:m15.RBV")-ExtraPVval("29idb:m16.RBV")
	print "Slit2B: ("+num2str(size_h)+" x "+num2str(size_v)+") @ ("+num2str(center_h)+","+num2str(center_v)+")"
	
	size_v=ExtraPVval("29idb:m24.RBV")
	print "Slit3C: motor_val="+num2str(size_v)
	
	center_v=(ExtraPVval("29idb:m27.RBV")+ExtraPVval("29idb:m26.RBV"))/2
	size_v=ExtraPVval("29idb:m27.RBV")-ExtraPVval("29idb:m26.RBV")
	print "Slit3D: "+num2str(size_v*1000)+"µm @ "+num2str(center_v)+"mm"
end

Function IEX_DiagnosticPosition()
	print "------Beamline Diagnostic Positions ------------"
	print "H-wire: "+num2str(ExtraPVval("29idb:m1.RBV"))  
	print "V-wire: "+num2str(ExtraPVval("29idb:m2.RBV")) 
	print  "W-mesh: "+num2str(ExtraPVval("29idb:m5.RBV")) 
	print "D-2B (after mono):"+num2str(ExtraPVval("29idb:m6.RBV")) 
	print "D-3B (double YAG):"+num2str(ExtraPVval("29idb:m7.RBV")) 

	print "------C-Branch Diagnostic Positions ------------"
	print "D-4C (before exit slit):"+num2str(ExtraPVval("29idb:m17.RBV")) 
	print "Gas-Cell: "+num2str(ExtraPVval("29idb:m20.RBV")) 
	
	print "------D-Branch Diagnostic Positions ------------"
	print "D-4D (before exit slit):"+num2str(ExtraPVval("29idb:m25.RBV")) 
	print "D-5D (before endstation):"+num2str(ExtraPVval("29idb:m28.RBV")) 
end

Function IEX_MonoVals()
	Print "lines/m: "+num2str(ExtraPVval("29idmono:GRT_DENSITY"))
	Print "Calculated Photon Energy: "+num2str(ExtraPVval("29idmono:ENERGY_MON"))
	Print "Desired Photon Energy: "+num2str(ExtraPVval("29idmono:ENERGY_SP"))
	Print "Mirror Pitch: "+num2str(ExtraPVval("29idmonoMIR:P.RBV"))
	Print "Grating Pitch: "+num2str(ExtraPVval("29idmonoGRT:P.RBV"))
	Print "Mirror Translation: "+num2str(ExtraPVval("29idmonoMIR:X.RBV"))
	Print "Grating Translation: "+num2str(ExtraPVval("29idmonoGRT:X.RBV"))
End

Function IEX_MirrorPositions()
	variable Tx,Ty,Tz,Rx,Ry,Rz
	Tx=ExtraPVval("29id_m0:TX_MON")
	Ty=ExtraPVval("29id_m0:TY_MON")
	Tz=ExtraPVval("29id_m0:TZ_MON")
	Rx=ExtraPVval("29id_m0:RX_MON")
	Ry=ExtraPVval("29id_m0:RY_MON")
	Rz=ExtraPVval("29id_m0:RZ_MON")
	printf "M0:  %.3f/%.3f/%.3f/%.3f/%.3f/%.3f\r",Tx,Ty,Tz,Rx,Ry,Rz
	
	Tx=ExtraPVval("29id_m1:TX_MON")
	Ty=ExtraPVval("29id_m1:TY_MON")
	Tz=ExtraPVval("29id_m1:TZ_MON")
	Rx=ExtraPVval("29id_m1:RX_MON")
	Ry=ExtraPVval("29id_m1:RY_MON")
	Rz=ExtraPVval("29id_m1:RZ_MON")
	printf "M1:  %.3f/%.3f/%.3f/%.3f/%.3f/%.3f\r",Tx,Ty,Tz,Rx,Ry,Rz
	
	Tx=ExtraPVval("29id_m3r:TX_MON")
	Ty=ExtraPVval("29id_m3r:TY_MON")
	Tz=ExtraPVval("29id_m3r:TZ_MON")
	Rx=ExtraPVval("29id_m3r:RX_MON")
	Ry=ExtraPVval("29id_m3r:RY_MON")
	Rz=ExtraPVval("29id_m3r:RZ_MON")
	printf "M3R:  %.3f/%.3f/%.3f/%.3f/%.3f/%.3f\r",Tx,Ty,Tz,Rx,Ry,Rz


End
Function IEX_ARPESmotors()
	variable mx,my,mz,mth,mphi,mchi,TA
	mx=ExtraPVval("29idc_m1:RBV")
	my=ExtraPVval("29idc_m2:RBV")
	mz=ExtraPVval("29idc_m3:RBV")
	mth=ExtraPVval("29idc_m4:RBV")
	mphi=ExtraPVval("29idc_m5:RBV")
	mchi=ExtraPVval("29idc_m6:RBV")
End

Function IEX_RSXSmotors()
	
End	

Function XAS_diode_Dialog()
	variable Diode_ScanNum, TEY_ScanNum
	string disp
	Prompt Diode_ScanNum, "Scan Number for XAS Diode Scan:"
	Prompt TEY_ScanNum, "Scan Number for XAS TEY Scan:"	
	Prompt Disp, "Display?", popup "yes;no"
	DoPrompt "XAS normalization",  Diode_ScanNum, TEY_ScanNum, disp
	if(v_flag==0)
		print "XAS_diode("+num2str(Diode_ScanNum)+","+num2str(TEY_ScanNum)+")"
		XAS_diode(Diode_ScanNum, TEY_ScanNum)
		if(cmpstr(disp,"yes")==0)
			wave TEY=$("XAS_"+num2str(TEY_ScanNum)+"_TEY")
			wave Energy=$("XAS_"+num2str(TEY_ScanNum)+"_Energy")
			Display  TEY vs Energy
		endif
	endif
end

Function XAS_diode(Diode_ScanNum, TEY_ScanNum)
	variable Diode_ScanNum, TEY_ScanNum
	string basename="mda_", suffix=""
	string TEY_pv="c29idc_ca1_read"
	string diode_pv="c29idc_ca1_read"
	setdatafolder root:
	string df_diode="root:"+FolderNamewithNum(basename,Diode_ScanNum,suffix)+":"
	string df_tey="root:"+FolderNamewithNum(basename,TEY_ScanNum,suffix)+":"
	wave ca15=$(df_diode+"c29idb_ca15_read ")
	wave ca1=$(df_tey+"c29idc_ca1_read ")
	wave TEY_energy=$(df_tey+"c29idmono_ENERGY_MON")
	duplicate/o ca1 $("XAS_"+num2str(TEY_ScanNum)+"_TEY") 
	duplicate/o TEY_energy $("XAS_"+num2str(TEY_ScanNum)+"_Energy") 
	wave TEY= $("XAS_"+num2str(TEY_ScanNum)+"_TEY") 
	wave Energy=$("XAS_"+num2str(TEY_ScanNum)+"_Energy")
	TEY=ca1/ca15
	Note TEY ,"Normalized by diode current mda_"+num2str(Diode_ScanNum)
	Note Energy ,"Normalized by diode current mda_"+num2str(Diode_ScanNum)
end

Function XAS_RSXS()
	wave mesh=c29idb_ca14_read
	wave D2=c29idb_ca16_read
	wave TEY=c29idd_ca2_read
	duplicate/o D2 TFY_norm
	duplicate/o TEY TEY_norm
	wave TEY_norm
	wave TFY_norm
	wave hv=c29idmono_ENERGY_MON
//	CA2Flux_wv(hv,D2,TFY_norm)
	TEY_norm=TEY/mesh
	TFY_norm=TFY_norm/mesh //photons

end
Menu "kspace"	
			"kplot - IEX data", IEX_kplot_dialog() 
	end
end	 
 Function IEX_kplot_dialog()
	string wvname
	Variable Wk=4.8
	Prompt wvname, "Wave:", popup, wavelist("*",";","DIMS:3")
	Prompt Wk, "Work Function:"
	DoPrompt "Kplot with IEX data", wvname, wk
	if(v_flag==0)
		print "IEX_kplot(\""+wvname+"\","+num2str(Wk)+")"
		IEX_kplot(wvname,Wk)
	endif
end
Function IEX_kplot(wvname,Wk)
	string wvname
	Variable Wk
	//Set the Energy Scale to Binding Energy
	IEX_SetEnergyScale(wvname,0,1,Wk)
	string  keysep=":",listsep=";"
	variable hv=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_ActualPhotonEnergy",keysep,listsep) 
	variable hvphi=hv-Wk	//photon energy minus the work function
	Execute "kplot(\""+wvname+"\",\"TwoPolar\",\"Already Done\",\"\",\"\")"
	print "kplot_hv = Photon Energy - Work Function = "+num2str(hvphi)	
end