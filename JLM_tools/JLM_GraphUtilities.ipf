#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// JLM_GraphUtilities
// $Description: Common Procedures for graphs
// $Author: JLM$
// SVN History: $Revision: 0 $ on $Date:May 11, 2017 $

Menu "APS Procs"
	Submenu "Graph Utilities"
		"Duplicate window size",  DupWinSize_Dialog()
		"----------------"
		"Graph all waves in DataFolder",GraphAllWavesinFolder()
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
		
	end
End

Menu "Graph"
	submenu "IEX Graph Tools"
		"Ledgend with Folders", LedgendwithFolders()
		"Title = Top Image Folder", Image_FolderinTitle()
		 "SetDataFolder to top image or trace", SetDataFolderTopImageTrace()
		 "Legend from list", print "LegendfromList(LegendList,Title,overwrite)"
		 
	end
end			
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
//////////////////////////////////////////////////////
///////////////// ---Graph Tools --- ///////////////////
//////////////////////////////////////////////////////
Function CopyWaveColors(Graph_Source,Graph_Copy)
	string Graph_Source,Graph_Copy
	DoWindow/F $Graph_Source
	String Tlist_Source, Tlist_Copy
	String ColorList_Source, ColorList_Copy
End

//////////////////////////////////////////////////////
////////////////// ---Legend --- //////////////////////
//////////////////////////////////////////////////////
Function LedgendwithFolders() //Adds the datafolder to the legend
	Legend/C/N=text0/A=MC
	string tlist=tracenamelist("",";",1)
	string txt="", t
	string df, wvname
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
		graphlist[i][0]=gtitle
		graphlist[i][1]=gname
		graphlist[i][2]=df
	endfor
end

//////////////////////////////////////////////////////
//////// --- Graph all waves in data folder --- ////////////
//////////////////////////////////////////////////////
Function GraphAllWavesinFolder()
	display
	DFREF dfr=getdatafolderDFR()
	variable i
	For(i=0;i<CountObjectsDFR(dfr,1);i+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, i)
		appendtograph wv
	endfor	
	LedgendwithFolders()
	movewindow 585,150,1085,550
	ModifyGraph margin(right)=180
end
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
//////////////////////////////////////////////////////
/////////////// --- Crop an  Image --- //////////////////
//////////////////////////////////////////////////////
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