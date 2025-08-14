[DSR-TMTC-0020-CCU] The CCU DHU shall make use only of the following standard  PUS services:

• Service 1: Acknowledgement

• Service 3: Housekeeping

• Service 5: Events

• Service 6: Memory access

• Service 9: Time distribution (\*)

• Service 17: Test

• A TC service for commanding the suite (replacement for Service 8)

• A TM service for the delivery of science data streams to the S/C SSMM. This  service shall support the concurrent operation of more than one stream

 (\*) The particulars of the time distribution service shall be defined in mission-specific sub services

[DSR-TMTC-0020-CCU-U-M-H] The CCU DHU shall make use only of the following  standard PUS services:

• Service 1: Acknowledgement and request verification

• Service 3: Housekeeping and diagnostic

• Service 5: Events and error reporting

• Service 6: Memory access and management

• Service 9: Time distribution and management (\*)

• Service 12: Onboard monitoring  • Service 17: Test

• Service 20: Onboard parameter management

• Service 128: Payload service

• A TC service for commanding the suite (replacement for Service 8)

• A TM service for the delivery of science data streams to the S/C SSMM. This  service shall support the concurrent operation of more than one stream

• VenSpec-M private services (TBD)

• VenSpec-U private services (TBD)  (\*) The particulars of the time distribution service shall be defined in mission-specific sub services

# PUS packet Utilization Standard

### Service 1: Acknowledgement and request verification

**Function**: Confirms receipt of telecommands and verifies their execution status

**Document Reference**: The document mentions that all channels must use Service 1 to respond to Service 9 time synchronization commands

### Service 5: Events and Error Reporting

* **Function**: Reports significant events, state changes, and error conditions
* **Significance**: Provides a traceable operational history and anomaly notifications
* **Document Reference**: The document states "All anomalous conditions as well as any mitigation measures shall be reported by means of appropriate event packets"

### Service 6: Memory Access and Management

* **Function**: Allows reading from and writing to onboard memory
* **Significance**: Supports software updates, parameter modifications, and diagnostic data retrieval
* **Document Reference**: The document describes the baseline approach for channel software updates using Service 6

### Service 20: Onboard Parameter Management

* **Function**: Manages operational parameter settings
* **Significance**: Allows adjustment of instrument behavior without software updates
* **Document Reference**: The document lists this as a standard service in Section 8

### TC Service for Suite Commanding (Replacement for Service 8)

* **Function**: Provides unified command control for the entire VenSpec suite
* **Significance**: Enables coordinated operation of multiple instruments
* **Document Reference**: The document mentions that the CCU handles telecommands received from the spacecraft and distributes them to the appropriate subunits

### TM Service for Science Data

* **Function**: Delivers science data streams to the spacecraft's Solid State Mass Memory (SSMM)
* **Significance**: Supports concurrent operation of multiple data streams, optimizing downlink bandwidth usage
* **Document Reference**: The document describes in detail the CCSDS packet structure and science data compression implementation
