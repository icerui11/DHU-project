# WP 1000 specification

* [ ]  study the possible use of DMA, AHB, APB and how to configure the compression core and SDRAM

# WP 2000 AHB address divide

List all AHB slave on the AHB bus

e.g. GPIO ,DMA , APB-bridge




# Systembus design

当一组 image压缩完成后通知processor(通过compression core finished signal), 因此需要有一个通知模块

* 所有output 为IO口，通知模块需通知processor是哪一个compression core完成压缩
* 这个模块的Input 能接收processor  控制信号，再根据控制信号读取指定地址的的SDRAM 中的compression data(Sdram_AHB_Master) TBD : 因为需明确是否只需告诉processore 将传输 compressed data就足够，这也就是说需明确Sdram_AHB_Master 能否作为Master

AHBCTRL modul 负责AHB总线的仲裁，根据优先级确定，所以也需要明确每个模块的优先级

设计SDRAM的MEM address 的读写控制逻辑

### DMA and AHB

The DMA controller acts as an independent bus master that can initiate transfers on its own, while a regular AHB controller serves as bus infrastructure that coordinates and arbitrates bus access between different masters.
