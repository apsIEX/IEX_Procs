#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// JLM_MathConversions
// $Description: Common math shortcuts and conversions
// $Author: JLM$
// SVN History: $Revision: 0 $ on $Date:May 11, 2017 $	

Menu "APS Procs"
	Submenu "Math & Conversions"	
		"asind" ,print "print asind(x)"
		"acosd" ,print "print acosd(x)"
		"atand" ,print "print atand(x)"
		"sind" ,print "print sind(x)"
		"cosd" ,print "print cosd(x)"
		"tand" ,print "print tand(x)"		
		"------------------"
		"mrad2deg", print "print mrad2deg(x)"
		"deg2mrad", print "print deg2mrad(x)"
		"mrad2arcsec",print "print mrad2arcsec(x)"
		"arcsec2mrad" ,print "print arcsec2mrad(x) "
		"eV2nm" ,print "print eV2nm(x)"
		"nm2eV" ,print "print nm2eV(x)"
		"k_e, momentum of an electron" ,print "k_e(E)"
		"q_hv, momentum of a photon",print "q_hv(hv)"
		"------------------"			
		"FWHM Lorentzian", print "FWHM_LW(x)"
		"FWHM Gaussian", print "FWHM_GW(w_coef)"
	End
end

///////////////// Angles
Function mrad2deg(x)
	variable x
	return x*1e-3*180/pi
end

Function deg2mrad(x)
	variable x
	return  x*pi/180*1e3

end

Function mrad2arcsec(x)
	variable x
	return x*1e-3*180/pi*3600
end

Function arcsec2mrad(x)
	variable x
	return  x/3600*pi/180*1e3
end

////////////////// Trig Functions
Function asind(x)
	variable x
	return asin(x)*180/pi
end

Function acosd(x)
	variable x
	return acos(x)*180/pi
end

Function atand(x)
	variable x
	return atan(x)*180/pi
end

Function sind(x)
	variable x
	return sin(x*pi/180)
end

Function cosd(x)
	variable x
	return cos(x*pi/180)
end

Function tand(x)
	variable x
	return tan(x*pi/180)
end

////////////////// Conversions Functions
Function ev2nm(x)
	variable x
	variable hc=1239.84193
	return hc/x
end

Function nm2eV(x)
	variable x
	variable hc=1239.84193
	return hc/x
end
///////////////////////
Function FWHM_LW(w)//igor lorentzian width to FWHM
	variable w
	variable FWHM=2*sqrt(w)
	return FWHM
end
Function FWHM_GW(w_coeff)//igor gaussian width to FWHM
	variable w_coeff
	variable sigma=w_coeff/sqrt(2) //Igor is stupid read def of gaussian
	variable FWHM=2*sqrt(2*ln(2))*sigma //sigma to fwhm conversion
	print FWHM
	return FWHM
end

Function cubicroots(a2,a1,a0) //cubic roots x^3+a2*x^2+a1*x+a0=0
	variable a2,a1, a0
	variable/C Q,R,S,T,D, x1,x2,x3
	Q=(3*a1-a2^2)/9
	R=(9*a2*a1-27*a0-2*(a2)^3)/54
	D= Q^3+R^2
	S=(R+sqrt(D))^(1/3)
	T=(R-sqrt(D))^(1/3)
	x1= S+T-a2/3
	x2=-(S+T)/2-a2/3+sqrt(3)/2*(S-T)*sqrt(-1)
	x3=-(S+T)/2-a2/3-sqrt(3)/2*(S-T)*sqrt(-1)
	print "x1=",x1	
	print "x2=",x2	
	print "x3=",x3
end


//////////////////Momentum-space
Function k_e(eV) //momentum of an electron
	variable eV //E=hv+W in eV
	return 0.5124*sqrt(E)
end

Function q_hv(hv)//momentum of a photon
	variable hv
	variable lA=eV2nm(hv)*10//wavelength in angstroms
	return 2*pi/lA
end
