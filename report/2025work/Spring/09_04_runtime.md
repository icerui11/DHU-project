# 15.04 Buffer memory size

* [ ]  明确所有压缩核所需要的SDRAM 大小，最好是其大小边界
* [ ]  需要知道MEM-controller 能否支持并发储存多路数据到SDRAM的任务（比如3个compression core 的compressed data 以及 两个BIP-MEM需要从sdram 读取）
* [ ]  由于使用BIP-MEM 从SDRAM 需要延迟，这个大小将是多少

# 4.9 Run-time configuration

如果我使用spw RMAP 来更新设计在spacewire router中的register，用register的值配置SHyLoC compressor , 那么在FPGA设计中是否我只需要一个ahb master就足够了？但是当compressor 例如ccsds123 awaitingconfig signal 为高 时是否需要设置额外的控制逻辑使得这个ahb master开始读取register中的值？

另外我使用router status register储存这个configuration register的话，我还需要将这个status register改为ahb 接口?也就是加上ahb slave接口

实际configuration parameter update through Router port 0 from GR712, in port 0 there is a rmap_target.

* [X]  需要确定AHB master 控制信号是GR712 还是FPGA上产生

* 控制信号s

## meeting with pablo in 28.04

PGM From the ASW point of view, the easiest would be if the configuration registers where in the shared memory space, so that no protocol is involved, just writing to several memory positions, then then memory manager takes care of the rest.

RY The problem with that solution is that the settings could be changed while the core is still compressing. Our preference would be to do the configuration via SpW.

在meeting中我只是想确认processor是通过GPIO 还是SpW RMAP 配置compression core，也就是接口层面的问题（这个可以在以后灵活的修改）对于compression core configuration register当然是如Pablo所想的，只需将配置参数写入memory position就足够了。并且我想指出configuration phase 完成后 ，在one set of data（Nx* Ny* Nz） 完成compression 之间，因为compression core 使用AHB bus 进行配置，即使即使configuration value 被修改也没有问题, 因为compression core 会通过拒绝AHB write的方式拒绝新的configuration value 写入。直到compression core处于 AwaitingConfig 状态时才能开始配置。

对于新的”double buffer“ 的提议当然是可行的。所以可行的方案是当compression core 进入AwaitingConfig 状态时，AHB master 将”next configuration to be used “的 value 传输给相应的压缩核 AHB slave 配置接口进行配置。我们下一步会开始compression core runtime implemention

Dear Pablo,

In the meeting, I simply wanted to confirm whether the processor would configure the compression core through GPIO or SpW RMAP, —this is an interface-level question that we can modify flexibly in future iterations.

Regarding the compression core configuration registers, I agree with Pablo's view that writing configuration parameters to memory positions would be sufficient. However, I'd like to highlight an important feature of the compression core: even if configuration values are modified during the compressing state, this won't cause issues since the compression cores use the AHB bus for configuration.

Specifically, once the configuration phase is complete, the compression core will reject any new configuration values written（through reject the AHB write operation）until it returns to the "AwaitingConfig" state after completing the current compression(Nx \* Ny \* Nz). This built-in protection mechanism prevents configuration changes from affecting an ongoing compression operation.

Regarding the new "double buffer" proposal, this is certainly feasible. A viable approach would be that when the compression core enters the "AwaitingConfig" state, the AHB master would transfer the values from "next configuration to be used" to the corresponding compression core AHB slave configuration interface for configuration. Our next step will be to begin the compression core runtime implementation.

#### CCSDS123_ahbs

elsif hsel_v = '1' and ip_error_v = '1' then
hready_v := '0';
hresp_v := HRESP_ERROR;

elsif hresp_r = HRESP_ERROR then
hready_v := '1';
hresp_v := HRESP_ERROR;

* 一旦配置被成功接收（valid\_r = '1'），任何后续通过AHB总线的写入尝试都会被拒绝
* IP核会向AHB总线返回错误响应（HRESP\_ERROR）

## AHB parameter

* hburst      0b000     single transfer burst

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
