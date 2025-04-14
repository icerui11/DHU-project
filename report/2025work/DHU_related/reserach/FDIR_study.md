# CCU-Channels SWICD

The VenSpec suite has different FDIR layers. Since failures must be detected and managed as close as possible to the source, every channel has internal FDIR mechanisms. Only if the channels are not able to handle a failure, the CCU will act.

One high level FDIR mechanism is the implementation of a (bi-directional) heartbeat between CCU and the channels via the SpW timecode. For VESH and VESU the service 9 and the corresponding response are used as a bi-directional heartbeat. For VESM only a heartbeat from VESM to CCU will be implemented. Service 210 (TBC) will be used for that.

All anomalous conditions as well as any mitigation measures shall be reported by means of appropriate event packets. The status of automatic protection functions shall be provided in HK-data.

# 3251 CCU and VenSpec FDIR report


# General

Failure Detection Isolation and Recovery Analysis

## FDIR functions


* are those functions that implement the **failure detection, isolation and recovery actions**. The FDIR functionality is established at various levels within the space segment, e.g. at hardware and software levels. The implementation of the FDIR functions is based on specific system needs, e.g. specific time constants.
* shall be implemented in a hierarchical manner in order to detect, isolate and recover failures at the lowest possible implementation level.
