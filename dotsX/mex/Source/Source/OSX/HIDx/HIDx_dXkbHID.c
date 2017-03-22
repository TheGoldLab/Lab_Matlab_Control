/* HIDx_dXgameHID.c
 Defices class- and device-specific routines for setup, reset, and callback that allow the dXkbHID class to interact with HIDx
 in a useful way.
 
 Copyright 2007 by Benjamin Heasly at University of Pennsylvania
*/

#include "HIDx.h"
#define FREQ 1000 // unless you want time reported in slug-feet per pound-hour, use this to get seconds

/* In HIDx.h:
	Declare these three functions,
	add "dXkbHID" to dXClassList[],
	add &dXkbHID_HIDxSetup to dXClassSetup[]
*/

int dXkbHID_HIDxSetup(const mxArray *extras){

	// remember class-specific functions
	devices[device_count].reset = &dXkbHID_HIDxReset;
	devices[device_count].callback = &dXkbHID_HIDxCallback;

	// enqueue all device elements for event notification
	//	this also sets the queue callback to devices[device_count].callback
	HIDxMakeDeviceQueue(&devices[device_count]);

	if(devices[device_count].source != NULL){
		CFRunLoopAddSource(HIDxRunLoop, devices[device_count].source, HIDxRunLoopMode);
		CFRunLoopWakeUp(HIDxRunLoop);
	}

	// zero the time of event reporting
	devices[device_count].zero_time = AbsoluteToDuration(UpTime());

	// for dXkbHID, there should be only one device, 
	//	so the index of this device is the same as the current number of devices
	return(device_count);
}

void dXkbHID_HIDxReset(void *self){
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

// dXkbHID uses a Queue callback (IOHIDCallbackFunction)
void dXkbHID_HIDxCallback(void *target,IOReturn result,void *refcon,void *sender){

	HIDxDeviceStruct	*HIDxDevice = (HIDxDeviceStruct*)refcon;
	IOHIDQueueInterface **queue = HIDxDevice->device->queue;
	IOHIDEventStruct	event;
	IOReturn			ret;
	
	//temporary readouts
	register int i, event_count=0;
	int key[QUEUE_DEPTH], cookie;
	bool state[QUEUE_DEPTH];
	double time[QUEUE_DEPTH];
	double *shipItOut;
	AbsoluteTime false_zero = {0,0};
	
	ret = (*queue)->getNextEvent(queue, &event, false_zero, 0);
	while(ret == kIOReturnSuccess){

		// cookies 21 and greater encode keys which, minus 17, correspond to PTB's KbName mappings
		//	So 17 is some BS magic number?  It is at least consistent for:
		//		Microsoft ergo keyboard 4000
		//		Dell RT7D10 keyboard
		//		Dumb White Apple keyboard
		//	Other cookies correspond to metakeys with magic number +222, also consistently across keyboards
		cookie = (int)event.elementCookie;
		if(cookie >= 21) key[event_count] = cookie-17;
		else if(cookie<=8) key[event_count] = cookie+222;
		else cookie = -1; // strange events from HID keyboard emulation
			
		// if any longValue, must free it, even if this was a useless event
		if(event.longValueSize>0 && event.longValue!=NULL){
			state[event_count] = (*(UInt32*)event.longValue)!=0;
			free(event.longValue);
		} else {
			state[event_count] = (event.value)!=0;
		}

		// event worth reporting?
		if(cookie > 0){
			// get event time relative to HIDx('reset') time
			//	scale time by "sample frequency"
			time[event_count] = (double)(AbsoluteToDuration(event.timestamp)-HIDxDevice->zero_time)/FREQ;
			event_count++;
		}

		// and repeat
		ret = (*queue)->getNextEvent(queue, &event, false_zero, 0);
	}

	// ship data to MATLAB via rHIDPutData
	if(event_count){

		HIDxDevice->rHIDPutDataArgs[2] = mxCreateDoubleMatrix(event_count, 3, mxREAL);
		shipItOut = mxGetPr(HIDxDevice->rHIDPutDataArgs[2]);
		for(i=0;i<event_count;i++,shipItOut++){
			*(shipItOut)				= (double)key[i];
			*(shipItOut+event_count)	= (double)state[i];
			*(shipItOut+2*event_count)	= time[i];
		}
		//ship data to MATLAB
		mexCallMATLAB(0, NULL, 3, HIDxDevice->rHIDPutDataArgs, "rHIDPutValues");
	}
}