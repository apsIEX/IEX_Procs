#pragma rtGlobals=1		// Use modern global access method.
/// Written by J.L. McChesney  jmcchesn@aps.anl.gov
/// Developement for the IEX Beamline (Sector 29 at the APS) June 2011
// 1/16/2012 Added Tabs and search of wave notes
//10/11/2012 Added GraphTools tab and x-axis selection
// 11/19/2012 - v104 Added live update/browse feature
//2/5/2013 - v105 Added keyword grab
//11/8/2013 - v106 Added keyword separators
//11/20/2014 -v106 Fixed DataFolder nav to go update
//07/19/2017 -v110 Fixed live button, can plot waves in root:


//Uses Killallinfolder  // BL 7.0 ALS Tools:Image_Tool4031
//List boxes modeled after BL 7.0 Procs Fits Loader

//__________to do __________ fix export so that it has x-scale

Function NewSpectraViewer()
	string dfn
	dfn=SpectraViewerSetup()
	SpectraViewerPanel(dfn)
end

Function/s SpectraViewerSetup()
	setdatafolder root:
	string dfn=uniquename("SpectraViewer_",11,0)
	newdatafolder/o $dfn
	string df="root:"+dfn+":"
	//Variables
	string/g $(df+"SortString"),$(df+"Notetext"), $(df+"Wavenote") 
	variable/g $(df+"Notepos")
	svar NoteText=$(df+"NoteText"),Wavenote= $(df+"Wavenote")
	nvar NotePos=$(df+"NotePos")
	NoteText="";NotePos=1; WaveNote=""
	//Lists
	string/g $(df+"folderlist"), $(df+"wvDFlist_x"), $(df+"wvDFlist_y"),$(df+"wvGraphList"), $(df+"folderSelect"), $(df+"wvDFSelect_x"),$(df+"wvDFSelect_y"), $(df+"wvGraphSelect")
	string/g $(df+"wvSortList"), $(df+"wvSortSelect")
	svar folderlist=$(df+"folderlist"), wvDFlist_x=$(df+"wvDFlist_x"),wvDFlist_y=$(df+"wvDFlist_y"), wvGraphList=$(df+"wvGraphList"), folderSelect=$(df+"folderSelect")
	svar wvDFSelect_x=$(df+"wvDFSelect_x"),wvDFSelect_y=$(df+"wvDFSelect_y"),wvGraphSelect=$(df+"wvGraphSelect")
	svar  wvSortList=$(df+"wvSortList"), wvSortSelect=$(df+"wvSortSelect")
	folderlist=""
	wvDFlist_x=""
	wvDFlist_y=""
	wvGraphList=""
	wvSortList=""
	variable/g $(df+"wvDFnum_x"), $(df+"wvDFnum_y"), $(df+"wvGraphnum"), $(df+"wvSortnum")
	variable i
	//create folderlist
	for (i=0;i<countobjectsdfr(root:, 4);i+=1)
		string folder=GetIndexedObjNameDFR(root:, 4, i )
		folderlist=addlistitem(folder,folderlist, ";")
	endfor
	folderlist=sortlist(folderlist,";",16)
	//create wvDFlist, list of waves in datafolder
	Setdatafolder $("root:"+stringfromlist(i, folderlist))
		for(i=0;i<countobjectsdfr(root:, 4);i+=1)
		folder=GetIndexedObjNameDFR(root:, 4, i )
		Setdatafolder $("root:"+folder+":")
		wvDFlist_x=wavelist("*", ";", "")
		wvDFlist_y=wavelist("*", ";", "")
		if (itemsinlist(wvDFlist_y)!=0) //find folder with waves
			folderSelect=folder
			i=countobjectsdfr(root:, 4)
		endif
	endfor
	setdatafolder root:
	make/o/w/u $(df+"filecolors") = {{0,0,0},{0,0,0},{0,0,65535},{65535,0,0}}
	wave filecolors=$(df+"filecolors")
	matrixtranspose filecolors
	//creat listwave
	make/o/n=(5,2,2) $(df+"wvDFSelectw_x")
	make/o/n=(5,2,2) $(df+"wvDFSelectw_y")
	make/o/T/n=(5) $(df+"wvDFListw_x")
	make/o/T/n=(5) $(df+"wvDFListw_y")
	make/o/n=(5,2) $(df+"wvGraphSelectw")
	make/o/T/n=(5) $(df+"wvGraphListw")
	make/o/n=(5,2) $(df+"wvSortSelectw")
	make/o/T/n=(2,3) $(df+"wvSortListw")
	wave wvDFSelectw_x=$(df+"wvDFSelectw_x"),wvDFSelectw_y=$(df+"wvDFSelectw_y"), wvGraphSelectw=$(df+"wvGraphSelectw"), wvSortSelectw=$(df+"wvSortSelectw")
	setdimlabel 1,1,foreColors,wvDFSelectw_x
	setdimlabel 1,1,foreColors,wvDFSelectw_y
	setdimlabel 1,1,foreColors,wvGraphSelectw
	setdimlabel 1,1,foreColors,wvSortSelectw
	// live update 
	Variable/g $(df+"LiveVar")
	make/n=1 $(df+"temp_x"), $(df+"temp_y")
	//keyword 
	string/g $(df+"keyword"),$(df+"info"), $(df+"keysep")
	svar keyword=$(df+"keyword"), info=$(df+"info"), keysep=$(df+"keysep")
	keyword=""//keys give you command line infor
	info=""
	keysep="="
	//fitting	
	return dfn	
end

Function SpectraViewerPanel(dfn)
	string dfn
	string df="root:"+dfn+":"
	//MakeWindow
	Display /W=(40,40,825,550)
	DoWindow/C/T/R $dfn,dfn
	setwindow $dfn, hook(cursorhook)=SpectraViewerHook, hookevents=3, hook=$""
	ControlBar 150
	ModifyGraph cbRGB= (1,52428,52428)
	TabControl tab0  tablabel(0)="Data Folders",  tablabel(1)="Sorting", tablabel(2)="Notes", tablabel(3)="GraphTools",tablabel(4)="Fit"
	TabControl tab0 proc=SVTabProc, size={825,20}
	///////Data Folder Tab///////////////////////
	//FolderPopupMenu
	PopupMenu DFButton, pos={10,50}, title="Data Folders", size={200,20}, mode=0, proc=SVDataFolderPopupMenuAction, value=#(df+"FolderList") 
	SetVariable currentDFdisplay, pos={10,30}, title="Set Data Folder", size={190,20}, value=$(df+"FolderSelect"), proc=SVCurrentDataFolder
	//x Data Folder Wave ListBox
	ListBox listboxwvDFy,pos={10,70},size={200,75},frame=4,proc=SVwvDFListBoxActiony
	ListBox listboxwvDFy,listWave=$(df+"wvDFListw_y"),selWave=$(df+"wvDFSelectw_y")
	ListBox listboxwvDFy,colorWave=$(df+"fileColors"),row= 50,mode= 2
	ListBox listboxwvDFy,widths={70,35}
	//y Data Folder Wave ListBoxy
	TitleBox titlexlistbox, pos={220,50},fixedSize=1,size={200,20}, title="x-wave", labelBack=(65535,65535,65535)
	ListBox listboxwvDFx,pos={220,70},size={200,75},frame=4, proc=SVwvDFListBoxActionx
	ListBox listboxwvDFx,listWave=$(df+"wvDFListw_x"),selWave=$(df+"wvDFSelectw_x")
	ListBox listboxwvDFx,colorWave=$(df+"fileColors"),row= 50,mode= 2
	ListBox listboxwvDFx,widths={70,5}
	//Graph Wave ListBox
	TitleBox titlelistbox, pos={430,50},fixedSize=1,size={200,20}, title="Waves on Graph", labelBack=(65535,65535,65535)
	ListBox listboxwvGraph,pos={430,70},size={200,75},frame=4,proc=SVwvGraphListBoxAction
	ListBox listboxwvGraph,listWave=$(df+"wvGraphListw"),selWave=$(df+"wvGraphSelectw")
	ListBox listboxwvGraph,colorWave=$(df+"fileColors"),row= 50,mode= 2
	ListBox listboxwvGraph,widths={70,35}
	//Live LiveUpDate
	nvar livevar=$(df+"LiveVar")
	Checkbox LiveCheck pos={675,30}, size={70,15}, title="Live Update", proc=SVLiveCheckProc, value=0//off
	////////////Note Button
	SetVariable AddNoteText,  pos={275,30},size={210,15}, limits={-inf,inf,0}, title="Note Text",value=$(df+"Notetext")
	SetVariable AddNotePos,  pos={495,30},size={55,15}, limits={0,inf,1}, title="Pos", value=$(df+"Notepos")
	Button Add2NoteButton, pos={300,50}, size={250,20}, title="Add to note to all waves in folder", proc=SVAddNoteAllinFolder, disable=1
	Button ReplaceNoteButton, pos={300,70}, size={250,20}, title="Replace note; all waves in folder", proc=SVAddNoteAllinFolder, disable=1
	Button RemoveNoteButton, pos={300,90}, size={250,20}, title="Remove note; all waves in folder", proc=SVAddNoteAllinFolder, disable=1	
	SetVariable DisplayWaveNote pos={225,115},size={325,150}, value=$(df+"WaveNote"), disable=1
	SetVariable SetKeyword pos={580,35}, size={150,15},title="Keyword:", value=$(df+"keyword"), proc=SVKeywordInfo, disable=1	
	SetVariable SetKeySep pos={735,35}, size={15,15},title=" ", value=$(df+"keysep"), proc=SVKeywordInfo, disable=1	
	SetVariable DisplayInfo pos={580,55}, size={150,15},title="Info:", value=$(df+"info"), disable=1
	///////////// Sorting Tab
	SetVariable SearchTermdisplay,pos={280,30},limits={-inf,inf,0}, title="Search Term", size={175,20}, disable=1, value=$(df+"SortString"), proc=SVSortList
	ListBox listboxSort,  pos={10,50}, size={400,80}, frame=4, proc=SVwvSortListBoxAction, disable=1
	ListBox listboxSort,listWave=$(df+"wvSortListw"),selWave=$""//(df+"wvSortSelectw")
	ListBox listboxSort,colorWave=$(df+"fileColors"),row= 50,mode= 2
	ListBox listboxSort,widths={70,35}
	////////////////Graphing Buttons/////////////////////////////
	Button DFbackButton pos={210,27}, size={25,20}, title="<", proc=SVDataFolderNavButtons
	Button DFforwardButton pos={240,27}, size={25,20}, title=">", proc=SVDataFolderNavButtons
	Button AppendButton pos={650, 50}, size={125,20}, title="Append", proc=SVAppendButton	
	Button RemoveButton pos={650, 70}, size={125,20}, title="Remove", proc= SVRemoveButton
	Button RemoveAllButton pos={650,1}, size={125,20}, title="Clear Graph", proc=SVRemoveAllButton
	Button NormtoOneButton pos={650,105}, size={125,20}, title="Normalize to One", proc=SVNorm2one
	Button ExportGraphButton pos={650,125}, size={125,20}, title="Export Graph", proc=SVExportGraph
	///////////////Graph Tools
	Button AveWaveButton pos={10,125}, size={100,20}, title="Ave Wave", proc=SVGraphToolsButton, disable=1
	Button DiffWaveButton pos={120,125}, size={100,20}, title="Diff Wave", proc=SVGraphToolsButton, disable=1
	Button ExportCalcWaveButton pos={230,125}, size={150,20}, title="Export Calc Waves", proc=SVGraphToolsButton,disable=1
	//////////////////Fit Tab
	Button FitBkgButton pos={510,30}, size={125,20}, title="Linear Bkg Fit", proc=SVFitButtons, disable=1
	Button SubBkgButton pos={510,50}, size={125,20}, title="Subtract Bkg", proc=SVFitButtons, disable=1
	Button NormtoCursersButton pos={650,80}, size={125,20}, title="Norm to Cusors",proc=SVFitButtons, disable=1
	Button FitFermiButton pos={320,30}, size={125,20}, title="FitFermi Cusors", proc=FitFermiGraph,disable=1
end

Function SVTabProc(name, tab)
	string name
	variable tab
	//tab0  tablabel(0)="Data Folders",  tablabel(1)="Sorting", tablabel(2)="Notes", tablabel(3)="GraphTools", tablabel(4)="Fit"
	
	// Data Folders
	SetVariable currentDFdisplay
	Button DFbackButton 
	Button DFforwardButton
	PopupMenu DFButton, disable=(tab!=0) 
	Checkbox LiveCheck, disable=(tab!=0)
	
	//Waves in Folder list boxes (x and y)
	ListBox listboxwvDFy,   disable=((tab!=0)&(tab!=1)&(tab!=2)) 
	ListBox listboxwvDFx,   disable=(tab!=0) 
	TitleBox titlexlistbox, disable=(tab!=0)
	
	//Waves on Graph
	ListBox listboxwvGraph,  disable=((tab!=0) &(tab!=3))
	TitleBox titlelistbox, disable=((tab!=0) &(tab!=3))
	
	//Graphing Bottons
	Button AppendButton, disable=((tab!=0)&(tab!=1))
	Button RemoveButton,  disable=((tab!=0)&(tab!=3))
	Button RemoveAllButton,  disable=((tab!=0)&(tab!=3)&(tab!=4))
	Button NormtoOneButton, disable=(tab==2)	
	Button ExportGraphButton, disable=(tab==2)
	
	//Graphing tools
	Button AveWaveButton, disable=(tab!=3)
	Button DiffWaveButton, disable=(tab!=3)
	Button ExportCalcWaveButton, disable=(tab!=3)
	
	
	//Sorting
	ListBox listboxSort, disable=(tab!=1)
	SetVariable SearchTermdisplay, disable=(tab!=1)

	//Notes
	SetVariable AddNoteText,disable=(tab!=2)
	SetVariable AddNotePos,disable=(tab!=2)
	Button Add2NoteButton,disable=(tab!=2)
	Button ReplaceNoteButton,disable=(tab!=2)
	Button RemoveNoteButton,disable=(tab!=2)
	SetVariable DisplayWaveNote, disable=(tab!=2)
	SetVariable SetKeyword , disable=(tab!=2)
	SetVariable SetKeySep, disable=(tab!=2)
	SetVariable DisplayInfo , disable=(tab!=2)
	//Graphing Tools
	
	//Fitting
	Button FitFermiButton, disable=(tab!=4)
	Button FitBkgButton , disable=(tab!=4)
	Button SubBkgButton  , disable=(tab!=4)
	Button NormtoCursersButton, disable=(tab!=4)
end

Function SVDataFolderListGet()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar folderselect=$(df+"folderselect"), folderlist=$(df+"folderlist")
	folderlist=""
	variable i
	for (i=0;i<countobjectsdfr(root:, 4);i+=1)
		string folder=GetIndexedObjNameDFR(root:, 4, i )
		folderlist=addlistitem(folder,folderlist, ";")
	endfor
	folderlist=sortlist(folderlist,";",16)
	folderlist=addlistitem("root:",folderlist)
end

Function SVsetdatafolder()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar folderselect=$(df+"folderselect"), folderlist=$(df+"folderlist")
	svar wvDFSelect_y=$(df+"wvDFSelect_y"), wvDFList_y=$(df+"wvDFlist_y"), wvDFSelect_x=$(df+"wvDFSelect_x"), wvDFList_x=$(df+"wvDFlist_x")
	variable i=whichlistitem(folderselect, folderlist)
	//get datafolder list
	 SVDataFolderListGet()
	//Get current row number
	setdatafolder $df
	ControlInfo listboxwvDFy
	variable row_y=v_value
	ControlInfo listboxwvDFx
	variable row_x=v_value
	//Setdatafolder
	If(strsearch(folderlist,folderselect,0)<0) 
		setdatafolder root:
	else
		setdatafolder $(selectstring(cmpstr(folderselect,"root:"),"root:","root:"+folderselect+":"))
		//Make datafolder wavelists and waves
		wvDFlist_y=wavelist("*", ";", "DIMS:1") //only 1-D wave
		wvDFlist_x=wavelist("*", ";", "DIMS:1")
		wvDFlist_x=addlistitem("calc",wvDFlist_x)
		wave/t wvDFlistw_y=$(df+"wvDFlistw_y"), wvDFselectw_y=$(df+"wvDFselectw_y")
		wave/t wvDFlistw_x=$(df+"wvDFlistw_x"), wvDFselectw_x=$(df+"wvDFselectw_x")
		nvar wvDFnum_y=$(df+"wvDFnum_y"),  wvDFnum_x=$(df+"wvDFnum_x")
		wvDFnum_y=itemsinlist(wvDFlist_y)
		wvDFnum_x=itemsinlist(wvDFlist_x)
		Redimension/N=(wvDFnum_y,2) wvDFListw_y
		Redimension/N=(wvDFnum_y,2,2) wvDFSelectw_y
		Redimension/N=(wvDFnum_x,2) wvDFListw_x
		Redimension/N=(wvDFnum_x,2,2)  wvDFSelectw_x
//		wvDFSelectw[][0]=stringfromlist(p,wvDFList)
		string firstpnt=""
		For (i=0;i<dimsize(wvDFListw_y,0);i+=1)
			wave wv=$stringfromlist(i,wvDFlist_y)
			firstpnt=AddListItem(num2str(wv[0]), firstpnt, ";", INF)
		endfor
	//	wvDFSelectw[][0]=stringfromlist(p,wvDFList)
		wvDFListw_y[][0]=stringfromlist(p,wvDFList_y)
		wvDFListw_y[][1]=stringfromlist(p,firstpnt)
	//	wvDFListw_x=wvDFListw_y
		wvDFListw_x[][0]=stringfromlist(p,wvDFList_x)
		wvDFListw_x[][1]=stringfromlist(p,firstpnt)
	endif
//	wvDFselect_y=stringfromlist(0,wvDFList_y)
//	wvDFselect_x=stringfromlist(0,wvDFList_x)
	//Updating WaveNote
	svar waveNote=$(df+"waveNote")
		if(waveexists( $(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_y,"root:"+folderselect+":"+wvDFselect_y)))==0)
		abort
		endif
	wave wv= $(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_y,"root:"+folderselect+":"+wvDFselect_y))
	wavenote=note(wv)
	//update wave list action box (SVwvDFListBox)	
	wvDFSelect_y= stringfromlist(row_y,wvDFlist_y)
	wvDFSelect_x= stringfromlist(row_x,wvDFlist_x)
	//Updating Keywords
	svar keyword=$(df+"keyword")
	 SVkeywordInfo("",0,"","") //bogus controls passed into
end

Function SVDataFolderPopupMenuAction(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	 SVDataFolderListGet()
	svar folderselect=$(df+"folderselect"), folderlist=$(df+"folderlist")
	svar wvDFSelect=$(df+"wvDFSelect_y"),wvDFList=$(df+"wvDFlist_y")
	variable i
	//get datafolder list
	 SVDataFolderListGet()
	svar folderselect=$(df+"folderselect")
	folderselect=popstr
	SVsetdatafolder()
end

Function SVwvDFListBoxActiony (ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
//	PauseUpdate; Silent 1
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFlist_y=$(df+"wvDFlist_y"), wvDFSelect_y=$(df+"wvDFSelect_y")
	wave wvDFSelectw_y=$(df+"wvDFSelectw_y")
	nvar  wvDFnum_y=$(df+"wvDFnum_y")
	wvDFnum_y=row
	wvDFSelect_y= stringfromlist(row,wvDFlist_y)
	//	PopupMenu DFButton  mode=0
	svar waveNote=$(df+"waveNote"), folderselect=$(df+"folderselect")
	if((event==4))//1=mouse down
		SVsetdatafolder()
		nvar checked=$(df+"LiveVar")
		SVLiveCheckProc("LiveCheck",checked)//check if Live Update is check
	endif
	return row
end


Function SVwvDFListBoxActionx (ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
//	PauseUpdate; Silent 1
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFlist_x=$(df+"wvDFlist_x"), wvDFSelect_x=$(df+"wvDFSelect_x")
	wave wvDFSelectw_x=$(df+"wvDFSelectw_x")
	nvar  wvDFnum_x=$(df+"wvDFnum_x")
	wvDFnum_x=row
	wvDFSelect_x= stringfromlist(wvDFnum_x,wvDFlist_x)
	if((event==1)) //1=mouse down
		SVsetdatafolder()//here
		nvar checked=$(df+"LiveVar")
		SVLiveCheckProc("LiveCheck",checked)//check if Live Update is check
	endif	
	return row
end

Function SVwvGraphListBoxAction (ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
	PauseUpdate; Silent 1
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	if ((event==4)) //+(event==10))    // mouse click or arrow up/down or 10=cmd ListBox
		svar wvGraphList=$(df+"wvGraphList"),wvGraphSelect=$(df+"wvGraphSelect")
		wave wvGraphSelectw=$(df+"wvGraphSelectw")
		nvar  wvGraphnum=$(df+"wvGraphnum")
		wvGraphnum=row
		wvGraphSelect= stringfromlist(wvGraphnum,wvGraphList)
	endif
	if((event==1))//1=mouse down
		SVupdateWVgraph()
	endif
	return row
end

Function SVwvSortListBoxAction (ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
	PauseUpdate; Silent 1
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvSortlist=$(df+"wvSortlist"), wvSortSelect=$(df+"wvSortSelect")
	wave wvSortSelectw=$(df+"wvSortSelectw")
	nvar  wvSortnum=$(df+"wvSortnum")
	if ((event==4)) //+(event==10))    // mouse click or arrow up/down or 10=cmd ListBox	
		wvSortnum=row
		wvSortSelect= stringfromlist(wvSortnum,wvSortlist)
		
		//set to current folder and wave
		svar FolderSelect=$(df+"folderselect"), wvDFSelect=$(df+"wvDFSelect")
		wave/t wvSortListw=$(df+"wvSortListw")
		FolderSelect=wvSortListw[row][0]
		wvDFSelect=wvSortListw[row][1]
		Setdatafolder $("root:"+FolderSelect)
	endif
	return row
end

Function SVDataFolderNavButtons(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFSelect=$(df+"wvDFSelect_y"), folderselect=$(df+"folderselect"), folderlist=$(df+"folderlist"), wvDFList=$(df+"wvDFlist_y")
	 SVDataFolderListGet()
	variable i=whichlistitem(folderselect, folderlist)
	strswitch (ctrlname)
		case "DFforwardButton":
			if(i==itemsinlist(folderlist,";")-1)//if end of then list loop 
				i=-1
			endif
			folderselect=stringfromlist(i+1, folderlist)
		break
		case "DFbackButton":
			if(i==0)//if end of then list loop 
				i=itemsinlist(folderlist,";")
			endif
			folderselect=stringfromlist(i-1, folderlist)
		break
	endswitch
	SVsetdatafolder()
	nvar Livevar=$(df+"livevar")
	if(Livevar==1)
		SVLiveCheckProc("LiveCheck",Livevar)//check if Live Update is check
	endif
end

Function SVLiveCheckProc(ctrlName,checked) : CheckBoxControl //needs to be check
	String ctrlName
	Variable checked
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar LiveVar=$(df+"LiveVar")
	LiveVar=checked
	if (LiveVar==0)
		removefromgraph/z Live_y
		killwaves/z Live_y,Live_x
	elseif(LiveVar==1)
		svar wvDFSelect_y=$(df+"wvDFSelect_y"), wvDFSelect_x=$(df+"wvDFSelect_x")
		svar folderselect=$(df+"folderselect")
		string name=(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_y,"root:"+folderselect+":"+wvDFselect_y))
		wave  wv=$(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_y,"root:"+folderselect+":"+wvDFselect_y))
		wave  wv_x=$(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_x,"root:"+folderselect+":"+wvDFselect_x))
		duplicate/o wv $(df+"Live_y")
		wave Live_y=$(df+"Live_y")
		if (cmpstr(wvDFselect_x,"calc")==0)
			duplicate/o wv $(df+"Live_x")
			wave Live_x=$(df+"Live_x")
			Live_x=dimoffset(Live_x,0)+dimdelta(Live_x,0)*p
		else
			duplicate/o wv_x $(df+"Live_x")
			wave Live_x=$(df+"Live_x")
		endif
		variable i, numtraces=itemsinlist(tracenamelist(dfn,";",1),";")
		//Check to see if wave is already on graph
		if(numtraces==0)
			if(WaveExists(Live_x))
				Appendtograph Live_y vs Live_x
			else
				Appendtograph Live_x
			endif
		else
			for(i=0;i<numtraces;i+=1)
				wave tracewv=WaveRefIndexed(dfn,i,1)
				if(WaveRefsEqual(Live_y,tracewv)==0)
						if(WaveExists(Live_x))
							Appendtograph Live_y vs Live_x
						else
							Appendtograph Live_y
						endif
				endif
			endfor
		endif
	endif
	SVupdateWVgraph()
End



Function SVAppendButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFSelect_y=$(df+"wvDFSelect_y"), wvDFSelect_x=$(df+"wvDFSelect_x")
	svar folderselect=$(df+"folderselect")
		wave wv= $(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_y,"root:"+folderselect+":"+wvDFselect_y))
		wave wv_x= $(selectstring(cmpstr(folderselect,"root:"),"root:"+wvDFselect_x,"root:"+folderselect+":"+wvDFselect_x))
	if(WaveExists(wv_x))
		Appendtograph wv vs wv_x
	else
		Appendtograph wv
	endif
	SVupdateWVgraph()
end

Function SVRemoveButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFSelect=$(df+"wvDFSelect_y"), folderselect=$(df+"folderselect")
	svar wvGraphSelect=$(df+"wvGraphSelect"),  wvGraphList=$(df+"wvGraphList"), tnamelist=$(df+"tnamelist")
	variable row=whichlistitem(wvGraphSelect, wvGraphList)
	Removefromgraph/z   $stringfromlist(row, tnamelist)
	SVupdateWVgraph()
end

Function SVRemoveAllButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFSelect=$(df+"wvDFSelect_y"), folderselect=$(df+"folderselect")
	svar wvGraphSelect=$(df+"wvGraphSelect"),  wvGraphList=$(df+"wvGraphList"), tnamelist=$(df+"tnamelist")
	variable row
	For(row=itemsinlist(wvGraphList); row>=0;row-=1)
		row-=1
		Removefromgraph/z   $stringfromlist(row, tnamelist)
	endfor
	SVupdateWVgraph()
end

Function SVExportGraph	(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	string wvlist=tracenamelist(dfn,";",1), what,tmp, tmp_x//,info
	variable i, n
	Display
	For (i=0;i<itemsinlist(wvlist);i+=1)
		wave wv=tracenametowaveref(dfn, stringfromlist(i,wvlist))
		appendtograph wv vs xwavereffromtrace(dfn, nameofwave(wv))
		string/g info=traceinfo(dfn, stringfromlist(i, wvlist), 0) 
		n=strsearch(info, "RECREATION", 0)
		n=strsearch(info, ":",n)
		info=info[n+1,inf]
		For(n=0;n<itemsinlist(info,";"); n+=1)
			what=stringfromlist(n,info,";")
			what=replacestring("(x)",what,"("+nameofwave(wv)+")")
			execute "Modifygraph "+what
		endfor
	endfor
end

Function SVNorm2one(ctrlName):ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvGraphSelect=$(df+"wvGraphSelect")
	wave wv= $wvGraphSelect
	duplicate/o wv $(GetwavesDataFolder(wv, 1)+Nameofwave(wv)+"_norm")
	wave wnorm=$(GetwavesDataFolder(wv, 1)+Nameofwave(wv)+"_norm")
	wavestats/q  wv
	wnorm=(wv-v_min)/(v_max-v_min)
	nvar wvgraphnum=$(df+"wvgraphnum")
	string tmp=stringfromlist(wvgraphnum,tracenamelist(dfn,";",1))
	replacewave/y trace=$stringfromlist(wvgraphnum,TracenameList("",";",1)), wnorm
	SVupdateWVgraph()
end

Function SVAddNoteAllinFolder(ctrlName):ButtonControl
	string ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"	
	svar Notetext=$(df+"Notetext")
	nvar NotePos=$(df+"NotePos")
	string wvlist=wavelist("*", ";", ""), txt, tmp
	variable i
	For(i=0;i<itemsinlist(wvlist);i+=1)
		wave wv=$stringfromlist(i, wvlist)
		txt=note(wv)
		tmp=txt
		strswitch(ctrlName)
		case "Add2NoteButton":
			tmp=addlistitem(Notetext,txt,"\r",NotePos) 
		break
		case "ReplaceNoteButton":
			tmp=removelistitem(NotePos, tmp, "\r")
			tmp=addlistitem(Notetext,tmp,"\r",NotePos) 		
		break
		case "RemoveNoteButton":
			tmp=removelistitem(NotePos, txt, "\r")
		break
		endswitch
		Note/K wv, tmp
	endfor
	//Updating WaveNote
	svar waveNote=$(df+"waveNote"), folderselect=$(df+"folderselect"), wvDFselect=$(df+"wvDFselect_y")
	wave wv= $("root:"+folderselect+":"+wvDFselect)
	wavenote=note(wv)
end

Function SVupdateWVgraph()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"	
	//Make graph wavelists and waves
	svar wvGraphlist=$(df+"wvGraphList"), wvGraphSelect=$(df+"wvGraphSelect")
	nvar wvGraphnum=$(df+"wvGraphnum")
	string/g $(df+"tnamelist")
	svar tnamelist=$(df+"tnamelist")
	tnamelist=TraceNameList("", ";", 1)
	variable i
	wvGraphList=""
	For (i=0; i<itemsinlist(tnamelist);i+=1)
		string trace=stringfromlist(i, tnamelist)
		string tpath=GetWavesDataFolder(TraceNameToWaveRef("", trace),2)
		wvGraphlist=addlistitem(tpath, wvgraphlist, ";", INF)
	endfor
	wave/t wvGraphlistw=$(df+"wvGraphlistw"), wvGraphselectw=$(df+"wvGraphselectw")
	nvar wvGraphnum=$(df+"wvGraphnum")
	wvGraphnum=itemsinlist(wvGraphlist)
	Redimension/N=(wvGraphnum) wvGraphListw
	Redimension/N=(wvGraphnum,2) wvGraphSelectw
	wvGraphListw[]=stringfromlist(p,wvGraphList)
	//Select last row
	wvGraphnum=itemsinlist(wvGraphList)
	wvGraphSelect= stringfromlist(wvGraphnum-1,wvGraphList)
	listbox listboxwvGraph row=wvGraphnum-1, selRow=wvGraphnum-1
End

Function SVCurrentDataFolder(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	SVsetdatafolder()	
end

Function SVSortList (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	string dfn=winname(0,1)
	string df="root:"+dfn+":"	
	svar term=$(df+"SortString"), wvSortList=$(df+"wvSortList")
	wvSortList=""
//		make/o/t/n=(2,3) Listwv ///folder;waves;note
	wave/t wvSortListw=$(df+"wvSortListw")
	string folderlist="", wvlist="", dfr, txt,ftermlist="",wtermlist=""
	string wvname
	variable i, j
	For(i=0; i<countobjectsdfr(root:,4); i+=1) //Get Folder Names
		string folder=GetIndexedObjNameDFR(root:, 4, i )
		folderlist=addlistitem(folder,folderlist, ";", inf)
	endfor
	folderlist=sortlist(folderlist,";",16)
	For(i=9; i<itemsinlist(folderlist);i+=1) //Change Folders
		dfr=stringfromlist(i,folderlist)
		setdatafolder $("root:"+dfr)
		wvlist=wavelist("*",";","TEXT:0")
		For(j=0; j<itemsinlist(wvlist);j+=1) //Change Waves
			wave wv=$stringfromlist(j,wvlist)
			txt=note(wv)
			variable var=strsearch(txt,term,0)
			if(strsearch(txt,term,0)>=0)
				ftermlist=addlistitem(dfr,ftermlist, ";",inf)
				wtermlist=addlistitem(nameofwave(wv),wtermlist, ";",inf)
			endif
		endfor
	endfor
	setdatafolder "root:"
	if(itemsinlist(ftermlist)<1)
		redimension/n=(1,3) wvSortListw
		wvSortListw[0][0]="no match found (case sensitive)"
		wvSortListw[0][1]=""
		wvSortListw[0][2]=""
	else
		redimension/n=(itemsinlist(ftermlist),3) wvSortListw
		wvSortList=wtermlist
		For (i=0; i<itemsinlist(ftermlist);i+=1)
			wvSortListw[i][0]=stringfromlist(i,ftermlist)
			wvSortListw[i][1]=stringfromlist(i,wtermlist)
			wvSortListw[i][2]=term
		endfor
	endif
	wvSortList=wvlist
end
End

function SVkeywordInfo(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar keyword=$(df+"keyword"), info=$(df+"info"), keysep=$(df+"keysep")
	info=Keywordinfo(keyword, keysep)
end

function/s KeywordInfo(keyword, keysep) 
	string keyword, keysep
	string df=getdatafolder(1)
	string dfn=getdatafolder(0)
	string wvname=getindexedobjname(df,1, 0)
	wave wv=$wvname
	string nt=note(wv), info
	if(cmpstr(keyword, "keys")==0)
		info="see command line"
		print nt
	else
		 info=stringbykey(keyword,nt,keysep,";")		 
	endif
	return info	
end

Function SVWaveNoteButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvGraphSelect=$(df+"wvGraphSelect")
	wave wv=$wvGraphSelect
	string nt=note(wv)
	print nt
End
Function SVTableButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar wvDFSelect=$(df+"wvDFSelect_y"), folderselect=$(df+"folderselect")
	print "Edit/k=0 root:"+folderselect+":"+wvDFselect
	SVupdateWVgraph()
end
	
Function SVGraphToolsButton(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	variable i=0
	string tracelist=tracenamelist("", ";",1)
	wave trace=tracenametowaveref("",stringfromlist(i,tracelist))
	wave trace_x=xwavereffromtrace("", stringfromlist(i,tracelist))
	strswitch(ctrlname)
		case "AveWaveButton":
			duplicate/o trace $(df+"avg")
			duplicate/o trace_x $(df+"avg_x")
			wave avg=$(df+"avg"), avg_x=$(df+"avg_x")
			For (i=0;i<itemsinlist(tracelist);i+=1)
				wave trace=tracenametowaveref("",stringfromlist(i,tracelist))
				avg+=trace
			endfor
			avg/=(itemsinlist(tracelist))
			appendtograph avg vs avg_x
			break
		case "DiffWaveButton":
			duplicate/o trace $(df+"diff")
			duplicate/o trace_x $(df+"diff_x")
			wave diff=$(df+"diff"), diff_x=$(df+"diff_x")
			string Firstwave, Secondwave
			if(itemsinlist(tracelist)>2)
				prompt Firstwave, "First wave", popup, tracenamelist("", ";",1)
				prompt Secondwave, "Second wave", popup, tracenamelist("", ";",1)
				DoPrompt "Select waves" Firstwave,Secondwave
			elseif(itemsinlist(tracelist)==2)
				Firstwave=stringfromlist(0,tracelist)
				Secondwave=stringfromlist(1,tracelist)
			endif
			wave wv1=tracenametowaveref("",Firstwave)
			wave wv2=tracenametowaveref("",Secondwave)
			diff=wv2-wv1
			appendtograph diff vs diff_x
			break
		case "ExportCalcWaveButton":
			string EXdiff, EXavg_x, EXavg, EXdiff_x
			EXavg="root:avg"
			EXavg_x=""
			EXdiff=""
			EXdiff_x=""				
			prompt EXavg, "avg"
			prompt EXavg_x, "avg_x"
			prompt EXdiff, "diff"
			prompt EXdiff_x, "diff_x"
			Doprompt  "Full path for waves, set to \"\" for no export", EXavg,EXavg_x, EXdiff, EXdiff_x
			if(strlen(EXavg)>0)
				duplicate/o $(df+"avg") $EXavg
				print "exported ", EXavg
				if(strlen(EXavg_x)>0)
					duplicate/o $(df+"avg_x") $EXavg_x
				endif
			endif
			if(strlen(EXdiff)>0)
				duplicate/o $(df+"diff") $EXdiff
				print "exported ", EXdiff
				if(strlen(EXdiff_x)>0)
					duplicate/o $(df+"diff_x") $EXdiff_x
				endif
				
			endif
			break
	endswitch
	SVupdateWVgraph()
end	
	
Function SVFitButtons(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	strswitch(ctrlname)
		variable cA, cB
		cA=numberbykey("POINT",csrinfo(A))
		cB=numberbykey("POINT",csrinfo(A))
		wave wv=tracenametowaveref("",stringbykey("TNAME",csrinfo(A)))
		wave wv_x=xwavereffromtrace("",stringbykey("TNAME",csrinfo(A)))
		setdatafolder getwavesdatafolder (wv,1) 
		case "FitBkgButton":
			wave wv=tracenametowaveref("",stringbykey("TNAME",csrinfo(A)))
			wave wv_x=xwavereffromtrace("",stringbykey("TNAME",csrinfo(A)))
			CurveFit/NTHR=0/TBOX=768 line  wv[pcsr(A),pcsr(B)] /X=wv_x /D 
		break 
		case "SubBkgButton":
			wave wv=tracenametowaveref("",stringbykey("TNAME",csrinfo(A)))
			wave wv_x=xwavereffromtrace("",stringbykey("TNAME",csrinfo(A)))
			duplicate/o wv $(df+"fitwv")
			wave fitwv=$(df+"fitwv")
			wave w_coef
			fitwv=w_coef[1]*wv_x+w_coef[0]
			duplicate/o wv $(stringbykey("TNAME",csrinfo(A))+"_s")
			wave wv_s=$(stringbykey("TNAME",csrinfo(A))+"_s")
			wv_s=wv-fitwv
		break
			case "NormtoCursersButton":
			wave wv=tracenametowaveref("",stringbykey("TNAME",csrinfo(A)))
			wave wv_x=xwavereffromtrace("",stringbykey("TNAME",csrinfo(A)))
			variable cmax, cmin
			cA=wv[numberbykey("POINT",csrinfo(A))]
			cB=wv[numberbykey("POINT",csrinfo(B))]
			duplicate/o wv $(stringbykey("TNAME",csrinfo(A))+"_nc")
			wave wnorm=$(stringbykey("TNAME",csrinfo(A))+"_nc")
			cmax=selectnumber(cA>cB, cB,cA)
			cmin=selectnumber(cA<cB, cB,cA)
		//	print cmax, cmin
			wnorm=(wv-cmin)/(cmax-cmin)
			if(findlistitem(nameofwave(wnorm), tracenamelist("",";",1), ";")==-1)
				appendtograph wnorm vs xwavereffromtrace(dfn, nameofwave(wv))
			endif
			SVupdateWVgraph()
		break
	endswitch
end	
	
Function SpectraViewerHook(H_Struct)
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
	//add hook for live
	
	
end

