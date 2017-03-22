/* mexUDPChars.c
 *
 * Matlab mex interface for converting UDP/IP sockets and sending and
 * receiving data of type char.
 *
 *  2010
 *  benjamin.heasly@gmail.com
 *	University of Pennsylvania
 *
 */

#include "mexUDP.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int status = 0;
    int nBytes = 0;
    static char bigByteBuffer[MEXUDP_MAX_DATAGRAM_LENGTH];
    void* mxData;
    
    // First argument should be a command string
    if(nrhs >= 1 && mxIsChar(prhs[0]) && mxGetM(prhs[0])==1) {
        mxGetString(prhs[0], bigByteBuffer, sizeof(bigByteBuffer));
        
        // second argument may be a socketID;
        int sockID = -1;
        if(nrhs>=2 && mxIsNumeric(prhs[1]))
            sockID = (int)mxGetScalar(prhs[1]);
        
        if(!strcmp(bigByteBuffer, "open")) {
            
            mexAtExit(mexUDP_closeAll);
            
            //  IP address args are short strings
            //  PORT args are numbers.
            if(nrhs>=4 && mxIsNumeric(prhs[3])
            && mxIsChar(prhs[1]) && mxIsChar(prhs[2])) {

                char *localIP = mxArrayToString(prhs[1]);
                char *remoteIP = mxArrayToString(prhs[2]);
                int localPort = (int)mxGetScalar(prhs[3]);
                
                // remote port is optional
                int remotePort;
                if(nrhs==5 && mxIsNumeric(prhs[4]))
                    remotePort = (int)mxGetScalar(prhs[4]);
                else
                    remotePort = localPort;
                
                // try to reuse an existing, matching socket
                status = mexUDP_find(localIP, remoteIP, localPort, remotePort);
                
                if(status < 0)
                    status = mexUDP_open(localIP, remoteIP, localPort, remotePort);
                
                //mexPrintf("mexUDP opened socket %d: %s:%d - %s:%d\n",
                //        status, localIP, localPort, remoteIP, remotePort);
                
                mxFree(localIP);
                mxFree(remoteIP);
                
            } else
                status = -10;
            
        } else if(!strcmp(bigByteBuffer, "sendBytes")) {
            
            if (mexUDP_isValidSocketIndex(sockID)) {
                
                // treat input as packed bytes, like uint8
                if(nrhs==3) {
                    nBytes = mxGetM(prhs[2]) * mxGetN(prhs[2]) * mxGetElementSize(prhs[2]);
                    if (nBytes <= sizeof(bigByteBuffer)) {
                        mxData = mxGetData(prhs[2]);
                        memcpy(bigByteBuffer, mxData, nBytes);
                        status = mexUDP_send(sockID, bigByteBuffer, nBytes);
                        
                    } else {
                        mexPrintf("input is too long to send (%d, max of %d)\n", nBytes, sizeof(bigByteBuffer));
                        status = -20;
                    }
                    
                } else
                    status = -30;
                
            } else
                status = -40;

        } else if(!strcmp(bigByteBuffer, "check")) {
            
            // optional timeout seconds, default to 0
            double timeoutSecs = 0;
            if(nrhs==3)
                timeoutSecs = mxGetScalar(prhs[2]);

            if (mexUDP_isValidSocketIndex(sockID))
                status = (int)(mexUDP_check(sockID, timeoutSecs) != 0);
            else
                status = -50;
            
        } else if(!strcmp(bigByteBuffer, "receiveBytes")) {
            
            if (mexUDP_isValidSocketIndex(sockID)) {
                
                nBytes = mexUDP_receive(sockID, bigByteBuffer, sizeof(bigByteBuffer));
                if(nBytes > 0) {
                    // treat data as individual bytes, uint8
                    plhs[0] = mxCreateNumericMatrix(1, nBytes, mxUINT8_CLASS, mxREAL);
                    mxData = mxGetData(plhs[0]);
                    memcpy(mxData, bigByteBuffer, nBytes);
                    
                } else
                    plhs[0] = mxCreateNumericMatrix(0, 0, mxUINT8_CLASS, mxREAL);
                
                return;
                
            } else
                status = -60;
            
        } else if(!strcmp(bigByteBuffer, "close")) {
            
            if (mexUDP_isValidSocketIndex(sockID))
                status = mexUDP_close(sockID);
            else
                status = 0;
            
        } else if(!strcmp(bigByteBuffer, "closeAll")) {
            
            mexUDP_closeAll();
            status = 0;
            
        } else {
            
            mexPrintf("unknown subcommand, %s\n", bigByteBuffer);
            status = -1000;
        }
        
        // all subcommands return int status
        // except receive, which returns above
        plhs[0] = mxCreateDoubleScalar((double)status);
        
    } else {
        mexPrintf("mexUDP usage:\n %s\n %s\n %s\n %s\n %s\n %s\n",
                "id = mexUDP('open', localIP, remoteIP, localPort [, remotePort])",
                "status = mexUDP('sendBytes', id, data)",
                "hasData = mexUDP('check', id [, timeoutSeconds])",
                "data = mexUDP('receiveBytes', id)",
                "status = mexUDP('close', id)",
                "status = mexUDP('closeAll')");
        return;
    }
}