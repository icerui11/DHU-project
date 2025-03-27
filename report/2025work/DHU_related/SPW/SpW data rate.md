

* The router internal clock is 100 MHz for both SpW node clocks and router logic
* External SpW nodes have different clocks (75 MHz or 50 MHz)



Potential issues that might arise:

1. **Data rate mismatches**: If external nodes run slower clocks (50MHz or 75MHz), they'll transmit at slower rates than the router's 100MHz ports. This isn't a problem by itself, as SpaceWire handles asynchronous rates.
2. **Buffer overruns**: If the router is sending at a faster rate than the receiving external node can handle over a sustained period, the receiving node's buffers might eventually fill up. However, SpaceWire's flow control mechanism with FCTs should prevent this in normal operation.
3. **Flow control efficiency**: With large differences in clock speeds, the faster device might spend more time waiting for FCTs from the slower device, reducing overall throughput efficiency.
4. **Jitter and skew tolerance**: Different clock frequencies might lead to different timing margins for jitter and skew tolerance, but as long as the SpaceWire specification is followed, this shouldn't cause operational issues.
