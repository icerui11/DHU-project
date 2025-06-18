# Venspec Venus data

LR (200ms, BoL, Nominal) and HR (3000ms, BoL, Nominal)
\<data type>_\<instrument scenario>_\<instrument channel>_\<binning>[_nostab].\<column number>.\<row number>.\<frame#>.bin

where:

\<data type> : Venus / Dark / Sun
\<instrument scenario> : integration time, beginning/end of life, min/max/nominal performance
\<instrument channel> : LR/HR
\<binning> : for science data this is in the form of <binx>x<biny>, it indicates how many superpixels (resulting from the 3x3 median) have been added together along the two detector axes. In the case of dark frames, this field is either "raw" or "median".
\<column number>.<row number> : image size, this is relevant as the binary files contain no metadata, so you need these two numbers to know the x and y resolution, and be able to restore the 2D image
\<frame#> : this is a serial number from zero to the number of frames simulated in that specific configuration (except for dark data, where only one master frame is provided)


我不明白的是 根据最新采集的Venspec-U 的数据根据 different level of binning 图像 observation data 最大尺寸为671 x 339, 

当binning 3x150 时 为225 x 4, binning 3x15 时 为 225 x 24。 但是根据CCU-Channels SWICD, Venspec-U LR and HR Venus observation full resolution 分别为 205x74, 205x18,  我不懂最终图像大小以哪个为准？ 

因为目前我们正在检查用于压缩Venspec-U data 的压缩器所使用FPGA 资源的大小 ，所以我们需要知道DHU所处理Venus data 最大尺寸将会是多少


Because we are currently evaluating the FPGA resources needed by the compressor for Venspec-U data, we need to know the maximum Venus data size that the DHU will handle. The dimensions from the latest Venus observation data  differ from those specified in the SWICD. According to the new Venspec-U data:

• Maximum observation image size (no binning): 671 × 339
• With 3 × 150 binning: 225 × 4
• With 3 × 15 binning: 225 × 24

However, the CCU-Channels SWICD lists the full-resolution Venus observations for Venspec-U LR and HR as 205 × 74 and 205 × 18, respectively. Which of these sizes should we consider the definitive maximum image dimension?

## reply from Lucio

However, I bet the more honest answer at this point is: it depends.I think we should probably do one or two iterations with these compression tests first, in order to give a thoughtful answer to your question. The many configurations we provided are there also to give us a wider picture of the parameter space, even if some of those may not be used (or not very often).I guess the previously defined binning was chosen to be just enough to achieve the science goals within a given authorised data volume. But of course at that time we would not account for all these new ideas like median filter, dark subtraction, and variance stabilisation.These onboard treatments have a potential benefic impact on the maximum SNR achievable with binning/stacking (before the 16 bit limits) and on the entropy of the data sent to the CCU (better compression ratio). In fact, just judging by the size of the png files vs the 16bit binaries, I'd bet that we have a factor 2 in compression rate already in the pocket. With one (admittedly ad-hoc) 2D differential preprocessor and Rice encoder I tested last year I got close to a record factor 3. I reckon the CCSDS123 3D will achieve something in between.
I am very likely have to deal with those data 10 years from now, when they will come back to the ground. From my perspective, the least irreversible (destructive) decisions are taken onboard (binning being the chief one), the better. Hence, if it was evaluated that 205 × 74 was the maximum size for LR compatible with a certain compression rate, say ~1.4, and tomorrow the latter turns out to be ~2.5, then a frame size of 340 x 80 would still be compatible with the data volume after the CCU, and I'll be in favour of it. That, of course, if there are no other constraints (like the CCU's FPGA resources).

## reply from Björn

Thanks for your detailed answer. That's exactly the problem!
If we implement now a 3D compression based on your 205 × 74 specification,
you'll not be able (within some limits) to simply increase it to e.g. 340 x
80. Resources for the max. observation image size (no binning) of 671 × 339
might be already critical (Rui?). Or should we use this size for resource
assessment?

# synthesis result

对于3D 压缩，如果frame size 只增加到340 x 80, 对于SHyLoC (ccsds123)使用 BIP mode FPGA的资源还是足够的，但是当压缩 no binning data(671 × 339) 时 SHyLoC 就必须配置为BIP-MEM mode, 也就意味着需要使用SDRAM 存储intermediate data, 原本SDRAM只是用来存储compressed data, 这样就意味我们需要重新思考目前方案的可行性了，这也就是为什么目前 最大可能的raw image size 特别关键

Thank you for your answer. As Björn mentioned, for 3D compression, according current FPGA synthesis result shows that if the frame size only grows to 340 × 80, running the SHyLoC (CCSDS-123) core in BIP mode still fits within the FPGA's resource budget. However, to compress the no-binning data (671 × 339), SHyLoC must be switched to BIP-MEM mode—meaning SDRAM would be needed to buffer intermediate data. Since the SDRAM was originally reserved solely for the compressed output, this forces us to rethink the feasibility of our current scheme. That's why knowing the maximum possible raw-image size is so critical.For 3D compression, if the frame size only grows to 340 × 80, running the SHyLoC (CCSDS-123) core in BIP mode still fits within the FPGA's resource budget. However, to compress the no-binning data (671 × 339), SHyLoC must be switched to BIP-MEM mode—meaning SDRAM would be needed to buffer intermediate data. Since the SDRAM was originally reserved solely for the compressed output, this forces us to rethink the feasibility of our current approach. That's why knowing the maximum possible raw-image size is so critical.
