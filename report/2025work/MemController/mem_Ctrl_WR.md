# Mem_controller

external SDRAM to FTSDRAM

processor 应该可以发布读compressed data 指令，memory controller作为ahb slave 将读取完成compressed 的data。

关于我们昨天讨论的关于不同通道需要同时读写数据到SDRAM的问题，但我认为这和gaisler 的memory controller 关系不大。在这里FTMCTRL 是作为ahb slave 充当的底层SDRAM 控制器，比如生成SDRAM 命令信号等。如果我们考虑到并发访问，这里控制权其实应该来自于AHB 控制器，也就是说AHB bus 控制逻辑应该是我们所需要设计的。 比如在目前DHU设计里 两个配置为BIP-MEM mode 的SHyLoC compression core 用于读取intermediate data, 所以 compression core 本身含有两个AHB master, 控制将存储在SDRAM中的compressed data 传输到GR712中又需要一个AHB master(这个master可能是位于GR712中， 因为我估计是processor 收到finished信号后 发送AHB 读请求 到 AHB 控制器中，再将AHB read reqest发送给FTMCTRL ) 所以仲裁这三个AHB master 请求 的AHB 控制器的逻辑 是我们设计的关键。在以前的项目SOPHI 中是使用SOCW interface，这需要被替换成AHB 接口，所以我认为 之后使用 SDRAM controller 是需要在其中加入AHB 接口。所以这里需要完成的是AHB controller 模块的设计, 这也是我认为我们项目中可能工作量最大的部分。 对于数据并发访问我认为通过加入FIFO 是可以进行处理的。

FPGA resource report 对于Venspec-U,-H 所需的FPGA 资源 我整理在了这个链接之中。https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open_Topics/FPGA%20resource%20usage/FPGA_resource_report.md



Regarding our discussion yesterday about different channels needing to read and write data to the SDRAM concurrently, I believe this is not closely related to the Gaisler memory controller. Here, FTMCTRL acts as the low-level SDRAM controller as an AHB slave, for example, generating SDRAM command signals. If we consider concurrent accesses, the control should actually come from the AHB controller—in other words, the AHB bus control logic is what we need to design.

For example, in the current DHU design, two SHyLoC compression cores configured in BIP-MEM mode are used to read intermediate data, so the compression cores themselves include two AHB masters. Additionally, controlling the transfer of compressed data stored in the SDRAM to the GR712 requires another AHB master (this master might be located on the GR712 side, because I estimate that the processor, after receiving the finished signal, sends an AHB read request to the AHB controller and then passes AHB read reqest to the FTMCTRL). Therefore, the key part of our design is the AHB controller logic that arbitrates among these three AHB master requests. 

In the previous SOPHI project, a SOCW interface was used, which now needs to be replaced with an AHB interface. Therefore, I believe that using the SDRAM controller in the future requires incorporating an AHB interface. What needs to be completed here is the design of the AHB controller module, which I consider to be potentially the largest workload in our project. Regarding concurrent data access, I think it can be handled by adding FIFOs.

For the FPGA resource report regarding the FPGA resources required for Venspec-U and Venspec-H, I have organized them in this link:
https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open_Topics/FPGA%20resource%20usage/FPGA_resource_report.md

## SDRAM

3DSD3G48VQ6486

organized with 6 banks of 512Mbit

clock Freuency: 133MHz


## FTMCTRL

The SDRAM controller supports  64M, 256M and 512M devices with 8 - 12 column-address bits, and up to 13 row-address bits. The  size of the two banks can be programmed in binary steps between 4MiB and 512MiB.
