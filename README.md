# IEX_Proc For Igor 6,7,8,9 compatible
file loading of data (mda and EA) from 29id of the APS plus additional utilities for stacking waves, reading metadata

## Install IEX_Pros:
1) Download/clone IEX_Procs and move the entire folder to the the Igor 'User Procedure' folder

2) Make an alias/shortcut to the JLM_HelpFile.iph and put it in the Igor Help Files folder if you want the help file to be automatically loaded, otherwise you can open the file within the experiment.

3) Make an alias/shortcut to the IEX_Menus.ipf and put it in the Igor Procedure folder if you want the help file to be automatically loaded, otherwise you can open the file within the experiment.

4) Follow the instructions for installing the igor hdf5 loader (https://www.wavemetrics.com/products/igorpro/dataaccess/hdf5)

5) If you need to load old data which was saved in the netCDF (.nc) format 
    - Igor 6 and 7 (32 bit only)
          you will also need to move nc_load.xop in the Igor Extensions folder. This comes from Katsuhisa Kitano on the igor exchange (https://www.wavemetrics.com/users/tools) 
    - Igor 8 and 9 (64 bit)
          NetCDF64.xop
          
----------------------------------------------------------------------

# Known Possible Issues:

  - mda files will not load => Make sure you have the appropriate version of mda2ascii (https://epics.anl.gov/bcda/mdautils/). Alternatively, you can load the already converted ascii version.
  
  - Mac complains that mda2ascii is from an unknown developer => (Open the System Preferences Security & Privacy panel and click the General tab. You should see a message that says "mda2ascii was blocked" and an Open Anyway button should appear near it. Click the Open Anyway. After restarting Igor it should work.

  
  - JLM_Tools contains functions which might be defined elsewhere such as sind (which is simply the sine function in degrees). Delete or comment out the functions which igor complains about when you compile or remove the #include JLM_Tools in  IEX_Menus.ipf

  - if you are having problems with .xop read (https://www.wavemetrics.com/forum/general/workaround-catalina-xop-problem) 

  - if the cropping looks weird the crop window will change slightly with each mcp/detector, can be adjusted in the cropping funcion in the loader.

  - scaling ang/energy is swapped (nc and h5 reference the images differently, check or uncheck the E vs K box respectively)
