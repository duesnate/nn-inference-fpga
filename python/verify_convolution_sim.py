
import torch
import math

file_input = open('/home/nate/UCLA/project/hdl/data/input_data.txt', 'r')
file_kernel = open('/home/nate/UCLA/project/hdl/data/kernel_data.txt', 'r')
file_output = open('/home/nate/UCLA/project/hdl/data/output_data.txt', 'r')

data_list = file_input.readlines()
input_data = torch.tensor([int(val) for val in data_list])
data_list = file_kernel.readlines()
kernel_data = torch.tensor([int(val) for val in data_list])
data_list = file_output.readlines()
output_data = torch.tensor([int(val) for val in data_list])

image_size    = 3
kernel_size   = 2
channels_in   = 3
gradient_bits   = 8
channels_out  = 1
stride_steps  = 1
zero_padding  = 0
relu_activation = 0

feature_size = int((image_size + 2 * zero_padding - kernel_size) / stride_steps + 1)
bits4sum = math.ceil(math.log2(kernel_size**2) - 1)
conv_batches = int(input_data.size()[0] / (channels_in * image_size**2))

input_tensor = torch.zeros(conv_batches, 1, channels_in, image_size, image_size)
kernel_tensor = torch.zeros(conv_batches, channels_out, channels_in, kernel_size, kernel_size)
output_tensor = torch.zeros(conv_batches, channels_out, feature_size, feature_size)
output_py = torch.zeros(conv_batches, channels_out, feature_size, feature_size)

idx_i = 0
idx_k = 0
idx_o = 0
for batch in range(conv_batches):
  for row in range(image_size):
    for col in range(image_size):
      for chn in range(channels_in):
        input_tensor[batch, 0, chn, row, col] = input_data[idx_i]
        idx_i += 1
  for row in range(kernel_size):
    for col in range(kernel_size):
      for chn_o in range(channels_out):
        for chn_i in range(channels_in):
          kernel_tensor[batch, chn_o, chn_i, row, col] = kernel_data[idx_k]
          idx_k += 1
  
  output_py[batch] = (torch.nn.functional.conv2d(input_tensor[batch],kernel_tensor[batch]) / 2**(gradient_bits + bits4sum)).floor()

  for row in range(feature_size):
    for col in range(feature_size):
      for chn in range(channels_out):
        output_tensor[batch, chn, row, col] = output_data[idx_o]
        idx_o += 1

if torch.tensor(output_py.size()).prod() == (output_py == output_tensor).sum():
  print("Data matches.")
else:
  print("Error: Data does not match.")


