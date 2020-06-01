#pragma rtGlobals=1		// Use modern global access method.

// JLM_FolderUtilities
// $Description: Common Procedures for dealing with DataFolders
// $Author: JLM$
// SVN History: $Revision: 0 $ on $Date:May 11, 2017 $

#include "JLM_WaveUtilities" //WaveNote Utilites , ScanName Utilites

Menu "APS Procs"
	Submenu "Folder and Stacking Utilites"
		"Stack all waves in a current DataFolder", StackAllinFolder()
		"Stack waves from ScanNum wave", StackWaves_Dialog()
		"Stack waves first, last", StackWavesfromFirstLast_Dialog()
		"Move waves to DataFolder",MakeDFnMoveWaves_Dialog()
		"Move folders into DataFolder",MakeDFnMoveFolder_Dialog()
		 "Average waves first, last", AverageWaves_FirstLast_Dialog()
		"Kill DataFolders - first, last",KillDataFolder_FirstLast_Dialog()
		"Kill Waves - first, last",Killwaves_FirstLast_Dialog()
	end
end

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
Function Killwaves_FirstLast_Dialog()
	string basename, suffix
	variable first , last
	Prompt basename, "Basename:"
	Prompt suffix, "Suffix:"
	Prompt first, "first"
	Prompt last, "last"
	DoPrompt "Kills a series of waves based on the wavename = basename+num+suffix", basename, suffix, first, last
	Print "Killwaves_FirstLast("+basename+","+suffix+","+num2str(first)+","+num2str(last)+")"
	 Killwaves_FirstLast(basename, suffix,first, last)
end
Function Killwaves_FirstLast(basename, suffix,first, last)
	string basename, suffix
	variable first , last
	variable i
	for(i=first;i<=last;i+=1)
		wave wv=$WaveNamewithNum(basename,i,suffix)
		killwaves/z wv
	endfor
end

Function KillDataFolder_FirstLast_Dialog()
	string basename, suffix
	variable first , last
	Prompt basename, "Basename:"
	Prompt suffix, "Suffix:"
	Prompt first, "first"
	Prompt last, "last"
	DoPrompt "Kills a series of waves based on the wavename = basename+num+suffix", basename, suffix, first, last
	Print "KillDataFolder_FirstLast(\""+basename+"\",\""+suffix+"\","+num2str(first)+","+num2str(last)+")"
	 KillDataFolder_FirstLast(basename, suffix,first, last)
end

Function KillDataFolder_FirstLast(basename, suffix,first, last)
	string basename, suffix
	variable first , last
	variable i
	for(i=first;i<=last;i+=1)
		wave wv=$WaveNamewithNum(basename,i,suffix)
		KillDataFolder/z wv
	endfor
end

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function RedimAllinFolder(n0,n1,n2,n3) //-1 leaves dimension unchanged
	variable n0,n1,n2,n3
	variable i
	DFREF dfr=getdatafolderDFR()
	For(i=0;i<CountObjectsDFR(dfr,1);i+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, i)
		redimension/n=(n0,n1,n2,n3) wv
	endfor			
end

Function/s GetDataFolderList()
	DFREF dfr = GetDataFolderDFR()
	string folderlist=""
	variable i
	for (i=0;i<countobjectsdfr(dfr, 4);i+=1)
		string folder=GetIndexedObjNameDFR(dfr, 4, i )
		folderlist=addlistitem(folder,folderlist, ";")
	endfor
	folderlist=sortlist(folderlist,";",16)	
	return folderlist
End
/////////////////////////////////////////////////////////////////////////
/////////////////////////////Average Waves////////////////////////////////
/////////////////////////////////////////////////////////////////////////
Function AverageWaves_FirstLast_Dialog()
	string ScanNumWavePath,Basename,Suffix,StackName
	variable first, last
	Prompt basename, "Basename:"
	Prompt suffix, "Suffix"
	Prompt StackName, "Name of averaged wave"
	Prompt first, "first scan number"
	Prompt last, "last scan number"
	DoPrompt "Waves to stack have the format basename+scannumber+suffix", Basename,Suffix,first,last
	if (V_Flag)
		abort								
	endif
	print "AverageWaves_FirstLast(\""+BaseName+"\",\""+Suffix+"\","+num2str(first)+","+num2str(last)+")"
	AverageWaves_FirstLast(BaseName,Suffix,first,last)
End

Function AverageWaves_FirstLast(BaseName,Suffix,first,last)
	variable first,last
	String Basename, Suffix
	variable num=abs(last-first)+1,n
	string StackName=basename+suffix+"_"+num2str(first)+"_"+num2str(last)
	For(n=0;n<=abs(last-first);n+=1)
		variable	scannum=first+n
		wave wv=$WaveNamewithNum(basename,scannum,suffix)
		if(n==0)
			duplicate/o wv $("root:"+StackName)
			wave wv_stack=$("root:"+StackName)
		else
			wv_stack+=wv
		endif
		wv_Stack/=num
	endfor
End




/////////////////////////////////////////////////////////////////////////
/////////////////////////////Stacking Waves////////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function StackAllinFolder_Dialog()
	string dfn
	variable i 
	string dflist=""//=DataFolderDir(1)
	for (i=0;i<countobjectsdfr(root:, 4);i+=1)
		string folder=GetIndexedObjNameDFR(root:, 4, i )
		dflist=addlistitem(folder,dflist, ";")
	endfor
	dflist=sortlist(dflist,";",16)
	prompt dfn, "Select Data Folder",popup, dflist
	DoPrompt "Stack All Waves in Folder", dfn
	if(v_flag)
		abort
	endif
//	StackAllinFolder_new(dfn)
	setdatafolder $dfn
	StackAllinFolder()
End

Function StackAllinFolder_new(dfn)
	string dfn
	variable n
	DFREF dfr=$dfn
	For(n=0;n<CountObjectsDFR(dfr,1);n+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, n)
		if(n==0)
			duplicate/o wv $("root:"+GetWavesDataFolder(wv,0))
			wave wv_stack=$("root:"+GetWavesDataFolder(wv,0))
			switch(waveDims(wv))
				case 1:
					Redimension/N=(-1,CountObjectsDFR(dfr,1)) wv_stack
					break
				case 2:
					Redimension/N=(-1,-1,CountObjectsDFR(dfr,1)) wv_stack
					break
				case 3:
					Redimension/N=(-1,-1,-1,CountObjectsDFR(dfr,1)) wv_stack
					break
			endswitch
		endif
		switch(waveDims(wv))
			case 1:
				wv_stack[][n]=wv[p]
				break
			case 2:
				wv_stack[][][n]=wv[p][q]	
				break
			case 3:
				wv_stack[][][][n]=wv[p][q][r]
				break
		endswitch
	endfor	
	setdatafolder root:		
end
Function StackAllinFolder()
	variable n
	DFREF dfr=getdatafolderDFR()
	For(n=0;n<CountObjectsDFR(dfr,1);n+=1)
		wave wv=$GetIndexedObjNameDFR(dfr, 1, n)
		if(n==0)
			duplicate/o wv $("root:"+GetWavesDataFolder(wv,0))
			wave wv_stack=$("root:"+GetWavesDataFolder(wv,0))
			switch(waveDims(wv))
				case 1:
					Redimension/N=(-1,CountObjectsDFR(dfr,1)) wv_stack
					break
				case 2:
					Redimension/N=(-1,-1,CountObjectsDFR(dfr,1)) wv_stack
					break
				case 3:
					Redimension/N=(-1,-1,-1,CountObjectsDFR(dfr,1)) wv_stack
					break
			endswitch
		endif
		switch(waveDims(wv))
			case 1:
				wv_stack[][n]=wv[p]
				break
			case 2:
				wv_stack[][][n]=wv[p][q]	
				break
			case 3:
				wv_stack[][][][n]=wv[p][q][r]
				break
		endswitch
	endfor	
	setdatafolder root:
end

Function StackWaves_Dialog()
	string ScanNumWavePath,Basename,Suffix,StackName
	Prompt ScanNumWavePath, "Wave with list of scan numbers",popup, WaveList("*",";","")
	Prompt basename, "Basename:"
	Prompt suffix, "Suffix"
	Prompt StackName, "Name of new stacked wave"
	DoPrompt "Waves to stack have the format basename+scannumber+suffix", ScanNumWavePath,Basename,Suffix,StackName
	if (V_Flag)
		abort								
	endif
	wave ScanNumWave=$ScanNumWavePath
	print "StackWavesfromListWave("+ScanNumWavePath+", \""+BaseName+"\",\""+Suffix+"\",\""+ StackName+"\")"
	StackWavesfromListWave(ScanNumWave, BaseName,Suffix,StackName)
End

Function StackWavesfromListWave(ScanNumWave, BaseName,Suffix,StackName)
	Wave ScanNumWave
	String Basename, Suffix,StackName
	variable n
	For(n=0;n<dimsize(ScanNumWave,0);n+=1)
		if (ScanNumWave[n]<10)
			wave wv=$(BaseName+"00"+num2str(ScanNumWave[n])+Suffix)
		elseif (ScanNumWave[n]<100)
			wave wv=$(BaseName+"0"+num2str(ScanNumWave[n])+Suffix)
		else
			wave wv=$(BaseName+num2str(ScanNumWave[n])+Suffix)
		endif
//			print 	BaseName+num2str(ScanNumWave[n])+Suffix
		if(n==0)
			duplicate/o wv $("root:"+StackName)
			wave wv_stack=$("root:"+StackName)
			switch(waveDims(wv))
				case 1:
					Redimension/N=(-1,dimsize(ScanNumWave,0)) wv_stack
					break
				case 2:
					Redimension/N=(-1,-1,dimsize(ScanNumWave,0)) wv_stack
					break
				case 3:
					Redimension/N=(-1,-1,-1,dimsize(ScanNumWave,0)) wv_stack
					break
			endswitch
		endif
		switch(waveDims(wv))
			case 1:
				wv_stack[][n]=wv[p]
				break
			case 2:
				wv_stack[][][n]=wv[p][q]	
				break
			case 3:
				wv_stack[][][][n]=wv[p][q][r]
				break
		endswitch
	EndFor
End
Function StackWavesSubFolder_Dialog()
	string ScanNumWavePath,fldBasename,fldSuffix,Wave2stack,StackName
	Prompt ScanNumWavePath, "Wave with list of scan numbers",popup, WaveList("*",";","")
	Prompt fldbasename, "Folder Basename (including ro0t:)"
	Prompt fldsuffix, "Folder Suffix"
	Prompt Wave2stack, "Name of wave to be stacked"
	Prompt StackName, "Name of new stacked wave"
	DoPrompt "Waves to stack have the format basename+scannumber+suffix", ScanNumWavePath,fldBasename,fldSuffix,wave2stack,StackName
	if (V_Flag)
		abort								
	endif
	wave ScanNumWave=$ScanNumWavePath
	print "StackWaveSubfolder("+ScanNumWavePath+", \""+fldBaseName+"\",\""+fldSuffix+"\",\""+"\""+ wave2stack+"\",\""+StackName+"\")"
	StackWaveSubfolder(ScanNumWave, fldBaseName,fldSuffix, wave2stack,StackName)
End

Function StackWaveSubfolder(ScanNumWave, fldBaseName,fldSuffix, wave2stack,StackName)
	Wave ScanNumWave
	String fldBasename, fldSuffix,StackName,wave2stack
	variable n
	For(n=0;n<dimsize(ScanNumWave,0);n+=1)
		variable num=ScanNumWave[n]
		string numstr=Num2Str_SetLen(num,4)
//		print fldBaseName+numstr+fldSuffix+":"+wave2stack

		wave wv=$(fldBaseName+numstr+fldSuffix+":"+wave2stack)
		if(n==0)
			duplicate/O wv $StackName
			wave wv_stack=$StackName
			switch(waveDims(wv))
				case 1:
					Redimension/N=(-1,dimsize(ScanNumWave,0)) wv_stack
					break
				case 2:
					Redimension/N=(-1,-1,dimsize(ScanNumWave,0)) wv_stack
					break
				case 3:
					Redimension/N=(-1,-1,-1,dimsize(ScanNumWave,0)) wv_stack
					break
			endswitch
		endif
		switch(waveDims(wv))
			case 1:
				wv_stack[][n]=wv[p]
				break
			case 2:
				wv_stack[][][n]=wv[p][q]	
				break
			case 3:
				wv_stack[][][][n]=wv[p][q][r]
				break
		endswitch
	endfor
end
Function StackWavesfromFirstLast_Dialog()
string ScanNumWavePath,Basename,Suffix,StackName,ScaleStr
	variable first, last, countby=1
	Prompt basename, "Basename:"
	Prompt suffix, "Suffix"
	Prompt StackName, "Name of new stacked wave"
	Prompt first, "first scan number"
	Prompt last, "last scan number"
	Prompt countby, "Count by"
	Prompt ScaleStr, "Scaling wave: first; delta; units (empty string = Scan Number)"
	DoPrompt "Waves to stack have the format basename+scannumber+suffix", Basename,Suffix,StackName,ScaleStr,first,last,Countby
	if (V_Flag)
		abort								
	endif
	print "StackWavesfromFirstLastCountBy(\""+BaseName+"\",\""+Suffix+"\",\""+ StackName+"\",\""+ScaleStr+"\","+num2str(first)+","+num2str(last)+","+num2str(countby)+")"
	StackWavesfromFirstLastCountBy(BaseName,Suffix,StackName,ScaleStr,first,last,countby)
End
Function StackWavesfromFirstLastCountBy(BaseName,Suffix,StackName,ScaleStr,first,last,countby)
	variable first,last,countby
	String Basename, Suffix,StackName,ScaleStr
	variable num=(last-first)/countby+1,i
	For(i=0;i<num;i+=1)
		wave wv=$WaveNamewithNum(basename,first+i*countby,suffix)
//		print 	BaseName+num2str(ScanNum)+Suffix
		//Setup Stackwave
		if(i==0)
			duplicate/o wv $("root:"+StackName)
			wave wv_stack=$("root:"+StackName)
			switch(waveDims(wv))
				case 1:
					Redimension/N=(-1,num) wv_stack
					break
				case 2:
					Redimension/N=(-1,-1,num) wv_stack
					break
				case 3:
					Redimension/N=(-1,-1,-1,num) wv_stack
					break
			endswitch
		endif
		//Write wave into
		switch(waveDims(wv))
			case 1:
				wv_stack[][i]=wv[p]
				break
			case 2:
				wv_stack[][][i]=wv[p][q]
				break
			case 3:
				wv_stack[][][][i]=wv[p][q][r]
				break
		endswitch
	EndFor
	//Wave scaling
	if(strlen(ScaleStr)==0)
		ScaleStr=num2str(first)+";"+num2str(countby)+";ScanNum"
	endif
	variable offset= str2num(stringfromlist(0,ScaleStr,";"))
	variable delta= str2num(stringfromlist(1,ScaleStr,";"))
	string units=stringfromlist(2,ScaleStr,";")
	switch(waveDims(wv))
		case 1:
			SetScale/p y,offset, delta, units, wv_stack	
			break
		case 2:
			SetScale/p z,offset, delta, units, wv_stack
			break
		case 3:
			SetScale/p t,offset, delta, units, wv_stack	
			break
	endswitch
	note wv_stack, "Stack num: "+num2str(first)+"/"+num2str(last)+"/"+num2str(countby)+"/r"
	note wv_stack, "Stack basename: "+basename+";"+"stack suffix:"+suffix+"/r"
End
Function StackWavesfromFirstLast(BaseName,Suffix,StackName,ScaleStr,first,last)
	variable first,last
	String Basename, Suffix,StackName,ScaleStr
	StackWavesfromFirstLastCountby(BaseName,Suffix,StackName,ScaleStr,first,last,1)
end

/////////////////////////////////////////////////////////////////////////
/////////////////Moving Waves into DataFolder  //////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function MakeDFnMoveWaves_Dialog()
	variable first, last, stackfldr
	string base, suff,dfn="data"
	Prompt first, "first scan number:"
	Prompt last, "last scan number:"
	Prompt base, "base name:"
	Prompt suff, "suffix:"
	Prompt dfn, "data folder name"
	Prompt stackfldr, "Stack all in folder?", popup, "no;yes"
	DoPrompt "Wave name = BaseName+ScanNumber+Suffix", first, last, base, suff, dfn, stackfldr
	if(v_flag)
		abort
	endif
	stackfldr-=1 //makes boolean no=0;yes=1
	string txt=num2str(first)+","+num2str(last)+",\""+base+"\",\""+suff+"\",\""+dfn+"\","+num2str(stackfldr)
	MakeDFnMoveWaves(first,last, base, suff,dfn,stackfldr)
	print "MakeDFnMoveWaves("+txt+")"
End
Function MakeDFnMoveWaves(first,last, basename, suffix,dfn,stackfldr)
	variable first, last,stackfldr
	string basename, suffix,dfn
	if (datafolderexists(dfn))
	
	else 
		newdatafolder $dfn
	endif
	variable i
	For(i=first;i<=last;i+=1)
		wave wv=$WaveNamewithNum(basename,i,suffix)
		movewave wv, $(":"+dfn+":")
	endfor
	if(stackfldr==1)
		setdatafolder $dfn
		stackallinfolder()
	endif
end

	string df=getdf()
	svar dname=$(df+"dname")
	setupV(getdfname(),dname)
	
Function MakeDFnMoveFolder_Dialog()
	variable first, last, stackfldr, countby=1
	string Basename, Suffix,df="root:data"
	Prompt first, "first scan number:"
	Prompt last, "last scan number:"
	Prompt countby, "count by:"
	Prompt Basename, "base name:"
	Prompt Suffix, "suffix:"
	Prompt df, "data folder full path"
	Prompt stackfldr, "Stack all in folder?", popup, "no;yes"
	DoPrompt "Wave name = BaseName+ScanNumber+Suffix", first, last,countby Basename, Suffix, df, stackfldr
	if(v_flag)
		abort
	endif
	stackfldr-=1 //makes boolean no=0;yes=1
	string txt="\""+Basename+"\",\""+Suffix+"\",\""+df+"\","+num2str(stackfldr)+","+num2str(first)+","+num2str(last)+","+num2str(countby)
	MakeDFnMoveFolders(Basename,Suffix,df,stackfldr,first,last,countby)
	print "MakeDFnMoveFolders("+txt+")"
End


Function MakeDFnMoveFolders(Basename,Suffix,DataFolder,stackfldr,first,last,countby)
	variable first, last, countby, stackfldr
	string basename, suffix,DataFolder
	if (datafolderexists(DataFolder))
	else 
		newdatafolder $DataFolder
	endif
	variable i
	
	For(i=first;i<=last;i+=countby)
		string mda=FolderNamewithNum(basename,i,suffix)
		Execute "MoveDataFolder "+mda+","+DataFolder
	//	MoveDataFolder	mda, df
	endfor
	if(stackfldr==1)
		setdatafolder $DataFolder
		stackallinfolder()
	endif
end

