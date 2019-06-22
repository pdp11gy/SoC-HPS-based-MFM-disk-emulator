# SoC-HPS-based-MFM-disk-emulator
 MFM disk emulator ( ST506, ST412, ST225 )  based on DE10-Nano  board
                                                                                 
                                                                                 
This is a new follow-up project from the RL01 / RL02 disk emulator, also based on SoC/HPS             
environment with the DE10-Nano board: https://github.com/pdp11gy/SoC-HPS-based-RL-disk-emulator .          
It is based on the DE10-Nano with a different I/O interface. Details on my homepage, www.pdp11gy.com    
After extracting the file MFM-disk_Emulator_SoC.zip, you will find all sources. It's also based on
Quartus Version 16.1.                                                        
**Please note , this project is in the beta state**                                                                                     
The project is different because it can do real time decoding and encoding "on the fly". As with the       
RL01/RL02 emulator, it is intended to save the data in an .img file to be also compatible with the            
SIMH project.  There are still some open points which are briefly described in the sources of the MFM                
decoders MFM_gap_DECODER_V1_0.v and CL_my_MFM_DEcoder_V1_0.v. At the moment I don't have the possibility for        
further analyze this problem in the DEC environment because I do not have the necessary vintage hardware      
and also not the necessary environment around. Maybe there will be cooperation. Any hint is welcome.                             
An exact problem description is in the file MFM_debug.pdf

 
