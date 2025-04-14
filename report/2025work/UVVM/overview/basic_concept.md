# VVC framework

each VVC has a standardized structure

Key innovation of VVC framework is that it provides a communication mechanism that works regardless of whether you use a test harness or not

* Global package-based communication
* Command Distribution Methods (CDMs)
* Command queues in VVCs
* 传统方法需要大量的信号连接和端口映射
* VVC Framework方法大大简化了结构，主要依靠通过包的全局通信
* is not necessary to define intermediate signals between the component and the DUT
* if the project is large and the interface interactions are complex, it is recommened  to create a SPW VVC. if it is small, use the Utility library

# UVVM architecture

Test harness

1. component instantiation
2. signal connections between components
3. clock generation
4. basic reset logic

应该只关注结构和连接

测试逻辑和顺序控制应该在test sequencer中

## Hands-on practice

### VVC clock generator

1. use clock generator VVC to run the clock, put in the test harness
   1. controlling it from the test sequencer
2. all test components inside the test harness
   1. so for the different test cases only switch which testbench, i.e. test sequencer to run
