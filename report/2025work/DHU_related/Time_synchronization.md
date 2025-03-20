# Mission specific constants

Tim-007 : ESA-ENVIS-ESOC-MOC-RS-001

* Accuracy to which time correlation is maintained. : 1ms
  * Time correlation refers to the synchronization of time between different systems or components

GR712 has two options:

1. Software-based Approach (ASW application software)
2. hardware-based solution on the GR712

The GR712 has two options, and this is what we need to trade off: * The ASW could implement a high priority task to react to timecodes from the S/C side, distribute a corresponding timecode on the VenSpec side and synchronize itself. This solution would lead to systematic delay linked to the latency of the propagation chain (reception, interruption, transmission of the timecode), but the jitter (which is the most important factor here) should not be too big because the load of the processor is going to be low, but we need to implement it and test it.

* Alternatively, there might be a hardware-based solution on the GR712, so that once it is properly configured time codes get generated without SW intervention. The question here is how to deal with the internal clock drift, because with 30 ppm we could lose 1 ms in 33 s, so the task receiving the timecode from the S/C

As shown in the GR712RC block diagram, it contains only six SpaceWire nodes and does not include a SpaceWire router, each SpaceWire node is independent and has its own time interface for sending and receiving Time-codes. When a Time-code is received on one node, it updates the time registers in that specific interface, but there is no automatic forwarding mechanism to other SpaceWire interfaces. which means it does not support hardware-based timing synchronization. To use the GR712 for timing synchronization, the only option is for a SpaceWire node to receive the timecode and then use an interrupt ASW to send the timecode through another SpaceWire link to the SpaceWire router in the DHU FPGA. The router within the FPGA then distributes the timecode to VenSpec. Additionally, if we want to distribute the timecode directly through processor hardware, we must use the GR740, as it is the model that internally includes a SpaceWire router

[I've been researching our options for timecode distribution with the GR712RC, as discussed in our recent documentation (](https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open_Topics/timing_code.md?ref_type=heads&plain=0)[https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open\_Topics/timing\_code.md](https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open_Topics/timing_code.md))

[I've been researching options for timecode distribution with the GR712RC](https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open_Topics/timing_code.md?ref_type=heads&plain=0). [After reviewing the GR712RC documentation, I can confirm that this processor does not support hardware-based timecode distribution ](https://git.rz.tu-bs.de/ida/rosy/research/venspec/documentation/-/blob/main/Open_Topics/timing_code.md?ref_type=heads&plain=0)

GR712 has 2 spw node which with RMAP

spw router shall only forward the timecode

GR712RC的前两个SpaceWire节点(GRSPW2-0和GRSPW2-1)支持RMAP(RMAP Target), 我认为我们可以通过FPGA内的router 发送RMAP 读请求，目标地址应该是APB base address(0x80100800 for GRSPW2-0 or 0x80100900 for GRSPW2-1 ) +address offset 0x14 Time register. 并通过RMAP回复返回时间值. FPGA接收到RMAP回复包含时间码值,提取时间码值并写入路由器的时间码寄存器，最后路由器将时间码广播到所有活跃端口。 但这种方案最大的缺点是RMAP 将作为N-Char 传输，并没有特殊优先级，而Time-code是特殊的的L-char. 所以通过RMAP会导致额外的延迟.

所以我建议还是使用软件方法读取time register的值来分发timecode
