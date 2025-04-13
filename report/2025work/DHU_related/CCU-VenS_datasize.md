# Data Handling Budget

The actual data transmission from VenSpec CCU to S/C will always be performed with bursts at the max allowed SpW data rate between CCU and S/C

The VenSpec team strongly recommends to work with the specified data volumes, rather than with data rates.

# VenSpec-U requirements to CCU

https://venspec.atlassian.net/wiki/x/BQDgAw

### R0-CCU-0012          Data production Venus observation mode

In Venus observation mode, VenSpec-U will generate Science data for LR and HR channels for a duration of 2820s typically.

Worst case, including 20% margin:

- LR science data: Bursts of 293 kbit every 200 ms (~1.5 Mbit/s)
- HR science data: Bursts of 73 kbit every 1500 ms

As a goal, the CCU shall be able of handling and compressing science data arriving at the CCU at a maximum rate of 6 Mbit/s

Note

* An acquisition always comes with a dedicated science header.

### R0-CCU-0013     Data production sun calibration mode, pinholes

Worst case (incl. 20% margin): the 140 acq. will be sent in 7s minimum:

- Science data (both channels on a single acq.): Bursts of 380 kbit every 50ms

This results in a maximum data rate of 7,6 Mbps

### R0-CCU-0013     Data production, Sun calibration mode, Diffusers

This results in a maximum data rate of 77 Mbps

During Sun calibration mode with Diffusers, VenSpec-U will generate up to 70 acquisitions.

Worst case (incl. 20% margin): the 70 acq. will be sent in 7s minimum:

- Science data (both channels on a single acq.): Bursts of 7670 kbit every 100ms

👀️ need to tack care whether over the DHU max

### R0-CCU-0025   Buffer memory

The CCU shall contain enough memory to buffer the VenSpec-U channel's data as long as needed before dump to S/C becomes possible. The sizing case corresponds to a single solar scan with diffuser (537 Mbit incl. 20% margin).

### R0-CCU-0040 Compression cores parameters in V-U TC

The CCU shall pick up the compression cores parameters from the V-U configuration TC, configure the compression cores, then dispatch the TC to V-U.

This is to ensure that the compression cores are configured before V-U sends science data.

# VenSpec calibration operation

![1743411480029](images/CCU-VenS_datasize/1743411480029.png)

# Venspec-u intro

VenSpec-U is an imaging spectrometer operating in the ultraviolet, designed to observe the atmosphere of Venus.

It employs of a pushbroom observation method

## Venspec-u data

![1743091595929](images/CCU-VenS_datasize/1743091595929.png)


![1744579031160](images/CCU-VenS_datasize/1744579031160.png)

for dark calibration 

Nx: 1024

Ny: 30

Nz: 2048

![1744580903311](images/CCU-VenS_datasize/1744580903311.png)

对于Venspec-U dark calibration 这里所提供的parameter，compression core 只能被配置BIP-MEM mode FPGA 才有足够的resource 综合两个SHyLoC compressor, 这时根据计算 单个compression core 用于储存intermediate data 大小为67 Mbit.


## VenSpec-U Dark Calibration and Memory Requirements

For the VenSpec-U dark calibration data, the compression core would need to be configured in BIP-MEM mode since the FPGA wouldn't have sufficient internal resources to handle this data volume. Based on the calculations, a single compression core would need approximately 67 Mbit of memory for storing intermediate data during compression.


![1744581565702](images/CCU-VenS_datasize/1744581565702.png)

对于Venspec-H, 我也注意到了只有calibration data才能 使用3D compressor, 在observation 的时候只能使用1D compression, 对于SHyLoC 由于input data 是由ccsds123进行预处理，但是 CCSDS123 the bitwidth can only be from 2 to 16. 但是Venspec-H 的位宽需要32bits, 这超过了CCSDS123 的处理范围。 所以我认为对于对于Venspec-H 更合理的是所有数据都使用CCSDS121 进行1D压缩，否则如果使用CCSDS123 3D处理Venspec-H，就需要额外需要一个单独的CCSDS121 处理normal data

这里需要注意的是compression core 的结构是在compile time 决定的，并不能在run-time的时候修改，所有SHyLoC 需要在综合前决定使用CCSDS123 或者CCSDS121 处理


## VenSpec-H Compression Considerations

For VenSpec-H, I've identified an important limitation. The documentation indicates that only calibration data could potentially use the 3D compressor (CCSDS 123), while observation data would need to use 1D compression (CCSDS 121).

The key constraint here is bit width. The CCSDS 123 implementation in SHyLoC can only process data with bit depths from 2 to 16 bits, as specified in the D\_GEN parameter. However, VenSpec-H requires up to 32 bits of precision for certain observation modes. 

This exceeds the processing capability of CCSDS 123 as implemented in SHyLoC. Therefore, a more reasonable approach would be to use CCSDS 121 for 1D compression of all VenSpec-H data. Using CCSDS 123 for 3D processing of VenSpec-H would require an additional standalone CCSDS 121 processor for normal observation data, which adds complexity.


## Architecture Configuration Limitations

It's important to note that the compression core architecture (BIP, BIP-MEM, BSQ, or BIL) must be determined at compile time and cannot be modified during runtime. The SHyLoC implementation requires deciding whether to use CCSDS 123 or CCSDS 121 before synthesis.

This means that the system design needs to be finalized before implementation, and the choice between compression algorithms cannot be made dynamically during mission operations.
