# IEX_Igor For Igor 6


1) Download IEX_Procs and move the entire folder to the User Procedure Folder


2) Make an alias/shortcut to the JLM_HelpFile.iph and put it in the Igor Help Files folder (if you want the help file to be automatically loaded)

3) Make an alias/shortcut to the IEX_Menus.ipf and put it in the Igor Procedure folder (if you want the IEX prodedures to be automatically loaded)

----------------------------------------------------------------------

Notes JLM_Tools contains functions which might be defined elsewhere such as sind (which is simply the sine function in degrees). Delete or comment out the functions which igor complains about when you compile


JLM_Fileloader uses the nc_loader which is available from the Wavemetrics website and is dependent on the operating system. I'm working to update for use with Igor 8 which has a built in loader.


