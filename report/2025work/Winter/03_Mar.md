# router_fifo_spwctrl_16bit

1. address_send state need to strip off the logic address (greater than 31)
2. compressor need 16 bits input data, spw transmit 8 bits data. SHyLoC receive the raw data from Router spw_fifo_out.tx_data. In the router_fifo_spwctrl module, rx_data should be assembled into a 16-bit CCSDS raw data

## control_rx channel
