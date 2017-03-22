/* 
*	asl.c
 *	Matlab Mex file
 *
 * Makes a MATLAB mex file for reading data from the ASL eye-tracking
 *  device that is coming into the serial port
 * 
 *
 *  Created by jigold on Fri Jan 24 2005 from Jeff Law's modification
 *	of 	comm.c:	
 *		source for Matlab MEX file. Matlab interface to the serial ports
 *					Tom L. Davis
 *					created 3-27-04
 *
 *  27 Jan 2006		BSH improved error code handling for 'read' calls.
 *  9  Oct 2006		BSH relaxed error filtering to permit negative h and v values
 *	7  June 2007	BSH expanded data frame from 10 bytes to 12 bytes to accomodate frame_number
 *					as checked in asl software Serial Out Format dialog
 *
 */

#include "serialPort.h"
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#define DEFAULT_BUF_SIZE 8192 // size of the read and write buffers (increase if necessary).
#define FRAME_LENGTH 12 // number of bytes in a frame of data from eyetracker "serial out"

static void close_port(void);
static PORTINFO asl_port = {-1};

/* 
* as usage:
 *	 isActive = as('init', <buffer_size>),
 *	 new_samples = as('read', <num_samples>)
 *	 as('reset')
 *	 isActive = as('close')
 *		
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *command=NULL;
	int new_bytes=0, read_bytes=0;
	
	// If no arguments given, print usage string
	if(nrhs < 1) {
		mexPrintf("as usage:\n\t isActive = as('init', <buffer_size>),\n\t new_samples = as('read', <num_samples>)\n\t as('reset')\n\t isActive = as('close')\n");
		return;
	}
	
	// First argument is command string... get and convert to char *
	if(mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1 && mxIsChar(prhs[0])) {
		read_bytes =  mxGetN(prhs[0]) + 1;
		command = mxCalloc(read_bytes, sizeof(char));
		if(mxGetString(prhs[0], command, read_bytes))
			mexWarnMsgTxt("as: Not enough space. String is truncated.");
	} else {
		mexErrMsgTxt("as: First argument should be a string (command)");
	}
	
	// case on command string...
	if(!strncmp(command, "init", 3)) {

		// done with command
		mxFree(command);
		
		// register exit routine
		if(mexAtExit(close_port) != 0 ) {
			close_port();
			mexErrMsgTxt("as('init'): failed to register exit routine.");
	    }

		// check whether we already have the port open
		if(asl_port.fd == -1){

			// the last (optional) argument sets the size of the buffer
			if(nrhs == 2 && mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 1 && mxIsNumeric(prhs[1]))
				asl_port.bufSize = (int) mxGetScalar(prhs[1]);
			else
				asl_port.bufSize = DEFAULT_BUF_SIZE;

			// allocate the buffer
			if(!(asl_port.curBufPtr = asl_port.bufPtr = calloc(asl_port.bufSize, sizeof(char))))
				mexErrMsgTxt("as('init'): working buffer allocation failed.");
			
			// configure the port
			if(openSerialPort(1, &asl_port, "57600,n,8,1" ))
				mexErrMsgTxt("as('init'): could not open port.");
			
			//start adding data at duh
			asl_port.endBufPtr = asl_port.bufPtr;
		}
		
		//always return the port number
        if(!(plhs[0] = mxCreateDoubleScalar((double)asl_port.fd)))
            mexErrMsgTxt("as('init'): mxCreateNumericArray failed.");

		//mexPrintf("current port is <%s> with fd <%d>\n", asl_port.bsdPath, asl_port.fd);

	} else if(!strncmp(command, "read", 3)) {
	
		register int i;
		int n=0;
		unsigned char *inPtr, *headers[DEFAULT_BUF_SIZE];
		double *outPtr;
	
		// done with command
		mxFree(command);
		
		// find out how many bytes we should try to read
	    if((nrhs < 2) || ((read_bytes = (int) mxGetScalar(prhs[1])) > asl_port.bufSize-(int)(asl_port.endBufPtr-asl_port.bufPtr)))
			//free space left in buffer
			read_bytes = asl_port.bufSize-(int)(asl_port.endBufPtr-asl_port.bufPtr);
			
		// read the port buffer into our buffer
		if((new_bytes = (int) read(asl_port.fd, asl_port.endBufPtr+1, read_bytes)) == -1) {
			mexPrintf("Error reading serial port - %s(%d).\n", strerror(errno), errno);
			mexErrMsgTxt("as('read'): device read failed.");
		} else if (read_bytes == new_bytes) {
			mexPrintf("Possible overflow\n");
			
			//don't run off the buffer
			asl_port.endBufPtr = asl_port.bufPtr;

		} else {
			// point to last element of data
			asl_port.endBufPtr += new_bytes;
		}
		
		// flush the serial port queue of the data we just read
		if(flushPort(&asl_port))
			mexErrMsgTxt("as('read'): port flush failed.");

		// Scan the input buffer and find samples by header bytes--those with the first bit SET.
		// Only permit data that pass a 13-byte sanity mask
		for(inPtr=asl_port.bufPtr; inPtr<=asl_port.endBufPtr-(FRAME_LENGTH-1); inPtr++){

			if(*(inPtr)==0x80 && *(inPtr+1)<0x80 && *(inPtr+2)<0x80 && *(inPtr+3)==0x00
				&& *(inPtr+4)<0x80 && *(inPtr+5)==0x00 && *(inPtr+6)<0x80 && !(*(inPtr+7)&0x81)
				&& *(inPtr+8)<0x80 && *(inPtr+9)<0x80 && *(inPtr+10)<0x80 && *(inPtr+11)<0x08
				&& *(inPtr+FRAME_LENGTH)==0x80){
				
				//mexPrintf("head: %X\tsn: %X%x\tdiam: %X%x\tblank: %X\thorz: %X(%X)%x\tvert: %X%x(%X)\n",
				//	*(inPtr),*(inPtr+1),*(inPtr+2),*(inPtr+3),*(inPtr+4),*(inPtr+5),
				//	*(inPtr+6),*(inPtr+7),*(inPtr+8),*(inPtr+9),*(inPtr+10),*(inPtr+11));

				headers[n++] = inPtr;
				inPtr += FRAME_LENGTH-1;
			}
		}
		
		// Decode data if they exist
		if(n>0){
		
			// Create a matrix for the return data
			if(!(plhs[0] = mxCreateDoubleMatrix((mwSize)(n), (mwSize)4, mxREAL)))
				mexErrMsgTxt("as('read'): mxCreateDoubleMatrix failed.");

			// get a ptr to return matrix
			outPtr = mxGetPr(plhs[0]);

			// decode data following each good header byte
			for(i=0;i<n;i++,outPtr++) {
				inPtr = headers[i];

				//these 12 bytes have supposedly good data to decode.
				//cast data byte pairs as short to incorporate 16-bit two's complement signedness
				//frame numbers are unsigned
				//package as double because that's how MATLAB likes to roll

				*outPtr			= (short)((*(inPtr+3)|(*(inPtr+7)&0x08)<<4)<<8|*(inPtr+4)|(*(inPtr+7)&0x10)<<3); //pupil diam
				*(outPtr+n)		= (short)((*(inPtr+6)|(*(inPtr+7)&0x40)<<1)<<8|*(inPtr+8)|(*(inPtr+11)&0x01)<<7); //horz eye pos
				*(outPtr+(n*2))	= (short)((*(inPtr+9)|(*(inPtr+11)&0x02)<<6)<<8|*(inPtr+10)|(*(inPtr+11)&0x04)<<5); //vert eye pos
				*(outPtr+(n*3))	= (unsigned short)((*(inPtr+1)|(*(inPtr+7)&0x02)<<6)<<8|*(inPtr+2)|(*(inPtr+7)&0x04)<<5); //frame number
			}

			//move trailing bytes to start of buffer
			for(asl_port.curBufPtr=asl_port.bufPtr, inPtr=headers[n-1]+FRAME_LENGTH; inPtr<=asl_port.endBufPtr;)
				*(asl_port.curBufPtr++) = *(inPtr++);

			//point to the last data byte
			asl_port.endBufPtr = asl_port.curBufPtr-1;

		} else {
		
			// Create an empty matrix for the return "data"
			if(!(plhs[0] = mxCreateDoubleMatrix((mwSize)0, (mwSize)4, mxREAL)))
				mexErrMsgTxt("as('read'): mxCreateDoubleMatrix failed.");
		}
		
	} else if(!strncmp(command, "write", 3)) {

		// done with command
		mxFree(command);
		
		mexPrintf("as: Command is write\n");
		
	} else if(!strncmp(command, "reset", 3)) {
		
		// done with command
		mxFree(command);
		
		// flush read/write queues
		if(flushPort(&asl_port))
			mexErrMsgTxt("as('reset'): port flush failed.");

		asl_port.endBufPtr = asl_port.bufPtr;
		
	} else if(!strncmp(command, "close", 3)) {

		// done with command
		mxFree(command);
		
		// call die routine to close port, clear asl_port struct
		close_port();
		
		//always return the port number
        if(!(plhs[0] = mxCreateDoubleScalar((double)asl_port.fd)))
            mexErrMsgTxt("as('close'): mxCreateNumericArray failed.");

	} else {

		// done with command
		mxFree(command);
		
		mexErrMsgTxt("as: Unknown command");
	}
}

/* PRIVATE ROUTINE: close_port
 *
 * Close all ports if COMM gets cleared or MATLAB exits
*/
static void close_port(void)
{
	if(asl_port.fd != -1) {
		closeSerialPort(&asl_port);
		asl_port.fd = -1;
		free(asl_port.bufPtr);
		asl_port.bufPtr = NULL;
    }	
}