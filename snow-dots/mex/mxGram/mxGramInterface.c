/* mxGramInterface.c
 *
 * Matlab mex interface for converting mxArrays into arrays of bytes
 * (uint8) and back.
 *
 *  2010
 *  benjamin.heasly@gmail.com
 *	University of Pennsylvania
 *
 */

#include "mxGram.h"

// may be platform dependent, roughly the max length of a UDP datagram
#define MAX_NUM_BYTES 8192

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    static char bigByteBuffer[MAX_NUM_BYTES];
    char* byteData;
    int nBytes = 0;
	int nBytesRead = 0;
    mxArray *newMex;
    
    // just for "test" case
    int ii;
    MX_GRAM_UINT16 testInt;
	MX_GRAM_UINT16 readInt;
    double testDoubles[] = {-6000, -1.1, 0, 1.1, 6000, 3.14159265358979};
    int n = sizeof(testDoubles)/sizeof(testDoubles[0]);
    double readDouble;
    
    if(sizeof(double) != 8) mexPrintf("\n\nThis platform does not use 8-byte doubles--a problem\n\n");
    
    if(nrhs > 0 && mxIsChar(prhs[0])){
        mxGetString(prhs[0], bigByteBuffer, sizeof(bigByteBuffer));
        
        if(!strcmp(bigByteBuffer, "mxToBytes") && nrhs==2) {
            
            nBytes = mxToBytes(prhs[1], bigByteBuffer, sizeof(bigByteBuffer));
            if (nBytes > 0) {
                plhs[0] = mxCreateNumericMatrix(1, nBytes, mxUINT8_CLASS, mxREAL);
                byteData = mxGetData(plhs[0]);
                memcpy(byteData, bigByteBuffer, nBytes);
                plhs[1] = mxCreateDoubleScalar(nBytes);
                
            } else {
                plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT8_CLASS, mxREAL);
                plhs[1] = mxCreateDoubleScalar(-1);
            }
            
        } else if (!strcmp(bigByteBuffer, "bytesToMx") && nrhs==2) {
            
            nBytes = mxGetM(prhs[1]) * mxGetN(prhs[1]);
            if (nBytes > 0 && nBytes <= sizeof(bigByteBuffer)) {
                byteData = mxGetData(prhs[1]);
                memcpy(bigByteBuffer, byteData, nBytes);
                
                nBytesRead = bytesToMx(&newMex, (const char *)bigByteBuffer, nBytes);
                if (nBytesRead > 0) {
                    plhs[0] = newMex;
                    plhs[1] = mxCreateDoubleScalar(nBytesRead);
                    
                } else {
                    plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
                    plhs[1] = mxCreateDoubleScalar(-2);
                }
                
            } else {
                plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
                plhs[1] = mxCreateDoubleScalar(-3);
            }
            
        } else if (!strcmp(bigByteBuffer, "test")) {
            
            mexPrintf("Sanity test for uint16:\n\n");
            for (ii=0; ii<65536; ii+=100) {
                testInt = ii;
                writeInt16ToBytes(testInt, bigByteBuffer);
                readInt = readInt16FromBytes(bigByteBuffer);
                mexPrintf("%u -> %u %u -> %u\n",
                        (MX_GRAM_UINT16)testInt,
                        (MX_GRAM_UINT8)bigByteBuffer[0], (MX_GRAM_UINT8)bigByteBuffer[1],
                        (MX_GRAM_UINT16)readInt);
            }
            mexPrintf("\n");
            
            mexPrintf("Sanity test for double:\n\n");
            for (ii=0; ii<n; ii++) {
                writeDouble64ToBytes(testDoubles[ii], bigByteBuffer);
                readDouble = readDouble64FromBytes(bigByteBuffer);
                mexPrintf("%.15f -> %.15f\n",
                        testDoubles[ii],
                        readDouble);
            }
        }
        
    } else {
        
        mexPrintf("mxGram usage:\n %s\n %s\n",
                "[uint8Array, status] = mxGram('mxToBytes', variable)",
                "[variable, status] = mxGram('bytesToMx', uint8Array)");
        
    }
}

