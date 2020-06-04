# IEX_Igor For Igor 6

Download IEX_Procs and move to the User Procedure Folder
Make an alias/shortcut to the JLM_HelpFile.iph and put it in the Igor Help Files folder


Notes JLM_Tools contains functions which might be defined elsewhere such as sind (which is simply the sine function in degrees). Delete or comment out the functions which igor complains about when you compile

JLM_Fileloader uses the nc_loader which is available from the Wavemetrics website and is dependent on the operating system. I'm working to update for use with Igor 8 which has a built in loader.


