
********************************
FPGA NN Inference Project Report
********************************

Introduction
============

Machine learning (ML) has been increasing in popularity as of late due to technilogical advancements in available processing power. Although concepts of ML and, more specifically, deep neural networks (DNN) are not exactly new, it has only been in the last decade or so that these techniques have become practical solutions for real-world problems. A large number of tools have been created and made available by various organizations that provide an accessible framework for the development of neural networks (NN) such as TensorFlow, Caffe, and PyTorch. These frameworks provide the tools needed in order to quickly implement NNs on a central processing unit (CPU) or graphics processing unit (GPU) if supported. As of late, GPUs have been the goto processing resource for implementing ML models and algorithms due to the large number of processing cores it contains. Modern-day GPUs can have thousands of processing cores to enable massive parallelization of single instruction multiple data (SIMD) type calculations. Although GPUs have been greatly beneficial for the advancement of DNN performance, they come with a few drawbacks. First, GPUs consume large amounts of energy and are thus particularily limited in mobile and other low-power applications. Second, the development of NNs on GPUs requires the use of an application programming interface (API) which provides access to parallel processing capabilites for general purpose use cases. This extra layer of abstraction from the hardware reduces the maximum achievable hardware efficiency and increases energy consumption. Most popular is NVIDIA's CUDA platform which provides developers with a comprehensive library for NN support on NVIDIA GPUs. NVIDIA's active development in the CUDA framework and its features will no doubt make improvements on performance and efficiency. Due to the static nature of a GPU's architecture, however, there exists a fundamental limitation to the achievable utilization of hardware and its efficiency.

This leads in to the purpose of this project which is to explore the topic of neural network inference using field-programmable gate arrays (FPGA). Unlike GPUs, FPGAs are configured at a much lower hardware logic level for the purpose of accelerating specific tasks. FPGAs can be quickly and easily reconfigured for any application changes. The ability to describe very specific digital circuits means there is no need for an extra layer of software for development. 

The primary application of NN models covered in this effort will be for image recognition and will focus primarily on convolutional neural networks (CNN). The first part of this report will summarize the current state of research and the advancements that have been made for FPGA inference. The project also seeks to determine whether FPGAs have the potential to compete as an effective alternative to GPUs. Metrics of evaluation include cost, peak performance capability, energy efficiency (or performance density), and additional advantageous features such as adaptability. The report will break down the various components used in a NN model and describe how they become implemented in programmable logic (PL). These components include convolutional, fully-connected, pooling, and non-linear units. Outside of the NN itself are supporting PL components such as a direct memory access (DMA) engine, a control unit (CU), and a memory-mapped interface to the processing system (PS). Additional supporting components may be added depending on the implementation architecture of the model.

Due to the modular nature of a NN with all its independently functioning components, people have been able to construct generic modules that can scale in size, be re-ordered, and even be swapped out for others. These hardware description language (HDL) modules take in parameters pre-synthesis that are used to define compatible interfaces and desired functionality for a specific design. There already exists a number of tools capable of auto-generating HDL for realizing NN models in PL. Some tools require the user to describe the model in a higher level language while others don't require any programming at all. This is important since most software developers and scientists using ML in their work are not too familiar with HDL design. In addition, describing a NN design from scratch using HDL would be an arduous process even for an experienced digital designer. The development of these tool-flows and libraries is an important step forward in reducing the barrier to entry for FPGA use in ML applications. We will briefly explore the various tool-flows currently available that provide auto-generation of synthesizable code for building NN models.


Components
==========

Convolutional Block
-------------------

Colored images consist of a grid of pixels where each pixel has three associated intensity values for red, green, and blue (RGB). Thus we we describe colored images as having three channels. It is common today for these color values to be 8-bits in size for each, which provides an intensity range from 0 to 255 for each color. All the different shades and colors we view on a screen are thus represented using 24-bits for each pixel. For example, a small 10x10 RGB image would have 100 pixels and the image would consist of 300 8-bit values. For machine learning, we describe these types of images as having three channels. You can visualize it as three grids, one for each color channel.

The convolution operation consists primarily of the multiply-accumulate (MAC) operation. The trained weights of a CNN are realized using what is called a "kernel"; basically just a two-dimensional grid of weights. This grid of weights is superimposed upon a portion of the input image and is iteratively moved across the entire image. For each iterative location of the kernel, the image grid and kernel grid are elementwise multiplied with one another. The resulting product from each element is then summed together to produce a single output value for that iteration. For the next iteration the kernel is shifted over the image by one or more grid spaces (pixels) such that it covers a slightly different section of the input image. This process is repeated for the entire area of the image and will produce a new output grid of values which can be referred to as a "feature map". This feature map will then be available for the next layer in the NN design. 

Implementing a convolution function in hardware is computationally expensive and will require a fair amount of processing resources. Convolution operations will typically consume the majority of the CPU/GPU processing time when working with CNN models. It is intuitive then that the convolution operations will occupy the majority of the utilized logic resources when implementing a CNN in an FPGA. 

Break down conv fpga implementation design and resource usage. How are kernel weights loaded?

Notice that convolutional blocks used in NN designs are for the most part all very similar if not identical. The only differences would be parameters such as input and kernel size as well as other settings such as zero padding widths and stride size. These blocks therefor have a high potential for modularity. A generic convolution block can be described in HDL just once and then be instantiated as many times as needed. By using generic inputs during instantiation, block parameters are determined pre-synthesis allowing for various types of convolutional operations. 
Talk about the use of modularity. Instantiations of a generic convolutional block. How this can be used for auto-generation of HDL to describe a CNN.

Discuss the proposed implementation architectures in other papers

Pooling Block
-------------

Non-Linear Activation Block
---------------------------

Fully Connected Block
---------------------

Architecture
============


FPGA vs. GPU
============


Techniques for Improved Efficiency
==================================


Available Toolflows
===================


Custom Design and Implementation
================================


Performance Evaluation
======================


Direction of Future Work
========================


Conclusion
==========
