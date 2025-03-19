DOC: ESA-ENVIS-ESOC-GS-IF-003_ESA-EnVision_GenericFrameAndPacketStructure

# packet sequence control: sequence (segmentation) Flags

The sequence flags shall be set as follows:

01bin means first packet of a group of packets

00bin means continuation packets

10bin means last packet of a group of packets

11bin means “stand-alone” packet


# Venspec format   



**   ReqID**: 2.1.1.2

Since VenSpec-H only transmits complete lines of spectral channels, whileVenSpec-U provides full flexibility, only the band-interleaved per pixel (BIP)scheme shall be used, i.e. a spectral channels x special lines array of detector readout is used.

VenSpec-H outputs lines that contain all the spectral channels. This design naturally chunk-transmits an entire line of spectra at once
