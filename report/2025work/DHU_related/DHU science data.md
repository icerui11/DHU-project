# Issue 1 spectrometer's acquisition direction

![1743169582385](images/DHUsciencedata/1743169582385.png)

This is the image acquisition schematic from the CCU-Channels SWICD, but it should only be an illustration of the CCSDS123 compression method and not represent the data acquisition direction of the Venspec-U. As shown in the Venspec-U schematic, the spatial axis should be the x-axis, not the y-axis, with the y-axis being along-track. So the image acquisition schematic in the CCU-Channels SWICD is drawn incorrectly.

![1743170703896](images/DHUsciencedata/1743170703896.png)

# Question for data set of Venspec-U

According to the document (DHU Interface to VenSpec-U) at https://venspec.atlassian.net/wiki/x/SY5D, it is stated that :


- VenSpec-U will acquire a spectra, store it in internal memory, do some processing before sending it to the CCU.
- We can decide "how to send the spectra" to the CCU, and which axis (spectral or spatial) first

VenSpec acquires data in a BIL format. According to the 2200 DHU Interface to VenSpec-U, the data acquired by VenSpec should be processed and then output to the CCU in a BIP format, which means the spectral axis comes first. However, I noticed that Pablo mentioned in an email "pixel information in BIL format." I am not sure if this indicates that the data format requirements for the DHU compression core handling VenSpec-U data have changed. If so, we would need to adjust two of the compression cores to compress data in the BIL format.

Additionally, since CCSDS123 achieves only about 11% throughput in BIL format compared to BIP format during 3D compression (this may vary slightly depending on the image), if we need to compress VenSpec-U data in BIL format, we must take this into consideration.

![1743174697336](images/DHUsciencedata/1743174697336.png)

This is the data from the paper "SHyLoC 2.0: Versatile Hardware Solution for On-Board Data and Hyperspectral," and the data source was obtained solely by using CCSDS123.
