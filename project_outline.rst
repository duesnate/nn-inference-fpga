
Machine Learning on FPGAs
-------------------------

**Objectives**

* Summarize where research and technology currently stands in regards to DNN implementation on FPGAs while primarily focusing on algorithms for image recognition.
* Describe what common components comprise a DNN.
* Explore the various FPGA logic architectures that have been developed to describe these components.
* Highlight the advantages and disadvantages of using FPGAs for machine learning in comparison to other popular hardware such as GPUs.
* Examine the techniques used for increasing implementation efficiency and the corresponding trade-offs to consider. How are the advantages of FPGAs leveraged to improve this efficiency?
* Examine the high-level tool-flows that are currently available for auto generation of DNNs on FPGAs.
* Implement a selection of the algorithms and techniques described in this research.
* Create a metric for evaluating the performance of these implementations.
* Propose new methods for inference on FPGAs or highlight possible areas of improvement upon past research.


**Fundamental Algorithms**

* Multilayer Perceptron (MLP)
* Convolutional Neural Network (CNN)
* Recurrent Neural Network (RNN)
* Binarized Neural Network (BNN)
  - Full / Partial
  - XNOR-Net


**Popular Designs**

* LeNet
* AlexNet
* VGG
* GoogleNet
* ResNet
* Inception


**Data Sets**

* MNIST Handwritten Digits
* CIFAR-10/100
* SVHN: Street View House Numbers
* ImageNet


**FPGA Advantages**

* Large OCM (alleviates throughput bottlenecks)
* Data-type flexibility
* Reconfiguration at runtime
* Energy efficiency


**FPGA Disadvantages**

* Frequency capped around 100-300 MHz
* Large amount of logic overhead for reconfigurability
* Steep development learning curve
* 


**Implementation Metrics**

* Latency
* Initiation Interval (inversely proportional to throughput)
* Resource Utilization


**Efficiency Techniques**

* Compression
* Quantization
* Parallelization
* Folding (time-multiplexing)


**SoC Architecture**

* Ethernet - Data loading
* Memory Mapping - Interfacing PL and PS
* DMA - Memory storage
* OS? FreeRTOS or Linux


**DNN Components**

* Convolutional Layer
* Fully Connected Layer
* Activation Functions: Sigmoid, Tanh, ReLu
* Pooling Layer
* Local Response Normalization (LRN)
* Classifiers: SoftMax
* BNN Specific
  - Batchnorm-activation
  - Max-pooling using OR-operator
  - Popcount for accumulation
  - Matrix-Vector-Threshold Unit (MVTU)

Yellow: Key topics and related points
Blue: Look into this further
Orange: Directly applicable supporting information
Green: Specific technical strategies

**Notes [4]: Toolflows for Mapping CNNs on FPGAs: A Survey and Features**

* Most applicable toolchains:

  - DNNWEAVER
  - HADDOC2 (No time-sharing / unrolling, thus too resource heavy)
  - AutoCodeGen
  - Deep-Burning
  - Angel-Eye
  - Snowflake


**Notes [5]: A Survey of FPGA-Based Neural Network Inference Accelerator**

* FC and CONV layers typically consume more than 99% of the total used computation and storage resources.
* Using SoCs, NN are typically implemented in the PL and controlled using the PS.
* FPGAs are typically used for pre-trained inference NN. Can/should we use FPGAs for training too?
* Increase performance:

  - More computation units: reduce unit size, reduce precision (may reduce accuracy)
  - Increase utilization efficiency: parallelism, time-multiplexing, efficient memory/ocm use and scheduling.
  - Increase working frequency
  - Sparsification: settings more wieghts to zero.

* Latency = (parallel inferences) / (system throughput)
* Energy Efficiency = (operations) / (energy)
* Compression:

  - Searching a good network structure.
  - Skipping layers at runtime.
  - Quantization of weights and activations.
  - Linear-quantization: nearest fixed-point representation (suffers over/under-flow).
  - Non-linear-quantization: cluster weight values and assign to binary codes, potential for up to 16x model size compression with little or no loss in accuracy.

* Weight Reduction:

  - Approximate weight matrix using low-rank representation (SVD) providing 4x improvement and <1% accuracy loss.
  - Pruning: remove zero weights, apply L1 normalization to weights during training, up to 10x speed improvement.

* Hardware architecture design: computation unit level, loop unrolling level, system level
* Computation units objective: small, more quantity, high clock rate

  - Small CU using low bit-width
  - Non-linear quantization: factorized coeff based dot product
  - FC layers can use smaller bit-width than CONV layers while maintaining accuracy
  - Using a single DSP for multiple low bit-width multiplications simultaneously

* Fast Convolution:

  - Discrete Fourier Transformation (DFT) based fast convolution
  - "block-wise circular constraint" converting multiplication in FC layers to 1D convolutions to be accelerated in frequency domain.
  - Frequency domain methods require complex-number multiplication
  - Winograd algorithm uses only real number multiplication

* Frequency Optimization:

  - Working frequency limited to routing between SRAM and DSP (700-900 MHz)
  - Xilinx CHaiDNN-v2, xfDNN

* Loop Unrolling:

  - For increasing hardware utilization for 
  - ESE architecture for sparse LSTM network acceleration
  
* Roofline Model:

  - The two primary limiting factors for NN accelerator designs are computation resources and off-chip memory bandwidth.
  - Computation to communication (CTC) ratio

* Loop Tiling and Interchange
* Cross-Layer Scheduling
* Regularize Data Access Patterns

  - Regularize DDR access patterns to increase memory bandwidth using feature map formats such as NCHW or CHWN

    + N: Batch dimension
    + C: Channel dimension
    + H, W: Feature map y and x dimension

* Look into 6x6 Winograd fast convolution
* FPGA vs. GPU

  - Paper claims: Combining all the best techniques can theoretically provide 72TOP/s with 50W, 10x higher efficiency than 32-bit float equivalent design on a GPU.
  - Techniques: double MAC, sparsification, quantization, fast convulution, double frequency design
  - The main issues are incorporating all these techniques together in a single design and solving irregular data access patterns for sparse networks

* Other proposed ideas:

  - Depth-wise convolution
  - complex branch in single shot [multi-box] detector (SSD)
  - TVM uniform mapping optimization framework
  - Instruction based methods of switching networks by loading new parameter data. Does not modify hardware
  - Mixed methods


**Ideas**

* Quantize multiplication weights by powers of 2 (binary shift)
* Network with multiple (3?) multi-layer CNN designs that are then weighted and combined before the FC layers. Weights will vary with dependence related to the input. This allows an optimal CNN design to be used for the various input images. Think Kalman-filters.


**References**

1. `FINN: A Framework for Fast Scalable Binarized Neural Network <https://arxiv.org/pdf/1612.07119.pdf>`_
2. `VHDL Generator for a High Performance Convolutional Neural Network FPGA-Based Accelerator <https://ieeexplore.ieee.org/document/8279827>`_
3. `Fast inference of deep neural networks in FPGAs for particle physics <https://arxiv.org/pdf/1804.06913.pdf>`_
4. `Toolflows for Mapping Convolutional Neural Networks on FPGAs: A Survey and Future Directions <http://delivery.acm.org/10.1145/3190000/3186332/a56-venieris.pdf?ip=104.172.28.204&id=3186332&acc=OA&key=4D4702B0C3E38B35%2E4D4702B0C3E38B35%2E4D4702B0C3E38B35%2E2972FD4B0DB409AC&__acm__=1570327531_2905a0d5a63758f18977c909ec032ed9>`_
5. `A Survey of FPGA-Based Neural Network Inference Accelerator <https://arxiv.org/pdf/1712.08934.pdf>`_
6. `Accelerating DNNs with Xilinx Alveo Accelerator Cards <https://www.xilinx.com/support/documentation/white_papers/wp504-accel-dnns.pdf>`_
7. `A Survey of the Recent Architectures of Deep Convolutional Neural Networks <https://arxiv.org/pdf/1901.06032.pdf>`_
8. `A guide to convolution arithmetic for deep learning <https://arxiv.org/pdf/1603.07285.pdf>`_

