#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// JLM_GraphUtilities
// $Description: Common Procedures for graphs
// $Author: JLM$
// SVN History: $Revision: 0 $ on $Date:May 11, 2017 $

Menu "APS Procs"
	Submenu "Graph Utilities"
		"Duplicate window size",  DupWinSize_Dialog()
		"----------------"	
		"Graph Series All waves in DataFolder",GraphSeriesWave_AllinFolder()
		"Graph Series by ScanNum List",GraphSeriesWave_ScanNumList()
		"Graph Series by First, Last, Countby",GraphSeriesWave_FirstLast() 
		"Graph Series by WaveList", GraphSeriesWave_List()
		
		"Graph Series Folder All SubFolders", print "GraphSeriesFolder_AllFolders(ywvname,xwvname)"
		"Graph Series Folder by ScanNumList - mda",GraphSeriesFolder_ScanNumList()
		"Graph Series Folder by First, Last, Countby - mda", GraphSeriesFolder_FirstLast()
		"Graph Series Folder by  First, Last, Countby - mda",GraphSeriesFolder_List()	
		"----------------"
		"Add DataFolder to legend",LedgendwithFolders()
		"Title = Top Image Folder",Image_FolderinTitle()
		"Set DataFolder to top image or trace",SetDataFolderTopImageTrace()
		"Make wave with all wavelist from graph",MakeGraphListWave()
		 "Legend from list",  "LegendfromList(LegendList,Title,overwrite)"
		"----------------"	
		"Average Image", ImgAvg_dialog()	
		"Integrate image", Integrate2Dli()	
		"Crop Image", Crop_xy_Dialog()
		 "Mirror Image", Mirror_Image_Dialog()
		"----------------"
		"Color all traces from wave in a given datafolder",print "ColorbyDataFolder(dfn,R,G,B)"
		
	end
End

Menu "Graph"
	submenu "IEX Graph Tools"
		"Ledgend with Folders", LedgendwithFolders()
		"Title = Top Image Folder", Image_FolderinTitle()
		 "SetDataFolder to top image or trace", SetDataFolderTopImageTrace()
		 "Legend from list", print "LegendfromList(LegendList,Title,overwrite)"
		 "ModifyGraph: Normalize Traces",NormTraces2One_Graph()
	end
end	


		
//////////////////////////////////////////////////////
//////////////  --- Modify All Traces --- ///////////////////
//////////////////////////////////////////////////////
Function NormTraces2One_Graph()
	variable bkgx1,bkgx2
	bkgx1=xcsr(A,"")
	bkgx2=xcsr(B,"")
	variable i,scale,avg
	string trace, dfn
	string TraceList=TraceNameList("", ";", 3)
	for(i=0;i<itemsinList(TraceList,";");i+=1)
		Trace=stringfromlist(i,TraceList,";")
		wave wv=TraceNameToWaveRef("", Trace )
		wavestats/q wv
		scale=1/v_max
		wavestats/q/r=(bkgx1,bkgx2) wv
		avg=v_avg
		ModifyGraph offset($trace)={0,-avg*scale}
		ModifyGraph muloffset($trace)={0,scale}
	endfor
End
Function NormTraces2One(bkgx1,bkgx2)
	variable bkgx1,bkgx2
	variable i,scale,avg
	string trace, dfn
	string TraceList=TraceNameList("", ";", 3)
	for(i=0;i<itemsinList(TraceList,";");i+=1)
		Trace=stringfromlist(i,TraceList,";")
		wave wv=TraceNameToWaveRef("", Trace )
		wavestats/q wv
		scale=1/v_max
		wavestats/q/r=(bkgx1,bkgx2) wv
		avg=v_avg
		ModifyGraph offset($trace)={0,-avg*scale}
		ModifyGraph muloffset($trace)={0,scale}
	endfor
End


Function OffsetTraces_Dialog()
	variable offset_x,offset_y
	Prompt offset_x, "x offset:"
	Prompt offset_y, "y offset:"
	DoPrompt "Make waterfall:" offset_x, offset_y
	if (v_flag==0)
		print "OffsetTraces("+num2str(offset_x)+","+num2str(offset_y)+")"
		OffsetTraces(offset_x,offset_y)
	endif
End

Function OffsetTraces(offset_x,offset_y)
	variable offset_x,offset_y
	string TraceList=TraceNameList("", ";", 3)
	variable i
	for(i=0;i<itemsinlist(TraceList,";");i+=1)
		OffsetSingleTrace(i, offset_x*i,offset_y*i)
	endfor
end
Function OffsetSingleTrace(trace_num, offset_x,offset_y)
	variable trace_num,offset_x,offset_y
	string TraceList=TraceNameList("", ";", 3)
	string Trace=stringfromlist(trace_num,TraceList,";")
	wave wv=TraceNameToWaveRef("", Trace )
	ModifyGraph offset($trace)={offset_x,offset_y}
end

Function ColorTrace_Dialog()
	string ColorList="black;red;green;blue;magenta;cyan;purple"
	variable trace_num
	string color
	Prompt trace_num, "Trace number:"
	Prompt color, "Color:", popup, ColorList
	DoPrompt "Color Trace", trace_num, color
	if (v_flag==0)
		print "ColorTrace("+num2str(trace_num)+",\""+color+"\")"
		ColorTrace(trace_num,color)
	endif
End
Function ColorTrace(trace_num,color)
	variable trace_num
	string color
	string rgb
	string Trace=stringfromlist(trace_num,TraceNameList("", ";", 3),";")
	wave wv=TraceNameToWaveRef("", Trace )
	strswitch(color)	
		case "black": 
			rgb="(0,0,0)"
			break
		case "red":
			rgb="(65535,0,0)"
			break
		case "green": 
			rgb="(2,39321,1)"
			break
		case "blue":
			rgb="(0,0,65535)"
			break
		case "magenta":
			rgb="(65535,0,52428)"
			break
		case "cyan":
			rgb="(1,52428,52428)"
			break
		case "purple":
			rgb="(36873,14755,58982)"	
			break
	endswitch
	Execute "ModifyGraph rgb("+trace+")="+rgb
End	
//////////////////////////////////////////////////////
//////////////  --- Windows Tools --- ///////////////////
//////////////////////////////////////////////////////
Function DupWinSize_Dialog()
	string source, win
	Prompt source, "Original", popup, WinList("*", ";","WIN:3")
	Prompt win, "Window to be resized", popup, WinList("*", ";","WIN:3")
	DoPrompt "Duplicate properites", source, win 
	print "DupWinSize(\""+Source+"\",\""+Win+"\")"
	DupWinSize(Source,Win)
End
Function DupWinSize(Source,Win) //Resizes Window Win to that of  Source
	string Source, Win
	Getwindow $Source wsize
	MoveWindow/W=$Win V_left, V_top, V_right, V_bottom
end



////////Graph Tools /////////////

	variable i
	For(i=0;i<itemsinlist(TraceNameList("",";",1),";");i+=1)
		string tname=stringfromlist(i,TraceNameList("",";",1),";")
		wave wv=TraceNameToWaveRef("", tname)
		string fld=GetwavesDataFolder(wv,1)
		variable val=FindListItem(dfn,fld,":",0,0)
		if (val>-1)
			ModifyGraph rgb($tname)=(r,g,b)
		endif
	endfor
end

//////////////////////////////////////////////////////
////////////////// ---Legend --- //////////////////////
//////////////////////////////////////////////////////
Function LedgendwithFolders() //Adds the datafolder to the legend
	string Title=""
	LedgendwithFoldersTitle(Title)
end

Function LedgendwithFoldersTitle(Title)
	string Title 
	Legend/C/N=text0/A=MC
	string tlist=tracenamelist("",";",1) 
	string txt="", df, wvname
	if(strlen(Title)>0)
		txt=Title+"\r"
	endif
	variable i
	For(i=0;i<itemsinlist(tlist,";");i+=1)
		df=getwavesdatafolder(tracenametowaveref("", stringfromlist(i,tlist,";")),0)
		wvname=nameofwave(tracenametowaveref("", stringfromlist(i,tlist,";")))
		txt=txt+"\\s("+stringfromlist(i,tlist,";")+") "+df+":"+wvname+"\r"
	endfor
	txt=txt[0,strlen(txt)-2]
	tlist=ImageNameList("",";")
	For(i=0;i<itemsinlist(tlist,";");i+=1)
		df=getwavesdatafolder(imagenametowaveref("", stringfromlist(i,tlist,";")),0)
		wvname=nameofwave(imagenametowaveref("", stringfromlist(i,tlist,";")))
		txt=txt+"\\s("+stringfromlist(i,tlist,";")+") "+df+":"+wvname+"\r"
	endfor
	txt=txt[0,strlen(txt)-1]
	Legend/C/N=text0/J txt
end
Function LegendfromList(LegendList,Title,overwrite) //overwrite ==0 to include tracename
	String LegendList,Title
	variable overwrite
	string tlist=tracenamelist("",";",1)
	variable i
	string txt=Title
	For(i=0;i<itemsinlist(tlist,";");i+=1)
		if (overwrite==0)
			txt=txt+"\r\\s("+stringfromlist(i,tlist,";")+") "+stringfromlist(i,tlist,";")+"   "+stringfromlist(i,LegendList,";")
		else
			txt=txt+"\r\\s("+stringfromlist(i,tlist,";")+") "+stringfromlist(i,LegendList,";")
		endif
	endfor
	Legend/C/N=text0/J txt
end

//////////////////////////////////////////////////////
//////////////// --- Graph Title --- ////////////////////
//////////////////////////////////////////////////////
Function Image_FolderinTitle() //sets the graph title to the image's wave name
	wave wv=ImageNameToWaveRef(WinName(0,1),stringfromlist(0,ImageNameList("",";"),";"))
	string fld=GetWavesDataFolder(wv, 0 )
	string gname=WinName(0,1)
	string name=WinName(0,1)+":"+fld
	DoWindow/T $WinName(0,1),name
end	

Function/S WindowTitle(WindowName) // Returns the title of a window given its name.
        String WindowName // Name of graph, table, layout, notebook or control panel.
         String RecMacro
        Variable AsPosition, TitleEnd
        String TitleString
         if (strlen(WindowName) == 0)
                WindowName=WinName(0,1)         // Name of top graph window
        endif
 
        if (wintype(WindowName) == 0)
                return ""                       // No window by that name
        endif
        RecMacro = WinRecreation(WindowName, 0)
        AsPosition = strsearch(RecMacro, " as \"", 0)
        if (AsPosition < 0)
                TitleString = WindowName        // No title, return name
        else
                AsPosition += 5                 // Found " as ", get following quote mark
                TitleEnd = strsearch(RecMacro, "\"", AsPosition)
                TitleString = RecMacro[AsPosition, TitleEnd-1]
        endif
         return TitleString
End
//////////////////////////////////////////////////////
///////// --- SetDataFolder to top image  --- //////////////
//////////////////////////////////////////////////////
Function SetDataFolderTopImageTrace()
	wave wv=ImageNameToWaveRef(WinName(0,1),stringfromlist(0,ImageNameList("",";"),";"))
	if(WaveExists(wv)==0)
		wave wv=tracenametowaveref("",stringfromlist(0,tracenamelist("",";",1),";") )
	endif
	DFREF dfr=GetWavesDataFolderDFR(wv)
	setdatafolder dfr
end	
//////////////////////////////////////////////////////
///// ---Make wave with all wavelist from graph  --- ////////
//////////////////////////////////////////////////////
Function MakeGraphListWave()
	string gtitlelist, gnamelist, gtitle, gname, df //df=datafolder of first trace
	gnamelist=winlist("*",";","WIN:1")
	gtitlelist=""
	variable i
	make/o/n=(itemsinlist(gnamelist,";"),3)/t root:graphlist
	wave/t graphlist=root:graphlist
	For(i=0;i<itemsinlist(gnamelist,";");i+=1)
		gname=stringfromlist(i,gnamelist,";")
		gtitle=windowtitle(gname)
		df=getwavesdatafolder(tracenametowaveref(gname, stringfromlist(0,tracenamelist(gname,";",1),";")),0)
		gtitlelist=addlistitem(gtitle,gtitlelist,";",i)
		wave/t graphlist=root:graphlist
		graphlist[i][0]=gtitle
		graphlist[i][1]=gname
		graphlist[i][2]=df
	endfor
end

//////////////////////////////////////////////////////
//////// --- Graph all waves in data folder --- ////////////
//////////////////////////////////////////////////////
Function GraphSeriesWave_AllinFolder()
	display
	DFREF dfr=getdatafolderDFR()
	variable i
	For(i=0;i<CountObjectsDFR(dfr,1);i+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, i)
		appendtograph wv
	endfor	
end

Function GraphSeriesFolder_AllFolders(ywvname,xwvname)
	string ywvname, xwvname
	display
	DFREF dfr=getdatafolderDFR()
	variable i
	For(i=0;i<CountObjectsDFR(dfr,4);i+=1)
		string fld=GetIndexedObjNameDFR(dfr, 4, i)
		setdatafolder $fld
		DFREF fldr=getdatafolderDFR()
		Wave/SDFR=fldr xwv=$xwvname
		Wave/SDFR=fldr ywv=$ywvname	
		appendtograph ywv vs xwv
		setdatafolder dfr
	endfor	
end

//GraphSeries_waves
Function GraphSeriesWave_ScanNumList()
	variable DoGraph
	string basename="EA_",suffix="avgy"
	string ScanNumList=""
	Prompt DoGraph,"Display Option:", popup,"New;Append"
	Prompt basename, "basename:"
	Prompt suffix, "suffix:" 
	Prompt ScanNumList, "ScanNum List (separated by ;):"
	DoPrompt "Graph Series parameters:" DoGraph, basename, suffix, ScanNumList
	if (v_flag==0)
		if (DoGraph==1)
			Display
		endif
		print "AppendSeriesWave_ScanNumList(" +basename+", "+suffix+","+ ScanNumList+")"	
		AppendSeriesWave_ScanNumList(basename, suffix, ScanNumList)
	endif
end
Function  AppendSeriesWave_ScanNumList(basename, suffix, ScanNumList)
	string basename, suffix, ScanNumList
	//Making wvList
	variable i
	string wvList=""
	for(i=0;i<itemsinlist(ScanNumList);i+=1)
		variable scanNum=str2num(stringfromlist(i,ScanNumList))
		wvList=addlistitem(WaveNamewithNum(basename,scanNum,suffix),wvList,";",inf)
	endfor
	AppendSeriesWave_List(wvList)
End

Function GraphSeriesWave_FirstLast() 
	variable DoGraph,first,last,countby
	string basename="EA_",suffix="avgy"
	Prompt DoGraph,"Display Option:", popup,"New;Append"
	Prompt basename, "basename:"
	Prompt suffix, "suffix:" 
	Prompt first, "First ScanNum:"
	Prompt last, "Last ScanNum:"
	Prompt countby, "Countby ScanNum:"
	DoPrompt "Graph Series parameters:" DoGraph, basename, suffix, first,last,countby
	if (v_flag==0)
		if (DoGraph==1)
			Display
		endif	
		print "AppendSeriesWave_FirstLast("+basename+","+ suffix+","+num2str(first)+", "+num2str(last)+","+num2str( countby)+")"
		AppendSeriesWave_FirstLast(basename, suffix, first, last, countby)
	endif
End
	
Function AppendSeriesWave_FirstLast(basename, suffix, first, last, countby)
	string basename, suffix
	variable first, last, countby
	//Making wvList
	variable scanNum
	string wvList=""
	for(scanNum=first;scanNum<=last;scanNum+=countby)			
		wvList=addlistitem(WaveNamewithNum(basename,scanNum,suffix),wvList,";",inf)
	endfor
	AppendSeriesWave_List(wvList)
	print "AppendSeriesWave_List(\""+wvList+"\")"
End


Function GraphSeriesWave_List()
	variable DoGraph
	string basename="EA_",suffix="avgy"
	string wvList=""
	Prompt DoGraph,"Display Option:", popup,"New;Append"
	Prompt wvList, "Wave List (separated by ;):"
	DoPrompt "Graph Series parameters:" DoGraph, wvList
	if (v_flag==1)
		abort	
	endif
	if (DoGraph==1)
		Display
	endif
	AppendSeriesWave_List(wvList)
	print "AppendSeriesWave_List(\""+wvList+"\")"
End

Function AppendSeriesWave_List(wvList)
	string wvList
	variable i
	for(i=0;i<itemsinlist(wvList,";");i+=1)
		wave wv=$stringfromlist(i,wvList,";")
		appendtograph wv
	endfor
End


Function GraphSeriesFolder_ScanNumList()
	variable DoGraph
	string basename="root:mda_",suffix="",  wvName_y,  wvName_x
	string ScanNumList=""
	Prompt DoGraph,"Display Option:", popup,"New;Append"
	Prompt basename, "basename:"
	Prompt suffix, "suffix:" 
	Prompt ScanNumList, "ScanNum List (separated by ;):"
	DoPrompt "Graph Series parameters:" DoGraph, basename, suffix, ScanNumList
	if (v_flag==1)
		abort	
	else
		// selecting waves to plot
		string df=FolderNamewithNum(basename,str2num(stringfromlist(0,ScanNumList,";")),suffix)
		setdatafolder $df
		Prompt wvName_y, "Wave to graph:" popup,WaveList("*",";","DIMS:1")
		Prompt wvName_x, "X-wave :" popup,"Calculated;"+ WaveList("*",";","DIMS:1")
		DoPrompt "Wave to Graph:", wvName_y, wvName_x
		if (v_flag==1)
			abort
		endif
	endif
	if (DoGraph==1)
		Display
	endif
	 print "AppendSeriesFolder_ScanNumList("+wvName_y+","+ wvName_x+","+basename+","+suffix+","+ ScanNumList+")"
	 AppendSeriesFolder_ScanNumList(wvName_y, wvName_x,basename,suffix, ScanNumList)
End
Function AppendSeriesFolder_ScanNumList(wvName_y, wvName_x,basename,suffix, ScanNumList)
	string wvName_y, wvName_x,basename,suffix, ScanNumList
	
	//Making wvList
	variable i
	string FolderList=""
	for(i=0;i<itemsinlist(ScanNumList);i+=1)
		variable scanNum=str2num(stringfromlist(i,ScanNumList))
		FolderList=addlistitem(FolderNamewithNum(basename,scannum,suffix),FolderList,";",inf)
	endfor
	AppendSeriesFolder_List(FolderList,wvname_y, wvname_x)
End

Function GraphSeriesFolder_FirstLast()
	variable DoGraph,first,last,countby
	string basename="EA_",suffix="avgy", wvName_y ,wvName_x
	Prompt DoGraph,"Display Option:", popup,"New;Append"
	Prompt basename, "basename:"
	Prompt suffix, "suffix:" 
	Prompt first, "First ScanNum:"
	Prompt last, "Last ScanNum:"
	Prompt countby, "Countby ScanNum:"
	DoPrompt "Graph Series parameters:" DoGraph, basename, suffix, first,last,countby
	if (v_flag==1)
		abort	
	else
		// selecting waves to plot
		string df=FolderNamewithNum(basename,first,suffix)
		setdatafolder $df
		Prompt wvName_y, "Wave to graph:" popup,WaveList("*",";","DIMS:1")
		Prompt wvName_x, "X-wave :" popup,"Calculated;"+ WaveList("*",";","DIMS:1")
		DoPrompt "Wave to Graph:", wvName_y, wvName_x
		if (v_flag==1)
			abort
		endif
	endif
	if (DoGraph==1)
		Display
	endif
	print "AppendSeriesFolder_FirstLast("+wvName_y+", "+wvName_x+","+basename+","+suffix+","+num2str(first)+","+num2str(last)+","+num2str(countby)+")"
	AppendSeriesFolder_FirstLast(wvName_y, wvName_x,basename,suffix,first, last, countby)
End

Function AppendSeriesFolder_FirstLast(wvName_y, wvName_x,basename,suffix,first, last, countby)
	string wvName_y, wvName_x,basename,suffix
	variable first, last, countby
	//Making wvList
	variable scanNum
	string FolderList=""
	for(scanNum=first;scanNum<=last;scanNum+=countby)
		FolderList=addlistitem(WaveNamewithNum(basename,scanNum,suffix),FolderList,";",inf)
	endfor
	AppendSeriesFolder_List(FolderList,wvname_y, wvname_x)
End


Function GraphSeriesFolder_List()
	variable DoGraph
	string wvName_y, wvName_x
	string FolderList=""
	Prompt DoGraph,"Display Option:", popup,"New;Append"
	Prompt FolderList, "Folder List (separated by ;):"
	DoPrompt "Graph Series parameters:" DoGraph, FolderList
	if (v_flag==1)
		abort	
	else
		// selecting waves to plot
		string df=stringfromlist(0,Folderlist,";")
		setdatafolder $df
		Prompt wvName_y, "Wave to graph:" popup,WaveList("*",";","DIMS:1")
		Prompt wvName_x, "X-wave :" popup,"Calculated;"+ WaveList("*",";","DIMS:1")
		DoPrompt "Wave to Graph:", wvName_y, wvName_x
		if (v_flag==1)
			abort
		endif
	endif
	if (DoGraph==1)
		Display
	endif
	AppendSeriesFolder_List(FolderList,wvname_y, wvname_x)
End

Function AppendSeriesFolder_List(FolderList,wvname_y, wvname_x)
	string FolderList,wvname_y, wvname_x
	variable i
	for(i=0;i<itemsinlist(FolderList,";");i+=1)
		string df=stringfromlist(i,FolderList,";")
		wave wv=$(df+wvname_y)
		if(cmpstr(wvname_x,"Calculated"))
			appendtograph wv
		else
			wave wv_x=$(df+wvname_x)
			appendtograph wv vs wv_x
		endif
	endfor
End


/////////////////////////////////////////////////////////////////////////
///////////////////////////Average Image///////////////////////////	
/////////////////////////////////////////////////////////////////////////

Function ImgAvg_dialog()
	string wvname,suffix="avg"
	variable axis
	prompt wvname, "Wave:", popup, "-----2D------;"+WaveList("*",";","DIMS:2")
	Prompt axis, "axis to average", popup, "x-axis;y-axis"
	Prompt suffix,"suffix"
	DoPrompt "Average Image", wvname, axis,suffix
	if(v_flag==0)
		wave wv=$wvname
		string A=selectstring(axis-1,"Y","X")
		string opt="/"+A+"/D="+GetWavesDataFolder($nameofwave(wv),2)+suffix
		print "ImgAvg("+nameofwave(wv)+",\""+opt+"\")"
		ImgAvg(wv,opt)
	endif
end


//////////////////////////////////////////////////////
//////////// --- Integrate 2D Image --- //////////////////
//////////////////////////////////////////////////////
Proc Integrate2Dli(mat,xmi,xma,ymi,yma) //from Rubin Reininger
//Converted it to a function to make faster. Took out second parameter, just a string name
	String mat
	Variable xmi,xma,ymi,yma
	Prompt mat,"2D Matrix Wave",popup,WaveList("*",";","DIMS:2")
//	Prompt mktbl,"Put waves in new table?",popup,"Yes;No"
//	Prompt mkgrf,"Display waves in new graph?",popup,"Yes;No"
	Prompt xmi,"xmi"
	Prompt xma,"xma"
	Prompt ymi,"ymi"
	Prompt yma,"yma"
	print Integrate2DliF(mat,xmi,xma,ymi,yma)
End
Function Integrate2DliF(mat,xmi,xma,ymi,yma)
	String mat
	Variable xmi,xma,ymi,yma
	wave wmat=$mat
	Silent 1;PauseUpdate
	if( WaveDims(wmat) != 2)
		Abort mat+" is not a two-dimensional wave!"
	endif
	
	// Determine full X and Y Ranges
	Variable rows=DimSize(wmat,0)
	Variable cols=DimSize(wmat,1)
	Variable xmin,ymin,dx,dy
//	print rows,cols
	xmin=DimOffset(wmat,0)
	dx=DimDelta(wmat,0)
	ymin=DimOffset(wmat,1)
	dy=DimDelta(wmat,1)
	// Lets integrate along the columns
//	String wy=base+"Y"		//Integration along the columns
//	String wx=base+"X"		//Integration along the row
//	if((abs(xmin/xmi)>5) || (abs(xmi/xmin)>5) || (abs(ymin/ymi)>5) || (abs(ymi/ymin)>5))
//		Print "Integration limits way out"
//		return-1
//	endif
	Make/O/N=(cols) wavey
	Make/O/N=(rows) wavex
	SetScale/P x xmin,dx,"", wavex
	SetScale/P x ymin,dy,"", wavey
	Variable i=0
	do
		wavey=wmat[i][p]	
		wavex[i]=area(wavey,ymi,yma)
		i+=1						
	while (i<rows)	
	variable integRe
	integRe=area(wavex,xmi,xma)			
	killwaves wavex, wavey
//	print integRe
	return integRe
End

Function Crop_xy_Dialog()
	variable first_x, last_x, first_y, last_y
	string wvname
	Prompt wvname, "Wave to crop", popup, WaveList("!*CT*", ";", "DIMS:2")+";"+WaveList("!*CT*", ";", "DIMS:3")+";"+WaveList("!*CT*", ";", "DIMS:4")
	Prompt first_x, "First x-point in cropped image"
	Prompt last_x, "Last x-point in cropped image"
	Prompt first_y, "First y-point in cropped image"
	Prompt last_y, "Last y-point in cropped image"	
	DoPrompt "Cropping xy",wvname, first_x, last_x, first_y, last_y 
	if(v_flag==0)
		print "Crop_xy("+wvname+","+num2str(first_x)+","+num2str(last_x)+","+num2str(first_y)+","+num2str(last_y)+")"
		wave wv=$wvname
		Crop_xy(wv,first_x, last_x, first_y, last_y)
	endif
End


Function Crop_xy(wv,first_x, last_x, first_y, last_y)
	variable first_x, last_x, first_y, last_y
	wave wv
	variable scale_offset
	// x-axis
	scale_offset=dimoffset(wv,0)
	DeletePoints/M=0 last_x+1, dimsize(wv,0)-(last_x+1), wv
	DeletePoints/M=0 0,first_x,wv
	SetScale/p x, scale_offset+dimdelta(wv,0)*first_x,dimdelta(wv,0), waveunits(wv,0), wv
	// y-axis
	scale_offset=dimoffset(wv,1)
	DeletePoints/M=1 last_y+1, dimsize(wv,1)-(last_y+1), wv
	DeletePoints/M=1 0,first_y,wv
	SetScale/p y, scale_offset+dimdelta(wv,1)*first_y, dimdelta(wv,1),waveunits(wv,1), wv	

end


Function Mirror_Image_Dialog()
	string wvname, axis
	Prompt wvname,"Image wave to mirror:", popup,  WaveList("!*CT*", ";", "DIMS:2")
	Prompt axis, "Mirror axis (x-axis gives vertical reflection):", popup, "x;y"
	DoPrompt "Mirror Imgae", wvname, axis
	if(v_flag==0)
		wave wv=$wvname
		print "Mirror_Image("+wvname+",\""+axis+"\")"
		Mirror_Image(wv,axis)
	endif
End

Function /wave Mirror_Image(wv,axis)
	wave wv
	string axis
	duplicate/o wv $(getwavesdatafolder(wv,2)+"_m")
	wave wv_m= $(getwavesdatafolder(wv,2)+"_m")
	if(cmpstr(axis,"x")==0)
		wv_m[][]=wv[p][dimsize(wv,1)-1-q]
		setscale/p y, dimoffset(wv,1)+dimdelta(wv,1)*dimsize(wv,1), dimdelta(wv,1), waveunits(wv,1) wv_m
	elseif(cmpstr(axis,"y")==0)
		wv_m[][]=wv[dimsize(wv,0)-1-p][q]
		setscale/p x, dimoffset(wv,0)+dimdelta(wv,0)*dimsize(wv,0), dimdelta(wv,0), waveunits(wv,0) wv_m
	endif
	return wv_m
end

Function/wave Symmetrize_Image(wv, axis)//mirrors and averages overlapping areas
	wave wv
	string axis
	
	//////work in progress
	variable Clean=WaveExists($(getwavesdatafolder(wv,2)+"_m"))//Checking to see if mirrored wave already exists...book keeping
	wave wv_m=Mirror_Image(wv,axis)
	Duplicate/o wv $(getwavesdatafolder(wv,2)+"_s")
	wave wv_s= $(getwavesdatafolder(wv,2)+"_s")
	variable n1, n2, newsize,i,j
	if(cmpstr(axis,"x")==0)
		n1=min(min(dimoffset(wv,1),(dimoffset(wv,1)+dimdelta(wv,1)*dimsize(wv,1))),min(-dimoffset(wv,1),-1*(dimoffset(wv,1)+dimdelta(wv,1)*dimsize(wv,1))))
		n2=max(max(dimoffset(wv,1),(dimoffset(wv,1)+dimdelta(wv,1)*dimsize(wv,1))),max(-dimoffset(wv,1),-(dimoffset(wv,1)+dimdelta(wv,1)*dimsize(wv,1))))
		newsize=floor((n2-n1)/dimdelta(wv,1))
		redimension/n=(-1,newsize) wv_s
		setscale/i y,n1,n2,waveunits(wv,1) wv_s	
		for(i=0;i<dimsize(wv,0);i+=1)
			//x=dimoffset(wv_s,0)+dimdelta(wv_s,0)*i
			wv_s[i][]= interp2d(wv,  dimoffset(wv,0)+dimdelta(wv,0)*p, y )+interp2d(wv_m,  dimoffset(wv_m,0)+dimdelta(wv_m,0)*p, y )
		endfor	
	elseif(cmpstr(axis,"y")==0)
		n1=min(dimoffset(wv,0),-1*(dimoffset(wv,0)+dimdelta(wv,0)*dimsize(wv,0)))
		n2=max(dimoffset(wv,0),-1*(dimoffset(wv,0)+dimdelta(wv,0)*dimsize(wv,0)))
		newsize=floor((n2-n1)/dimdelta(wv,0))
		redimension/n=(newsize,-1) wv_s
		setscale/i x,n1,n2,waveunits(wv,0) wv_s
	endif

	if( Clean==0)
		Killwaves wv_m
	endif
	return wv_s
End

