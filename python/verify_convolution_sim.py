
import torch
import math

# Convolution parameters to match testbench configuration
image_size      = 3
kernel_size     = 2
channels_in     = 3
gradient_bits   = 8
channels_out    = 1
stride_steps    = 1
zero_padding    = 0
relu_activation = 0

file_input  = open('/home/nate/UCLA/project/hdl/data/input_data.txt', 'r')
file_kernel = open('/home/nate/UCLA/project/hdl/data/kernel_data.txt', 'r')
file_output = open('/home/nate/UCLA/project/hdl/data/output_data.txt', 'r')

data_list = file_input.readlines()
input_data = torch.tensor([int(val) for val in data_list])
data_list = file_kernel.readlines()
kernel_data = torch.tensor([int(val) for val in data_list])
data_list = file_output.readlines()
output_data = torch.tensor([int(val) for val in data_list])

feature_size = int((image_size + 2 * zero_padding - kernel_size) / stride_steps + 1)
bits4sum = math.ceil(math.log2(kernel_size**2) - 1)
conv_batches = int(input_data.size()[0] / (channels_in * image_size**2))

input_array  = torch.zeros(conv_batches, 1,            channels_in,  image_size,  image_size)
kernel_array = torch.zeros(conv_batches, channels_out, channels_in,  kernel_size, kernel_size)
output_array = torch.zeros(conv_batches, channels_out, feature_size, feature_size)
output_check = torch.zeros(conv_batches, channels_out, feature_size, feature_size)

idx_i = 0
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
  output_check[batch] = (torch.nn.functional.conv2d(input_array[batch],kernel_array[batch]) / 2**(gradient_bits + bits4sum)).floor()

# Check whether VHDL testbench output matches PyTorch expected output
if (output_check == output_array).sum() == torch.tensor(output_check.size()).prod():
  print("Check Passed: Data matches.")
else:
  print("Check Failed: Data does not match.")


