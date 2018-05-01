#pragma rtGlobals=3		// Use modern global access method and strict wave access.
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#include "Image_Tool5"

/////////////////----------Change the defaults ----------////////////////
///	In... function newImageTool5(w)...  after setupV(dfn,w) add the following
///	JMdefaults(dfn)



/////////////////----------JM additions----------////////////////
Function JMdefaults(dfn) //Added to newImageToolV()
	string dfn
	string df="root:"+dfn+":"
//Sets default Color Table	
	nvar whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"), whichCTv=$(df+"whichCTv"), whichCTzt=$(df+"whichCTzt")
	whichCT=41 //Set the default color table 0=grayscale, 41=rainbowlight
	whichCTh=whichCT
	whichCTv=whichCT
	whichCTzt=whichCT
	Button Img_CTButton title="Img_CT",pos={5,40},fSize=9,proc=Img_JMButtons
	Button Reload_Button title="Reload", pos={5,60},fSize=9,proc=Img_JMButtons
	Button Nplus_Button title="+", pos={45,1},fColor=(1,39321,39321),size={15,18},fSize=7,proc=Img_JMButtons
	Button Nminus_Button title="-", pos={30,1},fColor=(1,39321,39321),size={15,18},fSize=7,proc=Img_JMButtons
End

Function Img_JMButtons (ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,1)
	string df= "root:"+dfn+":"
	svar dname=$(df+"dname")
	strswitch(ctrlName)
		case "Img_CTButton":
			ExportCTandGraphImg()
		break
		case "Reload_Button":
			setupV(dfn,dname)
			SetAxis/A
		break
		case "Nplus_Button":
			dname=Img_NextWave(1)
			setupV(dfn,dname)
			SetAxis/A; SetImgToolCursor_midpoints(dfn)
		break
		case "Nminus_Button":
			dname=Img_NextWave(-1)
			setupV(dfn,dname)
			SetAxis/A; SetImgToolCursor_midpoints(dfn)
	endswitch
End
Function/s Img_NextWave(n)
	variable n
	string ImgTooldf=winname(0,1)
	svar dname=$("root:"+ImgTooldf+":dname")
	wave wv= $dname
	string wvname=NameOfWave(wv )
	DFREF saveDFR = GetDataFolderDFR()
	setdatafolder GetWavesDataFolderDFR(wv )
	string wvlist=WaveList("!*_CT",";","DIMS:2,TEXT:0")
	wvlist+=WaveList("!*_CT",";","DIMS:3,TEXT:0")
	wvlist+=WaveList("!*_CT",";","DIMS:4,TEXT:0")
	wvlist=sortlist(wvlist,";",16)
	variable i=whichlistitem(wvname,wvlist,";")
	string wvnext=stringfromlist(i+n,wvlist,";")
	wave wvn=$wvnext
	wvnext=GetWavesDataFolder(wvn, 2 )
	SetDataFolder saveDFR
	return wvnext
end
Function SetImgToolCursor_midpoints(dfn)
	string dfn
	string df= "root:"+dfn+":"
	string plist="xp;yp;zp;tp"
	string ctrlist="SetXP;SetYP;SetZP;SetTP"
	variable i
	svar dname=$(df+"dname")
	wave wv=$dname
	STRUCT WMSetVariableAction sva
	sva.eventCode=3
	sva.win=dfn
	for (i=0;i<wavedims(wv);i+=1)
		variable size
		sva.vname=stringfromlist(i,plist)
		sva.dval=dimsize(wv,i)/2
		sva.ctrlName=stringfromlist(i,ctrlist)
		SetPCursor(sva)
	endfor
end

Function ExportCTandGraphImg() //exerpt from ImageTool5
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	struct imageWaveNameStruct s
	variable mv0,mv1,mh0,mh1
	variable gv0,gv1,gh0,gh1
	string notestr=""
	getaxis/q left; gV0=min(v_min,v_max); gV1=max(v_min,v_max)
	getaxis/q bottom; gH0=min(v_min,v_max); gH1=max(v_min,v_max)
	SVAR dname = $(df+"dname")
	wave Swv = $dname
	string s_note = note(swv)
	duplicate/o $(df+"ct") $(dname+"_ct")
			nvar  whichCT=$(df+"whichCT")
			nvar gamma=$(df+"gamma")
			nvar invertCT=$(df+"invertCT")
			string colorlist = colornameslist()
			string ctnam = StringFromList(whichCT, colorlist)
			notestr ="CT:name="+CTnam+",gamma="+num2str(gamma)+",invert="+num2str(invertCT)+"\r"
			WAVE CTw=$(dname+"_ct")
			Note/K CTw			//kill previous note 		
   		Note CTw,  notestr
		display; appendimage $dname
		ModifyImage  $(nameofwave($dname)) cindex= $(dname+"_ct")
		string wn=winname(0,1)
		SetAxis /W=$wn left, gV0,gV1
		SetAxis /W=$wn bottom,gH0,gH1 
End
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////