#compile the spw library context 
vcom -2008 -quiet  -work work $DUT/simulation/src/4links/ip4l_context_RTG4.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_ctrl.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_fifo_2c.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_filter_errors.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_rx_add_eep.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_rx_bit_rate.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_rx_flowcredit_x.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_rx_sync_RTG4.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_rx_to_2b_RTG4.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_rx_to_data.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_timeout_det.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_tx_discard.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_tx_ds.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_tx_flowcontrol.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_RTG4.vhd 
vcom -2008 -quiet -check_synthesis -work work $DUT/simulation/src/4links/spw_rtl/spw_wrap_top_level_RTG4.vhd
#Brom library
vcom -2008 -quiet -check_synthesis -work Brom $DUT/SpwCodec_16bitinput/RTL/spw_utils/ROM_Package.vhd
vcom -2008 -quiet -check_synthesis -work Brom $DUT/SpwCodec_16bitinput/RTL/spw_utils/Brom_data.vhd
#src library

vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/reg_bank_inf_asym2.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/asym_FIFO.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_8bitto16.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_datacontroller.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_datactrl_fifo.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_rxlogic_top_fifo.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_TXlogic_top.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/DUT_16bitInput.vhd
vcom -2008 -quiet -check_synthesis -work work $DUT/SpwCodec_16bitinput/RTL/spw_utils/DUT_16bitInput_noAHB.vhd