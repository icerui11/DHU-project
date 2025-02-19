# VVC framework

Key innovation of VVC framework is that it provides a communication mechanism that works regardless of whether you use a test harness or not

* Global package-based communication
* Command Distribution Methods (CDMs)
* Command queues in VVCs


* 传统方法需要大量的信号连接和端口映射
* VVC Framework方法大大简化了结构，主要依靠通过包的全局通信
* is not necessary to define intermediate signals between the component and the DUT


* if the project is large and the interface interactions are complex, it is recommened  to create a SPW VVC. if it is small, use the Utility library
