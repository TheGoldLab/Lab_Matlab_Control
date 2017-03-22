/* HIDx_dXgameHID.c
 Defices class- and device-specific routines for setup, reset, and callback that allow the dXgameHID class to interact with HIDx
 in a useful way.
 
 Copyright 2007 by Benjamin Heasly at University of Pennsylvania
*/

#include "HIDx.h"
#define MAX_CHANS 256
#define FREQ 1000

/* In HIDx.h:
	Declare these three functions,
	add "dXgameHID" to dXClassList[],
	add &dXgameHID_HIDxSetup to dXClassSetup[]
*/

// gamepad management info
typedef struct GPControl{
	HIDxChannelizer channelizer[MAX_CHANS];
	int nChans;
} GPControl;

int dXgameHID_HIDxSetup(const mxArray *extras){

	// remember class-specific functions
	devices[device_count].reset = &dXgameHID_HIDxReset;
	devices[device_count].callback = &dXgameHID_HIDxCallback;

	// enqueue all device elements for event notification
	//	this also sets the queue callback to devices[device_count].callback
	HIDxMakeDeviceQueue(&devices[device_count]);

	if(!CFRunLoopContainsSource(HIDxRunLoop, devices[device_count].source, HIDxRunLoopMode)){
		CFRunLoopAddSource(HIDxRunLoop, devices[device_count].source, HIDxRunLoopMode);
		CFRunLoopWakeUp(HIDxRunLoop);
	}

	// zero the time of event reporting
	devices[device_count].zero_time = AbsoluteToDuration(UpTime());

	// game HID can channelize each button
	GPControl *GP = calloc(1, sizeof(GPControl));
	devices[device_count].extras = GP;
	register int i;
	if(extras !=NULL && mxIsStruct(extras)){
		 GP->nChans = mxGetNumberOfElements(extras);
		 // copy MATLAB struct array into C struct array for faster access and safe defaults
		 for(i=0; i<GP->nChans && i<devices[device_count].cookie_count && i<MAX_CHANS; i++){
			GP->channelizer[i].gain = (mxGetFieldNumber(extras, "gain")>=0) ? mxGetScalar(mxGetField(extras, i, "gain")) : 1;
			GP->channelizer[i].offset = (mxGetFieldNumber(extras, "offset")>=0) ? mxGetScalar(mxGetField(extras, i, "offset")) : 0;
			GP->channelizer[i].high = (mxGetFieldNumber(extras, "high")>=0) ? mxGetScalar(mxGetField(extras, i, "high")) : mxGetNaN();
			GP->channelizer[i].low = (mxGetFieldNumber(extras, "low")>=0) ? mxGetScalar(mxGetField(extras, i, "low")) : mxGetNaN();
			GP->channelizer[i].delta = (mxGetFieldNumber(extras, "delta")>=0) ? mxGetScalar(mxGetField(extras, i, "delta")) : 0;
			GP->channelizer[i].freq = (mxGetFieldNumber(extras, "freq")>=0) ? mxGetScalar(mxGetField(extras, i, "freq")) : FREQ;
		}
	} else GP->nChans = 0;
	
	// for dXgameHID, there is only one device, 
	//	so the index of this device is the same as the current number of devices
	return(device_count);
}

void dXgameHID_HIDxReset(void *self){
	HIDxDeviceStruct *HIDxDevice = (HIDxDeviceStruct*)self;
	IOHIDQueueInterface** queue = HIDxDevice->device->queue;

	// stop new events
	(*queue)->stop(queue);
	
	// pass garbage callback reference to kill old events
	(*queue)->setEventCallout(queue, &flushQueueCallback, NULL, NULL);
	
	// run the runloop to chase old events into the garbage callback
	CFRunLoopRunInMode(HIDxRunLoopMode,HIDxRunLoopTime,false);

	//restore useful callback reference
	(*queue)->setEventCallout(queue, (IOHIDCallbackFunction)(HIDxDevice->callback), NULL, HIDxDevice);

	//zero the event clock
	HIDxDevice->zero_time = AbsoluteToDuration(UpTime());

	//restart queue events
	(*queue)->start(queue);
}

// dXgameHID uses a Queue callback (IOHIDCallbackFunction)
void dXgameHID_HIDxCallback(void *target,IOReturn result,void *refcon,void *sender){

	HIDxDeviceStruct	*HIDxDevice = (HIDxDeviceStruct*)refcon;
	IOHIDQueueInterface **queue = HIDxDevice->device->queue;
	IOHIDEventStruct	event;
	IOReturn			ret;
	GPControl			*GP = HIDxDevice->extras;
	
	//temporary readouts
	register int i;
	int element[QUEUE_DEPTH], event_count=0;
	double value[QUEUE_DEPTH], time[QUEUE_DEPTH];
	double *shipItOut;
	AbsoluteTime false_zero = {0,0};
	
	ret = (*queue)->getNextEvent(queue, &event, false_zero, 0);
	while(ret == kIOReturnSuccess){

		// free the long value
		if(event.longValueSize>0 && event.longValue!=NULL){
			value[event_count] = *(double*)event.longValue;
			free(event.longValue);
		} else {
			value[event_count] = (double)event.value;
		}

		// identify elements as the ith cookie
		for(i=0; i<HIDxDevice->cookie_count && HIDxDevice->cookie_monster[i]!=event.elementCookie; i++);
		element[event_count] = i;

		// transform single value
		channelizeData(&GP->channelizer[i], &value[event_count], NULL, 1);

		// scale time by "sample frequency"
		time[event_count] = (double)(AbsoluteToDuration(event.timestamp)-HIDxDevice->zero_time)/FREQ;

		// and repeat
		event_count++;
		ret = (*queue)->getNextEvent(queue, &event, false_zero, 0);
	}

	// ship data to MATLAB via rHIDPutData
	if(event_count){
		HIDxDevice->rHIDPutDataArgs[2] = mxCreateDoubleMatrix(event_count, 3, mxREAL);
		shipItOut = mxGetPr(HIDxDevice->rHIDPutDataArgs[2]);
		for(i=0;i<event_count;i++,shipItOut++){
			*(shipItOut)				= (double)element[i]+1;
			*(shipItOut+event_count)	= value[i];
			*(shipItOut+2*event_count)	= time[i];
		}
		mexCallMATLAB(0, NULL, 3, HIDxDevice->rHIDPutDataArgs, "rHIDPutValues");
	}
}