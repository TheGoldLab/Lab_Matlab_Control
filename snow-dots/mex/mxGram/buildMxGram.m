% Script to build the mex function "mxGram".
%   mexBytesmxGram can convert a Matlab array into a string of bytes and
%   return the bytes in an array of type uint8.  Can convert such a uint8
%   array back into a regular Matlab array.

mex mxGramInterface.c mxGram.c -output mxGram