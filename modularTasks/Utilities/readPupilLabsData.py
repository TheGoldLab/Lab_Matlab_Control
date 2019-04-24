import sys
import scipy.io as scpy   
import numpy as np
import msgpack

from file_methods import *

#Python Script to read Eye Data, extract desired information and then create a .mat structure where rows are times, columns are:
    #  1. timestamp
    #  2. gaze x
    #  3. gaze y
    #  4. confidence

#input: 
    #sys.argv[1]: the filepath to the datafile
    #sys.argv[2]: the desired name of the newly created .mat structure


# Use pupil-labs function to load data
data = load_pldata_file(sys.argv[1], sys.argv[2])

# Make matrix with samples as rows, columns as below
raw_data = np.zeros((len(data.data),6),dtype=np.object)

for q in range(len(data.data)):
    raw_data[q][0] = data.data[q]['timestamp']
    raw_data[q][1] = data.data[q]['norm_pos'][0]
    raw_data[q][2] = data.data[q]['norm_pos'][1]
    raw_data[q][3] = data.data[q]['confidence']
    try:
        raw_data[q][4] = data.data[q]['base_data'][0]['diameter']
        raw_data[q][5] = data.data[q]['base_data'][1]['diameter']
    except IndexError:
        if data.data[q]['base_data'][0]['topic'] == 'pupil.0':
            raw_data[q][4] = data.data[q]['base_data'][0]['diameter']
            raw_data[q][5] = -1
        else:
            raw_data[q][4] = -1
            raw_data[q][5] = data.data[q]['base_data'][0]['diameter']

# save in temporary file
scpy.savemat(sys.argv[3] +'.mat', {sys.argv[3]:raw_data})