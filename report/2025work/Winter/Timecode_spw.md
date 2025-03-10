# using SpW Timecode for S/C synchronization

S/C contain many subsystem with individual clocks running at different tick rates and with varying performance that can degrade over time.

Without proper synchronization, it becomes difficult to:

* coordinate commands and activities across subsystems
* correlate telemetry data from different sources

**Time Distribution Methods**:

* They discuss two common methods: a "message" based method (software) and a "hardware tick" based method (hardware/firmware)
* SpaceWire Time Codes are used to create a virtual clock on connected hosts

The challenges in synchronizing spacecraft time are similar to those in ground-based systems:

A. Latency – the time it takes to transfer and respond to a time update. Each spacecraft subsystem must account for latency and be tolerant within a measured minimum and maximum range. A technique for measuring latency is described in the SpaceWire Time Distribution Protocol [2].

B. Jitter – the intermittent delay in the path between the master sending the time and the slave receiving and updating their time. Each spacecraft subsystem must tolerate a measured maximum jitter.

C. Drift – the variation in the clock tick rate due to oscillator performance, which typically degrades over time and varies with temperature. The time “master” clock must be calibrated periodically to account for the drift in the time conversion. The drift can be accounted for as a clock rate correction [2] to mimic the actual clock rate changes.

D. Time conversion – the different clocks may tick at different rates and a conversion from the hardware clock value to the time representation unit (usually in seconds) is applied using the clock tick rate, clock hardware value, and an offset, which typically includes drift. The conversion algorithm needs to account for latency, varying jitter, and clock degradation

# overview

provide a means of synchronising units across a SpaceWire system with resonably low jitter.

The time information can be provided as "ticks" or as an incrementing value which may be synchronized to spacecraft time

# 4link IP

the value of the last received timecode can be read from port 0 using the relevant status register.

By default, this register has address 0x03, 0x00. Where 0x03 is the
module address and 0x00 is the timecode register address within the module

constant c_misc_status_reg_addr	: t_byte := x"03";	-- misc status register, contains time code byte
constant c_misc_config_reg_addr	: t_byte := x"04";	-- misc config register, contains time code mask
two method to chose timecode master:

c_misc_config_reg_addr or c_tc_master_mask
