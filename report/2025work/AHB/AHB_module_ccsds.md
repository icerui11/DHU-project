# module function


## ahbtbm_ctrl_bi

AHB master controller specifically designed for BIP and BIL 

It's responsible for:

1. Address generationaddress_write_cmb <= address_write + x"00000004";
   address_read_cmb <= address_read + x"00000004";
2. Burst transfer management
3. Transfer type selection : 决定使用nonseq or seq

   htrans_cmb <= "10"; -- NONSEQ
   htrans_cmb <= "11"; -- SEQ
4. data flow management

this controller uses a Finite State Machine(FSM) to manage the data transfer process.


## ccsds123_ahb_mst

This module implements the core functionality of the AHB master, receiving signals from the controller and driving the AHB bus
