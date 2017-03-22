/* mexUDP.c
 *
 * mexUDP defines a few c-routines for managing multiple UDP sockets which
 * Matlab can use and reference by index.
 *
 *	BSH 20 Jan 2006
 *  BSH 18 Nov 2009
 *  BSH 11 Feb 2010
 */

#include "mexUDP.h"

int mexUDP_open(char* localIP, char* remoteIP, int localPort, int remotePort) {
    
    struct sockaddr_in LOCAL_addr;
    struct protoent *udpProto;
    int sockFD, sockID;
    
    memset(&LOCAL_addr, 0, sizeof(LOCAL_addr));
    LOCAL_addr.sin_family = AF_INET;
    LOCAL_addr.sin_port = htons(localPort);
    LOCAL_addr.sin_addr.s_addr = inet_addr(localIP);
    
    udpProto = getprotobyname("udp");
    sockFD = socket(PF_INET, SOCK_DGRAM, udpProto->p_proto);
    if (sockFD < 0) {
        mexPrintf("socket() failed with return %d, (google errno %d)\n", sockFD, errno);
        return(sockFD);
    }
    
    int status;
    status = bind(sockFD, (struct sockaddr *)&LOCAL_addr, mexUDP_addressSize);
    if (status < 0) {
        mexPrintf("failed to bind() local %s:%d (return=%d, errno=%d)\n", 
                localIP, localPort, status, errno);
        close(sockFD);
        return(status);
    }
    
    // now the socket should be fine, so keep it
    sockID = mexUDP_numSockets++;
    mexUDP_sockets[sockID] = sockFD;
    
    // store the message target
    mexUDP_remoteAddresses[sockID] = mxCalloc(1, sizeof(LOCAL_addr));
    mexMakeMemoryPersistent(mexUDP_remoteAddresses[sockID]);
    mexUDP_remoteAddresses[sockID]->sin_family = AF_INET;
    mexUDP_remoteAddresses[sockID]->sin_port = htons(remotePort);
    mexUDP_remoteAddresses[sockID]->sin_addr.s_addr = inet_addr(remoteIP);
    
    //mexPrintf("local = %s : %d\n", inet_ntoa(LOCAL_addr.sin_addr), ntohs(LOCAL_addr.sin_port));
    //mexPrintf("remote = %s : %d\n",inet_ntoa(mexUDP_remoteAddresses[sockID]->sin_addr),
    //        ntohs(mexUDP_remoteAddresses[sockID]->sin_port));
    
    return(sockID);
}

int mexUDP_find(char* localIP, char* remoteIP, int localPort, int remotePort) {
    
    struct sockaddr_in LOCAL_addr;
    int result, sockID;
    
    for(sockID=0; sockID<mexUDP_numSockets; sockID++) {
        result = getsockname(mexUDP_sockets[sockID],
                (struct sockaddr*)&LOCAL_addr,
                (unsigned int *)&mexUDP_addressSize);
        
        if(result<0) {
            //mexPrintf("local getsockname failed: %s (errno %d)\n", result, errno);
            continue;
        } else {
            //mexPrintf("local = %s : %d\n", inet_ntoa(LOCAL_addr.sin_addr), ntohs(LOCAL_addr.sin_port));
            if(strcmp(inet_ntoa(LOCAL_addr.sin_addr), localIP)
            || ntohs(LOCAL_addr.sin_port) != localPort)
                continue;
        }
        
        if(NULL==mexUDP_remoteAddresses[sockID]) {
            //mexPrintf("remote address missing\n");
            continue;
        } else {
            //mexPrintf("remote = %s : %d\n", inet_ntoa(mexUDP_remoteAddresses[sockID]->sin_addr),
            //        ntohs(mexUDP_remoteAddresses[sockID]->sin_port));
            if(strcmp(inet_ntoa(mexUDP_remoteAddresses[sockID]->sin_addr), remoteIP)
            || ntohs(mexUDP_remoteAddresses[sockID]->sin_port) != remotePort)
                continue;
        }
        
        // this is a match
        return(sockID);
    }
    // there was no match
    return(-1);
}

int mexUDP_send(int sockID, char* message, int messageLength) {
    
    int status;
    status = sendto(mexUDP_sockets[sockID], message, messageLength, MSG_DONTWAIT,
            (struct sockaddr *)mexUDP_remoteAddresses[sockID], mexUDP_addressSize);
    return(status);
}

int mexUDP_check(int sockID, double timeoutSecs) {
    
    static struct timeval timeout;
    static fd_set readfds;
    
    // reinitialize optional timeout, default to non-blocking
    if (timeoutSecs > 0) {
        double intPart = 0;
        double fracPart = modf(timeoutSecs, &intPart);
        timeout.tv_sec = (time_t)intPart;
        timeout.tv_usec = (suseconds_t)(1e6*fracPart);
        
    } else {
        timeout.tv_sec = 0;
        timeout.tv_usec = 0;
    }
            
    // reinitialize file descriptor
    FD_ZERO(&readfds);
    FD_SET(mexUDP_sockets[sockID], &readfds);
    
    // check for data at the socket
    select(mexUDP_sockets[sockID]+1, &readfds, NULL, NULL, &timeout);
    return(FD_ISSET(mexUDP_sockets[sockID], &readfds));
}

int mexUDP_receive(int sockID, char* message, int messageLength) {
    
    int length;
    length = recvfrom(mexUDP_sockets[sockID],
            message,
            messageLength,
            MSG_DONTWAIT,
            (struct sockaddr *)mexUDP_remoteAddresses[sockID],
            (unsigned int *)&mexUDP_addressSize);
    return(length);
}

int mexUDP_close(int sockID) {
    
    if(mexUDP_sockets[sockID] >=0) {
        //mexPrintf("closing socket %d\n", sockID);
        close(mexUDP_sockets[sockID]);
        mexUDP_sockets[sockID]=-1;
        
        if(mexUDP_remoteAddresses[sockID] != NULL) {
            mxFree(mexUDP_remoteAddresses[sockID]);
            mexUDP_remoteAddresses[sockID] = NULL;
        }
    }
    return(0);
}

void mexUDP_closeAll() {
    int sockID;
    for(sockID=0; sockID<mexUDP_numSockets; sockID++) {
        mexUDP_close(sockID);
    }
    mexUDP_numSockets = 0;
}

int mexUDP_isValidSocketIndex(int sock) {
    int isValid = (sock >=0) && (sock < mexUDP_numSockets);
    return(isValid);
}
