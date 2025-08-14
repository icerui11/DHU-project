# 11.12

initializing additional signals during reset can have several impacts

Advantage

* deterministic Behaviour, ensures known state after reset, more predictable system behavio

disadvantage

* each initialized register requires additional reset logic, increase routing complexity
* increased fanout on reset signal

~~~~Internal
Internal power-on Reset and post programming Reset circuit for Flash-based FPGAs
~~~~

https://ww1.microchip.com/downloads/aemDocuments/documents/FPGA/ApplicationNotes/ApplicationNotes/lpf_ac380_an.pdf

Internal power-on Reset and post programming Reset circuit for Flash-based FPGAs

1. the state of a system at startup is an important consideration in designing the most of the digital circuits. it is a good practice to provide a mechanism to reset the synchronous circuirtry in a known state after the bring-up
   1. otherwise, the system may initially operate in an unpredictable fashion because the flip-flops are not designed to power-on in any particular state.
   2. a power-on reset(POR) circuit insures that the device starts operating from a known state when the power is first applied.
   3. in Microsemi's Flash based FPGA system that doesn't  have an internal or dedicated reset controller and implement a simple internal POR/PPR circuit using one FPGA I/O and a few logic tiles
   4. VCC: voltage collector common. it represents the positve power supply voltage in electronic circuits.

如果是初始化SRAM based fpga 可以使用 verilog $readmemh 在reconfiguration的过程中初始化RAM，

Use a C++ program ˝ We’ll call this program genhex ˝ Much of the program is boilerplate and error checking

圣诞前任务：

* [ ]  建立new top-level file that contains router and spw controller, SHyLoC compression core
* [X]  create a new top-level module for SHyLoC
  * [ ]  之前存在的问题是 smartdesign automatically breaks up the record into individuak signals SmartDesign
* [ ]  学习代码过度边界问题

假期工作：

* [ ]  需要研究SHyLoC ccsds121和123一起使用，和只使用123区别，会存在哪些问题


##### 12.12 建立新的SHyLoC顶层模块

1. don't use wrapper file, since it is designed for post synthesis, 也就是直接使用ccsds123_top and ccsds_shyloc_top
   1. post-synthesis netlists usually don't support record types
   2. Wrapper expand complex AHB record type signals into individual standard logic signal
   3. 注意ccsds121 parameter D_gen 和 W_buffer_gen注意实际大小，因为虽然顶层修改了，但是submodule依然使用的parameter定义的
   4.
2. synthesize tool would say:Port ahbslave121\_in of entity work.shyloc\_subtop is unconnected. If a port needs to remain unconnected, use the keyword open.
   1. but when i set the ShyLoc_sub_top file as the root and synthesizing it doesn't produce this issue
   2. If you want to use types other than these, you should write a wrapper for them. VHDL is often a second class citizen when it comes to EDA support.
   3. 确实，如果直接将sub_top文件进行综合则不会有问题，一旦使用smartdesign，就无法使用record signal。
3. 需要研究SHyLoC ccsds121和123一起使用，和只使用123区别，会存在哪些问题


# 13.12.2024 建立新 router_top, router_fifo_spwctrl

1. 可以建立一个新的router_top, submodule include router, router_fifo_ctroller, 需要使用context router_context,
   1. 根据FIFO port数量及 spw node generate 相应数量的component, 用于生成对应的controller
      1. key points to note: generate conditions must be static, and Component instance names must be unique
      2. 需注意原controller rx data 已经为8bit了，直接连接router中的FIFO rx_data需注意拼合控制bit
   2. 需要注意route_fifo 和spw node 数据是相反的，rx_data是input，tx_data是output
   3. 再根据SHyLoC dataout bitwidth 决定asymetric fifo convert ratio（可选，需要修改逻辑，因为原code为32 to 8 bit）
2. 建立新的router_fifo_spwctrl, 因为tx_data 输出 router spw_fifo_in.rx_data，还要输出第一个地址数据（path address, logic address）附在第一个数据上, 可以新建立一个generic parameter选择port，
   1. 在tx_state fsm中添加一个新state，addr_send , 添加一个新signal send_port_done ，如当进入eop_tx state,说明如果再传输需进入addr_send state, 再次传输port address,
   2. 建立了一个新的flowchart
   3. 关于asymetric FIFO 可以有两种方案，一种是使用原来的代码，另一种是使用RAM模式来处理，类似于routing table ram一样。只不过与之相反变成32bit 写，8bit 读，可以使用一个LSRAM，256个 input, 1024 output

# ##### 18.12 整体数据方案

1. **Data Transmission**: First, 8-bit raw data is transmitted through the brick to the router channel and sent to the FIFO port.
2. **FIFO Output**: The output of the FIFO port is `tx_data`（9bit）, which is then received by the controller, outputting 8-bit `rx_data_out` to SHyLoC as raw data.
3. **Data Compression**: The controller compresses the received raw data to generate 32-bit data.
4. **Address Addition**: During the conversion, a path address or logic address needs to be added.
5. **Data Forwarding**: The `spw_controller` forwards the `tx_data` to the `fifo_rx_data` in the router, which is then forwarded to the corresponding `spw_node`.
6. **Data Comparison**: The compressed data received is compared in the `spw brick`.

* 所以压缩后的数据不能直接传给router fifo_rx_data, 因为还需要输入地址数据
* SpaceWire interface names outgoing data as tx_data from link perspective
* Router names incoming data as rx_data from router's own perspective
* this naming convention better expresses data flow relative to the router

# 年终总结 end summary

I mainly learned about the RMAP protocol and the design of other router IPs. I deployed a 4-links router IP on SF2 and optimized it, focusing primarily on the initialization of the routing table. I designed  a new FSM for initialization assignments in a safer manner. then, i used the brick to read and write commands using the RMAP protocol to configure the router.
