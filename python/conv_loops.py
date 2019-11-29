
import math

IMAGE_SIZE = 6
KERNEL_SIZE = 3
STRIDE_STEPS = 2
CHANNEL_COUNT = 3
GRADIENT_BITS = 8
NEURON_COUNT = 4
FEATURE_SIZE = 6
# FEATURE_SIZE = math.floor((IMAGE_SIZE-KERNEL_SIZE)/STRIDE_STEPS)+1

# for row_iter in range(1,FEATURE_SIZE+1):
#     for col_iter in range(1,FEATURE_SIZE+1):
#         for row in range(1,KERNEL_SIZE+1):
#             for column in range(1,KERNEL_SIZE+1):
#                 for channel in range(1,CHANNEL_COUNT+1):
#                     print('-'*20)
#                     print('Image:  (',STRIDE_STEPS*(row_iter-1)+row,',', STRIDE_STEPS*(col_iter-1)+column,')')
#                     print('Kernal: (', row,',', column,')')
#                     print('Feature:(', row_iter,',', col_iter,')')


# <= unsigned(Input_Image(GRADIENT_BITS * (channel + CHANNEL_COUNT * (column - 1) + CHANNEL_COUNT * IMAGE_SIZE * (row - 1)) - 1 downto 
#                         GRADIENT_BITS * (channel + CHANNEL_COUNT * (column - 1) + CHANNEL_COUNT * IMAGE_SIZE * (row - 1) - 1));
# Weights((neuron + (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * NEURON_COUNT) * GRADIENT_BITS - 1 downto 
#         (neuron + (channel + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * NEURON_COUNT - 1) * GRADIENT_BITS))
for row in range(1,FEATURE_SIZE+1):
    for column in range(1,FEATURE_SIZE+1):
        for channel in range(1,CHANNEL_COUNT+1):
            for neuron in range(1,NEURON_COUNT+1):
                print('-'*20)
                print('(',(neuron + ((channel-1) + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * NEURON_COUNT) * GRADIENT_BITS - 1,' downto', (neuron + ((channel-1) + ((column - 1) + (row - 1) * FEATURE_SIZE) * CHANNEL_COUNT) * NEURON_COUNT - 1) * GRADIENT_BITS,')')

