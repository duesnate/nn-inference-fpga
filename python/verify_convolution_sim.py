import torch
from torch import conv2d
import math

file_input  = open('/home/nate/UCLA/project/hdl/data/convolution/input_data.txt', 'r')
file_kernel = open('/home/nate/UCLA/project/hdl/data/convolution/kernel_data.txt', 'r')
file_output = open('/home/nate/UCLA/project/hdl/data/convolution/output_data.txt', 'r')

input_data  = torch.tensor([int(val) for val in file_input.readlines()])
kernel_data = torch.tensor([int(val) for val in file_kernel.readlines()])
output_data = torch.tensor([int(val) for val in file_output.readlines()])

# Load convolution parameters stored in input data file
image_size      = int(input_data[0])
channels_in     = int(input_data[2])
kernel_size     = int(input_data[1])
gradient_bits   = int(input_data[3])
channels_out    = int(input_data[4])
stride_steps    = int(input_data[5])
zero_padding    = int(input_data[6])
relu_activation = int(input_data[7])

feature_size = int((image_size + 2 * zero_padding - kernel_size) / stride_steps + 1)
bits4sum = math.ceil(math.log2(kernel_size**2) - 1)
conv_batches = int(input_data.size()[0] / (channels_in * image_size**2))

print('----------------------------------------')
print('Input Size:            ',image_size,'x',image_size,'x',channels_in)
print('Kernel Size:           ',kernel_size,'x',kernel_size,'x',channels_in,'x',channels_out)
print('Output Feature Size:   ',feature_size,'x',feature_size,'x',channels_out)
print('Resolution:            ',gradient_bits,'- bit')
print('Stride Steps:          ',stride_steps)
print('Zero Padding:          ',zero_padding)
print('ReLU Activation:       ',relu_activation)
print('Number of Batches:     ',conv_batches)

# Initialize multi-dimensional arrays
input_array  = torch.zeros(conv_batches, 1,            channels_in,  image_size,  image_size)
kernel_array = torch.zeros(conv_batches, channels_out, channels_in,  kernel_size, kernel_size)
output_array = torch.zeros(conv_batches, channels_out, feature_size, feature_size)
output_check = torch.zeros(conv_batches, channels_out, feature_size, feature_size)

idx_i = 8
idx_k = 0
idx_o = 0

# Cycle through all batches
for batch in range(conv_batches):
  # Store input data in multi-dimensional array
  for row in range(image_size):
    for col in range(image_size):
      for chn in range(channels_in):
        input_array[batch, 0, chn, row, col] = input_data[idx_i]
        idx_i += 1
  # Store kernel weights in multi-dimensional array
  for row in range(kernel_size):
    for col in range(kernel_size):
      for chn_o in range(channels_out):
        for chn_i in range(channels_in):
          kernel_array[batch, chn_o, chn_i, row, col] = kernel_data[idx_k]
          idx_k += 1
  # Store output data in multi-dimensional array
  for row in range(feature_size):
    for col in range(feature_size):
      for chn in range(channels_out):
        output_array[batch, chn, row, col] = output_data[idx_o]
        idx_o += 1
  
  # Use PyTorch convolution function to generate expected results
  conv2d_data = conv2d(input_array[batch], kernel_array[batch], padding=zero_padding, stride=stride_steps)
  # Scale down results to designated bit-width integers
  output_check[batch] = (conv2d_data / 2**(gradient_bits + bits4sum)).floor()

# Check whether VHDL testbench output matches PyTorch expected output
num_correct = (output_check == output_array).sum()
num_total = torch.tensor(output_check.size()).prod()
print('----------------------------------------')
if num_correct == num_total:
  print('Check Passed. All', int(num_total), 'data items match.')
else:
  print('Check Failed.', num_total-num_correct, 'out of', num_total, 'data items do not match.')
print('----------------------------------------')


