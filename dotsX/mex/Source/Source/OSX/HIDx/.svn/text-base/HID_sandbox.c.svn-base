#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/param.h>
#include <termios.h>

#include "mex.h"
#include "HID_Utilities_External.h"

void TestQueueCallback(void *target,IOReturn result,void *refcon,void *sender);
void TestReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize);

void HandleReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize);
void FlushReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize);
void cleanup();

#define DEFAULT_REPORT_SIZE 100
#define NUM_REPORTING_DEVICES 100
#define DEFAULT_NUM_REPORTS 100

typedef struct ReportStruct{
	int deviceIndex;
	int serialNumber;
	IOReturn error;
	UInt32 bytes;
	unsigned char report[DEFAULT_REPORT_SIZE];
} ReportStruct;

typedef struct dXptr{
	const char *class;
	int index;
	const char *prop;
} dXptr;

static CFRunLoopRef			myRunLoop;
static CFStringRef			myRunLoopMode;
static CFTimeInterval		myRunLoopTime;
static CFRunLoopSourceRef	source; 
static pRecDevice			device;
static IOHIDDeviceInterface122** interface;
static IOHIDQueueInterface** queue;
static unsigned char		rawBuffer[DEFAULT_REPORT_SIZE];
							
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *command=NULL;
	int buf_len;
	
	// If no arguments given, print usage string
	if(nrhs < 1) {
		mexPrintf("You can't 0 a sandbox\n");
		return;
	}
	
	// First argument is command string... get and convert to char *
	if(mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1 && mxIsChar(prhs[0])) {
		buf_len =  mxGetN(prhs[0]) + 1;
		command = mxCalloc(buf_len, sizeof(char));
		if(mxGetString(prhs[0], command, buf_len))
			mexWarnMsgTxt("sadbox heap error!");
	} else {
		mexErrMsgTxt("you can't 1 a sandbox without a string");
	}
	
	//mexPrintf("%s\n",command);
		
	// case on command string...
	if(!strncmp(command, "init", 3)) {

		// done with command
		mxFree(command);
		
		if(nrhs < 2) {
			mexPrintf("You can't 1 a sandbox init\n");
			return;
		}
		
		// register exit routine
		if(mexAtExit(cleanup) != 0 ) {
			cleanup();
			mexErrMsgTxt("failed to register exit routine, cleanup.");
		}

		int HIDID;
		if(mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 1 && mxIsDouble(prhs[1])) {
			HIDID = mxGetScalar(prhs[1]);
		} else {
			mexErrMsgTxt("you can't 2 a sandbox init without a hidID");
			return;
		}

		//use the CF run loop for the thread on which lpHID was initialized.
		myRunLoop=CFRunLoopGetCurrent();

		//use the default run mode or a custom lpHID mode?
		//myRunLoopMode=kCFRunLoopDefaultMode;
		myRunLoopMode=CFSTR("dotsXHIDCFRunLoopModekthxlalala");
		
		HIDBuildDeviceList(NULL,NULL);
		pRecDevice currentDevice;
		pRecElement elm;

		int i=0, result=99;
		for(currentDevice=HIDGetFirstDevice(); currentDevice != NULL; currentDevice=HIDGetNextDevice(currentDevice)){
			//display info for all HID devices
			
			if(HIDID==currentDevice->productID){
			
				mexPrintf("matched %s\n", currentDevice->product);
				i++;
				device = currentDevice;
				interface = device->interface;
				queue = (*interface)->allocQueue(interface);
				if(queue){
					result = (*queue)->create(queue, 0, 64);
					
					// add all elements to the queue
					//	later, keep track of cookies
					for(elm=HIDGetFirstDeviceElement(device, kHIDElementTypeIO); elm!=NULL; elm=HIDGetNextDeviceElement(elm, kHIDElementTypeIO)){
						result = (*queue)->addElement(queue, elm->cookie, 0);
						//mexPrintf("%d %d\n", (*queue)->hasElement(queue, elm->cookie), elm->cookie);
					}
					
					//fire up the queue
					result = (*queue)->start(queue);
					
					//create ASES
					result = (*queue)->createAsyncEventSource(queue, &source);
					
					//pass callback ref
					result = (*queue)->setEventCallout(queue, TestQueueCallback, NULL, queue);
					
					//hook up with runloop
					CFRunLoopAddSource(myRunLoop, source, myRunLoopMode);
					
				}
			break;
			}
		}

		mexPrintf("found %d matching HID devices\n", i);
		
	} else if(!strncmp(command, "read", 3)) {

		// done with command
		mxFree(command);
		
		if(nrhs>1){
			myRunLoopTime = (CFTimeInterval)mxGetScalar(prhs[1]);
			CFRunLoopRunInMode(myRunLoopMode,myRunLoopTime,false);
		} else {
			myRunLoopTime = (CFTimeInterval)1.00;
			CFRunLoopRunInMode(myRunLoopMode,myRunLoopTime,true);
		}
		
	} else if(!strncmp(command, "put", 3)) {

		// done with command
		mxFree(command);
		
		if(nrhs>3) {
		
		// get classname, index, property, value
		static mxArray *rhs[3];
		rhs[0] = mxDuplicateArray(prhs[1]);
		rhs[1] = mxDuplicateArray(prhs[2]);
		rhs[2] = mxDuplicateArray(prhs[3]);
		mexCallMATLAB(0, NULL, 3, rhs, "rHIDPutValues");

		// setting the object field value directly is a hot idea
		//	but without pointers, it's too slow to copy ROOT_STRUCT and the object to and fro
		//static mxArray *ROOT_STRUCT, *obj;
		//static mwIndex index;
		//static const char *class, *prop;
		//class = mxArrayToString(prhs[1]);
		//index = (mwIndex)mxGetScalar(prhs[2])-1;
		//prop = mxArrayToString(prhs[3]);
		//ROOT_STRUCT = mexGetVariable("global", "ROOT_STRUCT");
		//obj = mxGetField(ROOT_STRUCT, index, class);
		//mxSetField(obj, 0, prop, mxDuplicateArray(prhs[4]));
		//mxSetField(ROOT_STRUCT, index, class, obj);
		//mexPutVariable("global", "ROOT_STRUCT", ROOT_STRUCT);

		} else {
			mexErrMsgTxt("need an object to put into");
			return;
		}

	} else if(!strncmp(command, "write", 3)) {

		// done with command
		mxFree(command);
		mexPrintf("you can't 8 a sandbox\n");
		
	} else if(!strncmp(command, "scan", 3)) {

		//display info for all HID devices
		mexPrintf("Scanning all HID devices:\n");
		HIDBuildDeviceList(NULL,NULL);
		pRecDevice currentDevice;
		int i=0;
		for(currentDevice=HIDGetFirstDevice(); currentDevice != NULL; currentDevice=HIDGetNextDevice(currentDevice)){
			i++;
			mexPrintf("%d. %s(%d)\t%s(%d)\t%d/%d inputs/outputs\tver. %d\tsn. %d\n", i, 
			currentDevice->manufacturer, currentDevice->vendorID, currentDevice->product, currentDevice->productID,
			currentDevice->inputs, currentDevice->outputs, currentDevice->version, currentDevice->serial);
		}
		mexPrintf("Found %d HID devices.\n", i);

	} else if(!strncmp(command, "reset", 3)) {

		// done with command
		mxFree(command);

	} else if(!strncmp(command, "close", 3)) {

		// done with command
		mxFree(command);
		cleanup();
		
	} else {

		// done with command
		mxFree(command);
		mexErrMsgTxt("Unknown sandbox");
	}
}

//called when queue transitions to non-empty.
// so empty it every time
void TestQueueCallback(void *target,IOReturn result,void *refcon,void *sender)
{
	mexPrintf("TestQueueCallback %d\n", (int)result);

	IOHIDQueueInterface	**q		= (IOHIDQueueInterface**)refcon;
	IOHIDEventStruct	event;
	AbsoluteTime		zTime	= {0,0};
	IOReturn			ret	= kIOReturnSuccess;
	
	while(ret == kIOReturnSuccess){
		ret = (*queue)->getNextEvent(queue, &event, zTime, 0);
		
		//thing with freeing longValue
		if(event.longValueSize!=0 && event.longValue!=NULL)
			free(event.longValue);
			
		mexPrintf("%d event\n", event.value);
	}
	
}

// callback is registered with the CFRunLoop and triggered when the RunLoop gets data reports from the PMD
// this callback does the usful work of formatting and sorting the reports, and buffering the data in this exec
// for later reading-out to MATLAB
void HandleReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize)
{
	//mexPrintf("%s: %d\n", refcon, *(int*)target);
	
	mxArray *data;
	data = mxCreateDoubleScalar(*(double*)target);
	mexCallMATLAB(0,NULL,1, &data, "Mexico");
}

// callback is registered with the CFRunLoop and triggered when the RunLoop gets data reports from the PMD
// this degenerate callback lets the reports disappear into oblivion, effectively flushing the OS report buffer
void FlushReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize){
	//mexPrintf("FlushReportCallback--remove this print or DIE\n");
}

void cleanup(){

	//take PMD device sources out of the CF run loop
	//free the internal HID device list
	HIDReleaseDeviceList();

}