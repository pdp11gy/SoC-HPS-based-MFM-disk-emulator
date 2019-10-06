# SoC-HPS-based-MFM-disk-emulator
 MFM disk emulator ( ST506, ST412, ST225 )  based on DE10-Nano  board
                                                                                 
                                                                                 
This is a new follow-up project from the RL01 / RL02 disk emulator, also based on SoC/HPS             
environment with the DE10-Nano board: https://github.com/pdp11gy/SoC-HPS-based-RL-disk-emulator .                        
It is also based on the DE10-Nano with another I/O interface. Details on my homepage, www.pdp11gy.com                                                                                      
**All sources with environment setup  are located in the zip-folder MFM-disk_Emulator_SoC_v1_0.zip**                           
The project provides real time decoding and encoding. As with the RL01/RL02 emulator project, it is                  
intended to save the data in an .dsk file to be also compatible with the SIMH project.                                                                                  
Currently, it is possible to read a complete disk, one cylinder or one treck. The real time decoder                 
is also able to provide MFM gap recording. This is necessary in emulator mode because the former disk                           
manufacturers did always use a different one servo/header format ( At low level format ).                                  
The emulater saves the data in a .mfm file which contains the decoded data with all servo/header                       
information. The raw data will be saved in a .dsk format to be also SIMH-compatible. Additionally,                       
the MFM-gaps are stored in a .gap file for the emulator mode. More details on my homepage + user manual.                               
At the moment I don't have the possibility for further analyze this problem in the DEC environment              
because I do not have the necessary vintage hardware and also not the necessary environment around.           
Unfortunately, I also do not have an up and running  MFM-disk based PC at the moment.                                                                                                                                                                                                                                   
Furthermore, it is planned to bring both interfaces together like in the overview.pdf dokument.                                                                                                        
A detailed description with hints and explanations, open points+solutions is in the document MFM_debug.pdf

 
