import sys
import scipy.io as scpy   
import numpy as npy
import msgpack

#Python Script to read Eye Data, extract desired information and then create a .mat structure where rows are times, columns are:
   	#  1. timestamp
    #  2. gaze x
    #  3. gaze y
    #  4. confidence

#input: 
    #sys.argv[1]: the filepath to the datafile
    #sys.argv[2]: the desired name of the newly created .mat structure


#paths for quick access while debugging:
#"Raw_Data/data_2018_06_19_10_48_eye/data_2018_06_19_10_48_eye/000/pupil_data"
#"Raw_Data/data_2018_06_25_07_47_eye/data_2018_06_25_07_47_eye/000/pupil_data"
#with open("Raw_Data/data_2018_06_19_10_48_eye/data_2018_06_19_10_48_eye/000/pupil_data", "rb") as f:
with open("%s" % (sys.argv[1]), "rb") as f:
    data = msgpack.unpack(f, encoding='utf-8')

#creates vector in python of len(data["gaze_positions"]) rows and 4 columns
raw_data = npy.zeros((len(data["gaze_positions"]),4), dtype=npy.object)

for q in range(len(data["gaze_positions"])):
	raw_data[q][0] = data["gaze_positions"][q]["timestamp"]
	raw_data[q][1] = data["gaze_positions"][q]["norm_pos"][0] 
	raw_data[q][2] = data["gaze_positions"][q]["norm_pos"][1]
	raw_data[q][3] = data["gaze_positions"][q]["confidence"]

scpy.savemat(sys.argv[2] +'.mat', {sys.argv[2]:raw_data})