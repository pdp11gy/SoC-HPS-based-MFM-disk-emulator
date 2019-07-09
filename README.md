# SoC-HPS-based-MFM-disk-emulator
 MFM disk emulator ( ST506, ST412, ST225 )  based on DE10-Nano  board
                                                                                 
                                                                                 
This is a new follow-up project from the RL01 / RL02 disk emulator, also based on SoC/HPS             
environment with the DE10-Nano board: https://github.com/pdp11gy/SoC-HPS-based-RL-disk-emulator .          
It is based on the DE10-Nano with a different I/O interface. Details on my homepage, www.pdp11gy.com    
After extracting the file MFM-disk_Emulator_SoC.zip, you will find all sources. It's also based on
Quartus Version 16.1.                                                        
**Please note , this project is in the beta state**                                                                                     
The project provides real time decoding and encoding. As with theRL01/RL02 emulator, it is intended to                
save the data in an .dsk file to be also compatible with the SIMH project.                                                       
There are still some open points which are briefly described in the sources of the MFM decoder                               
MFM_gap_DECODER_V1_0.v and CL_my_MFM_DEcoder_V1_0.v. Currently, it is possible to read a complete                      
disk(RD51) based on a PDP11-23, RQDX-1 environment and save it in SIMH-compatible .dsk format.         
At the moment I don't have the possibility for further analyze this problem in the DEC environment              
because I do not have the necessary vintage hardware and also not the necessary environment around.           
Unfortunately, I also do not have a MFM-based PC at the moment.                                                          
Maybe there will be cooperation. Any hint is welcome.                                                                                                                                                                         
Furthermore, it is planned to bring both interfaces together like in the overview.pdf dokument.                                                                                                        
A detailed description with hints and explanations, open points+solutions is in the document MFM_debug.pdf

 
