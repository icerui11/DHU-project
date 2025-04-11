# 4.9 Run-time configuration

如果我使用spw RMAP 来更新设计在spacewire router中的register，用register的值配置SHyLoC compressor , 那么在FPGA设计中是否我只需要一个ahb master就足够了？但是当compressor 例如ccsds123 awaitingconfig signal 为高 时是否需要设置额外的控制逻辑使得这个ahb master开始读取register中的值？

另外我使用router status register储存这个configuration register的话，我还需要将这个status register改为ahb 接口?也就是加上ahb slave接口


##
