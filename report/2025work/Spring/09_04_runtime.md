# 4.9 Run-time configuration

如果我使用spw RMAP 来更新设计在spacewire router中的register，用register的值配置SHyLoC compressor , 那么在FPGA设计中是否我只需要一个ahb master就足够了？但是当compressor 例如ccsds123 awaitingconfig signal 为高 时是否需要设置额外的控制逻辑使得这个ahb master开始读取register中的值？

另外我使用router status register储存这个configuration register的话，我还需要将这个status register改为ahb 接口?也就是加上ahb slave接口

实际configuration parameter update through Router port 0 from GR712, in port 0 there is a rmap_target.


## router_ahb_reg

因为router\_config\_memory.vhd implements a configuration memory that can be both read from and written to

while router_status_reg implements a status register that is read-only from the AXI interface.

so it's reasonable to use router_config_memory instead of status reg

```


type r_maxi_lite_dword is record
	taddr	: t_dword;
	wdata 	: t_byte;
	w_en	: std_logic;
	tvalid	: std_logic;
end record r_maxi_lite_dword;

type r_saxi_lite_dword is record
	rdata	: t_byte;
	tready	: std_logic;
end record r_saxi_lite_dword; ```

router_port_0_controller 将output r_maxi_lite_dword 传输数据给 router_config_memory

当axi_in.taddr(23 downto 16) = g_axi_addr , 也就是06 时 
			if(axi_in.tvalid = '1' and axi_in.taddr(23 downto 16) = g_axi_addr) then				-- handshake request and valid address for this module ?
					is_valid 		<= '1';															-- valid high ? (used for register preload)
					wr_en 			<= axi_in.w_en;						    						-- load write status 
				end if;
```

## router_port_0_controller_v2

原router_port_0_controller Modul Address is from 0x00 to 0x05

add router_ahb_reg address 0x06             address Space size 32x6

-----from compression core AHB offset 0x00-0x14
