# SpaceWire Router Arbitration


## FIFO Priority vs Round-Robin Priority

### FIFO Priority (FiFo)

In FIFO priority mode, requests are processed strictly in the order they are received:

* The oldest request gets highest priority
* New requests are added to the end of a queue
* When a port finishes its transmission, the next port in the queue gets access

**Key characteristics of FIFO priority:**

* Fair based on request time (first-come, first-served)
* Prevents newer requests from blocking older ones
* More predictable and consistent latency across all ports
* Better for time-sensitive applications

### Round-Robin Priority

In Round-Robin mode, the router cycles through each port in sequence:

* A priority pointer rotates through all ports
* When multiple requests exist, the one closest to the pointer gets priority
* After a port is serviced, the pointer moves to the next port

**Key characteristics of Round-Robin:**

* Fair based on port number
* Ensures no port is permanently starved
* Can have higher variance in latency between ports
* Lower-numbered ports may have advantages in certain configurations

## port control

In the SpaceWire RMAP router using FIFO arbitration, a port maintains exclusive control of the output destination port until it completes sending its entire packet, which is terminated with an EOP (End of Packet) or EEP (Error End of Packet).
