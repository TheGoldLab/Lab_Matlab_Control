/* mexUDP.h
 *
 * mexUDP defines a few c-routines for managing multiple UDP sockets which
 * Matlab can use and reference by index.
 *
 *	BSH 20 Jan 2006
 *  BSH 18 Nov 2009
 *  BSH 11 Feb 2010
 */

#ifndef _MEX_UDP_H_
#define _MEX_UDP_H_

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/time.h>
#include <math.h>

#include "mex.h"

// may be platform dependent, roughly the max datagram length
#define MEXUDP_MAX_DATAGRAM_LENGTH 8192
#define MEXUDP_MAX_NUM_SOCKETS 512

static int                  mexUDP_numSockets=0;
static int                  mexUDP_sockets[MEXUDP_MAX_NUM_SOCKETS];
static struct sockaddr_in   *mexUDP_remoteAddresses[MEXUDP_MAX_NUM_SOCKETS];
static int                  mexUDP_addressSize=sizeof(struct sockaddr);

int mexUDP_open(char* localIP, char* remoteIP, int localPort, int remotePort);
int mexUDP_find(char* localIP, char* remoteIP, int localPort, int remotePort);
int mexUDP_send(int sock, char* message, int messageLength);
int mexUDP_check(int sock, double timeoutSecs);
int mexUDP_receive(int sock, char* message, int messageLength);
int mexUDP_close(int sock);
void mexUDP_closeAll();

int mexUDP_isValidSocketIndex(int sock);

#endif
