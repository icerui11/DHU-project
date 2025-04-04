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

# 03.04--

## block-encoder has lower performance

set GRLIB C:/Users/yinrui/Desktop/SHyLoc\_ip/grlib-gpl-2020.1-b4251

set SRC121 C:/Users/yinrui/Desktop/SHyLoc\_ip/shyloc\_ip-main/CCSDS121IP-VHDL

set SRC C:/Users/yinrui/Desktop/SHyLoc\_ip/shyloc\_ip-main/CCSDS123IP-VHDL

do $SRC/modelsim/tb_scripts/43\_Test.do

* [ ]  modify the SHyLoC sub-toplevel to adjust parameter to generate compressor

Ingeneral, thesampleadaptiveencoder  offers better performance for hyperspectral andmultispec traldata.This is mostly noticeable in BIP order, wherethe  block-adaptive coder under-performs,as it forms the blocks  in the way the samples arrive,even mixing spatial and spectral  information. Sample adaptive is also less complex than the  block-adaptiveone. -----shyloc2 sample-adaptive encoder

## SHyLoC_toplevel_v2

previous Top file support only CCSDS121 as block encoder. Here CCSDS 123 as sample encoder or 1D compression function is needed

我需要将这个顶层模块根据ccsds123 的parameter   constant ENCODING\_TYPE: integer  := 0;      --! (0) Only pre-processor is implemented (external encoder can be attached); (1) Sample-adaptive encoder implemented. 和 ccsds121 parameter   constant PREPROCESSOR\_GEN : integer := 1;      --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) Any-other preprocessor is present. 将模块能根据参数generate 成3 个主要模块：第一个是1d compression 时 preprocessor 和 encoder 都使用CCSDS121， 另一个是3d compression时，根据 encoding\_type选择 sample encoder 也就是encoder是ccsds123 或者encoder 是CCSDS121.

create 3 constant :
constant MODE_1D : boolean := (shyloc_121.ccsds121_parameters.PREPROCESSOR_GEN = 2) and
(shyloc_123.ccsds123_parameters.ENCODING_TYPE = 0);
constant MODE_3D_sample : boolean := (shyloc_123.ccsds123_parameters.ENCODING_TYPE = 1);
constant MODE_3D_EXTERNAL : boolean := (shyloc_123.ccsds123_parameters.ENCODING_TYPE = 0) and
(shyloc_121.ccsds121_parameters.PREPROCESSOR_GEN = 1);

### set new SHyLoC parameter file

However, after making modifications, it's important to note that the SHyLoC generic map also need to remap in the dedicate module, because original package has changed.
