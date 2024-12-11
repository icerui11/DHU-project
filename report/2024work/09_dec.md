# 09.12

### ### *  编写routing_table version 2, 考虑初始化前几个logicAddress
*  router_routing_table_top_v2
~~~~

code detail:

1. 源代码基础上将initial state扩展成 initial_path and initial_logic state, (based on the source code, expand the initial state into ...)
2. because the logic address is from 32 to 255 and is 32bits and is represented in the routing table as 8 bits, the hexadecimal range multiplied by 4 is from 0x80 to 0x400.
3. in initial_logic state, the condition index< c_num_ports is unnecessary because all remaining logic addresses need to be initialized
4. 修改后代码问题在于从initial_path to initial_logic 之间 第一个地址 就是0x80  element,也就是init_wr_data 晚了一个周期才取到正确的值，也就是只取到element(01) (15 downto 8)的值
5. ![1733757880701](images/09_dec/1733757880701.png)
6. 在leave initial_path state时 init_wr_en:=0，避免写入多余数据
7. ![1733759954578](images/09_dec/1733759954578.png)
8. the key lies in the timing of the state machine and when variables/signals get updated. the key points are the value of element is not update, 也就是在else中的其实是有一个周期了， the new value of index(1) won't be avaliable until the next clock cycle. if we want to update element immediately, you should update it during the state transition
9. 不知道为何新创立的routing_table_v2 initialization value都对，但是产生RMAP Reply command有问题，因此建立routing_table_v3，只使用function对RAM进行赋值
10. type t_byte_ram is array (natural range <> ) of std_logic_vector(7 downto 0); 源代码routing_table中 这是一个自定义的类型， nature range<> 表示这是一个 unconstrained array, 具体大小在实例化时才确


### ~~~~10.12

1. 在原routing_table中之所以 如果直接用初始function对ram 赋值会使用过多的FPGA resource 是因为init_router_mem return v_ram, v_ram 是t_ram 类型，t_ram 又是 type t_ram is array (natural range <>) of mem_element。 the function returns the entire memory array at once
2. 还是使用FSM去初始化
