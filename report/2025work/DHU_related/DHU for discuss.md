需要明确的是：怎么管理来自不同通道buffered sensor data或者compressed data, 因为compressed data 不再是CCSDS packet了，也就是不同VenS 数据在压缩后怎么区分?比如进入buffer 的memory应该如何再被提取出来传输给 processor, 这涉及到需要processor 的软件部分来提取储存在buffer memory的数据

in CCU-channels SWICH 11.3 评论 by pablo:

1. All packets, regardless of its content and their need to be compressed, have to be formatted as CCSDS packets (primary and secondary header, service type, sub-type, APID, length, etc.). In particular, packets related to the transmission of science (data and metadata) shall contain the values demonstrated below (beside the rest of mandatory fields from the CCSDS standard).

👀️ Q: 所以这意味着待压缩数据包进去compressor前页是CCSDS packets，那么就包含 不仅是scientific data,也会有header data和CRC ，应该压缩核如CCSDS123 按照3D 压缩， 那么压缩尺寸已经固定了，所以我猜测这里是compressor将strip off这些数据，只保留scientific data, 这样在理想状态下compressor直接通过spw link 传输给processor，如果拥塞则需要存在buffer memory中，这时就需要processor 发送命令提取这部分缓存的compressed data。

note: The header of the science packets to be compressed have to have a fixed length because the FPGA will strip that header irrespective of the content. =====已注明

1. VenSpec-U is Pushbroom , since the limit of VenSpec-H, only BIP will be used, 但需要注意的是这与图上标注的不太一样，因为这是VenSpec- U 的采集方式，但不应该是Venspec-U的输出方式
2. 但是还有一个问题，DHU Router 处理能力，比如3 个通道的HK packet，已经VenSpec-M 的scientific data/ 所以Router应该设置为FIFO 模式吗？这样每个端口的处理时间相同，

   1. 使用FIFO仲裁能确保按照请求到达的顺序处理，避免某些端口被长时间阻塞的问题
   2. 我认为processor 应该来负责调度整个VenSpec 数据压缩调度功能，（我需要确认各个VenSpec channel数据大小），比如三个VenSpec数据同时到达DHU，其瞬时速率会超过FPGA to Processor(100 mbps) 上限， 尽管可能拉长时间 平均速率不会超过

      1. 虽然VenSpec-U , M 数据会压缩后才传输给processor，所以FPGA 可以先接收来自VenSpec的数据，但是HK (size 4114 bytes ) 依然是传输给processor （SpW address 192）
      2.
3. 已经压缩的数据如果未直接通过spw 传输到processor中，而是存在buffer中，则会加大DHU调取的复杂度(但问题是怎么保证新数据不会覆盖老数据？是否能计算最坏情况，给图像缓存计算最大的地址空间 ）

   1. Every single sensor readout shall be transmitted using separate SpaceWire packets and shall
      be finished before next readout starts. from CCU SWICH
4. Two data fields at the beginning of the payload (D0 and D1) that contain:

   1. D0: The data set ID (to identify this particular data set)
   2. D1: A sequence number (to track the packet's position in the sequence)
   3. 问题是压缩完成后D0,D1 还需要附在compressed data 前吗？
   4. **The key issue**: The compression core will discard these first two fields (D0 and D1) before compression. This means that the data ID information won't be part of the compressed data.
5. 我在考虑compressor 的runtime configuration功能，我的设想是processor在每次传输后 通过spw 发送configuration data， 但是SHyLoC 通过AHB接收配置信息，

##question about DHU datarte especially for sun calibration mode

@VESP-U R0-CCU-0014

During Sun calibration mode with Diffusers, VenSpec-U will generate up to 70 acquisitions.

Worst case (incl. 20% margin): the 70 acq. will be sent in 7s minimum:

- Science data (both channels on a single acq.): Bursts of 7670 kbit every 100ms

This results in a maximum data rate of 77 Mbps

但是根据 VenSpec Data Budget Summary 显示actually used max data rate 为65 Mbit/s，我不知道这是怎么来的

所以我的

## 分段传输和完整传输

但我明白一点的是，比如我压缩一个16x16x6 的图像，如果一次只传输一半，分成两次传输压缩，那我前一半不是中间结束部分的数据由于没有接收到后一半的数据导致信息不完整, 不会导致分两次传输的压缩结果和一次压缩传输压缩结果不一致吗？还是说无损算法可以恢复出来。给我解释这个问题

### from Pablo

Compression can be configured for 2D (frames) or 3D (cubes = several frames). In either case, pixels from two different elements shall not be sent in the same packet. For instance, if a frame is 512 bytes (very small) one can compress a cube of 4 frames by sending a packet of 2048 bytes. However, if you choose to compress the frames separately, they shall be in 4 separate packets of 512 bytes each.

question from Pablo mail:

* When compressing in 2D (single frame) when does the compression start? After the first spectrum (i.e. after receiving all the colors corresponding to a spatial location) or after the end of the frame (i.e. when all the colors for all the spatial locations have been received)? How will the GR712 be notified that the compression of the frame is done so that it can be processed further?
* Same questions for 3D compression: can the compression start after the first spectrum or does it have to wait to the first full frame? Does the compression core have to know in advance how many frames are coming or does it run in "streaming mode" where it can take as many frames as you through at it?

A:

1. 这里的compressing in 2D 指的是 只使用CCSDS121 进行压缩吗，
   1. 根据https://venspec.atlassian.net/wiki/x/SY5D （DHU Interface to VenSpec-U）VenSpec-U 在扫描时是2D 方式扫描，但是VenSpec-U 单次采集的数据应该是x 轴是special line

![1743087639697](images/DHUfordiscuss/1743087639697.png)

这是CCU-Channels SWICD 的示意图，但这应该只是CCSDS123 压缩方式示意图，并不应该是Venspec-U 的采集方向

![1743090458636](images/DHUfordiscuss/1743090458636.png)

Additionally, for the SHyLoC compressor, there is no 2D compression mode. When SHyLoC uses CCSDS 121 as the predictor, it performs 1D compression, and when it uses CCSDS 123 as the predictor, it performs 3D compression.

具体来说，对于CCSDS123 在预测时如示意图所示，如果配置为full prediction 在计算local differences 会使用spectial 方向的4个sample 和 spectral 方向上的p band的值， 即使是reduced prediction 不计算directional local difference(spectial direction) 但在计算Local sum 时也会根据配置参数计算 top of current sample or using 4 neighbouring sample的值。 所以CCSDS123不存在2 D 压缩，当然例外是处理第一行的数据不存在 top of current sample的值，所以只使用left of current sample的值。所以CCSDS123 不存在2d compression的说法

Specifically, for CCSDS123 during prediction as shown in the diagram, if configured for full prediction, it will use 4 samples in the spatial direction and P band values in the spectral direction when calculating local differences. Even with reduced prediction that doesn't calculate directional local differences (spatial direction), when calculating the Local sum, it will still compute values based on configuration parameters using either the top of current sample or using 4 neighboring samples. Therefore, CCSDS123 doesn't have 2D compression. The only exception is when processing the first row of data where there's no 'top of current sample' value, so it only uses the 'left of current sample' value. Therefore, the concept of 2D compression doesn't exist in CCSDS123

![1743166163583](images/DHUfordiscuss/1743166163583.png)

如这图所示X-axis 应该表示cross-track spatial dimension,

VenSpec 的采集方式是按照BIL 采集数据，根据2200 DHU Interface to VenSpec-U ， VenSpec 采集的数据应该可以处理后给CCU 输出按照BIP 格式输出，也就是spectral firt. 但是我看见Pablo 在邮件中说 pixel imformation in BIL format, 我不知道这是否代表对DHU 压缩核处理VenSpec-U 的数据格式要求发生了改变？如果改变我们需要将其中两个压缩核调整成压缩BIL 格式。 此外，因为CCSDS123 在进行3D 压缩时 Throughput BIL只有BIP 格式 大约11-18%（根据图像会有些不同），如果我们需要使用BIL 格式压缩VenSpec-U 数据我们需要对这点进行考虑。

### Shyloc

BIP  architecture is able to accept one compressed sample per  clock cycle. This feature makes this prediction architecture  capable of providing the highest possible throughput.

As analternative to the BIP architecture, BIP-MEM ar chitecture offers the user the possibility of using an external  memory to store the mentioned FIFO\_TOP\_RIGHT. The  access to this memory is performed by the AMBA AHB  master interface present in the IP core. One read and one  write operations are needed per sample compression.

![1743094831977](images/DHUfordiscuss/1743094831977.png)

When compressing in 2D (single frame) when does the compression start? After the first spectrum (i.e. after receiving all the colors corresponding to a spatial location) or after the end of the frame (i.e. when all the colors for all the spatial locations have been received)? How will the GR712 be notified that the compression of the frame is done so that it can be processed further?

A:

对于BIP 压缩，基本可以理解成当CCSDS123 获得前p个波段的数据就可以进行压缩，对于压缩算法计算局部和 时所需要的邻居像素，只用提取储存在FIFO中的数据就可以了，所以使用BIP压缩，compressor 可以更多的并行处理，基本等于每一个周期可以处理一个样本。

对于BIL 压缩，在计算局部和 和 计算局部差值时都有更多的数据依赖，无论是使用reduced prediction(只使用前P个波段的中心局部差值 `𝑑𝑥,𝑦,𝑧`进行预测) 还是full prediction (使用中心局部差值(central local differences) `𝑑𝑥,𝑦,𝑧`和方向局部差值(directional local differences) `𝑑𝑥,𝑦,𝑧^NW`、`𝑑𝑥,𝑦,𝑧^N`、`𝑑𝑥,𝑦,𝑧^W`进行预测) 计算局部和需要等待 $P \times Nx $ 数据才能开始压缩。

所有总结来说，使用BIP order 压缩时，数据是按spectrum 方向传输，只需收到p个波段（可以设置为3）就可以开始压缩了，而使用BIL ，由于计算 local differeces 原因，而BIL 是X-axis 传输，所以须等待P 波段 数据传输完成才能计算后续prediction residual. 这也就是BIL 压缩 Throughput 比BIP低的原因。 但是ccsds123使用BIL mode 压缩时 也都不需要receive all the spectrum 就可以开始压缩了（只需要P or P+3 个 band）. 在使用BIP-mode 时每一个pixel都含有了所有的spectrum。

## Only BIP will be used, so compression starts after reception of the first P bands, i.e. after the first P lines?

A:Only BIP will be used, so compression starts after reception of the first P bands, i.e. after the first P lines? 针对这个问题将以下回答翻译成英文，并对我的回答给出建议 看我的理解对不对：这里我想更详细的表述：SHyloc应该被分为两个阶段来研究：prediction and encoder. 之前我所讨论的主要是预测 阶段， 这里其实我忽略了一点，就是我们使用的SHyLoC compressor 使用CCSDS121 作为block encoder的话， 压缩开始还和block size有关，allowed value [8,16,32,64] ，也就是ccsds121 等待累积满J个样本后，才能开始编码压缩。所以在这里起决定意义的是CCSDS121 的block size。 无论是采用CCSDS121 作为1D 压缩 还是CCSDS123+CCSDS121. 而且我认为考虑when compression start的话 研究 p band 主要针对的是 ccsds123 作为preprocessor 预测阶段 ，对压缩开始意义不大。 这里起决定意义的是CCSDS121 的block size。 无论是采用CCSDS121 作为1D 压缩 还是CCSDS123+CCSDS121。但是我发现我们在压缩BIP的Hyperspectral image时 使用sample encoder能获得更高的compression ratio,

所以我总结的是当使用3d compression , 也就是 CCSDS123 作为 predictor，这里有两个encoder选择：分别是CCSDS123 sample encoder or CCSDS121作为 block encoder. 但是考虑到BIP 使用sample encoder能获得更高的的压缩比，所以在3d 压缩 encoder 我们会选择ccsds123 作为sample encoder。 这时理论上收到每一个pixel开始压缩，比如spetial(0,0) 的前p or P+3 band（根据配置参数）,开始 prediction 阶段，sample encoder开始对每一个sample编码，，CCSDS-123 能够在收到足够多的初始波段数据后立即开始压缩过程，而不需要等待整个帧的完成，也不需要预先知道要处理的帧数量。

There are more detailed explanation: SHyLoC should be studied in two stages: prediction and encoding. Previously, I mainly discussed the prediction stage, but I overlooked something important - when using the CCSDS121 as a block encoder in our SHyLoC compressor, compression start also depends on the block size, with allowed values [8, 16, 32, 64]. This means CCSDS121 waits until J samples have accumulated before it can begin encoding compression. So the determining factor here is the CCSDS121 block size, whether using CCSDS121 for 1D compression or CCSDS123+CCSDS121 together.

I believe that when considering when compression starts, studying P bands is mainly relevant to the prediction stage of CCSDS123 as a preprocessor, and not very significant for when compression actually begins. The determining factor is the CCSDS121 block size, whether using CCSDS121 for 1D compression or CCSDS123+CCSDS121 for 3D compression.

However, I've discovered that when compressing BIP Hyperspectral images, using a sample encoder (which is from CCSDS123)achieves a higher compression ratio. So my conclusion is that for 3D compression (CCSDS123 as predictor), there are two encoder options: CCSDS123 sample encoder or CCSDS121 as block encoder. Considering that BIP achieves higher compression ratios with the sample encoder, for 3D compression encoding we would choose CCSDS123 as the sample encoder instead of CCSDS121 as block encoder.

In this case, theoretically compression begins with each received pixel, for example after receiving the first P or P+3 bands (depending on configuration parameters) of spatial position (0,0), the prediction stage begins, and the sample encoder starts encoding each sample. Therefore, we can consider that CCSDS123 starts compression as soon as data is available. CCSDS-123 can begin the compression process immediately after receiving enough initial band data, without needing to wait for the entire frame to complete or knowing in advance how many frames will be processed.

So the CCSDS123 can run in streaming mode

对于1D compression, 也就是 CCSDS121，这时会每收到J(block size) 然后进行处理开始压缩.

1. For the CCSDS 123 preprocessor (predictor):
   * For the very first pixel at position (0,0,0), prediction uses default values since there are no preceding samples.
   * For subsequent bands of the first pixel, prediction can use information from previously processed bands of the same pixel, up to P previous bands.
   * The process doesn't need to wait for P complete bands before starting; it begins immediately but with limited historical data for early samples.
2. For the CCSDS 121 block-adaptive encoder:
   * the block size J (with allowed values of 8, 16, 32, or 64) affects when coding can begin.
   * The encoder must accumulate J mapped prediction residuals before selecting the optimal encoding option and producing output.
   * In a combined CCSDS 123 + CCSDS 121 system, the CCSDS 123 preprocessor can start producing mapped residuals immediately, but the CCSDS 121 encoder must wait until it has accumulated J samples.

So in summary, for BIP order:

* The CCSDS 123 prediction starts immediately, though with limited context for early samples
* The P parameter affects prediction quality rather than when compression starts
* The CCSDS 121 block size J determines when encoded output begins to be produced

The key factor that determines when compressed output becomes available is primarily the block size J of the CCSDS 121 encoder rather than the P parameter of the CCSDS 123 predictor.

How will the GR712 be notified that the compression of the frame is done so that it can be processed further? 对于这个问题：

如果compressor 压缩完了所有数据，Finished signal 会asserted。然后compressor 会根据配置模式进行配置，配置完成了就可以进行下一次压缩。但是目前的设计还没有考虑到通知GR712 压缩完成。目前FPGA内compressor 的设计是：使用compile time configuration, compressor 会持续不断地进行压缩 Hyperspectral image(大小固定为$ Nx \times Ny \times Nz$ ) 每一次的压缩不需要GR712的干预。

在这里compressor提供两种配置方式，一种是在compile time 配置，这意味着所有所有参数都在FPGA synthesis前被配置，所以配置成这个模式时压缩器会自动根据参数进行配置并开始准备接收sample 开始新的压缩过程

另一种是run-time 配置，这是compressor需要通过AHB bus 接收配置参数，只有接收参数成功并且配置参数在定义的范围内 compressor才能配置成功，compressor 配置成功后，就可以开始压缩。

所以在这里我也需要确认compressor是选用 run-time configuration 还是compile-time configuration. 如果压缩参数是预定义好的不需要进行调整的话使用compile-time configuration 因为选用run-time configuration ，我们需要使用一个ahb master 配置 SHyLoC compressor, 我们需要明确compressor 配置方式和要求, 比如可以在FPGA 设计一个ahbram ，configuration parameter 可以储存在这个ahbram中，prarameter可以通过GR712 修改 configuration parameter 或者根据venspec channal 的packet 配置 compressor.

也就是说GR712 可以通过Finished signal 得知compression of the frame is done. 可以通过GR712 修改下一次压缩的配置参数，因为compressor 将被配置为run-time configuration, 所以将会有一个AHB master 传输给在compressor 中用于接收configuration parameter的AHB slave. 当compressor AwaitingConfig signal 置低且ready 为高就可以

Therefore, I also need to confirm here whether the compressor uses run-time configuration or compile-time configuration. If the compression parameters are predefined and don't need adjustment, compile-time configuration would be appropriate. Because if using run-time configuration, we need to use an AHB master to configure the SHyLoC compressor, and we need to clarify the compressor configuration method and requirements. For example, we could design an AHBRAM in the FPGA where configuration parameters could be stored, and parameters could be modified through the GR712 processor or configured based on packets from VenSpec channels.

我个人更偏向通过AHB i/o配置，因为这是更容易的选项，因为使用spacewire channel 0 会涉及在spw router 中添加新的status register，应该会需要更复杂的测试，我看见Pre-EM User-manual 应该是有8bit 的bus可以用于GR712 和 FPGA通信， 另外一点是我可以通过GR712 将 configuration register的值储存在MRAM 中通过GR712 FTMC控制，我看见我们的设计应该FPGA也就是可以通过Memcontroller读取 CFG的值（configuration register）完成run-time configuration 配置，这种方式可行吗

I personally perfer configuring via AHB I/O since it's the easier option. Using SpaceWire channel 0 would involve adding a new status register to the SPW router and likely require more complex testing. I saw in the Pre-EM User Manual that there is an 8-bit bus available for communication between the GR712 and the FPGA.

Additionally, we can store the value of the configuration register in the MRAM through the GR712’s FTMC control. According to our design, the FPGA should be able to read the configuration register (CFG) via the memory controller to complete the run-time configuration. Do you think this approach is feasible?

对于CCSDS123 不同的数据排列类型，compressor处理方式也是不同的：

* 在BIP模式下：处理完第一个像素的前P个波段后，压缩就可以开始
  * 一般P 定义为3，因为超过3对压缩几乎没有影响（但p值过大会消耗过多的DSP）
* 在BIL模式下：处理完第一行中足够的像素后，压缩就可以开始

Same questions for 3D compression: can the compression start after the first spectrum or does it have to wait to the first full frame? Does the compression core have to know in advance how many frames are coming or does it run in "streaming mode" where it can take as many frames as you through at it? 关于这个问题我认为ccsds 是当压缩完一个cube后会根据配置的方式，如果不调整parameter，每次compressor完成一个cube（x ,y,z） 压缩后会进行配置，配置完成后会发送ready 信号就会接收Raw image, compressor会计算接收了多少个数据（$ Nx \times Ny \times Nz$）, 如果有data 没有传输给compressor 而compressor没有完成此次压缩的话 compressor会处于等待状态，除非收到全部的input data，

另外对于SHyLoC compressor 并不存在2D compression, SHyLoC 使用CCSDS121作为predictor时 是1D 压缩，使用CCSDS123 作为predictor时 是3D 压缩。

CCSDS121 1d 压缩的机制是什么？以及CCSDS121 作为CCSDS123 的block encoder的好处是什么？为什么不使用CCSDS123 的sample encoder

## CCSDS 121 1D compression mechanism:

CCSDS 121 is a lossless data compression standard that uses a simple unit-delay predictor followed by an adaptive entropy encoder. The compression mechanism works as follows:

1. **Prediction**: The unit-delay predictor estimates the current sample based on the previous sample. For the first sample in a sequence, a reference value is used.
2. **Mapped Prediction Residual**: The difference between the predicted value and the actual value (prediction residual) is mapped to a non-negative integer.
3. **Block-Adaptive Entropy Encoding**: The mapped residuals are divided into blocks of J samples. For each block, multiple encoding options are evaluated concurrently:
   * Fundamental Sequence (FS) coding
   * Sample splitting (with different k values)
   * Second-extension option
   * Zero-block option
   * No compression option
4. The option that produces the shortest codeword for the current block is selected, and an identifier for this option is attached to the compressed block.

## Benefits of using CCSDS 121 as a block encoder for CCSDS 123:

1. **Adaptive Encoding**: The block-adaptive approach allows the encoder to adapt to changing statistics in the data, potentially achieving better compression than the sample-adaptive encoder in some cases.
2. **Lower Bit Rate Capability**: The CCSDS 121 block-adaptive encoder can achieve bit rates lower than 1 bit per pixel (bpp), while the CCSDS 123 sample-adaptive encoder has a theoretical minimum limit of 1 bpp.
3. **Zero-Block Handling**: The block-adaptive encoder has a specific option for blocks of all zeros, which can significantly improve compression for sparse data with many zero values.
4. **Flexibility**: The block-adaptive encoder provides multiple coding options that can be selected based on the data characteristics, potentially leading to better compression performance across a wider range of data types.

但是数据显示使用sample encode 压缩率会更好

The main reason why someone might choose the block-adaptive encoder over the sample-adaptive encoder is the potential for higher compression ratios, especially for data with varying statistical properties or with many blocks of zeros. However, this comes at the cost of increased computational complexity since multiple encoding options need to be evaluated for each block.

The sample-adaptive encoder provided in CCSDS 123 is simpler and may have lower computational requirements, but it cannot achieve bit rates below 1 bpp, which can be a limitation for high compression requirements.

关于CCU-Channels SWICD 11.3. compression implementation ,"Although the data ID will be tracked by correlating the APID of the header with the compression core that is processing it, since D0 and D1 will be discarded by the compression, it might be advisable to put the data ID somewhere among the pixels so that it gets compressed together. The two best candidates are the first pixel of each frame or the first pixel of each line. One solution that will certainly not work is to put it at the beginning of each packet, because then these fake pixels will be scattered all over the frame."  我想知道如果加入这个D0和D1 进 actual pixel, 那么一个cube data set 将这会改变fixed predefined data format 吗？ 我需要明确这一点。

另外在对于

如果不将D0，D1放入对于Data Set ID and Packet Sequence number这些数据是否是在进入FPGA时被去掉？如果是的话，我需要明确这些header 是多少bit--应该不用SWICD 有说明。

Regarding CCU-Channels SWICD 11.3 compression implementation, "Although the data ID will be tracked by correlating the APID of the header with the compression core that is processing it, since D0 and D1 will be discarded by the compression, it might be advisable to put the data ID somewhere among the pixels so that it gets compressed together. The two best candidates are the first pixel of each frame or the first pixel of each line. One solution that will certainly not work is to put it at the beginning of each packet, because then these fake pixels will be scattered all over the frame." I want to know if adding this D0 and D1 into actual pixels will change the fixed predefined data format of a cube data set? I need to clarify this point. Additionally, for APID, Service Type and Subtype, are these data removed when entering the FPGA? If so, I need to know how many bits these headers are. Then I can modify the design to remove these headers before the packet enters the compressor.

另外在service(213,2) and (213,3) 时，关于SWICD 说明的“It shall be noted that APID, Service Type and Subtype, Data Set ID and Packet Sequence number(as well as the 16 bit of the CRC at the end) will be ignored by the compression core, but they will be carefully observed by the processor whenever data is to be sent uncompressed (by sending it to SpW 192 instead of 220).” 这是否说明compression core可以直接忽略这些信息（==APID, Service Type and Subtype, Data Set ID and Packet Sequence number==）不需要在FPGA内去掉这些信息即可，对吗？

![1743278599828](images/DHUfordiscuss/1743278599828.png)

Q2:

另一点是关于压缩数据时发生有数据丢包的情况，从而导致Compressor 没有收到足够数量的数据（$ Nx \times Ny \times Nz$）那这时如果下一个Hyperspectrum压缩数据 进入接着压缩会造成数据混乱。所以我想知道有没有必要在DHU FPGA设计这样一个逻辑：当收到一个packet 的service 为（213，1）时表示这个packet是header data，就代表下一次的image 压缩开始了，可以设计一个计数器统计有多少个数据进入compressor前，如果在下一个header前没收到足够数量的数据就说明发生了丢包，这时可以返回一个error信号给GR712 说明传输丢包，这时设计一个逻辑给Compressor 输出一个Forcestop signal,使得compressor 强制进入新的压缩状态，避免了当一个新的image 需要压缩，而上一次压缩由于丢包造成未完成压缩的情况。所以相当于每次compressor在接收 header data时都将检查是否是正确数量的包到达compressor，如果没有，就执行一次forcestop 命令。

Another issue concerns data packet loss before compression, which can lead to the Compressor not receiving the expected number of data samples (Nx × Ny × Nz). If compression of the next hyperspectral image begins immediately afterward, this can cause data confusion. Therefore, I'm wondering if it's necessary to design the following logic in the DHU FPGA: When a packet with service (213,1) is received, indicating header data and the start of a new image compression, a counter could track how many data samples enter the compressor. If the expected amount of data isn't received before the next header arrives, this indicates packet loss. In this case, an error signal could be sent to the GR712 processor reporting the transmission loss, and logic could be implemented to output a ForceStop signal to the Compressor, forcing it to enter a new compression state. This would prevent situations where a new image needs compression while the previous compression remains incomplete due to packet loss. Essentially, each time the compressor receives header data, it would verify whether the correct number of packets reached the compressor, and if not, execute a ForceStop command.

Q3

![1743414687646](images/DHUfordiscuss/1743414687646.png)

首先这里的问题是为什么对于Calibration data

![1743413672889](images/DHUfordiscuss/1743413672889.png)

我想知道这个VenSpec Data Budget Summary 中计算Instrument data rate with maturity margin 是否包含了使用spacewire 传输的开销，如果没有的话还需加上8b/10b 的开销。 并且在sun calibration Venspec-U 和Venspec-H 同时进行，并且我注意到对CCU 对calibration data 的compression factor为1，那这时Venspec-U 传输给DHU的datarate 就是$ 76.692Mbit/s \times 10b\div8b = 95.865Mbit/s  $ Venspec-H Sun calibration最大datarate 为 $14.354Mbit/s \times 10b \div 8b =17.9425Mbit/s$ 。那这时部分数据需要存储在SDRAM中才能完成传输，当GR712和FPGA之间的spw link 可以传输缓存在SDRAM中的数据数据时，这时需要控制指令通过memory controller提取临时存储在SDRAM中的数据，那这个命令应该由GR712生成，还是由FPGA 自己生成，因为如果calibration data未经压缩的话储存在SDRAM也是固定长度，GR712就可以发布指令读取特定地址的数据，完成数据的传输。

I would like to know if the 'Instrument data rate with maturity margin' in the VenSpec Data Budget Summary includes the SpaceWire transmission overhead. If not, the 8b/10b encoding overhead would need to be added. Additionally, during sun calibration, both VenSpec-U and VenSpec-H operate simultaneously, and I've noticed that the CCU's compression factor for calibration data is 1. In this case, VenSpec-U's transmission rate to the DHU would be 76.692Mbit/s × 10b÷8b = 95.865Mbit/s, while VenSpec-H's maximum sun calibration data rate would be 14.354Mbit/s × 10b÷8b = 17.9425Mbit/s. This means some data would need to be stored in SDRAM to complete the transmission. When the SpW link between GR712 and FPGA can transmit the data cached in SDRAM, control commands would need to retrieve this temporarily stored data through the memory controller. Should these commands be generated by the GR712 or by the FPGA itself? Since calibration data is of fixed length if uncompressed, storing it in SDRAM would also be of fixed length, allowing the GR712 to issue commands to read data from specific addresses, completing the data transmission.

**BIP (Band Interleaved by Pixel)**:

* Processes all spectral bands for one pixel before moving to the next pixel
* Allows for maximum throughput (one sample per clock cycle) as there are fewer data dependencies between consecutive pixels
* Enables pipeline implementation for hardware acceleration
* Memory requirements include storing adjacent samples for all bands

**BIL (Band Interleaved by Line)**:

* Processes a complete line in one spectral band before moving to the next band
* Creates more data dependencies that limit parallelism
* Needs more complex scheduling to maintain throughput
* Requires storing local differences for a line of pixels
* Common for pushbroom sensors in satellite applications

Different architectures have been developed for each ordering to optimize performance. BIP generally achieves the highest throughput but may require more memory resources, while BIL typically aligns better with how data is acquired by many satellite sensors.

### response for email:

Hi Björn,

I've reviewed the document section between "11. Compression" and "12. Time Synchronization" in detail.

Regarding the time synchronization approach, I can confirm this should not pose any problems for the DHU hardware. The FPGA will only need to route TC and TM messages as specified, and we simply need to verify the FPGA router's timecode forwarding functionality in our upcoming tests.

For the channel dataset, having the basic spatial and spectral dimensions along with the bitwidth data is sufficient.

My main question remains regarding D0 and D1 (data ID and sequence). I agree with the SWICD's point that these values cannot simply be placed at the beginning of each packet. As I mentioned in my MD document comments, when adding these D0 and D1 values to the science data for compression, we need to ensure that the product of the three-dimensional data accurately matches the input data quantity.

I've updated the MD document with additional comments and questions that we should discuss in our next disccussion.

Best regards,

response to email

I have provided detailed answers to your questions in the attachment.

Regarding the packet size, it has no impact on the compression core. My understanding is that VenSpec-U has 2048 bands. Due to the packet size limitation, where each packet can only be 2 Kbytes, only half a line of data can be transmitted at a time. In practice, this does not affect the compressor functionality, as the compressor simply waits for the next sample. When a new sample arrives, the compressor continues processing until all samples have been received and the compression operation is completed.

正因为compression core 只关心data size, 我需要更清晰的知道关于D0(data ID) and D1(sequence) 的具体设置，因为如果需要put data ID among the pixel 的话，这样是否会让compression raw image data size 变大呢？

Precisely because the compression core only cares about data size, I need to understand more clearly the specific configuration of D0 (data ID) and D1 (sequence). If we need to put the data ID among the pixels, would this increase the raw image data size for compression?

关于calibration data:

- LR and HR calibration at the same time, yes. So both compression cores
  have to run at the same time. formally speaking, we “don't need” compression for dark cal. 什么意思

# Email in 15.04 from pablo

context:

```
Thank you very much for putting this information together. This is really informative and important (in fact most of it should go to the user manual of the pre-EM even if they are not specific to the pre-EM). We have two follow-up questions on this topic:
 
Is it true that these three signals (Awaiting Config, Ready, Finished) will be repeated three times (i.e. once per core)?
How will the compression core notify how much compressed data it has produced? I assume that the starting memory address for output will be provided to the core during the configuration phase, but the output size will not be predictable and therefore has to be communicated back to the processor somehow.
 

From your comment about the dimensions I understand that for the normal VESU observations defined in https://venspec.atlassian.net/wiki/spaces/PfPssEnvisionCcu/pages/337641556/CCU-Channels+SWICD#11.3.2.-Configuration-of-compression-cores the dimensions would be x=205, y=6486 (although we will probably break this down in several chunks) and z=74, whereas for the VESH dayside we would have x=256, y=1, z=384 (at most). Is this right? Once you confirm it, I can ask DLR to swap X and Y in the diagram.

Concerning D0 and D1, the only effect for you is that the header of the packet is 28 bytes (6 bytes of primary header, 14 bytes of the secondary header and 8 bytes for D0 and D1), which the compression core shall discard alongside the trailing 2 bytes of the CRC. Concerning the inclusion of "virtual pixels" containing data ID, this is up to the channels. For instance, VESU could decide to extend the dimension of their data to 207 pixels in the spatial direction where the first two are "virtual" and always contain the data set ID. This would definitely increase the size of the raw data, but my expectation is that it would have a very small impact in the compressed version because it would be a constant value on each data set. Additionally, we could "recommend" to the channels to limit the number of virtual pixels to one or two per frame instead of per row.

```

Answer for Q1:

Yes. Each compression core will have its own set of control signals. Since each core works independently, naturally each has its own control signals.

对于这一点，我们想知道的是GR712打算通过I/O 还是spw RMAP 读取Finished这些信号.

我们计划是compression core configuration parameter 通过RMAP GR712传输给FPGA，但如果是直接通过RMAP 读取compression core status(这里面含有Finished 等控制信号)则不可行，因为可能有其它链路正在从FPGA 传输给 GR712, 这意味RMAP数据包需要等待。

Answer for Q2:

compressor core  本身并没有通知有多少compressed data 的功能。我们可以设计counter 统计有多少compressed data. 可以将compression data number 储存在compression core的 status register中，这个值可以随Finished 信号一起被读取。

对于Venspec channel dimension size 根据SWICD 我能确认 x, y, z 大小是正确的。

此外我们需要确认对于VESU observation y size, y将被分成多少个chunk，因为我们需要将a set of compressed data放入 buffer memory中，因此这个chunk number 很重要，这关系到SDRAM 的大小 是否足够

### response

Answer for Q1:

Yes. Each compression core will have its own set of control signals. Since each core works independently, naturally each has its own control signals.

For this point, we want to know whether the GR712 plans to read these signals via I/O or SpW RMAP.

Another aspect concerns the configuration parameters. Our plan is to transmit the compression core configuration parameters from the GR712 to the FPGA via RMAP. However, if we try to directly read the compression core status (which includes the Finished and other control signals) through RMAP, it won't work because there might be other links transferring data from the FPGA to the GR712. This means the RMAP packets would have to wait.

Answer for Q2:

The compressor core itself does not have a function to indicate how many compressed data items there are. We can design a counter to count the number of compressed data items. The compression data number can be stored in the compression core’s status register, and this value can be read together with the Finished signal.

Regarding the Venspec channel dimension size, according to SWICD, I can confirm that the sizes for x, y, and z are correct.

In addition, we need to confirm for the VESU observation y size: into how many chunks will the y dimension be divided? This is important because we need to store a set of compressed data in the buffer memory, and the number of chunks is critical. It directly affects whether the SDRAM size will be sufficient.

比如从AwaitingConfig signal deasserted 到 finished signal asserted 期间 总共的 compressed data 数量，

~在这里我认为更有用的是one acquision 所产生的compressed data 数量，因为我计划需要确定是否需要将one acquisitions of data 缓存进fifo后 再传输给processor，这样compressed data 数量也可以提前发送给processor，让processor 控制信号控制memory controller 传输缓存的compressed data 到processor中~

The compressor core itself doesn't have a built-in function to indicate the amount of compressed data. If needed, we can design a counter to count the number of compressed data items—for example, counting the quantity between when the AwaitingConfig signal is deasserted and when the finished signal is asserted.

It is necessary to determine whether one set of data should be cached in the SDRAM first before being transferred to the processor. This way, the number of compressed data items can be sent to the processor ahead of time, allowing the processor's control signals to instruct the memory controller in transferring the cached compressed data to the processor.

For data, can the processor control each channel to start transmitting data, or must the FPGA always be ready to start receiving data?

## Venspec-U calibration

LR and HR calibration at the same time

根据Venspec-U 所说，LR and HR calibration at the same time，那么这是否意味这Venspec-U 需要两个SpW link来传输数据给我DHU？因为我们Pre-EM 设计的每个channel只有一个SpW port. 如果是这样我们需要增加一个spw port.

反之，如昨天我们对Memory controller 讨论的那样，如果Venspec-U 只通过一个SpW link传输raw data,我们考虑memory controller并发访问SDRAM 对于Venspcec-U 相关的数据就不需要考虑两个compression core在BIP-mem mode 同时访问SDRAM的问题了. 因为这样处理Venspec-U LR and HR 肯定有一个compression core处于空闲状态


Based on what Venspec-U mentioned—that LR and HR calibration occur at the same time—does this mean that Venspec-U requires two SpW links to transfer data to DHU? Because in our Pre-EM design, each channel only has one SpW port. If that is the case, we need to add an extra SpW port.

Conversely, as we discussed yesterday regarding the memory controller, if Venspec-U only transfers raw data through one SpW link, then in our consideration of the memory controller's concurrent access to SDRAM concerning Venspec-U-related data, there is no need to consider the problem of two compression cores simultaneously accessing SDRAM in the BIP-mem mode.

Because handling it this way, one of the compression cores for Venspec-U's LR and HR will definitely be idle.
