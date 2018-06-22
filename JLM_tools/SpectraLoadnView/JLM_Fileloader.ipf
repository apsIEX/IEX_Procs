#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName = JLM_FileLoaderModule


// $Description: Loader for files found at IEX Beamline  (Sector 29 at the APS) 
// $Author: JLM$
// SVN History: $Revision: 2.04 $ on $Date:May 11, 2017 $

/// Developement for the IEX Beamline (Sector 29 at the APS) June 2011
///	v1.01	Added an MDAascii load 11/25/2013
///v2.00 Cleaned up and added MDAascii C-code conveter
	///v2.02 	Uses User Procedures in Documents
	//			Fixed tif (convert to float)
	//			Filenames can start with number
	///v2.03 Added MPA file to loader
	///v2.04 Fixed LoaderPanel renaming bug added help functions
	//20170817 loading arpes data cropped added dither
	// v2.06 Cleaned up procedure to make easier to share - implemented static functions
//v3.00 Mda loader works on window, procedure uses static functions to a standalone

Menu "Data"
		"IEX LoaderPanel", Loader_Panel()
		//IEX_Menus.ipf in Igor Procedures set the "APS Procs" menu
End

Macro Loader_Panel()
	If(WinType("LoaderPanel")!=7)
		LoaderPanelVariables()
		LoaderPanelSetup()
	else
		dowindow/f LoaderPanel
	endif
end

function LoaderPanelVariables()
	string dfn="LoaderPanel", df="root:"+dfn+":"
	NewDataFolder/o/s root:LoaderPanel
	string/g filepath, filename, filelist, nfile, folderList, LPext,  datatype, datatypelist,wvdf, loadedwvlist
	variable/g filenum,checkBE_KE
	svar filepath=$(df+"filepath"), filename=$(df+"filename"), filelist=$(df+"filelist"), nfile=$(df+"nfile"), folderList=$(df+"folderList")
	svar datatypelist=$(df+"datatypelist"), datatype=$(df+"datatype"), wvdf=$(df+"wvdf"), loadedwvlist=$(df+"loadedwvlist")
	nvar filenum=$(df+"filenum"), checkBE_KE=$(df+"checkBE_KE")
	make/o/w/u $(df+"filecolors")
	wave  filecolors= $(df+"filecolors") 
	filecolors={{0,0,0},{0,0,0},{0,0,65535},{65535,0,0}}
	matrixtranspose filecolors
	make/o/n=(5,2,2)$(df+"fileSelectw")
	make/o/T/n=(5,2) $(df+"fileListw")
	setdimlabel 2,1,foreColors,fileselectw
	filelist="Select;"
	folderList="Select;"
	LPext="*.mda"///change default here
	datatypelist="MDA;Igor Binary;General Text;Spec;MDAascii;Tiff;NetCDF;MPA" ///edit to include other data types
	datatype="MDA" ////change default time here
	wvdf="root:"
end

Function LoaderPanelSetup() 
	setdatafolder "root:"
	string dfn="LoaderPanel", df="root:"+dfn+":"
	NewPanel /W=(100,300,475,700)
	DoWindow/C/T/R LoaderPanel,"Loader Panel"
	setwindow LoaderPanel, hook(cursorhook)=LoaderPanelHook
	ModifyPanel cbRGB=(1,52428,52428)
	// Get Data Folder and File Name
	PopupMenu popFolder, pos={10,10}, size={20,20},  title="Path:", mode=0, proc=LoaderDataFolderPopupMenuAction, value=#"root:LoaderPanel:folderlist"
	Button LoaderUpdateButton, pos={75,10}, size={75,20}, title="Update", proc=LoaderUpdateFilesLB
	SetVariable setvarfilepath title=" ", size={300,20}, pos={10,30}, value=root:LoaderPanel:filepath
	SetVariable setvarext title="filter", size={75,15}, pos={220,50}, value=root:LoaderPanel:LPext, proc=LoaderSelectFilter
	PopupMenu popFile pos={10,375}, size={100,20}, title="File:",  proc=LoaderDataFilePopupMenuAction , value=#"root:LoaderPanel:filelist", disable=1
	ListBox listboxfiles,pos={10,50},size={200,340},proc=LoaderFileListBoxAction,frame=4
	ListBox listboxfiles,listWave=root:LoaderPanel:fileListw,selWave=root:LoaderPanel:fileSelectw
	ListBox listboxfiles,colorWave=root:LoaderPanel:fileColors,row= 50,mode= 9
	ListBox listboxfiles,widths={70,35}
	PopupMenu popdatatype, pos={220,70}, size={75,15}, title="Data Type", value =#"root:LoaderPanel:datatypelist", proc=LoaderDataTypePopupMenuAction
	
//	SetVariable setwvdf title="df", pos={220,115}, size={150,15}, value=root:LoaderPanel:wvdf
	Button LoadButton pos={220,130}, size={120,20}, title="Load", proc=LoaderLoadButton
	Button LoadButtonIT pos={345,130}, size={20,20}, title="IT", proc=LoaderLoadButtonIT
	
	Button LoadAllButton pos={220,150}, size={150,20}, title="Load all in Folder", proc=LoaderLoadAllButton, disable=0
	Button TiffAllButton pos={220,170}, size={150,20}, title="Load Folder in one wave", proc=LoadImage_tiff, disable=1
	
	Button buttonCmdLineLoad title="CmdLine LD",size={95,20}, pos={220,352},proc=LoaderLoad_CmdLine_Dialog
	Button buttonCmdLineLoad help={"Comand Line loading -- useful when remote desktopping"}
	
	Button buttonStackNLoad title="LDnS",size={50,20}, pos={320,352},proc=LoaderLoadNStack_Dialogue
	Button buttonStackNLoad help={"Load a monotonic series of waves and stack, killing the individual waves"}
	
	Button buttonLoadDither title="Load Dither Series",  pos={220,330},size={150,20},proc=LoaderPanel_DitherDialogButton
	Button buttonStackNLoad help={"Loads a series of Dither waves and stack"}
	
	Button LaunchSViewer pos={220,375 }, size={150,20}, title="New SpectraViewer", proc=LaunchSViewerButton
	Button PLHelp pos={350,10 }, size={20,20}, title="?", proc=JLM_LoaderPanelHelp

	//Variables
	CheckBox checkbox_KE_BE, title="BE", pos={342,75},size={30,15},variable=root:LoaderPanel:checkBE_KE,disable=1
	CheckBox checkbox_KE_BE, help={"Check for scaling data to be in binding energy"}
end

Function LoaderSelectFilter(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	PauseUpdate; Silent 1
	LoaderUpdateFilesLB(ctrlName)
end	
Function LoaderLoadButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	wave/t fileListw=$(df+"fileListw")
	wave fileSelectw=$(df+"fileSelectw")
	variable i,load
	nvar filenum=$(df+"filenum")
	svar filelist=$(df+"filelist"), filename=$(df+"filename"),wvdf=$(df+"wvdf")
	//get number of files to load for Progress bar
	variable total=0, j=0
	For(i=0;i<dimsize(fileListw,0);i+=1)
		if (fileSelectw[i][0]>0)
			total+=1
		endif
	endfor
	svar loadedwvlist=$(df+"loadedwvlist")
	loadedwvlist=""
	JLM_FileLoaderModule#OpenProgressWindow("Loading Status", total)
	//load waves and update progress bar
	setdatafolder $wvdf
	For(i=0;i<dimsize(fileListw,0);i+=1)
		load=fileSelectw[i][0]
		if(load>0)
			filename=fileListw[i][0]
			filenum=i
			LoaderLoadFile(df,filename)
			//string loadedwv=LoaderLoadFile(df,filename)
			//loadedwvlist=AddListItem(loadedwv,loadedwvlist, ";",inf)
			j+=1
			JLM_FileLoaderModule#updateprogresswindow(j)
		endif
	endfor
	//Move to DataFolder
	svar wvdf=$(df+"wvdf")
	JLM_FileLoaderModule#closeprogresswindow()
	//ListBox updating
	filenum+=1
	filename=stringfromlist(filenum,filelist)
	ListBox listboxfiles, row=filenum // move filelist up in panel window
	//deselect all files and select the next
	fileSelectw=0
	fileSelectw[filenum][0]=1
	DoWindow/F $dfn
end
Function LoaderLoadButtonIT(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	LoaderLoadButton("") 
End
Function LoaderLoadAllButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	svar filelist=$(df+"filelist"), filename=$(df+"filename")
	variable i
	For (i=0; i<itemsinlist(filelist,";");i+=1)
		filename=stringfromlist(i, filelist)
		string loadedwv=LoaderLoadFile(df, ctrlName)
	endfor
end
Function LaunchSViewerButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,64)
	execute "NewSpectraViewer()"
end

Function LoaderFileListBoxAction (ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
	PauseUpdate; Silent 1
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	if ((event==4)) //+(event==10))    // mouse click or arrow up/down or 10=cmd ListBox
		nvar filenum=$(df+"filenum")
		svar filename=$(df+"filename"), fileList=$(df+"fileList")
		wave  fileListw=$(df+"fileListw")
		filenum=row
		filename= stringfromlist(filenum,fileList)
	//	PopupMenu popFile  mode=row+1
	endif
	return row
end
	

Function LoaderDataTypePopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr
	string dfn=winname(0,64)
	string df="root:"+dfn+":"	
	svar datatype=$(df+"datatype")
	datatype=popstr
	svar LPext=$(df+"LPext")
	PopupMenu popdatatype mode=popNum //sets the menu to read the selected value
	strswitch (popstr) //Changes button configuration based on data type
		case "Igor Binary":
			LPext="*.ibw"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton  title="Load All",  disable=0
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=1
		break	
		case "General Text":
			LPext="*.txt"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton  title="Load All",  disable=1
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=1
		break
		case "Spec":
			LPext="*.*"
			Button LoadButton title="Load Single Scan",  disable=0
			Button LoadAllButton  title="Load Experiment",  disable=0
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=1
		break
		case "MDAascii":
			LPext="*.asc"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton title="Load All", disable=0
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=1
		break	
		case "MDA":
			LPext="*.mda"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton title="Load All", disable=0
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=1
		break
		case "Tiff":
			LPext="*.tif"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton title="Load All", disable=0
			Button TiffAllButton, disable =0
			CheckBox checkbox_KE_BE, disable=1
		break
		case "NetCDF":
			LPext="*.nc"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton title="Load All", disable=1
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=0
		break
		case "MPA":
			LPext="*.mpa"
			Button LoadButton title="Load",  disable=0
			Button LoadAllButton title="Load All", disable=1
			Button TiffAllButton, disable =1
			CheckBox checkbox_KE_BE, disable=1
		break
	endswitch
	LoaderUpdateFilesLB(ctrlName)
end

Function LoaderUpdateFilesLB(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,64)
	string df="root:"+dfn+":"	
	svar filepath=$(df+"filepath"), folderlist=$(df+"folderlist"), filelist=$(df+"filelist"), LPext=$(df+"LPext")
	nvar filenum=$(df+"filenum")
	wave/t filelistw=$(df+"filelistw")
	wave fileselectw=$(df+"fileselectw")
	string fullfileList=IndexedFile(LoadPath,-1,"????")	
	fullfilelist=sortlist(fullfilelist, ";", 16)
	fileList=JLM_FileLoaderModule#ReduceList( fullfileList, LPext ) 
	filenum=ItemsInList( fileList)
	filenum= List2Textw(fileList, ";",(df+"fileListw"))
	Redimension/N=(filenum,2) fileListw
	Redimension/N=(filenum,2,2) fileSelectw
	fileListw[][0]=stringfromlist(p,fileList)
	fileListw[][1]=num2str( JLM_FileLoaderModule#FileSize_MB( filepath, fileListw[p][0]) )+" MB"
	fileSelectw[][][%forecolors]=floor( log(JLM_FileLoaderModule#FileSize_MB( filepath, fileListw[p][0])) )+1
	PopupMenu popFile  value=#df+"fileList", mode=1
end

Function LoaderDataFolderPopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	PauseUpdate
	string dfn=winname(0,64)
	string df="root:"+dfn+":"	
	svar filepath=$(df+"filepath"), folderlist=$(df+"folderlist"), filelist=$(df+"filelist"), LPext=$(df+"LPext")
	nvar filenum=$(df+"filenum")
	wave/t filelistw=$(df+"filelistw")
	wave fileselectw=$(df+"fileselectw")
	if(popnum==1)
		newpath/o/q/m="Select Data Folder" LoadPath
		pathinfo LoadPath
		filepath=s_path
		folderlist=folderlist+filepath+";"
	else
		filepath=StringFromList(popnum-1, folderList)
		newpath/q/o LoadPath filepath
	endif
	string fullfileList=IndexedFile(LoadPath,-1,"????")	
	fullfileList=sortlist(fullfileList, ";", 16)
	fileList=JLM_FileLoaderModule#ReduceList( fullfileList, LPext ) 
	filenum=ItemsInList( fileList)
	filenum= List2Textw(fileList, ";",(df+"fileListw"))
	Redimension/N=(filenum,2) fileListw
	Redimension/N=(filenum,2,2) fileSelectw
	fileListw[][0]=stringfromlist(p,fileList)
	fileListw[][1]=num2str(JLM_FileLoaderModule#FileSize_MB( filepath, fileListw[p][0]) )+" MB"
	fileSelectw[][][%forecolors]=floor( log(JLM_FileLoaderModule#FileSize_MB( filepath, fileListw[p][0])) )+1
	PopupMenu popFile  value=#df+"fileList", mode=1
	LoaderDataFolderext(df)//preselect data type based on folder names
end
Function LoaderDataFolderExt(df) //preselect data type based on folder names
	string df
	nvar popdatatype=$(df+"popdatatype")
	svar filepath=$(df+"filepath"), datatype=$(df+"datatype"),datatypelist=$(df+"datatypelist")
	variable popnum
	if(stringmatch(filepath,"*mda*")==1)
		datatype="MDA"
	elseif(stringmatch(filepath,"*netCDF*")==1)
		datatype="NetCDF"
	elseif(stringmatch(filepath,"*tif*")==1)
		datatype="Tiff"
	elseif(stringmatch(filepath,"*SES*")==1)
		datatype="Igor Binary"
	elseif(stringmatch(filepath,"*MPA*")==1)
		datatype="MPA"
	elseif(stringmatch(filepath,"*mda_ascii*")==1)
		datatype="MDAascii"
	endif
	popnum=WhichListItem(datatype,datatypelist,";")
	LoaderDataTypePopupMenuAction ("popdatatype",popnum+1,datatype)
end


Function LoaderDataFilePopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	nvar filenum=$(df+"filenum"); filenum=popnum
	svar filename=$(df+"filename"); filename=popstr
	ListBox listboxfiles selRow=popNum-1, row=max(0,popNum-3)
	
end

Function LoaderPanelHook(H_Struct)	
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	string dfn=H_Struct.winName; string df="root:"+dfn+":"
	if(eventcode==2)
		dowindow /F $dfn
		JLM_FileLoaderModule#killallinfolder(df)
		killdatafolder $df
		return(-1)
	endif
end
///////////////////////////////Comand line interactions ///////////////////////////////////////////////////
Function LoaderLoad_CmdLine_Dialog(ctrlName) : ButtonControl
	String ctrlName
	string Basename="EA_",Suffix=".nc", stackname="Stack_",ScaleStr=""
	variable first=1, last=1
	string stack_str, kill_str
	Prompt Basename, "Basename"
	Prompt Suffix, "Suffix"
//	Prompt stack_str, "Stack series",popup "no;yes"
//	Prompt kill_str, "Kill waves after stacking",popup "no;yes"
//	Prompt stackname, "Name of new stacked wave - Note stacking does not work for mda folders"
//	Prompt ScaleStr, "Scaling wave: first; delta; units (empty string = Scan Number)"
	Prompt first, "First"
	Prompt last, "Last"
//	DoPrompt "",BaseName,Suffix,stack_str, kill_str,StackName,ScaleStr,First,Last
	DoPrompt "",BaseName,Suffix,First,Last
	if(V_flag==0)
		if(strlen(ScaleStr)==0)
			ScaleStr=num2str(first)+";1;ScanNum"
		endif
		LoaderLoad_CmdLine(BaseName,Suffix,First,Last) 
		print "LoaderLoad_CmdLine(\""+BaseName+"\",\""+Suffix+"\","+num2str(First)+","+num2str(Last)+")" 
	endif

End


Function LoaderLoad_CmdLine(BaseName,Suffix,First,Last) //
//filenames must have same basename and be must be monotonic
	string Basename,Suffix//,stack_str, kill_str,StackName,ScaleStr
	variable first, last
	string df="root:LoaderPanel:"
	svar filelist=$(df+"filelist")
	//find point number for first and last
	variable p_first=nan, p_last=nan
	p_first=LoaderLoad_FindFileNamewithNum(basename,first,suffix, filelist)
	p_last=LoaderLoad_FindFileNamewithNum(basename,last,suffix, filelist)
	if((numtype(p_first)*numtype(p_last))<0)
		print "did not find first or last file in list, don't forget extension in suffix"
		abort
	endif
	if(p_first*p_last<0)
		print "did not find first or last file in list, parameters"
		abort
	endif
	wave fileSelectw=$(df+"fileSelectw")
	fileSelectw[p_first,p_last]=1
	LoaderLoadButton("LoadButton")
End	

Function LoaderLoad_FindFileNamewithNum(basename,scannum,suffix, filelist)
	string basename, suffix,filelist
	variable scannum
	variable n
	for(n=1;n<=10;n+=1)//up to 10 digit filename
		string fname=basename+JLM_FileLoaderModule#Num2str_SetLen(Scannum,n)+suffix
		if(WhichListItem(fname,filelist,";",0,0)>=0)//case insensitive
			return WhichListItem(fname,filelist,";",0,0)
			break
		endif
	endfor
end
///////////////////////////LoadNStack///////////////////////////	

Function LoaderLoadNStack_Dialogue(ctrlName) : ButtonControl
	String ctrlName
	variable first, last
	string basename="EA_", fileext=".nc"
	string prefix="", suffix=""
	string stackname,ScaleStr
	string IT
	prompt basename, "Basename of files to be loaded"
	prompt fileext, "Extension of files to be loaded"
	prompt prefix, "Prefix for loaded waves (t for tif, else empty string)"
	prompt suffix, "Suffix for loaded waves (avgy for XPS, else empty string)"
	prompt stackname, "Name of the stacked wave"
	prompt first, "first scan number"
	prompt last, "last scan number"
	Prompt ScaleStr, "Scaling wave: first; delta; units (empty string = Scan Number)"
	Prompt IT, "Open new ImageToolV?", popup, "no;yes"
	doprompt "Load and Stack parameters",basename,fileext,prefix, suffix, stackname,ScaleStr,first,last, IT
	if (v_flag==0)
		 LoaderLoadNStack(basename,fileext,prefix, suffix, stackname,ScaleStr,first,last,IT)
		 print "LoaderLoadNStack(\""+basename+"\",\""+fileext+"\",\""+prefix+"\",\""+suffix+ "\",\""+stackname+"\",\""+ScaleStr+"\","+num2str(first)+","+num2str(last)+"\","+IT+"\")"
	endif
end


Function LoaderLoadNStack(basename,fileext,prefix, suffix, stackname,ScaleStr,first,last,IT)
	variable first, last
	string basename, fileext, prefix, suffix, stackname,ScaleStr
	string IT
	string cmd
	variable countby=1
	LoaderLoad_CmdLine(basename,fileext,first,last)
	if(Exists("StackWaves_FirstLastCountBy")==6)
		sprintf cmd, "StackWaves_FirstLastCountBy(%s,%s,%s,%s,%g,%g,%g)",BaseName,Suffix,StackName,ScaleStr,first,last,countby	
		Execute cmd
		sprintf cmd, "Killwaves_FirstLast(%s,%s,%g,%g)",prefix+BaseName,Suffix,first,last
		Execute cmd
	endif
	if (cmpstr(IT,"yes")==0)
		if(Exists("NewImageTool5")==6)
			execute "NewImageTool5(\""+StackName+"\")"	
		endif
	endif
end

//Function LoadNStack_tiff(basename,fileext,stackname,first,last)
//	variable first, last
//	string basename, fileext, stackname
//	LoaderLoad_CmdLine(basename,fileext,first,last)
//		
//	string wvname="t"+basename
//	StackWaves_FirstLast(wvname,"",stackname,num2str(first)+";"+num2str(1)+"; ScanNum",first,last)
//	Killwaves_FirstLast(wvname,"",first,last)
//		
//end
///////////////////////////////////////////////////////////////////////////////////
Function/S LoaderLoadFile(df, ctrlName)
	string df, ctrlName
	setdatafolder root:
	svar datatype=$(df+"datatype"), filename=$(df+"filename")
	svar filename=$(df+"filename")
	variable len=strlen(filename)-5
	string wname=filename[0,len]
	string loadedwv
	strSwitch(datatype)
		case "General Text":
			loadwave/o/g/n=$wname/p=LoadPath filename
			loadedwv=s_WaveNames
		break	
		case "Igor Binary":
			loadedwv=LoadIgorBinary(filename)
		break
		case "Spec":
			if (cmpstr(ctrlName, "LoadButton")==0)
				LoadScanfromSpec(df)
			elseif (cmpstr(ctrlName, "LoadAllButton")==0)
				LoadSpecAll(df)
			endif
		break
		case "MDAascii":
			svar filename=$(df+"filename"), filepath=$(df+"filepath")
			LoadMDAascii(df) 
		break
		case "MDA":
			svar filename=$(df+"filename"), filepath=$(df+"filepath")
			LoadMDA(df)
		break
		case "Tiff":
			svar filename=$(df+"filename"), filepath=$(df+"filepath")
			LoadImage_tiff(df)
		break
		case "NetCDF":
			svar filename=$(df+"filename"), filepath=$(df+"filepath")
			LoadNetCDF(df)
		break
		case "MPA":
			svar filename=$(df+"filename"), filepath=$(df+"filepath")
			LoadMPA(df)
		break
	endswitch
	//return loadedwv
End

////////////////////////////////////////////////////////////////////////////////////
Function ParseScan(buffer, which)
	string buffer
	variable which
	variable refnum
	if (which==0)
		open/p=Igor refnum as "TempLoad"
		fprintf refnum, buffer
	elseif(which==1)
		open/a/p=Igor refnum as "TempLoad"
		fprintf refnum, buffer
	endif	
	close refnum
End

//////////////////////////////////Load Igor Binary e.g. SES data//////////////////////////////////////
Function/S  LoadIgorBinary(filename)
	string filename
	string wvname= filename[0,strlen(filename)-5]
	loadwave/o/p=LoadPath filename
	string wvloaded=stringfromlist(0,s_waveNames)
	duplicate/o $wvloaded, $wvname
	killwaves/z  $wvloaded
	Redimension/S $wvname
	return  S_waveNames
End
//////////////////////////////////Load single scan from Spec//////////////////////////////////////
Function/s LoadScanfromSpec(df)
	string df
	setdatafolder root:
	svar filename=$(df+"filename")
	variable RefNum
	string buffer, stmp
	variable i, j=0
	GetFileFolderInfo/Q/Z/P=LoadPath filename
	Grep/indx/P=LoadPath/Q/E="(?i)\\#s\\b" filename 
	variable numscans=dimsize(w_index,0)
	string message="Which of the "+num2str(numscans)+" would you like to load?"	
	variable snum=1
	Prompt snum, "Scan number to load"
	DoPrompt message, snum
	open/r/p=LoadPath refnum as filename
	string test, test0
	make/o/n=2 $(df+"ExpHeaderw")
	wave ExpHeaderw=$(df+"ExpHeaderw")
	wave w_index=root:w_index
	variable lim=w_index[snum-1]
	Do
		FReadLine RefNum, buffer
		if ( j<1) //write run header
			test=buffer[0,1]
			if(cmpstr(test, "\r")==0)	
				j=1
			else
				note ExpHeaderw, buffer		
			endif
		elseif(i<lim)
		else
			test=buffer[0,1]		
			If (cmpstr(test,"#S")==0) //start of new scan
				//create folder
				variable v1
				string s1,s2
				sscanf buffer, "%s %d %s", s1, v1, s2
				string fname=s2+num2str(v1)
				if (datafolderexists(fname))
					JLM_FileLoaderModule#killallinfolder(fname) //ImageTool4031 utility
					killdatafolder/z fname
				endif
				newdatafolder/o $("root:"+fname)
				setdatafolder $("root:"+fname)
				//Scan header info
				make/o/n=2 $(df+"wvHeaderw")
				wave  wvHeaderw=$(df+"wvHeaderw")
				note wvHeaderw, buffer
				ParseScan(buffer,0)	
			elseif(cmpstr(test, "#D")*cmpstr(test, "#M")*cmpstr(test, "#G")*cmpstr(test, "Q#")*cmpstr(test, "#P")*cmpstr(test, "#U")*cmpstr(test, "#@")*cmpstr(test, "#X")*cmpstr(test, "#N")==0)
				note wvHeaderw, buffer
			elseif(cmpstr(test, "#C")==0)	//doesn't write abort, comment lines			
			elseif(cmpstr(test, "/r")==0)	//doesn't write blank strings	
			elseif(cmpstr(test, "#R")==0)	//end of scan
				pathinfo igor
				string filepath=s_path
				string loadedwv=LoadSingleSpec(filepath,"TempLoad", "#L") 
				abort
			else
				ParseScan(buffer,1)
			endif
		endif
	FStatus(refNum)
	i+=1
	While(V_filePos<V_logEOF)
	close refNum
	setdatafolder root:
	killwaves/z root:w_index	
	return loadedwv	
End
///////////////////////////////////Load all Spec scans in file //////////////////////////////
Function/s LoadSpecAll(df)
	string df
	setdatafolder root:
	svar filename=$(df+"filename")
	variable RefNum
	string buffer, stmp
	variable i, j=0
	GetFileFolderInfo/Q/Z/P=LoadPath filename
	Grep/indx/P=LoadPath/Q/E="(?i)\\#s\\b" filename 
	variable numscans=dimsize(w_index,0)
	JLM_FileLoaderModule#OpenProgressWindow("Loading Status", numscans)
	open/r/p=LoadPath refnum as filename
	string test, test0
	make/o/n=2 $(df+"ExpHeaderw")
	wave ExpHeaderw=$(df+"ExpHeaderw")
	Do
		FReadLine RefNum, buffer
		if ( j<1) //write run header
			test=buffer[0,1]
			if(cmpstr(test, "\r")==0)	
				j=1
			else
				note ExpHeaderw, buffer		
			endif
		else
			test=buffer[0,1]		
			If (cmpstr(test,"#S")==0) //start of new scan
				//create folder
				variable v1
				string s1,s2
				sscanf buffer, "%s %d %s", s1, v1, s2
				string fname=s2+num2str(v1)
				if (datafolderexists(fname))
					JLM_FileLoaderModule#killallinfolder(fname) //ImageTool4031 utility
					killdatafolder/z fname
				endif
				newdatafolder/o $("root:"+fname)
				setdatafolder $("root:"+fname)
				//Scan header info
				make/o/n=2 $(df+"wvHeaderw")
				wave  wvHeaderw=$(df+"wvHeaderw")
				note wvHeaderw, buffer
				ParseScan(buffer,0)	
			elseif(cmpstr(test, "#D")*cmpstr(test, "#M")*cmpstr(test, "#G")*cmpstr(test, "Q#")*cmpstr(test, "#P")*cmpstr(test, "#U")*cmpstr(test, "#@")*cmpstr(test, "#X")*cmpstr(test, "#N")==0)
				note wvHeaderw, buffer
			elseif(cmpstr(test, "#C")==0)	//doesn't write abort, comment lines			
			elseif(cmpstr(test, "/r")==0)	//doesn't write blank strings	
			elseif(cmpstr(test, "#R")==0)	//end of scan
//				pathinfo igor
//				string filepath=s_path
				string  filepath=SpecialDirPath("Igor Pro User Files", 0,0,0)
				string loadedwv=LoadSingleSpec(filepath,"TempLoad", "#L") 
				j+=1
				JLM_FileLoaderModule#updateprogresswindow(j)
			else
				ParseScan(buffer,1)
			endif
		endif
	FStatus(refNum)
	i+=1
	While(V_filePos<V_logEOF)
//	LoadSingleSpec(filepath,"TempLoad", "#L") //to load the last file
	close refNum
	JLM_FileLoaderModule#closeprogresswindow()
	setdatafolder root:
	killwaves/z root:w_index	
	return loadedwv	
End


Function/s LoadSingleSpec(filepath,filename, sheader)
	string filepath, filename, sheader //sheader is string denoting header line usually #L
	variable len=strlen(filename)-5
	string wname=filename[0,len]
	newpath/o/q storepath, filepath
	Grep/List/P=storepath/Q/E="(?i)\\"+sheader+"\\b" filename //get wave names
	string Header=s_value[3,strlen(s_value)]
	header=replacestring("  ", header, ";") // replace string separator (space)(space) with ;
	LoadWave/o/q/g/n=LP/p=storepath filename
	string loadedwv=S_wavenames
	variable num=V_flag
	variable i
	for(i=0;i<num;i+=1)
		string newname=stringfromlist(i,header), oldname=stringfromlist(i,S_wavenames)
		rename $oldname $newname
	endfor
	Spec1dSetScale(1, "")
	setdatafolder root:	
	return loadedwv
end

Function Spec1dSetScale(kill, toroot)
	variable kill //0 kills individual folders and copies all wave in toroot string to root: 
	string toroot
	string df=Getdatafolder(1)
	string wlist=wavelist("*",";","")
	variable offset, delta
	string units
	variable i,k
	wave wvHeaderw=$(df+"wvHeaderw"), expHeaderw=$(df+"expHeaderw")
	For (i=0;i<itemsinlist(wlist); i+=1)  //set the scale to the first wave
			wave scaling=$(stringfromlist(0, wlist))
		offset=scaling[0]
		delta=scaling[1]-scaling[0]
		units=nameofwave(scaling)
		wave w=$stringfromlist(i,wlist, ";")
		setscale/p x, offset, delta, units, w
		note w, note(expHeaderw) 
		note w, note(wvHeaderw)
	endfor
//	endif				
	If (kill==0)
		string which
		for(k=0;k<itemsinlist(toroot);k+=1)	
			which=stringfromlist(k, toroot, ";")
			duplicate w $("root:"+df+"_"+which)	
		endfor
		killdatafolder/z df
	endif
end


/////////////////////////////////Load MDA_ascii//////////////////
Function LoadMDA(df)
	string df
	string SpectraLoadNViewpath="User Procedures:IEX_Procs:JLM_tools:SpectraLoadNView:"
	//get loaderpanel variables and saves
	svar filepath=$(df+"filepath"), filename=$(df+"filename"),filelist=$(df+"filelist")
	nvar filenum=$(df+"filenum")
	string fp,fn, fl,asciifp
	variable fnum
	fp=filepath; fn=filename; fl=filelist
	fnum=filenum	
	// make directory for ascii files
	asciifp=MDAmkascii(SpectraLoadNViewpath)
	// convert mda to ascii
	MDA2ascii(filepath,filename,SpectraLoadNViewpath)
	//set path and loads the newly created ascii files
	filepath=asciifp
	newpath/q/o LoadPath filepath
	string filenamelist=IndexedFile(LoadPath,-1,".asc")	
	filelist=sortlist(filenamelist, ";", 16)
	filename=stringfromlist(0,filenamelist,";") 
	LoadMDAascii(df) //Loads the Ascii files
	MDArmascii(SpectraLoadNViewpath) //cleans up Ascii files
	//resets loaderpanel variables
	newpath/q/o LoadPath fp
	filepath=fp
	filename=fn
	filelist=fl
	fnum=filenum
end
Function MDA2ascii(filepath,filename,SpectraLoadNViewpath) //covert mda to ascii using mda2ascii
	string filepath, filename, SpectraLoadNViewpath
	string platform = IgorInfo(2)
	string exe,ascii,mda,cmd
		StrSwitch(platform)
		Case "Windows":
			 //full path to location of mda2ascii executable
			exe="\""+SpecialDirPath("Igor Pro User Files", 0, 1, 0)+parsefilepath(5,SpectraLoadNViewpath+platform+"_mda:","\\",0,0)
				exe+="mda2ascii.exe\" -d"
			 //location were to create tmp folder for converted ascii files setup in MDAmkascii()
			ascii="\""+SpecialDirPath("Igor Pro User Files", 0, 1, 0) +parsefilepath(5,SpectraLoadNViewpath,"\\",0,0)+"mda_tmp\""
			 //location of mda files
			mda=filepath+filename
			mda=parsefilepath(5,mda,"\\",0,0)
			mda=replacestring(" ", mda, "\\\ ")
			mda="\""+mda+"\""
			cmd=exe+" "+ascii+" "+mda
		break
		Case "Macintosh":
			//full path to location of mda2ascii executable
			exe=parsefilepath(5,SpecialDirPath("Igor Pro User Files", 0, 0, 0)+SpectraLoadNViewpath+platform+"_mda:","/",0,0)
			exe=replacestring(" ", exe, "\\\ ")
			exe+="mda2ascii -d" 
			 //location were to create tmp folder for converted ascii files
			ascii=parsefilepath(5,SpecialDirPath("Igor Pro User Files", 0, 0, 0)+SpectraLoadNViewpath,"/",0,0)+"mda_tmp"
			ascii=replacestring(" ", ascii, "\\\ ")
			 //location of mda files
			mda=filepath+filename 
			mda=parsefilepath(5,mda,"/",0,0)
			mda=replacestring(" ", mda, "\\\ ")
			sprintf cmd, "do shell script \"%s %s %s\"", exe, ascii, mda
		break
		endswitch
		ExecuteScriptText cmd	
end
Function/S MDAmkascii(SpectraLoadNViewpath)
	string SpectraLoadNViewpath
	string cmd, ascii
	string platform = IgorInfo(2)
		StrSwitch(platform)
		Case "Windows":
			ascii="\""+SpecialDirPath("Igor Pro User Files", 0, 1, 0) +parsefilepath(5,SpectraLoadNViewpath,"\\",0,0)+"mda_tmp\""
			sprintf cmd, "cmd.exe /C mkdir %s", ascii
		break
		Case "Macintosh":
			ascii=parsefilepath(5,SpecialDirPath("Igor Pro User Files", 0, 0, 0)+SpectraLoadNViewpath,"/",0,0)+"mda_tmp"
			ascii=replacestring(" ", ascii, "\\\ ")
			sprintf cmd, "do shell script \" mkdir -p %s\"", ascii
//			print cmd
		Break
		EndSwitch
		ExecuteScriptText cmd
		return SpecialDirPath("Igor Pro User Files", 0, 0, 0)+SpectraLoadNViewpath+"mda_tmp"
end

Function MDArmascii(SpectraLoadNViewpath)
	string SpectraLoadNViewpath
	string cmd, ascii
	string platform = IgorInfo(2)
		StrSwitch(platform)
		Case "Windows":
			ascii="\""+SpecialDirPath("Igor Pro User Files", 0, 1, 0) +parsefilepath(5,SpectraLoadNViewpath,"\\",0,0)+"mda_tmp\""
			sprintf cmd, "cmd.exe /C rmdir /s /q %s", ascii
	//		print replacestring("\\",ascii,"\\\\")
		break
		Case "Macintosh":
			ascii=parsefilepath(5,SpecialDirPath("Igor Pro User Files", 0, 0, 0)+SpectraLoadNViewpath,"/",0,0)+"mda_tmp"
			ascii=replacestring(" ", ascii, "\\\ ")
			sprintf cmd, "do shell script \"rm -rf %s\"", ascii
		break
		endswitch
		ExecuteScriptText cmd
	end

Function/S LoaderLoadMDAascii1D(df)
	string df
	svar filepath=$(df+"filepath"), filename=$(df+"filename")
	//create folder from filename
	variable i=strsearch(filename,".",0),j,n
	string basename=selectstring(numtype(str2num(filename[0])==2),filename[0,i-1],"f"+filename[0,i-1])	
	string fldname=cleanupname(basename,0)
	if (datafolderexists("root:"+fldname))
		setdatafolder $("root:"+fldname)
		killwaves/a/z
	else 
		newdatafolder/o $("root:"+fldname)
	endif
	setdatafolder $("root:"+fldname)
	//loads waves
	Loadwave/N/O/G/Q/A=input/P=loadpath filename //loads individulal waves
	string loadedwv=S_waveNames
	// Gets Extra PVs
	string ExtraPVs="", tmp
	grep/q/list/E="# Extra PV"/P=LoadPath filename
	ExtraPVs=s_value
	//make wave note
	For(n=0;n<CountObjects("",1);n+=1)
		wave wv=$GetIndexedObjName("",1,n)
		Note  wv, ExtraPVs
	endfor

end
// For multi dimwaves
Function LoaderLoadMDAascii2D(nx,ny,nz,nt, df2d, scanlist) //Takes 1D waves and make 2D waves
	variable nx,ny,nz,nt
	string df2d, scanlist
	variable i,j,k,l,n //i=scan number, j=q/y, k=r/z, l=s/t, n=detector
	string folder
	j=0;k=0;l=0
	For(j=0;j<ny;j+=1) 
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		folder=cleanupname(folder,0)
		setdatafolder $("root:"+folder)
		For(n=0;n<CountObjects("",1);n+=1)
			wave wv=$(df2d+GetIndexedObjName("",1,n))
			wave wv1d=$GetIndexedObjName("",1,n)
			wv[][j]=wv1d[p]
		endfor
		i+=1
	endfor
	setdatafolder root:
	For(i=0; i<itemsinlist(scanlist);i+=1) 
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		folder=cleanupname(folder,0)
		killdatafolder/z $folder
	endfor
	
end
Function LoaderLoadMDAascii3D(nx,ny,nz,nt, df2d, scanlist)//Takes 1D waves and make 3D waves
	variable nx,ny,nz,nt
	string df2d, scanlist
	variable i,j,k,l,n //i=scan number, j=q/y, k=r/z, l=s/t, n=detector
	string folder
	j=0;k=0;l=0
	For(i=0; i<itemsinlist(scanlist, ";");i+=1)
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		folder=cleanupname(folder,0)
		setdatafolder $("root:"+folder)
		k=str2num(stringfromlist(itemsinlist(folder,"_")-2,folder,"_"))
		j=str2num(stringfromlist(itemsinlist(folder,"_")-1,folder,"_"))
//		print folder, j, k
		For(n=0;n<CountObjects("",1);n+=1)
			wave wv=$(df2d+GetIndexedObjName("",1,n))
			wave wv1d=$GetIndexedObjName("",1,n)
			wv[][j-1][k-1]=wv1d[p]
		endfor
	endfor
	setdatafolder root:

	For(i=0; i<itemsinlist(scanlist);i+=1) 
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		killdatafolder/z $folder
	endfor
end
Function LoaderLoadMDAascii4D(nx,ny,nz,nt, df2d, scanlist)//Takes 1D waves and make 4D waves
	variable nx,ny,nz,nt
	string df2d, scanlist
	variable i,j,k,l,n //i=scan number, j=q/y, k=r/z, l=s/t, n=detector
	string folder
	j=0;k=0;l=0
	For(i=0; i<itemsinlist(scanlist, ";");i+=1)
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		folder=cleanupname(folder,0)
		setdatafolder $("root:"+folder)
		l=str2num(stringfromlist(itemsinlist(folder,"_")-3,folder,"_"))
		k=str2num(stringfromlist(itemsinlist(folder,"_")-2,folder,"_"))
		j=str2num(stringfromlist(itemsinlist(folder,"_")-1,folder,"_"))
		For(n=0;n<CountObjects("",1);n+=1)
			wave wv=$(df2d+GetIndexedObjName("",1,n))
			wave wv1d=$GetIndexedObjName("",1,n)
			//l=str2num(stringfromlist(1,folder,"_"))
			//k=str2num(stringfromlist(2,folder,"_"))
			//j=str2num(stringfromlist(3,folder,"_"))
			wv[][j-1][k-1][l-1]=wv1d[p]
		endfor
	endfor
	setdatafolder root:
//abort
	For(i=0; i<itemsinlist(scanlist);i+=1) 
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		folder=cleanupname(folder,0)
		killdatafolder/z $folder
	endfor
end
Function LoaderLoadMDAascii3Dold(nx,ny,nz,nt, df2d, scanlist)//Takes 1D waves and make 3D waves doesn't work for non completed scans
	variable nx,ny,nz,nt
	string df2d, scanlist
	variable i,j,k,l,n //i=scan number, j=q/y, k=r/z, l=s/t, n=detector
	string folder
	j=0;k=0;l=0
	For(j=0; j<ny;j+=1)
		For(k=0;k<nz;k+=1) 
			folder=stringfromlist(i,scanlist)
			folder=folder[0, strlen(folder)-5]
			setdatafolder $("root:"+folder)
			For(n=0;n<CountObjects("",1);n+=1)
				wave wv=$(df2d+GetIndexedObjName("",1,n))
				wave wv1d=$GetIndexedObjName("",1,n)
				wv[][k][j]=wv1d[p]
			endfor
			i+=1
		endfor
	endfor
	setdatafolder root:

	For(i=0; i<itemsinlist(scanlist);i+=1) 
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		killdatafolder/z $folder
	endfor
end
Function LoaderLoadMDAascii4Dold(nx,ny,nz,nt, df2d, scanlist)//Takes 1D waves and make 4D waves
	variable nx,ny,nz,nt
	string df2d, scanlist
	variable i,j,k,l,n //i=scan number, j=q/y, k=r/z, l=s/t, n=detector
	string folder
	For(l=0;l<nt;l+=1)
		For(k=0;k<nz;k+=1) 
			For(j=0; j<ny;j+=1)
				folder=stringfromlist(i,scanlist)
				folder=folder[0, strlen(folder)-5]
				setdatafolder $("root:"+folder)
				For(n=0;n<CountObjects("",1);n+=1)
					wave wv=$(df2d+GetIndexedObjName("",1,n))
					wave wv1d=$GetIndexedObjName("",1,n)
					//wv[][j][k][l]=wv1d[p]
					wv[][j][k][l]=wv1d[p]
				endfor
	//			print l+1,k+1,j+1, folder 
				i+=1
			endfor	
		endfor
	endfor
	setdatafolder root:
//abort
	For(i=0; i<itemsinlist(scanlist);i+=1) 
		folder=stringfromlist(i,scanlist)
		folder=folder[0, strlen(folder)-5]
		killdatafolder/z $folder
	endfor
end
Function/s LoadMDAascii(df) //uses ReduceList
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")
	if (strlen(filename)==0)
		print "no file selected"
		abort
	endif
	variable nx,ny,nz,nt
	grep/q/list/E="requested"/P=LoadPath filename
	string dims=stringfromlist(1, s_value,"= ")
	nx=str2num(stringfromlist(itemsinlist(dims, "x")-1,dims,"x")) //check dim value for multi dim waves
	ny=str2num(stringfromlist(itemsinlist(dims, "x")-2,dims,"x"))
	nz=str2num(stringfromlist(itemsinlist(dims, "x")-3,dims,"x"))
	nt=str2num(stringfromlist(itemsinlist(dims, "x")-4,dims,"x"))
	variable whichone=itemsinlist(dims, "x")-3, val1=ny, val2=ny*nz, val3=ny*nz*nt
	variable/g $(df+"numscans")
	nvar numscans=$(df+"numscans")
	numscans=selectnumber(itemsinlist(dims, "x")==1, selectnumber(whichone,val1,val2,val3),0)
	variable n,i
	string basename=filename[0,strsearch(filename,".",inf,1)-1]
	For(i=0;i<itemsinlist(dims, "x")-1;i+=1)
		basename=basename[0,strsearch(basename,"_",inf,1)-1]
	endfor
	string scanlist=JLM_FileLoaderModule#ReduceList(filelist,basename+"*")
	scanlist=sortlist(scanlist, ";", 16)
	//print scanlist
	string folder
	//Loads all Ascii 1 waves
	For (i=0;i<itemsinlist(scanlist);i+=1)
		filename=stringfromlist(i,scanlist)
		string loadedwv=LoaderLoadMDAascii1D(df)
		LoadMDAasciiMultiDim(df,i)
	endfor
	string fldname=cleanupname(basename,0)
	string df2d="root:"+fldname+":"
	//Make folder for mutlidimensional waves
	If(itemsinlist(dims,"x")>1)
		Newdatafolder/o $("root:"+fldname)
		For(n=0;n<CountObjects("",1);n+=1)
			duplicate/o $(GetIndexedObjName("",1,n)) $(df2d+GetIndexedObjName("",1,n))
			wave wv=$(df2d+GetIndexedObjName("",1,n))
			If(itemsinlist(dims,"x")==2)
				redimension/N=(-1,ny) wv
			elseif(itemsinlist(dims,"x")==3)
				redimension/N=(-1,ny,nz) wv
			elseif(itemsinlist(dims,"x")==4)
				redimension/N=(-1,ny,nz,nt) wv
			else
				print "Igor can only handle 4 dimensional waves"
			endif
		endfor
		If(itemsinlist(dims,"x")==2)
			LoaderLoadMDAascii2D(nx,ny,nz,nt, df2d, scanlist)
			svar Scale2D=$(df+"Scale2D")
			wave Yval=$(df+"Yval")
//			duplicate/o Yval $(df2d+stringfromlist(0,Scale2D))
		elseif(itemsinlist(dims,"x")==3)
			LoaderLoadMDAascii3D(nx,ny,nz,nt, df2d, scanlist)
		elseif(itemsinlist(dims,"x")==4)
			LoaderLoadMDAascii4D(nx,ny,nz,nt, df2d, scanlist)
		endif
	endif
	string firstscan=stringfromlist(itemsinlist(scanlist,"'")-1,scanlist)
	df2d="root:"+fldname+":"
	setdatafolder $df2d
	LoadMDAasciiRenameDets(df,firstscan)
	LoadMDAasciiSetScales(df,df2d,dims)
	//return loadedwv
end

Function LoadMDAasciiRenameDets(df,filename)
	string df,filename
	variable n, i,j,m
	///gets column names
	string ColNameList, findme, name
	svar Scale1D=$(df+"Scale1D")
	ColNameList="index;c"+stringfromlist(0,Scale1D,";")
	i=strsearch(filename,".",0)
	n=3
	Do
		findme=selectstring(n>=10, "#    "+num2str(n),  "#   "+num2str(n))
		grep/q/list/p=LoadPath/E=findme filename
		string tmp=s_value
		i=strsearch(s_value, "]", 0)
		j=strsearch(s_value, ",", i+1)
		name=selectstring(numtype(str2num(s_value[i+3])==2),"c"+s_value[i+3,j-1],s_value[i+3,j-1])
		ColNameList=addlistitem(name, ColNameList,";",inf)
		n+=1
	while (i>=0)
	ColNameList=removelistitem(itemsinlist(ColNameList,";")-1,ColNameList,";")//get rid of last blank entry
	for(n=1;n<itemsinlist(ColNameList);n+=1)
		name=stringfromlist(n, ColNameList)
		name=replacestring(":", name, "_")
		name=replacestring(".", name, "_")
		name=replacestring(" ",name, "")
		duplicate/o $("input"+num2str(n)) $name
		killwaves/z $("input"+num2str(n))
	endfor
	killwaves/z input0
end
Function LoadMDAasciiMultiDim(df,i)//gets multidimensional scales 
	variable i
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")
	nvar numscans=$(df+"numscans")
	variable n
	//Make MultiDim Scales
	If(i==0)
		nvar numscans=$(df+"numscans")
		make/o/n=(numscans) $(df+"Yval")
		make/o/n=(numscans) $(df+"Zval")
		make/o/n=(numscans) $(df+"Tval")
		string/g $(df+"Scale1D"),$(df+"scale2D"), $(df+"scale3D"), $(df+"scale4D")
		string name, units, type, which
		string Positioner="1-D Positioner 1;2-D Positioner 1;3-D Positioner 1;4-D Positioner 1"
		For(n=0;n<4;n+=1)
			which=stringfromlist(n,Positioner,";")
			grep/q/list/E=which/P=LoadPath filename
			name=stringfromlist(0, s_value[28,inf],",")
			name=selectstring(strlen(name)==0,name, stringfromlist(4, s_value[28,inf],","))
			name=replacestring(":", name, "_")
			name=replacestring(".", name, "_")
			type=stringfromlist(2, s_value[28,inf],",")
			units=stringfromlist(6, s_value[28,inf],",")
			svar scale=$(df+"scale"+num2str(n+1)+"D")
			scale=name+";"+type+";"+units
		endfor
	endif	
	//Gets Scale Values
	wave Yval=$(df+"Yval")
	wave Zval=$(df+"Zval")
	wave Tval=$(df+"Tval")
	variable val2D, val3D, val4D
	grep/q/list/E="# 2-D Scan Values:"/P=LoadPath filename
	Val2D=str2num(stringfromlist(1,s_value,":"))
	grep/q/list/E="# 3-D Scan Values:"/P=LoadPath filename
	Val3D=str2num(stringfromlist(1,s_value,":"))
	grep/q/list/E="# 4-D Scan Values:"/P=LoadPath filename
	Val4D=str2num(stringfromlist(1,s_value,":"))
	Yval[i]=Val2D
	Zval[i]=Val3D
	Tval[i]=Val4D
End
Function LoadMDAasciiSetScales(df,df2d,dims)
	string df, df2d,dims //df2d is the full path
	svar scale1D=$(df+"scale1D"), scale2D=$(df+"scale2D"), scale3D=$(df+"scale3D"), scale4D=$(df+"scale4D")
	variable n, i, start, delta, ny, nz
	string axis="x;y;z;t", units, name
	For(n=0;n<CountObjects("",1);n+=1)
		wave det=$GetIndexedObjName("", 1, n)
		For(i=1;i<=itemsinlist(dims,"x");i+=1)
			switch(i)
				case 1:
					units=stringfromlist(0,Scale1D)
					string wvname=selectstring(numtype(str2num(units[0,1])),"c"+units, units)
					wave wv=$(df2d+"c"+ units)
					start=selectnumber(stringmatch(Scale1D,"*LINEAR*"),0,wv[0])
					delta=selectnumber(stringmatch(Scale1D,"*LINEAR*"),1,wv[1]-wv[0])
					if(numtype(delta)!=0)
						start=0
						delta=1
						units="points"
					endif
					setscale/p x, start, delta, units, det
				break
				case 2:
					units=stringfromlist(0,Scale2D)
					wave Yval=$(df+"Yval")
					start=selectnumber(stringmatch(Scale2D,"*LINEAR*"),0,Yval[0])
					delta=selectnumber(stringmatch(Scale2D,"*LINEAR*"),0,Yval[1]-Yval[0])
					setscale/p y, start, delta, units, det
				break
				case 3:
					ny=str2num(stringfromlist(1,dims,"x"))
					units=stringfromlist(0,Scale3D)
					wave Zval=$(df+"Zval")
					start=selectnumber(stringmatch(Scale3D,"*LINEAR*"),0,Zval[0])
					delta=selectnumber(stringmatch(Scale3D,"*LINEAR*"),0,Zval[ny+1]-Zval[0])
					setscale/p z, start, delta, units, det
				break
				case 4:
					ny=str2num(stringfromlist(1,dims,"x"))
					nz=str2num(stringfromlist(2,dims,"x"))
					units=stringfromlist(0,Scale4D)
					wave Tval=$(df+"Tval")
					start=selectnumber(stringmatch(Scale4D,"*LINEAR*"),0,Tval[0])
					delta=selectnumber(stringmatch(Scale4D,"*LINEAR*"),0,Tval[ny*nz]-Tval[0])
					setscale/p t, start, delta, units, det
				break
			endswitch
		endfor
	endfor
End	
/////////////////////////////////////////////////////
///MDA tools
/////////////////////////////////////////////////////

Function MDAToolsHelp() 
	DoWindow/F MDAToolsInfo
	if(V_flag==0)
		string txt
		NewNotebook/W=(100,100,700,400)/F=1/K=1/N=MDAToolsInfo
		Notebook MDAToolsInfo ruler=Normal, margins={0,0,680}, spacing={0,0,0}
		Notebook MDAToolsInfo, fstyle=1, text="ExtraPVnotebook()\r"
		txt=" Creates a notebook list all the extra PV in a readable format from the first wave in the current datafolder\r"
		txt+="\r"
		Notebook MDAToolsInfo, fstyle=0, text=txt
		
		Notebook MDAToolsInfo, fstyle=1, text="ExtraPVstrList(key)\r"
		txt="  Returns a list with all Extra PVs which contain the key string\r"
		txt+="\r"
		Notebook MDAToolsInfo, fstyle=0, text=txt
		
		Notebook MDAToolsInfo, fstyle=1, text="ExtraPVval(pv)\r"
		txt="Returns the value associated with a given pv. The pv should be the unique string.\r"
		txt+="\r"
		Notebook MDAToolsInfo, fstyle=0, text=txt
		
		Notebook MDAToolsInfo, fstyle=1, text="ExtraPV2waveDialog()\r"
		txt="Fills in a wave with the values for a given PV. Requires the following structure:\r"
		txt+="     Folder containing the mda detector basename+ScanNumber+suffix, format support subfolders\r"
		txt+="          Example 1  29idc_0001; basename=\"29idc_\", ScanNumber=1; suffix=\"\"\r"
		txt+="          Example 2: root:MyMDA:29idc_0001;  basename=\"root:MyMDA:29idc_\", ScanNumber=1; suffix=\"\"\r"
		txt+="     PV: a string with the unique name of a PV\r"
		txt+="     ScanNum_wave: a wave containing the ScanNumber of interst \r"
		txt+="     Destination_wave: a wave of equal size to the ScanNum_wave where you want the values\r"
		txt+="\r"
		Notebook MDAToolsInfo, fstyle=0, text=txt
	endif
end

Menu "APS Procs"
	Submenu "IEX"
		Submenu "Wave note tools"	
			Submenu "MDA Tools"
				"MDA Extra PVs -- list all", ExtraPVnotebook()
				"MDA keyword search", print "ExtraPVstrList(\"pv\")"
				"MDA Extra PV val", print "ExtraPVva(\"pv\")"
				"MDA Extra PV to wave", ExtraPV2waveDialog()
				"MDA Summarize all loaded folders",MDA_MakeSummary()
				"MDA Tools Help", MDAToolsHelp()
			end
		end
	end
end

Function ExtraPVnotebook()
	DFREF dfr = GetDataFolderDFR()
	wave wv=$GetIndexedObjNameDFR(dfr, 1, 0)
	string buffer=note(wv)
	string folder=getwavesdatafolder(wv,0)
	DoWindow/F $(folder)
	if(V_flag==0)
		NewNotebook/W=(100,100,570,400)/F=1/K=1/N=$(folder)
		Notebook $folder showruler=0, backRGB=(45000,65535,65535)
		Notebook $folder text=""
		variable i
		string txt=""
		string tmp
		For (i=0;i<itemsinlist(buffer,";");i+=1)
				tmp=stringfromlist(i,buffer)
	//			tmp=replacestring(",", tmp,"\t")
				txt+=tmp+"\r"
		endfor
		Notebook $folder text=txt
	endif
end
Function/s ExtraPVstrList(key)
	string key
	DFREF dfr = GetDataFolderDFR()
	wave wv=$GetIndexedObjNameDFR(dfr, 1, 0)	
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+key+"*")
	return tmp
end
Function/s ExtraPVstr(df,key)
	string df,key
	wave wv=$(df+GetIndexedObjName(df, 1, 0))	
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+key+"*")
	string valstr=stringfromlist(2,tmp,",")
 	valstr=valstr[2,strlen(valstr)-2]
	return valstr
end
Function ExtraPVval(pv)
	string pv
	string extrapv=ExtraPVstrList(pv)
	string valstr=stringfromlist(2,extrapv,",")
 	variable val=str2num(valstr[2,strlen(valstr)-2])
 	return val
end
Function ExtraPVs2wave(pv, destwv_name, basename,suffix,scanname_wvname)
	string pv, basename,suffix,destwv_name,scanname_wvname
	wave destwv_wv=$(destwv_name),scanname_wv=$(scanname_wvname)
	variable i
	DFREF saveDFR = GetDataFolderDFR()
	for(i=0;i<dimsize(scanname_wv,0);i+=1)
		variable scannum=scanname_wv[i]
		string dfn=JLM_FileLoaderModule#FolderNamewithNum(basename,scannum,suffix)
		if(DataFolderExists(dfn)!=1)
			print "check that current data folder"
			abort
		endif
		setdatafolder $dfn // setdatafolder $("root:"+dfn)
		variable val=ExtraPVval(pv)
		destwv_wv[i]=val
		SetDataFolder saveDFR
	endfor
end
Function ExtraPV2waveDialog()
	string pv,basename,suffix, scannum,dest
	Prompt pv, "PV or string to search"
	Prompt basename, "Folder name prefix"
	Prompt suffix, "Folder name suffix"
	Prompt scannum, "Wave with scan numbers",popup, WaveList("*",";","")
	Prompt dest, "Destination wave", popup,  WaveList("*",";","")
	DoPrompt "Folder name = prefix+scan number+suffix", pv, dest, basename, scannum,suffix
	if (v_flag==0)
		wave dest_wv=$dest, scannum_wv=$scannum
		print "ExtraPVs2wave(\""+pv+"\",\""+GetWavesDataFolder(dest_wv,2)+"\",\""+basename+"\",\""+suffix+"\",\""+GetWavesDataFolder(scannum_wv,2)+"\")"
		ExtraPVs2wave(pv, GetWavesDataFolder(dest_wv,2), basename,suffix,GetWavesDataFolder(scannum_wv,2))
		endif
end
Function MDA_MakeSummary()
	setdatafolder root:
	string basename="mda_", suffix=""
	variable i,j
	// Data folder list //
	DFREF dfr = GetDataFolderDFR()
	string df="root:mdaSummary:"
	newdatafolder/o root:mdaSummary
	string folder="", folderlist=""
	for (i=0;i<countobjectsdfr(dfr, 4);i+=1)
		folder=GetIndexedObjNameDFR(dfr, 4, i )
		folderlist=addlistitem(folder,folderlist, ";")
	endfor
	folderlist=sortlist(folderlist,";",16)
	folderlist=JLM_FileLoaderModule#ReduceList(folderlist, basename+"*" ) 
	folderlist=JLM_FileLoaderModule#ReduceList(folderlist,"*"+suffix)
	//Extra PV info//
	setdatafolder $stringfromlist(0,folderlist,";")
	wave wv=$(GetIndexedObjName("", 1, 0))
	string buffer=note(wv)
	string PVlist=""
	//Make Extra PV waves
	For (i=0;i<itemsinlist(buffer,";");i+=1)
			string tmp=stringfromlist(i,buffer,";")
			tmp=stringfromlist(0,tmp,",")
			tmp=tmp[strsearch(tmp,":",0)+2,inf] //get PV name from ExtraPVs
			//testing is extra pv is string or variable 
			string extrapv=ExtraPVstrList(tmp)
			string valstr=stringfromlist(2,extrapv,",")
			valstr=valstr[2,strlen(valstr)-2]
			if(numtype(strlen(valstr))==0) //pv not an empty string
				pvlist=addlistitem(tmp,pvlist, ";")
	 			variable val=str2num(valstr[2,strlen(valstr)-2])
				if(numtype(val)==2)
					make/t/o/n=(itemsinlist(folderlist,";"))  $(df+cleanupname(tmp,0))
				elseif(numtype(val)==0)
					make/o/n=(itemsinlist(folderlist,";"))  $(df+cleanupname(tmp,0))
				endif
			endif
	endfor	
	// Make Summary Waves
	make/o/T/n=(itemsinlist(folderlist,";")) $(df+"Scan_Name")
	wave/T Scan_Name=$(df+"Scan_Name")
	//Fill in Tables
	for(i=0;i<itemsinlist(folderlist,";");i+=1)
		Scan_Name[i]=stringfromlist(i,folderlist,";")
		setdatafolder dfr
		setdatafolder $(stringfromlist(i,folderlist,";"))
		for(j=0;j<itemsinlist(pvlist,";");j+=1)
			//wave wv=$(df+cleanupname(stringfromlist(j,pvlist),0))
			//wv[i]=ExtraPVval(stringfromlist(j,pvlist))
			//testing is extra pv is string or variable 
			tmp=stringfromlist(j,pvlist)
			extrapv=ExtraPVstrList(tmp)
			valstr=stringfromlist(2,extrapv,",")
			valstr=valstr[2,strlen(valstr)-2]
			if(numtype(strlen(valstr))==0)  //pv not an empty string
	 			val=str2num(valstr[2,strlen(valstr)])
				if(numtype(val)==2)
					wave/t wvt=$(df+cleanupname(stringfromlist(j,pvlist),0))
					wvt[i]=valstr
				elseif(numtype(val)==0)
					wave wv=$(df+cleanupname(stringfromlist(j,pvlist),0))
					wv[i]=str2num(valstr)
				endif
			endif
		endfor
	endfor
	setdatafolder dfr
end	
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////		mda Panel		//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

Macro mdaKey_Panel()
	If(WinType("ncKeyPanel")!=7)
		mdaKeyPanel_Variables()
		mdaKeyPanel_Setup()
	else
		dowindow/f mdaKeyPanel
	endif
end
Function mdaKeyPanel_Variables()
	DFREF saveDFR = GetDataFolderDFR()
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	NewDataFolder/o/s root:mdaKeyPanel
	SetDataFolder saveDFR
	string/g $(df+"key"), $(df+"fldname"), $(df+"fldlist"),$(df+"ExtraPVList")
	string/g $(df+"val")
	svar key=$(df+"key"), fldname=$(df+"fldname"), fldlist=$(df+"fldlist"),ExtraPVList=$(df+"ExtraPVList")
	key="";fldname="";fldlist="Select Wave;",ExtraPVList="Select Attribute"
	fldlist=mdaPanel_FolderListGet()
	make/t/n=(itemsinlist(fldlist,";"))$(df+ "fldlist_wv")
	wave/t	fldlist_wv=$(df+ "fldlist_wv")
	fldname=stringfromlist(0,fldlist,";")
	nvar val=$(df+"val")
	val=nan
end
Function mdaKeyPanel_Setup()
	DFREF saveDFR = GetDataFolderDFR()
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	svar key=$(df+"key"), fldname=$(df+"fldname"), fldlist=$(df+"fldlist")
	svar val=$(df+"val")
	NewPanel /W=(514,454,779,535) 
	DoWindow/C/T/R $dfn,dfn
	setwindow $dfn, hook(cursorhook)=mdaKeyPanel_Hook, hookevents=3, hook=$""
	ModifyPanel cbRGB=(1,52428,52428)
	PopupMenu popupFolderList,pos={8,8},size={95,20},proc=mdaKeyPanel_PopMenuFolderList,title="Folder List"
	PopupMenu popupFolderList,mode=1,popvalue="---",value= #(df+"fldlist") 
	PopupMenu popupKeyList,pos={7,31},size={193,15},proc=mdaKeyPanel_PopMenuExtraPVList,title="Extra PVs List"
	PopupMenu popupKeyList,mode=1,value= #(df+"ExtraPVList")
	SetVariable setvarVal,pos={6,51},size={223,15}
	SetVariable setvarVal,limits={-inf,inf,0},value= root:mdaKeyPanel:val
	Button buttonF title=">",pos={200,7},size={15,20},proc=mdaKeyPanel_ButtonProcs
	Button buttonR title="<",pos={180,7},size={15,20},proc=mdaKeyPanel_ButtonProcs

	
	SetDataFolder saveDFR
end


Function mdaKeyPanel_ButtonProcs(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	svar fldlist=$(df+"fldlist"),fldname=$(df+"fldname")
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
				which=i+which
			endif
			fldname=stringfromlist(which,fldlist,";")
			STRUCT WMPopupAction pa
			pa.ctrlName="popupFolderList"
			pa.popStr=fldname
			pa.popNum=which
			mdaKeyPanel_PopMenuFolderList(pa)
			 PopupMenu popupFolderList,mode=1,popvalue=fldname//,value=fldlist 
		break
	endswitch
End

Function mdaKeyPanel_PopMenuExtraPVList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	svar fldname=$(df+"fldname"), ExtraPVList=$(df+"ExtraPVList"), key=$(df+"key")
	svar val=$(df+"val")
	ExtraPVList=mdaPanel_ExtraPVList(fldname)
	key=popStr
	val= ExtraPVstr("root:"+fldname+":",key)
	return 0
End		

Function mdaKeyPanel_PopMenuFolderList(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	pa.blockReentry = 1
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	svar fldname=$(df+"fldname"), fldlist=$(df+"fldlist")
	svar ExtraPVList=$(df+"ExtraPVList"), key=$(df+"key")
	fldlist=mdaPanel_FolderListGet()
	variable keynum=whichlistitem(key,ExtraPVList,";")+1
	
	Variable popNum = pa.popNum
	String popStr = pa.popStr
	fldname=popStr
	PopupMenu popupFolderList popvalue=popStr
	wave wv=$GetIndexedObjName("root:"+fldname+":", 1, 0)
	mdaKeyPanel_PopMenuExtraPVList("popupKeyList",keynum,key)

	return 0
End

Function/s mdaPanel_FolderListGet() //currently only works for folders in root directory
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	string fldlist=""
	variable i
	for (i=0;i<countobjectsdfr(root:, 4);i+=1)
		string folder=GetIndexedObjNameDFR(root:, 4, i )
		if(stringmatch(folder,"mda_*")==1)
			fldlist=addlistitem(folder,fldlist, ";")
		endif
	endfor
	fldlist=sortlist(fldlist,";",16)
	return fldlist
end

Function/s mdaPanel_ExtraPVList(fldname)
	string fldname
	setdatafolder $("root:"+fldname+":")
	wave wv=$GetIndexedObjName("root:"+fldname+":", 1, 0)
	string tmp=note(wv)
	string ExtraPVList=""
	variable i
	for(i=10;i<itemsinlist(tmp,";");i+=1)
		string PV=stringfromlist(i,tmp,";")
		PV=PV[strsearch(PV,":",0)+2,strsearch(PV,",",0)-1]
		ExtraPVList=addlistitem(PV,ExtraPVList, ";")
	endfor
	setdatafolder root:
	return ExtraPVList
end

	
Function mdaKeyPanel_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	string dfn="mdaKeyPanel", df="root:"+dfn+":"
	svar key=$(df+"key"), fldname=$(df+"fldname")
	nvar val=$(df+"val")
	wave wv=$fldname
	string pvlist=note(wv), pv
	pvlist=listmatch(pvlist,"*"+key+"*")
	pv="\r"+key
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
				string  keysep=":",listsep=";"
				val=WavenoteKeyVal(fldname,pv,keysep,listsep) 
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function mdaKeyPanel_Hook(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	string dfn=H_Struct.winName; string df="root:"+dfn+":"
	if(eventcode==2)
		dowindow /F $dfn
		JLM_FileLoaderModule#killallinfolder(df)
		killdatafolder $df
		return(-1)
	endif
end


//////////////////////////////////Load Tif///////////////////////////////////
Function/s LoadImage_tiff(df)
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")	
	ImageLoad/O/Q/P=LoadPath/T=tiff/N=temp filename
	Redimension/S temp
	string base="t"+filename[0,strlen(filename)-5]
	wave temp
	duplicate/o temp $("root:"+base)
	string folder=stringfromlist(itemsinlist(s_path,":")-1,s_path,":")
	return folder
End

Function Make3d(dims, base)
	variable dims
	string base
	wave temp
	redimension/N=(-1,-1,dims) temp
	variable i
	for(i=1;i<dims;i+=1)
		wave t2=$("temp"+num2str(i))
		temp[][][i]=t2[p][q]
		killwaves/z t2
	endfor
	duplicate/o temp, $base
	killwaves/z temp
end
///////////////////////mpa binary and ascii/////////////////////////////////
Function/s LoadMPA(df) //based on code from Jan Ilavsky @ the APSLoadNetCDF(df)
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")	
	///getting load  parameters
	string testline="", txt=""
	variable RefNum, Offset
	testLine=PadString (testLine, 300000, 0x20)
	open /R/P=LoadPath RefNum as filename
	FreadLine/N=2048 /T=";" RefNum, testLine
	testLine=ReplaceString("\r\n", testLine, ";" )
	close RefNum
	testLine=ReplaceString("\n", testLine, ";" )
	testLine=ReplaceString(" ", testLine, "" )
	txt=testLine
	testLine=testLine[0,strsearch(testLine, "[DAT", 0 )-1]
	string mpatype=StringByKey("mpafmt", testLine, "=", ";")
	variable mparange=1024^2 //NumberByKey("range", testLine, "=", ";")
	variable numBytes=NumberByKey("range", testLine , "=" , ";")
	string fname=filename[0,strlen(filename)-5]
	fname=cleanupname(fname,0)
	strswitch (mpatype)
		case "dat":
			testLine=""
			testLine=PadString (testLine, 300000, 0x20)
			open /R/P=LoadPath RefNum as filename
			FBinRead RefNum, testLine
			Offset=(strsearch(testLine, "[CDAT0,1048576 ]", 0))+22
			close RefNum
			GBLoadWave/Q/B/T={96,4}/S=(Offset)/W=1/P=LoadPath/N=MPA filename
			if(v_flag==0)
				abort
			endif
			wave MPA=$stringfromlist(0,s_waveNames)
			Redimension/S/N=(1024,1024) MPA
			duplicate/o MPA $fname
			killwaves/z MPA
		break
		case "asc":
			Offset=MPAnumdata(df)+1
			LoadWave/Q /J /D /O/N=MPA /K=0 /L={0,Offset,0,0,0}/P=LoadPath filename
			if(v_flag==0)
				abort
			endif
			wave MPA=$stringfromlist(0,s_waveNames)
			Redimension/S/N=(1024,1024) MPA
			duplicate/o MPA $fname
			killwaves/z MPA
		break
		case "spe":
			Offset=MPAnumdata(df)+8 //doesn't work
		break
		case "csv":
			Offset=MPAnumdata(df)+13
			//print offset
			DFREF saveDFR = GetDataFolderDFR()
			LoadWave/q /G /W/D /O/N=MPA/L={0,Offset,0,0,3} /K=0 /P=LoadPath filename //load several wave, need to convert to image
			if(v_flag==0)
				abort
			endif
			string list=""
			variable i
			for(i=0;i<itemsinlist(S_waveNames,";");i+=1)
				wave MPA=$(stringfromlist(i,S_waveNames,";"))
				if(dimsize(MPA,0)>1)
					list+=nameofwave(MPA)+";"
				endif
			endfor
			duplicate/o MPA $fname
			wave img=$fname
			redimension/S/n=(1024,1024) img
			wave wvx=$(stringfromlist(0,list,";")),wvy=$(stringfromlist(1,list,";")),wvint=$(stringfromlist(2,list,";"))
			variable n
			for(n=0;n<dimsize(wvint,0);n+=1) //repacking image
				variable xpnt=wvx[n],ypnt=wvy[n]
				img[xpnt][ypnt]=wvint[n]
			endfor
			for(i=0;i<itemsinlist(S_waveNames,";");i+=1)
				wave MPA=$(stringfromlist(i,S_waveNames,";"))
				killwaves/z MPA
			endfor	
		break
	endswitch	

//return fname
end

Function MPAnumdata(df)
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")
	variable RefNum
	Open/R/P=LoadPath refNum as filename
	String buffer, text
	Variable line = 0
	do
		FReadLine refNum, buffer
		if (strlen(buffer) == 0)
			Close refNum
			return -1	// The expected keyword was not found in the file
		endif
		text = buffer[0,5]
		if (CmpStr(text, "[CDAT0") == 0)         // Line does start with "[DATA" ?
			Close refNum
			return line + 1                                        // Success: The next line is the first data line.
		 endif
		line += 1	
	 while(1)
	 return -1          // We will never get here
end

Function MPAnumlines(df)
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")
	variable RefNum
	Open/R/P=LoadPath refNum as filename
	variable TicksStart=ticks
	String buffer, text
	Variable line = 0
	do
		FReadLine refNum, buffer
		if (strlen(buffer) == 0)
			Close refNum
			return -1	// The expected keyword was not found in the file
		endif
		text = buffer[0,5]
		if (CmpStr(text, "[CDAT0") == 0)         // Line does start with "[DATA" ?
			Close refNum
			return line + 1                                        // Success: The next line is the first data line.
		 endif
		line += 1	
	 while(1)
	do
		 FReadLine refNum, buffer
		 if (strlen(buffer) == 0)
			Close refNum
			return -1	// end of file reached
		endif
		line += 1
	while(1)
	line=0
	 FReadLine refNum, buffer
	 if (strlen(buffer) == 0)
			Close refNum
			return -1	// end of file reached
	endif
	variable startPnt, endPnt
	string tempStr//=NI1_COnvertLineIntoList(buffer)	
	StartPnt= str2num(StringFromList(0, tempStr , ";"))
	EndPnt= str2num(StringFromList(1, tempStr , ";"))
end

Function MPAmetadata(df)
	string df
end
///////////////////////NetCDF/////////////////////////////////
Function/s LoadNetCDF(df)
	string df
	svar filelist=$(df+"filelist"), filename=$(df+"filename"), filepath=$(df+"filepath")	
	killdatafolder/z $(df+"nc_load")
	newdatafolder $(df+"nc_load")
	setdatafolder $(df+"nc_load")
	Execute "Load_NetCDF/P=LoadPath/T/Q "+df+"filename"
	duplicatedatafolder $(df+"nc_load") $("root:"+filename[0,strlen(filename)-4])
	setdatafolder $("root:"+filename[0,strlen(filename)-4])
	killdatafolder $(df+"nc_load")
	NetCDFmetadata()
	NetCDF_SESscaling()
	string wvname=SelectString(exists(filename[0,strlen(filename)-4]),filename[0,strlen(filename)-4]+"avgy",filename[0,strlen(filename)-4])
//	string wvname=SelectString(exists(filename[0,strlen(filename)-4]),filename[0,strlen(filename)-4],filename[0,strlen(filename)-3])
//	wvname=SelectString(wavedims())
	wave wv=$wvname
	NetCDF_SES_CropImage(wv)
	nvar checkBE_KE=$(df+"checkBE_KE")
	if (checkBE_KE==1)
		variable wk=4.8
		IEX_SetEnergyScale(wvname,0,wavedims(wv)-1,wk)
	endif
	//return filename[0,strlen(filename)-4]
End
Function NetCDFmetadata()
	string df=getdatafolder(1)
	wave nc_array_data //datafile
	wave/t nc_varnames
 	variable i
 	string key, val, nt
 	nt=""
	For(i=0;i<dimsize(nc_varnames,0);i+=1)
  		key=nc_varnames[i]
 		wave wv=$("nc_"+key)
 		if(WaveType(wv,1)==2)
 			wave/t wvt=$("nc_"+key)
 			val=cleanupname(wvt[0],1)
 		else
 			val=cleanupname(num2str(wv[0]),1)
 		endif
 		note nc_array_data, key+":"+val+";"
 	endfor
end
Function NetCDF_SESscaling()//Set up for SES  at IEX SerialNumber:4MS276 as of 4/19/2017
	string dfn=getdatafolder(0)
	wave nc_Attr_DetectorMode,nc_Attr_AcquisitionMode, nc_Attr_LensMode
	wave nc_Attr_LowEnergy, nc_Attr_HighEnergy, nc_Attr_ActualPhotonEnergy, nc_Attr_EnergyStep, nc_Attr_EnergyStep_RBV
	wave nc_Attr_EnergyStep_Fixed_RBV, nc_Attr_EnergyStep_Swept, nc_Attr_EnergyStep_Swept_RBV

	wave nc_Attr_PassEnergy
	wave nc_Attr_FirstChannel
	wave nc_Attr_CentreEnergy_RBV
	wave nc_array_data
	duplicate/o nc_array_data $("root:"+dfn)
	wave wv=$("root:"+dfn)
	setdatafolder root:
	//Energy Scaling Info
	variable DetMode=nc_Attr_DetectorMode[0] // BE=0,KE=1
	variable AcqMode= nc_Attr_AcquisitionMode[0]
	variable LensMode=nc_Attr_LensMode[0]
	variable Estart, Estop, Edelta, Ehv,Ecenter
	string Eunits
	variable PassEnergyMode=nc_Attr_PassEnergy[0]
	string PElist="1;2;5;10;20;50;100;200;500"
	variable PE=str2num(stringfromlist(PassEnergyMode,PElist,";"))
	variable EperChannel=nc_Attr_EnergyStep_Fixed_RBV[0]
	if(waveExists(nc_Attr_EnergyStep_Swept))
		Edelta=selectnumber(DetMode,-nc_Attr_EnergyStep_Swept[0],nc_Attr_EnergyStep_Swept[0])
	else
		Edelta=selectnumber(DetMode,-nc_Attr_EnergyStep[0],nc_Attr_EnergyStep[0])
	endif
	Switch(AcqMode)
		case 0: //Swept
			Ehv=nc_Attr_ActualPhotonEnergy[0]
			Estart=selectnumber(DetMode,Ehv-nc_Attr_LowEnergy[0],nc_Attr_LowEnergy[0])
			Estop=selectnumber(DetMode,Ehv-nc_Attr_HighEnergy[0],nc_Attr_HighEnergy[0])
			Eunits=selectstring(DetMode,"Binding Energy (eV)","Kinetic Energy (eV)")
		break
		case 1: //Fixed
			Eunits=selectstring(DetMode,"Binding Energy (eV)","Kinetic Energy (eV)")
			Ecenter=nc_Attr_CentreEnergy_RBV[0] 
			Estart=Ecenter-(dimsize(wv,0)/2)*Edelta//not transposed yet
		break
		case 2://Baby Swept
			Eunits=selectstring(DetMode,"Binding Energy (eV)","Kinetic Energy (eV)")
			Ecenter=nc_Attr_CentreEnergy_RBV[0] 
			Estart=Ecenter-(dimsize(wv,0)/2)*Edelta//not transposed yet
		break
	endswitch
	//Angular Scaling Info
	variable DegPerChannel=.0292717// from SES file should be 0.0678/0.1631*EperChannel//
//	print DegPerChannel
	If(LensMode==0)
		// Transmission
			string opt="/X/D=root:"+dfn+"avgy"
			JLM_FileLoaderModule#ImgAvg(wv,opt)
			wave avg=$("root:"+dfn+"avgy")
			note avg Note(wv)
			killwaves wv
			SetScale/p x, Estart,Edelta,Eunits,avg
	Else //Angular Mode
		variable CenterChannel=571
		variable FirstChannel
		If(waveExists(nc_Attr_FirstChannel))
			FirstChannel=nc_Attr_FirstChannel[0]
		else
			FirstChannel=0
		endif
		//rotate image (KE vs deg)
		Redimension/S/N=(dimsize(nc_array_data,1),dimsize(nc_array_data,0),-1,-1) wv
		wv[][][][]=nc_array_data[q][p][r][x]	
		SetScale/p y, Estart,Edelta,Eunits,wv
		SetScale/p x, (FirstChannel-CenterChannel)*DegPerChannel,DegPerChannel,"Deg",wv
	EndIf
	If(dimsize(wv,2)==1)
		Redimension/N=(-1,-1,0) wv
	endif


	JLM_FileLoaderModule#killallinfolder(dfn)
	killdatafolder dfn
end

Menu "APS Procs"
	Submenu "IEX"
		Submenu "ARPES - Analysis Tools"		
			"KE_BE Scaling", IEX_SetEnergyScale_Dialog()
			"Angle Scaling", IEX_SetAngleScale_Dialog()
		end
	end
end

Function IEX_SetEnergyScale_Dialog()
	string wvname,Emodestr,Edimstr="y"
	variable Wk=4.8
	Prompt wvname, "Wave:",popup, "; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	Prompt Emodestr, "Energy Scale", popup, "Binding Energy; Kinetic Energy"
	Prompt Edimstr, "Energy Dimension:", popup, "x;y;z;t"
	Prompt Wk, "Work Function"
	DoPrompt "Set netCDF SES Energy Scale"wvname,Emodestr,Edimstr,WK
	variable Emode,Edim
	Emode=SelectNumber(cmpstr(Emodestr,"Binding Energy"),0,1)
	Edim=SelectNumber(cmpstr(Edimstr,"t"),3,1+cmpstr(Edimstr,"y")) //dim from  popup list
	if (v_flag==0)
		print "IEX_SetEnergyScale(\""+wvname+"\","+num2str(Emode)+","+num2str(Edim)+","+num2str(Wk)+")"	
		IEX_SetEnergyScale(wvname,Emode,Edim,Wk)
	endif
end
Function IEX_SetEnergyScale(wvname,Emode,Edim, Wk)
	string wvname
	variable Emode	// BE=0,KE=1
	variable Edim, Wk
	string  keysep=":",listsep=";"
	variable hvphi=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_ActualPhotonEnergy",keysep,listsep) 
	hvphi-=wk//photon energy plus the work function
	variable LowEnergy=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_LowEnergy_RBV",keysep,listsep) 
	variable HighEnergy=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_HighEnergy_RBV",keysep,listsep) 	
	variable CentreEnergy=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_CentreEnergy_RBV",keysep,listsep) 
	variable EnergyStep=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_EnergyStep_RBV",keysep,listsep)
	variable EnergyStep_Swept=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_EnergyStep_Swept_RBV",keysep,listsep) 
	variable AcqMode=JLM_FileLoaderModule#WavenoteKeyVal(wvname,"\r"+"Attr_AcquisitionMode_RBV",keysep,listsep) // Swept=0; Fixed=1
	variable Edelta=SelectNumber(numtype(EnergyStep),EnergyStep,EnergyStep_Swept) //temporarilty had renamed the attribute make back compatible
	variable Estart=SelectNumber(AcqMode,SelectNumber(Emode,LowEnergy-hvphi,LowEnergy), SelectNumber(Emode,CentreEnergy-(dimsize($wvname,Edim)/2)*Edelta-hvphi,CentreEnergy-(dimsize($wvname,Edim)/2)*Edelta))
	string Eunits=SelectString(Emode,"Binding Energy (eV)", "Kinetic Energy (eV)")
	variable i
	Switch (Edim)
		case 0:
			SetScale/p x, Estart,Edelta,Eunits,$wvname
			break
		case 1:
			SetScale/p y, Estart,Edelta,Eunits,$wvname
			break
		case 2:
			SetScale/p z, Estart,Edelta,Eunits,$wvname
			break
		case 3:
			SetScale/p t, Estart,Edelta,Eunits,$wvname
			break
		Endswitch
end
Function IEX_SetAngleScale_Dialog()
	string wvname,Aunits,Adimstr="x"
	variable A0
	Prompt wvname, "Wave:",popup,"; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	Prompt Adimstr, "Angle Dimension:", popup, "x;y;z;t"
	Prompt A0, "Angle zero:"
	Prompt Aunits, "Units"
	DoPrompt "Set Angular Scale"wvname,Adimstr,A0,Aunits
	variable Adim
	Adim=SelectNumber(cmpstr(Adimstr,"t"),3,1+cmpstr(Adimstr,"y")) //dim from  popup list
	if (v_flag==0)
		print "IEX_SetAngleScale(\""+wvname+"\","+num2str(Adim)+",\""+Aunits+"\","+num2str(A0)+")"	
		IEX_SetAngleScale(wvname,Adim,Aunits,A0)
	endif
end
Function IEX_SetAngleScale(wvname,Adim,Aunits,A0)
	string wvname,Aunits
	variable Adim,A0
	string  keysep=":",listsep=";"
	variable Astep=dimdelta($wvname,Adim)
	variable Aoffset=dimoffset($wvname,Adim)	
	Switch (Adim)
		case 0:
			SetScale/p x, Aoffset-sign(Astep)*A0,Astep,Aunits,$wvname			
			break
		case 1:
			SetScale/p y, Aoffset-sign(Astep)*A0,Astep,Aunits,$wvname			
			break
		case 2:
			SetScale/p z, Aoffset-sign(Astep)*A0,Astep,Aunits,$wvname			
			break
		case 3:
			SetScale/p t, Aoffset-sign(Astep)*A0,Astep,Aunits,$wvname			
			break
		Endswitch	
	print "dimoffset("+wvname+","+num2str(Adim)+")  "+num2str(Aoffset)+"  =>  "+num2str(Aoffset+A0) 	
End

//Dither Procedures
Function LoaderPanel_DitherDialogButton(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			LoaderPanel_LoadDitherSetDialog()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
 Function LoaderPanel_LoadDitherSetDialog()
	string Filebasename="EA_",stackname="Dither",killstr
	variable DitherNum=49,first,last,NextInSeries=1,kill
	prompt Filebasename,"File base name"
	prompt stackname, "Basename for Dither stack"
	prompt DitherNum,"Number of files per Dither"
	prompt first, "First wave to load"
	prompt last, "Last wave to load"
	prompt NextInSeries, "Next number in series"
	prompt killstr, "Keep individual dither waves", popup "no;yes"
	DoPrompt "Load Dither:",Filebasename,DitherNum,stackname,first,last,NextInSeries,killstr
	kill=selectnumber(cmpstr(killstr,"yes"),0,1)
	if(v_flag==0)
		print "LoaderPanel_(\""+Filebasename+"\","+num2str(DitherNum)+",\""+stackname+"\","+num2str(first)+","+num2str(last)+","+num2str(NextInSeries)+","+num2str(kill)+")"
		LoaderPanel_LoadDitherSet(Filebasename,DitherNum,stackname,first,last,NextInSeries,kill)
	endif
end	

Function LoaderPanel_LoadDitherSet(Filebasename,DitherNum,stackname,first,last,NextInSeries,kill)
	string Filebasename,stackname
	variable DitherNum,first,last,NextInSeries,kill
	variable lastDither=floor((last-first+1)/DitherNum)*DitherNum+first
	variable j
	for(j=first;j<=lastDither;j+=DitherNum+1)
		LoaderLoad_CmdLine(Filebasename,".nc",j,j+DitherNum)
		LoaderPanel_ManyDither(stackname,j,j+DitherNum,NextinSeries,kill)
		Print stackname+"_"+num2str(NextinSeries)+"= Loaded files "+num2str(j)+"- "+num2str(j+DitherNum)
		NextinSeries+=1
	endfor
End

Function LoaderPanel_ManyDither(stackname,first,last,i,k) //i=next dithernumber, k=1 means kill individual dither waves
	string stackname
	variable first,last,i,k
	variable j
	variable numdither=49
	for(j=first;j<=last;j+=numdither+1)
		string basename="EA_",suffix="",DitherName="Dither"
		LoaderPanel_EA_Dither(basename,suffix,DitherName,j,j+numdither,k)
		wave Dither
		duplicate/o Dither $(stackname+"_"+num2str(i))
		i+=1
	endfor
	Print "Last EA file"+num2str(j)+", Last Dither wave"+num2str(i-1)
	note Dither "Dither stacked waves "+num2str(first)+"_"+num2str(last)
end

Function LoaderPanel_EA_Dither(basename,suffix,DitherName,first,last,k)
	string basename, suffix,DitherName
	variable first, last,k
	if(strlen(Dithername)==0)
		Dithername="Dither_"+num2str(first)+"_"+num2str(last)
	endif
	variable i
	variable DitherNum=last-first
	for(i=0;i<DitherNum+1;i+=1)
		wave wv=$WaveNamewithNum(basename,first+i,suffix)
		if(i==0)
			duplicate/o wv $DitherName
			wave Dither=$DitherName
			redimension/n=(-1,dimsize(Dither,1)+last-first+1) Dither
		else
			wave Dither=$DitherName
			dither[][]+=wv[p][q+i]
		endif
	endfor
	//Get rid of tails in the data
//	DeletePoints/M=1 dimsize(Dither,0)-DitherNum,dimsize(Dither,0), Dither
//	DeletePoints/M=1 0,DitherNum, Dither
	if(k==1)//kill
		LoaderPanel_KillwavesFirstLast(first, last)
	endif
End

Function LoaderPanel_KillwavesFirstLast(first, last)
variable first , last
variable i
for(i=0;i<abs(first-last)+1;i+=1)
wave wv=$WaveNamewithNum("EA_",first+i,"")
killwaves/z wv
endfor
end

Function NetCDF_SES_CropImage(wv)
	wave wv
		if(dimsize(wv,0)==1000)
		variable p1=338,p2=819 // data exists between p1 and p2
		deletepoints/m=0 p2,dimsize(wv,0), wv //right side
		deletepoints/m=0 0,p1, wv //left side
		setscale/p x, dimoffset(wv,0)+p1*dimdelta(wv,0), dimdelta(wv,0),"Angle",wv
	endif
end

Menu "APS Procs"
	Submenu "IEX"
		Submenu "Wave note tools"	
			Submenu "NetCDF Tools"
				"nc Attributes panel",ncKey_Panel()
				"nc Attributes -- list all", WavenoteNotebook_Dialog()
				"nc Attribute keyword search", ncNoteSearch_Dialog()	
				"nc Attributes to wave", ncNote2waveDialog()	
			end
		end
	end
end

Function ncNoteSearch_Dialog()
	string wvname, key, keysep,listsep
	keysep=":"
	listsep=";"
	Prompt wvname, "Wave name",popup, WaveList("*",";","")
	Prompt key, "Attribute:"
	DoPrompt "netCDF wave note search", wvname, key
	if (v_flag==0)
			print WavenoteKeyVal(wvname,key,keysep,listsep)
	endif
End

Function ncNote2wave(pv, destwv_name, basename,suffix,scanname_wvname)
	string pv, basename,suffix,destwv_name,scanname_wvname
	pv="\r"+pv
	string keysep=":",listsep=";"
	wave destwv_wv=$(destwv_name),scanname_wv=$(scanname_wvname)
	variable i
	for(i=0;i<dimsize(scanname_wv,0);i+=1)
		variable scannum=scanname_wv[i]
		string wvn=JLM_FileLoaderModule#WaveNamewithNum(basename,scannum,suffix)
		if(WaveExists($wvn)!=1)
			print "check the current data folder"
		endif

		variable val=WavenoteKeyVal(wvn,pv,keysep,listsep)
		destwv_wv[i]=val
	endfor
end

Function ncNote2waveDialog()
	string pv,basename,suffix, destwv_name,scanname_wvname
	string AttrList=ncPanel_AttributeList($(stringfromlist(0,WaveList("*",";",""))))
	Prompt pv, "Attribute",popup AttrList 
	Prompt basename, "Wave name prefix"
	Prompt suffix, "Wave name suffix"
	Prompt scanname_wvname, "Wave with scan numbers",popup, WaveList("*",";","")
	Prompt destwv_name, "Destination wave", popup,  WaveList("*",";","")
	DoPrompt "Wave name = prefix+scan number+suffix", pv, destwv_name, basename, scanname_wvname,suffix
	if (v_flag==0)
		wave dest_wv=$destwv_name, scannum_wv=$scanname_wvname
		print "ncNote2wave(\""+pv+"\",\""+GetWavesDataFolder(dest_wv,2)+"\",\""+basename+"\",\""+suffix+"\",\""+GetWavesDataFolder(scannum_wv,2)+"\")"
		ncNote2wave(pv, GetWavesDataFolder(dest_wv,2), basename,suffix,GetWavesDataFolder(scannum_wv,2))
	endif

end
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////		nc Panel		//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
Macro ncKey_Panel()
	If(WinType("ncKeyPanel")!=7)
		ncKeyPanel_Variables()
		ncKeyPanel_Setup()
	else
		dowindow/f ncKeyPanel
	endif
end
Function ncKeyPanel_Variables()
	DFREF saveDFR = GetDataFolderDFR()
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	NewDataFolder/o/s root:ncKeyPanel
	SetDataFolder saveDFR
	string/g $(df+"key"), $(df+"wvname"), $(df+"wvlist"),$(df+"AttrList")
	string/g $(df+"val")
	svar key=$(df+"key"), wvname=$(df+"wvname"), wvlist=$(df+"wvlist"),AttrList=$(df+"AttrList")
	key="";wvname="";wvlist="Select Wave;",AttrList="Select Attribute"
	wvlist=ncPanel_WaveListGet()
	make/t/n=(itemsinlist(wvlist,";"))$(df+ "wvList_wv")
	wave/t	wvList_wv=$(df+ "wvList_wv")
	
	wvname=stringfromlist(0,wvlist,";")
	nvar val=$(df+"val")
	val=nan
end
Function ncKeyPanel_Setup()
	DFREF saveDFR = GetDataFolderDFR()
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	svar key=$(df+"key"), wvname=$(df+"wvname"), wvlist=$(df+"wvlist")
	svar val=$(df+"val")
	NewPanel /W=(514,454,779,535) 
	DoWindow/C/T/R $dfn,dfn
	setwindow $dfn, hook(cursorhook)=ncKeyPanel_Hook, hookevents=3, hook=$""
	ModifyPanel cbRGB=(1,52428,52428)
	//SetVariable setvarKey,pos={7,31},size={193,15},proc=ncKeyPanel_SetVarProc
	//SetVariable setvarKey,value= root:ncKeyPanel:key
	PopupMenu popupWaveList,pos={8,8},size={95,20},proc=ncKeyPanel_PopMenuWaveList,title="Wave List"
	PopupMenu popupWaveList,mode=1,popvalue="---",value= #(df+"wvList") 
	PopupMenu popupKeyList,pos={7,31},size={193,15},proc=ncKeyPanel_PopMenuAttrList,title="Attribute List"
	PopupMenu popupKeyList,mode=1,value= #(df+"AttrList")
	SetVariable setvarVal,pos={6,51},size={223,15}
	SetVariable setvarVal,limits={-inf,inf,0},value= root:ncKeyPanel:val
	Button buttonF title=">",pos={200,7},size={15,20},proc=ncKeyPanel_ButtonProcs
	Button buttonR title="<",pos={180,7},size={15,20},proc=ncKeyPanel_ButtonProcs
	SetDataFolder saveDFR
end
Function ncKeyPanel_ButtonProcs(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	svar wvname=$(df+"wvname"), wvlist=$(df+"wvlist")
	variable which=whichlistitem(wvname,wvlist,";")
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
			if((which+i)>itemsinlist(wvlist,";"))
				which=0
			elseif((which+i)<0)
				which=itemsinlist(wvlist,";")
			else
				which=i+which
			endif
			wvname=stringfromlist(which,wvlist,";")
			STRUCT WMPopupAction pa
			pa.ctrlName="popupFolderList"
			pa.popStr=wvname
			pa.popNum=which
			pa.eventCode=2
			ncKeyPanel_PopMenuWaveList(pa)
			 PopupMenu popupWaveList,mode=1,popvalue=wvname//,value=fldlist 
		break
	endswitch
End

Function ncKeyPanel_PopMenuAttrList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	svar wvname=$(df+"wvname"), AttrList=$(df+"AttrList"), key=$(df+"key")
	wave wv=$wvname
	svar val=$(df+"val")
	AttrList=ncPanel_AttributeList(wv)
	key=popStr
	string  keysep=":",listsep=";"
	wave wv=$wvname
	val=JLM_FileLoaderModule#WaveNoteKeySearch(wv,"\r"+key) 		
	return 0
End		

Function ncKeyPanel_PopMenuWaveList(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	svar wvname=$(df+"wvname"), wvlist=$(df+"wvlist")
	svar AttrList=$(df+"AttrList"), key=$(df+"key")
	wvlist=ncPanel_WaveListGet()
	variable keynum=whichlistitem(key,AttrList,";")+1
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			wvname=popStr
			wave wv=$wvname
			ncKeyPanel_PopMenuAttrList("popupKeyList",keynum,key)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function/s ncPanel_WaveListGet()
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	string wvlist
	wvlist=WaveList("*",";","")
	return wvlist
end
Function/s ncPanel_AttributeList(wv)
	wave wv
	string AttrList=""
	string tmp=note(wv)
	tmp=JLM_FileLoaderModule#ReduceList( tmp, "\rAttr_*" )
	variable i
	for(i=0;i<itemsinlist(tmp,";");i+=1)
		string Attr=stringfromlist(i,tmp,";\r")
		Attr=stringfromlist(0,Attr,":")
		AttrList=addlistitem(Attr[1,inf],AttrList)		
	endfor
	return AttrList
end

	
Function ncKeyPanel_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	string dfn="ncKeyPanel", df="root:"+dfn+":"
	svar key=$(df+"key"), wvname=$(df+"wvname")
	nvar val=$(df+"val")
	wave wv=$wvname
	string pvlist=note(wv), pv
	pvlist=listmatch(pvlist,"*"+key+"*")
//	if(itemsinlist(pvlist,"\r")>1)
//		pv=listmatch(pvlist,"\rAttr_*"+key+"*")
//	else 
//		pv="\r"+key
//	endif
	pv="\r"+key
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
				string  keysep=":",listsep=";"
				val=WavenoteKeyVal(wvname,pv,keysep,listsep) 
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function ncKeyPanel_Hook(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	string dfn=H_Struct.winName; string df="root:"+dfn+":"
	if(eventcode==2)
		dowindow /F $dfn
//		RemoveGasCell()
		JLM_FileLoaderModule#killallinfolder(df)
		killdatafolder $df
		return(-1)
	endif
end

end




//=================== Wave and Folder Name Procedures ===================
//NewPath DataExport "Doc HD:Users:Shared:User_Files:DongKiLee:Data_Export:"
Static Function  ExportWaves_Dialog()
	variable first, last
	string basename, suffix
	Prompt basename, "Wave name prefix"
	Prompt suffix, "Wave name suffix"
	Prompt first, "First"
	Prompt last, "Last"
	DoPrompt "Select parameters for igor waves to be exported : metadata -> *.txt, data -> *.dat", basename, suffix, first, last
	if (v_flag==0)
		JLM_FileLoaderModule#ExportWaves(basename, suffix, first, last)
	endif
End
Static Function ExportWaves(basename, suffix, first, last)
	variable first, last
	string basename
	string suffix
	variable scannum
	For(scannum=first;scannum<=last;scannum+=1)
		string wvname=JLM_FileLoaderModule#WaveNamewithNum(basename,scannum,suffix)
		wave wv=$wvname
		//make table and save it to disk -- .dat
		Edit/N=export/K=0 wv.id
		string fname= wvname+".dat"
		SaveTableCopy/O/M="\n"/N=1/P=DataExport/T=1 as fname
		killwindow export
		//make a file with the wavenotes -- .txt
		string wvnt=note(wv)
		fname= wvname+".txt"
		variable refnum
		Open/P=DataExport refnum as fname
		variable j
		for(j=0;j<itemsinlist(wvnt,";\r");j+=1)
			string txt=stringfromlist(j,wvnt,";\r")
			fprintf refNum, txt
		endfor
		close refnum
	endfor
End

//////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////// Procedures Borrowed from JLMTools ////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

//=================== Wave and Folder Name Procedures ===================
Static Function/s Num2Str_SetLen(num,ndigits) //Make a string of a set character length
	variable ndigits, num
	string str,zeros=""
	variable i
	for(i=1;i<ndigits-1;i+=1)
		zeros+=num2str(0)
	endfor
//	print strlen(zeros), ndigits
	if(strlen(zeros)>ndigits)
	//	print "number is greater than number of digits"
	elseif(strlen(zeros)<ndigits)
		str=zeros[0,strlen(zeros)-floor(log(num))]+num2str(num)
	endif
	return str
end
Static Function/s WaveNamewithNum(basename,scannum,suffix)
	string basename, suffix
	variable scannum
	variable n
	for(n=1;n<=10;n+=1)//up to 10 digit filename
		string wvname=basename+Num2str_SetLen(Scannum,n)+suffix
		if(WaveExists($wvname)==1)
			return wvname
			break
		endif
	endfor
end
Static Function/s FolderNamewithNum(basename,scannum,suffix)
	string basename, suffix
	variable scannum
	variable n
	for(n=1;n<=10;n+=1)//up to 10 digit filename
		string fldrname=basename+Num2str_SetLen(Scannum,n)+suffix
		if(DataFolderExists(fldrname)==1)
			return fldrname
			break
		endif
	endfor

end
//=================== Wave note Procedures ===================
//netcdf: key="/r....", keysp=":", listsep=";"
Static Function WavenoteKeyVal(wvname,key,keysep,listsep)
	string wvname,key,keysep,listsep
	wave wv=$(wvname)
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+key+"*")
	string valstr=stringbykey(key,tmp,keysep,listsep)
	variable val=str2num(valstr)
	return val
end
Static Function/s WaveNoteKeySearch(wv, str)
	wave wv
	string str
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+str+"*")
	if(itemsinlist(tmp)>1)
		tmp=stringfromlist(0,tmp)
		//prompt tmp,"Which list term", popup, tmp
		//Doprompt "", tmp
	endif
	string val=StringByKey(str,tmp, ":", ";")
	return val
End
//////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////// Procedures Borrowed from BL 7 at ALS ////////////////////////////////////////
/////////////////////////////written by J. Delinger, E. Rotenber, A. Bostwick//////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

//kill all the variable, strings and waves in a data folder
// will kill dependencies up to ten deep
static function killallinfolder(df)
	string df
	string savefolder=getdatafolder(1)
	if(datafolderexists(df))
		setdatafolder(df)
		variable i=0,count
		do	
			killstrings /A/Z
			killvariables /A/Z
			killwaves /A/Z
			count = CountObjects(df,1)
			count +=  CountObjects(df,2)
			count +=  CountObjects(df,3)
			i+=1
		while(count*(i<10))
		setdatafolder(savefolder)
	endif
end


//=================== List Procedures===================
static Function/T ReduceList( liststr, matchstr )
//=============================
//form JDD at ALS
// creates subset of full list matching selected string
// must use wildcards (*) - using stringmatch function
// Alternately use (!*xyz) to return list items that do NOT match the rest of matchStr.
// no wildcards if using strsearch function
//
        string liststr, matchstr
        string outlist="", sep=";", str
       
        variable notmatch=0
        if (stringmatch(matchstr[0],"!*"))
                notmatch=1
                print matchstr
                matchstr=matchstr[1,inf]
                print matchstr
        endif
        //print nitems
        variable nitems=ItemsInList(liststr), ii=0, keep
        DO
                str=StringFromList( ii, liststr)
                // can also insert LowerStr( str ) and/or LowerStr(matchstr) for better matching
                //outlist+=SelectString( strsearch( str, matchstr, 0) >0 , "", str+";")
                keep=abs(notmatch - stringmatch( str, matchstr))        // 0=(0-0) or (1-1)
                outlist+=SelectString( keep,"", str+";")
                ii+=1
        WHILE(ii<nitems)
        //print ItemsInList(outlist)
        return  outlist
end


//=================== Progress Window ===================
//written by Eli Rotenberg in Fits loader
static function  OpenProgressWindow(progressname,prog_max)
		string progressname
		variable prog_max
		dowindow /k Export 
		NewPanel /K=1 /W=(344,223,603,329) as progressname
		dowindow /C Export
		variable /g root:progress 
		SetDrawLayer UserBack
		SetDrawEnv fsize= 24
		DrawText 154,49,"of "+num2str(prog_max-1)
		SetVariable progress,pos={20,20},size={125,28},title="Frame",fSize=20
		SetVariable progress,limits={-Inf,Inf,0},value=  root:progress,bodyWidth= 0
		ValDisplay valdisp0,pos={13,63},size={218,30},limits={0,prog_max-1,0},barmisc={0,0}
		 ValDisplay valdisp0,value= #"root:progress"
end
static function updateprogresswindow(val)		
		variable val
		NVAR progress = root:progress
		progress= val
		DoUpdate
end		
static function closeprogresswindow()		
		dowindow /k Export 
		killvariables root:progress
end

static Function FileSize_MB( filepath, filnam ) //written by Eli Rotenberg in Fits loader
	string filepath, filnam
	GetFileFolderInfo/Q/Z filepath+ filnam
	return round( 10*V_logEOF/1E6 )/10			//MB
End

Static Function/S ImgAvg( img, opt )
//================ from JDD in ImageTool4
// Average image along selected direction by average value defined range
// Future:  other methods:  divide by edge profile;  plot norm wave
// options: 
//     output:  img+"_av" (default),   or  /D=outputwavename,  or /O (overwrite)
//     direction:    /X (default) or  /Y 
//     range:        /R=y1,y2  or x1,x2   (default = full range)
//     plot:    /P  (display new image)
	wave img
	string opt
	
	//output array name
	//variable overwrite    -- no overwrite option since output is 1D
	string imgn=NameOfWave(img), avgn=JLM_FileLoaderModule#KeyStr("D", opt)
	if ((strlen(avgn)==0)+stringmatch(imgn,avgn))
		avgn=NameOfWave(img)+"_av"
		//overwrite=KeySet("O", opt)
	endif
	
	//direction
	variable  idir=0*JLM_FileLoaderModule#KeySet("X", opt)+1*JLM_FileLoaderModule#KeySet("Y", opt)
	variable nav=DimSize(img, idir), n2av=DimSize(img, 1-idir)
	//create output 1D array
	make/o/n=(nav) $avgn
	WAVE avg=$avgn
	
	//mask
	variable imask, maskval
	string maskn=JLM_FileLoaderModule#KeyStr("M", opt)
	imask=JLM_FileLoaderModule#KeySet("M", opt)*(strlen(maskn)>0)		//key set AND value given
	imask*=(exists(maskn)==1)		//wave exists
	//future: multiply image by mask; use image to create mask
	if (imask)
		WAVE mask=$maskn
		NewDataFolder/O root:tmp
		Make/O/N=(nav) root:tmp:masksum
		WAVE masksum=root:tmp:masksum
		// perform mask sum loop
		variable jj
		DO
			if (idir==0)
				masksum+=mask[p][jj]
			else
				masksum+=mask[jj][p]
			endif
			jj+=1
		WHILE(jj<n2av)
	endif
	variable ii
	DO
		if (idir==0)
			avg+=img[p][ii]
		else
			avg+=img[ii][p]
		endif
		ii+=1
	WHILE(ii<n2av)
	
	//normalize by value or masksum
	if (imask)
		avg/=masksum[p]
	else
		avg/=n2av
	endif

	//scale identical to original image
	SetScale/P x DimOffset(img,idir), DimDelta(img,idir),WaveUnits(img,idir) avg
	
	if (JLM_FileLoaderModule#KeySet("P",opt))
		Display avg
	endif
	
	return avgn			// or return error message
End
static Function/T KeyStr( key, str )
	string key, str
	return StringByKey( key, str, "=", "/")
end
static Function KeySet( key, str )
	string key, str
	key=LowerStr(key); str=LowerStr(str)
	variable set=stringmatch( str, "*/"+key+"*" )
	// keyword NOT set if "/K=0" used
	set=SelectNumber( JLM_FileLoaderModule#KeyVal( key, str)==0, set, 0)
	return set
end
static Function KeyVal( key, str )
	string key, str
	return NumberByKey( key, str, "=", "/")
end
	

//Proc JLM_LoaderPanelHelp()
Function JLM_LoaderPanelHelp(ctrlName) : ButtonControl
	string ctrlName
	DoWindow/F FileLoaderHelp
	if(V_flag==0)
		string txt
		NewNotebook/W=(100,100,600,400)/F=1/K=1/N=LoaderPanelInfo
		Notebook LoaderPanelInfo, fstyle=1, text="LoaderPanel Help\r"
		Notebook LoaderPanelInfo, fstyle=0, text="version 2.40,  May 2017\r\r"
		
		Notebook LoaderPanelInfo, fstyle=1, text="Updates and Bug\r"
		Notebook LoaderPanelInfo, fstyle=0, text="This is a work in progress, please conact "
		Notebook LoaderPanelInfo, fstyle=2, text="jmcchesn@aps.anl.gov" 
		Notebook LoaderPanelInfo, fstyle=0, text=" if you find any bugs or make any fixes\r\r"
				
		Notebook LoaderPanelInfo, fstyle=1, text="Path: Menu and Update Button\r"
		txt="This is used to select the folder in which your data files live. "
		txt+="Only the files which were in the directory when the path was selected are listed; you will need to press the \"Update\" button "
		txt+="in order to refresh this list.\r\r"
		txt+="Previous paths are saved and can be selected from the pull down list.\r"
		txt+="\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		
		Notebook LoaderPanelInfo, fstyle=1, text="Data Type and Filter\r"
		txt="   Data Type Menu: This menu is used to select the type of data file to be loaded.  It automatically changes the filter to reflect the common extension "
		txt+="used for that data type.\r\r"
		txt+="   Current Data Types:\r"
		txt+="          MDA  - \"*.mda\" native mda format. Requires that mda2ascii be install in your Documents/Wavemetrics/Igor Pro User XX Files/ folder (Mac and Windows versions)\r."
		txt+=" Creates a folder containing each detector and positioner as separate waves within the folder. An handle multidimensional waves. Extra PVs are loaded in the wave notes."
		txt+=" Sets the wave scaling based on first and second positioner points. If positioners are not monotonic then this is a false scaling. WARNING for 29id the Mono scans should not be"
		txt+=" plotted against the wave scaling but instead using the actual mono energy (c29idmono_ENERGY_Mono)\r"
		txt+="There are several functions for dealing with MDA files which are listed under the menu \"APS Procs\MDA Tools\"\r"
		txt+="          Igor Binary  - \"*.ibw\" loads Igor binary files\r"
		txt+="          General Text  - \"*.txt\" Uses Igor's built in General Text Loader \r"		
		txt+="          Spec  - \"*.*\" Loads Spec files, not been debugged! \r"	
		txt+="          MDAascii  - \"*.asc\" Loads files which have already been converted to ascii using mda2ascii \r"	
		txt+="          Tiff  - \"*.tif\" loads tif files and converst to Single float so that they can be used with ImageTool5\r"
		txt+="          NetCDF  - \"*.nc\" loads netCDF files and automatically scales to 29ID SES settings (angle/energy) requires NetCDFLoader in your IgorExtension folder (Mac and Windows versions)\r"
		txt+="\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		
		txt="   Filter: a string used reduce the shown file list. * is a wild card.  Any string can be used (Be*.nc would show any file begining with Be and ending"
		txt+=" with the .nc extension). Note that changing the data type will automatically change the filter to a default value.\r"
		txt+="\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		
		Notebook LoaderPanelInfo, fstyle=1, text="Selecting files to load\r"
		txt="   Multiple files can be loaded at one time.  Use the standard Command or Control key selection method for your operating system.\r"
		txt+="\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		
		Notebook LoaderPanelInfo, fstyle=1, text="Load Buttons\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		txt="   Loads the selected file(s) based on the Data Type selected. WARNING: Load All - loads all files listed reguardless of if they are selected/highlighted/r"
		txt+="\r"
		Notebook LoaderPanelInfo, fstyle=1, text="CmdLine LD  Button\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		txt="   Opens a Dialog Box to load a series of waves where you specify the first and the last file number/r"
		txt+="\r"
		Notebook LoaderPanelInfo, fstyle=1, text="LDnS  Button\r"
		Notebook LoaderPanelInfo, fstyle=0, text=txt
		txt="   Opens a Dialog Box to load   and then stack a series of waveswhere you specify the first and the last file number/r"
		txt+="\r"
		
		Notebook LoaderPanelInfo, fstyle=0, text=txt
	endif
end

