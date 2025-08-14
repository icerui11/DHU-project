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

# quick reaction from Lucio

Quick reaction: pending discussion on our side (probably next week), for now I think it is reasonable to assume the (671 × 339) or the (2048x1024) as quite special purpose situations. We got those for the Sun calibration and the dark, and I may well imagine at least a few times we may want to have Venus captured at such high resolution, e.g. checking biases and assumptions on our data model before binning. But definitely it'll be by far not the "standard" Venus mode.Still, at this stage, if you can also process those (as well as the darks, etc), just to see what enabling the compression may mean in terms of data budget, that would be great. Do I understand correctly that in any case the "1D" compression would not be a problem in terms of resources?By the way, isn't the 3D algorithm also working in "2D" mode? What if you were to compress individual (671 × 339) or (2048x1024) images with the 3D compressor? Given the horizontal & vertical correlation of VensSpec-U frames, you sure will have a gain in size already (the tests I mentioned in my previous email were performed only one frame at a time, so effectively 2D predictors rather than 3D).

### resply

你的理解是对的，1D 压缩 任何情况都可以满足FPGA的资源要求。我理解你们想通过类似2D 压缩方式压缩 individual (671 × 339) or (2048x1024) images ，但是我们使用的3D 压缩器 IP core CCSDS123 算法限制 使得 在 BIP order 下必须存储 整个 Nx x Nz 大小的image 在FIFO中， 所以为了避免使用片外SDRAM, 对于calibration data (2048x1024) ，并且3d compression 效率不高的话，我们计划是只使用1D 压缩（CCSDS121）压缩 calibration data. 所以这里对于3D 压缩我们只需要关心需要3D 压缩的observation data image 最大尺寸是多少就足够了，如果这里(671 × 339) image只是 用于calibration data，那么这个image 将只会使用1D 压缩。 相对应的，如果观察的数据的observation data 有很强的空间相关性，那么它应该用3D 压缩， 所以我们需要知道需要使用3D 压缩的数据最大会是多少？


Your understanding is correct: 1D compression will satisfy the FPGA’s resource constraints in every case. I know you were hoping to treat individual images (671 × 339 or 2048 × 1024) like a 2D compression flow, but the CCSDS123 3D-compressor IP core imposes an algorithmic restriction in BIP mode—it must store the entire Nx × Nz image in the FIFO. To avoid using off-chip SDRAM (especially for the large calibration frames of 2048 × 1024, where 3D compression is also inefficient), we plan to apply only 1D compression (CCSDS121) to the calibration data.

That means for 3D compression we only need to know the maximum observation-data image size that will actually go through the 3D core. If the 671 × 339 frames are used solely for calibration, they will be handled by 1D compression. Conversely, any observation data with strong spatial correlation should be sent through the 3D compressor. Therefore, we need to determine the largest image dimensions that will require 3D compression.



















你的理解是正确的，
