vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_ctrl.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_fifo_2c.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_filter_errors.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_rx_add_eep.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_rx_bit_rate.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_rx_flowcontrol_x.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_rx_sync_RIG4.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_rx_to_2b_RIG4.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_rx_to_data.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_timeout_del.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_tx_discard.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_tx_ds.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_tx_flowcontrol.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_RIG4.vhd
vcom -08 -quiet -check_synthesis -work spw_codec $DUT/simulation/src/4links/spw_rtl/spw_wrap_top_level_RIG4.vhd
# compile the common package
#spw library
vcom -08 -quiet  -work spw $DUT/simulation/src/4links/spw/spw_codes.vhd
vcom -08 -quiet  -work spw $DUT/simulation/src/4links/spw/spw_data_types.vhd
vcom -08 -quiet  -work spw $DUT/simulation/src/4links/spw/SpaceWire_Sim_lib.vhd
#rmap library
vcom -08 -quiet  -work rmap $DUT/simulation/src/4links/rmap/rmap_initiator_lib.vhd
vcom -08 -quiet  -work rmap $DUT/simulation/src/4links/rmap/rmap_periph_pckg.vhd
#router library
vcom -08 -quiet  -work router $DUT/simulation/src/4links/router/router_pckg.vhd
vcom -08 -quiet  -work router $DUT/simulation/src/4links/router/router_records.vhd
#spw_utils library
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/reg_bank_inf_asym2.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/asym_FIFO.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/ROM_Package.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/Brom_data.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_8bitto16.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_datacontroller.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_datactrl_fifo.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_rxlogic_top_fifo.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/spw_TXlogic_top.vhd
vcom -08 -quiet -check_synthesis -work spw_utils $DUT/SpwCodec_16bitinput/RTL/spw_utils/DUT_16bitInput.vhd