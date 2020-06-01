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

/////////////////////////////////////////////////////////////////////////
////////////////////////// Extra  PVs  /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
Function Append_mda_wv(ScanNum,ywvName,xwvName)
	variable ScanNum
	string xwvName,ywvName
	string basename="mda_", suffix=""
	string dfn=FolderNamewithNum(basename,scannum,suffix)
	string df="root:"+dfn+":"
	wave xwv=$(df+xwvName)
	wave ywv=$(df+ywvName)
	appendtograph ywv vs xwv
end


Function XAS_mda(dfn, CA_TEY, CA_ref, Mono_RBV)
	string dfn, CA_TEY, CA_ref, Mono_RBV
	string df="root:"+dfn+":"
	wave TEY=$(df+CA_TEY)
	wave Mono=$(df+Mono_RBV)
	wave Ref=$(df+CA_ref)
	duplicate/o TEY $(df+CA_TEY+"_XAS")
	wave XAS=$(df+CA_TEY+"_XAS")
	XAS=TEY/Ref
	Note XAS ,"XAS is normalized by "+CA_ref
end	

Function XAS_ARPES_Dialog()
	string dfn, disp="yes"
	string CA_TEY="c29idc_ca2_read", CA_ref="c29idb_ca15_read"
	string Mono_RBV="c29idmono_ENERGY_MON"
	string dfList=JLM_FileLoaderModule#mdaPanel_FolderListGet()
	Prompt dfn, "mda folder:", popup dfList
	Prompt CA_TEY, "TEY PVname:"
	Prompt CA_Ref, "Diode PVname:"
	Prompt disp, "Display:", popup," yes;no"
	DoPrompt "XAS normalization",  dfn, CA_TEY,CA_Ref, disp
	if(v_flag==0)
	print  dfn, CA_TEY,CA_Ref, disp
	XAS_mda(dfn, CA_TEY, CA_ref, Mono_RBV)
		if(cmpstr(disp,"yes")==0)
			wave XAS=$(CA_TEY+"_XAS")
			wave Energy=$CA_ref
			Display  XAS vs Energy
		endif
	endif
end

Function XAS_RSXS_Dialog()
	string dfn, disp="yes"
	string CA_TEY="c29idb_ca16_read", CA_ref="c29idb_ca14_read"
	string Mono_RBV="c29idmono_ENERGY_MON"
	string dfList=JLM_FileLoaderModule#mdaPanel_FolderListGet()
	Prompt dfn, "mda folder:", popup dfList
	Prompt CA_TEY, "TEY PVname:"
	Prompt CA_Ref, "Diode PVname:"
	Prompt disp, "Display:", popup," yes;no"
	DoPrompt "XAS normalization",  dfn, CA_TEY,CA_Ref, disp
	if(v_flag==0)
	print  dfn, CA_TEY,CA_Ref, disp
	XAS_mda(dfn, CA_TEY, CA_ref, Mono_RBV)
		if(cmpstr(disp,"yes")==0)
			wave XAS=$(CA_TEY+"_XAS")
			wave Energy=$CA_ref
			Display  XAS vs Energy
		endif
	endif
end

Function AppendSeries_nc_Dialog()
	string ScanNumList,basename="EA_",suffix="avgy",scaling="BE"
	variable wk
	Prompt ScanNumList, "List of scan numbers \"1;25;177\""
	Prompt basename, "basename:"
	Prompt suffix, "suffix:"
	Prompt scaling, "wave x-scaling?",popup "BE;KE;As is"
	DoPrompt "Append to top graph, nc waves from list", ScanNumList,basename,suffix,scaling
	if(v_flag==0)
		//print "AppendSeries_nc(\"'+ScanNumList
		AppendSeries_nc(ScanNumList,basename,suffix,scaling,wk)
	endif
end

Function AppendSeries_nc(ScanNumList,basename,suffix,scaling,wk)
	string ScanNumList,basename,suffix,scaling
	variable wk
	variable scannum,i
	for(i=0;i<itemsinlist(ScanNumList,";");i+=1)
		scannum=str2num(stringfromlist(i,ScanNumList,";"))
		wave wv=$WaveNamewithNum(basename,scannum,suffix)
		strswitch(scaling)
			case "KE":
				IEX_SetEnergyScale(GetWavesDataFolder(wv,2),1,0,wk)
			break
			case "BE":
			 	IEX_SetEnergyScale(GetWavesDataFolder(wv,2),0,0,wk)
			 break
		endswitch
		appendtograph wv
	endfor
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