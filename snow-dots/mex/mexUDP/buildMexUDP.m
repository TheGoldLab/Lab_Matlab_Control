% Script to build the mex function "mexUDP".
%   mexUDP can open, close, use UDP/IP sockets with the matUDP
%   functions.  It knows how to send and receive data of type char, only.

mex mexUDPInterface.c mexUDP.c -output mexUDP