# 01.04

上周我主要明确了SHyLoC 应该采用哪种encoder，之前我一直使用ccsds121 作为block encoder，但是我们的3d 光谱压缩使用ccsds 123 作为sample encoder 能获取更高的压缩率。所以我修改了新的compressor 顶层模块。

之后将开始关于run-time 配置的功能设计分析，从设计角度看应该是IO配置更简单，但在fpga 上板测试需要processor的参与，所有测试更难。选择spacewire 配置则正好相反。具体来说我会选择


Last week, I mainly determined which encoder SHyLoC should use. Previously, I had been using CCSDS121 as the block encoder, but for our 3D spectral compression, using CCSDS123 as the sample encoder provides higher compression. Therefore, I modified the new compressor top-level module.

Next, I will begin analyzing the run-time configuration design. From a design perspective, I/O-based configuration is simpler, but testing on the FPGA board requires the processor’s involvement, making it more difficult overall. Choosing a SpaceWire-based configuration is precisely the opposite.

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

but until now its don't need to immediate to do

Because it might ultimately only be feasible to choose CCSDS121 as the 1D compressor or CCSDS as the sample encoder, the DataIn bandwidth for CCSDS121 can be the same as that of CCSDS123

Dataout is same

### CCSDS121 signal

#### IsHeaderIn:

is a boolean signal that indicates whether the current data being input through the DataIn port is a header of a preprocessor block, rather than a regular data sample. It will be used then ccsds123 works with ccsds121, ccsds123 generates a header that needs to be passed to CCSDS121. This signal is used to identify such cases.

this signal is set to 0 when a preprocessor is present(Preprocessor_GEN =2), as header information is handled internally by the preprocessor

#### NbitsIn

is a 6-bit wide signal that specifies the number of valid bits in the input header information

function: Header information may not always fill the complete data width(e.g. D_GEN bits), so this signal tells the encoder how many valid bits are actually contained in the header

### SHyLoC_top_inst

SHyLoC_toplevel_v2

do $DUT/DHU-project/simulation/script/pre_syn_submodul/system_3SHyLoC_test.do
system_3SHyLoC_tb
gen_SHyLoC from ShyLoc_top_Wrapper to SHyLoC_toplevel_v2

# ccsds123 synthesize issue

Instantiated entity shyloc\_utils.barrel\_shifter has not been analyzed.  occurs when synthesized

root reason is that barrel_shifter is compiled after weight_update


For your library dependency problem, the Archive Utility can help in these ways:

1. **Library Integrity Verification**
   * Use the Archive Utility to analyze your project, which will automatically detect missing library components
   * Generate a dependency report clearly showing compilation order and dependencies

or

Check file order in the Project view. File order is especially important for  VHDL files.

– For VHDL files, you can automatically order the files by selecting Run >Arrange VHDL Files. Alternatively, manually move the files in the  Project view. Package files must be first on the list because they are  compiled before they are used. If you have design blocks spread over  many files, make sure you have the following file order: the file  containing the entity must be first, followed by the architecture file, and  finally the file with the configuration.

 – In the Project view, check that the last file in the Project view is the  top-level source file. Alternatively, you can specify the top-level file  when you set the device options.
