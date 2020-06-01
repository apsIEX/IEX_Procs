#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// JLM_WaveUtilities
// $Description: Common Procedures for working with wave notes and  ScanNames with a fixed number of digits
// $Author: JLM$
// SVN History: $Revision: 0 $ on $Date:May 11, 2017 $

Menu "APS Procs"
	"WaveNoteSearchDialog"
end

/////////////////////////////////////////////////////////////////////////
/////////////ScanName Utilites///////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function/s Num2Str_SetLen(num,ndigits) //Make a string of a set character length
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
Function/s WaveNamewithNum(basename,scannum,suffix)
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
Function/s FolderNamewithNum(basename,scannum,suffix)
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

/////////////////////////////////////////////////////////////////////////
/////////////Wave Note Utilities/////////////////////////////////
/////////////////////////////////////////////////////////////////////////

Function WaveNoteSearch(wv, str)
	wave wv
	string str
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+str+"*")
	print tmp
End
Function/s WaveNoteKeySearch(wv, str)
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

Function WaveNoteSearchDialog()
	string wvname, key, which
	prompt wvname,  "Wave", popup, WaveList("*",";","")
	prompt key, "Search term"
	prompt which,"Key search only return the value of that key", popup, "string search;key search"
	Doprompt "",wvname, key, which
	if (V_Flag)
		abort								
	endif
	wave wv=$wvname
	if(cmpstr(which,"string search")==0)
		WaveNoteSearch(wv, key)
		print "WaveNoteSearch("+nameofwave(wv)+",\""+key +"\")"
	elseif(cmpstr(which,"key search")==0)
		WaveNoteKeySearch(wv, key)
		print "WaveNoteKeySearch("+nameofwave(wv)+",\""+key +"\")"
	endif
	print "WaveNoteKeySearch("+nameofwave(wv)+",\""+key +"\")"
End

//netcdf: key="/r....", keysp=":", listsep=";"
Function WavenoteKeyVal(wvname,key,keysep,listsep)
	string wvname,key,keysep,listsep
	wave wv=$(wvname)
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+key+"*")
	string valstr=stringbykey(key,tmp,keysep,listsep)
	variable val=str2num(valstr)
	return val
end
Function/s WavenoteKeyStr(wvname,key,keysep,listsep)
	string wvname,key,keysep,listsep
	wave wv=$(wvname)
	string buffer=note(wv)
	string tmp=listmatch(buffer,"*"+key+"*")
	string valstr=stringbykey(key,tmp,keysep,listsep)
	return valstr
end

 Function WavenoteNotebook_Dialog()
 	string wvname
 	Prompt wvname, "Wave name:", popup, WaveList("*",";","")
 	DoPrompt "Wave note to Notebook", wvname
 	if (v_flag==1)
		abort
	endif
	print "WavenoteNotebook(\""+wvname+"\")"
	 WavenoteNotebook(wvname)
end
Function WavenoteNotebook(wvname)
	string wvname
	wave wv=$wvname
	string nbName="NoteBook_"+wvname[strsearch(wvname,":",inf,3),inf]
	string buffer=note(wv)
	DoWindow/F $nbName
	if(V_flag==0)
		NewNotebook/W=(100,100,570,400)/F=1/K=1/N=$nbName
		Notebook $nbName showruler=0, backRGB=(45000,65535,65535)
		Notebook $nbName text=""
		variable i
		string txt=""
		string tmp
		For (i=0;i<itemsinlist(buffer,";");i+=1)
				tmp=stringfromlist(i,buffer)
	//			tmp=replacestring(",", tmp,"\t")
				txt+=tmp+"\r"
		endfor
		Notebook $nbName text=txt
	endif
end

/////////////////////////////////////////////////////////////////////////