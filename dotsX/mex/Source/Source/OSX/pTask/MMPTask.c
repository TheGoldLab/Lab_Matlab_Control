/*
 *  MMPTask.c
 *  LabTools MATLAB mex file
 *
 *	 Prefix: PT
 *
 *  Created by jigold on Mon Dec 29, 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 */


/* Data Types */
#define MAX_CMD_NAME_LENGTH 30
typedef struct {
	char command[MAX_CMD_NAME_LENGTH];
	void (*routine) ();
} dispatch_table_entry;

// REGISTER NEW COMMANDS HERE
extern void XorDots(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[]);

static dispatch_table_entry dispatch_table[] = {
	{"XorDots",  (void *) (&XorDots)  }};
	
// number of registered commands
#define NUMBER_COMMANDS (sizeof(dispatch_table)/sizeof(dispatch_table_entry))



 pTask('makeArray', 'aname', 'vname1', val1, 'vname2', val2, NULL)
 ptr = pTask('init')
 pTask('addTask', ptr, 'name', vara1 'name1', vara2, 'name2', NULL)
 pTask('makeTC1', ptr, 'task_name', 'tc_name', start, step, num)
 pTask('makeTC2', ptr, 'task_name', 'tc_name', start1, step1, num1, start2, step2, num2)
 pTask('nextTrial', ptr, flag?)
v = pTask('getVar', ptr, 'aname', 'vname')
[]= pTask('getArray', ptr, 'aname')
ptask('setScore', ptr, score)
[]=pTask('getScores', ptr)
 pTask('Clear', ptr)
 pTask('Free', ptr)
 
 
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	
    /* check for too many input arguments */
    if(nrhs > 4)
        mexErrMsgTxt("Too many inputs\n");
           
    /* First argument is aw_server (full path) */
    if((nrhs >= 1) && mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1 &&
        mxIsChar(prhs[0])) {
        buflen =  mxGetN(prhs[0]) + 1;
        server = mxCalloc(buflen, sizeof(char));
        if(status = mxGetString(prhs[0], server, buflen))
            mexWarnMsgTxt("Not enough space. String is truncated.");
    } else {
        buflen = strlen(DEFAULT_SERVER) + 1;
        server = mxCalloc(buflen, sizeof(char));
        status = sprintf(server, "%s", DEFAULT_SERVER);
    }
    
    /* Second argument is number of channels .. ignore it if not a scalar */
    if(nrhs >= 2 && mxIsDouble(prhs[1]) && mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 1) {
        num_channels = mxGetScalar(prhs[1]);
        if(num_channels < 1)
            num_channels = 1;
        else if(num_channels > 16)
            num_channels = 16;
    }

