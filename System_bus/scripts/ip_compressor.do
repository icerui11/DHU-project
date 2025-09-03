vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/toggle_sync.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reset_sync.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/amba.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/shyloc_functions.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/fixed_shifter.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/barrel_shifter.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reg_bank_inf.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reg_bank_tech.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reg_bank.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/fifop2_base.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/edac-0-7-src/edac-decl-0-7.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/edac-0-7-src/edac-body-0-7.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/edac-0-7-src/edac-rtl.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/fifop2_edac.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/fifop2.vhd
vcom -93 -quiet -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/bitpackv2.vhd

vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_parameters.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_constants_VH.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_config121_package.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_splitter.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_optcoder.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_lkcomp.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_header121_shyloc.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_sndextension.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_packing_top.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_fscoderv2.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_lkoptions.vhd

vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_shyloc_interface.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_clk_adapt.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_ahbs.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_shyloc_comp.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_shyloc_fsm.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_blockcoder_top_VH.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_predictor_comp.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/VH_ccsds121_predictor_fsm.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_predictor_top_VH.vhd
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/VH_compressor/ccsds121_shyloc_top_VH.vhd
# compile fifo for compressor
vcom -2008 -work VH_compressor $DUT/DHU-project/System_bus/RTL/Compressor/FIFO/router_shyloc_fifo.vhd

