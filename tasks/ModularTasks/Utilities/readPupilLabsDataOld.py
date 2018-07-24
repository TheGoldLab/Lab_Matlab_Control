import sys
import msgpack
import scipy.io as io

with open("%s" % (sys.argv[1]), "rb") as f:
    data = msgpack.unpack(f, encoding='utf-8')
io.savemat(sys.argv[2], data) # Warning: takes a lot of time

