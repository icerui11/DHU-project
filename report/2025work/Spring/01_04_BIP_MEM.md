# 01.04

## system reset

* [ ]  remember in system top-level put shift-register reset
  since at the mmoment use the debounce of reset, so its unnecessary to add the logic
* [X]  set SHyloc to synchronous reset
* [ ]  reduce reset signal high fan-out

remove fifo data reset logic

do $DUT/DHU-project/simulation/script/pre_syn_submodul/system_3SHyLoC_test.do

# 02.04

## issue in system_shyloc_7port

des: port4 显示 character sequence error

通过RMAP 读0x 00030000  Misc Status Registers.      第一个数据是 A2

### router_top

misc_status_mem_inst

objective: stores generic router status such as Timecode register and master mask

重新program 后无问题，不知是否是timecode master

- set CCSDS123 and 121 parameter  to synchronous reset
