/* HIDx_dXPMDHID.c
 Defices class- and device-specific routines for setup, reset, and callback that allow the dXgameHID class to interact with HIDx
 in a useful way.
 
 Copyright 2007 by Benjamin Heasly at University of Pennsylvania
*/

#include "HIDx.h"
#define REPORT_SIZE 64
#define REPORT_SAMPLES 31
#define MAX_CHANS 8

/* In HIDx.h:
	Declare these three functions,
	add "dXPMDHID" to dXClassList[],
	add &dXPMDHID_HIDxSetup to dXClassSetup[]
*/

//report holder
typedef struct PMDReport{
	int HIDxDeviceIndex;
	int serial;
	IOReturn result;
	UInt32 data_length;
	unsigned char data[REPORT_SIZE];
} PMDReport;

// PMD management info
typedef struct PMDControl{
	HIDxChannelizer channelizer[MAX_CHANS];
	int nChans;
	double channel[MAX_CHANS][REPORT_SAMPLES];
	double terminal[MAX_CHANS];
	int events[MAX_CHANS][REPORT_SAMPLES];
	int samples[MAX_CHANS];
	PMDReport report[QUEUE_DEPTH];
	int nReports;
	unsigned char raw_data[REPORT_SIZE];
} PMDControl;

int dXPMDHID_HIDxSetup(const mxArray *extras){

	// the first device we finds is always the master, now find the three reporters on the same bus location
	int master_index=device_count;
	pRecDevice masterDevice, currentDevice;
	HIDxDeviceStruct *PMDMaster = &devices[master_index];
	IOHIDDeviceInterface122	**interface;

	// keep one PMD struct per PMD being used
	//	useful to initialize to all 0
	PMDControl *PMD = calloc(1, sizeof(PMDControl));
	PMDMaster->extras = PMD;

	// new a PMDControl struct
	register int i;
	if(extras !=NULL && mxIsStruct(extras)){
		 PMD->nChans = mxGetNumberOfElements(extras);
		 // copy MATLAB struct array into C struct array for faster access and safe defaults
		 for(i=0; i<PMD->nChans && i<MAX_CHANS; i++){
			PMD->channelizer[i].gain = (mxGetFieldNumber(extras, "gain")>=0) ? mxGetScalar(mxGetField(extras, i, "gain")) : 1;
			PMD->channelizer[i].offset = (mxGetFieldNumber(extras, "offset")>=0) ? mxGetScalar(mxGetField(extras, i, "offset")) : 0;
			PMD->channelizer[i].high = (mxGetFieldNumber(extras, "high")>=0) ? mxGetScalar(mxGetField(extras, i, "high")) : mxGetNaN();
			PMD->channelizer[i].low = (mxGetFieldNumber(extras, "low")>=0) ? mxGetScalar(mxGetField(extras, i, "low")) : mxGetNaN();
			PMD->channelizer[i].delta = (mxGetFieldNumber(extras, "delta")>=0) ? mxGetScalar(mxGetField(extras, i, "delta")) : 0;
			PMD->channelizer[i].freq = (mxGetFieldNumber(extras, "freq")>=0) ? mxGetScalar(mxGetField(extras, i, "freq")) : 1;
		}
	} else PMD->nChans = 0;

	// zero the timestamp for reports
	PMDMaster->zero_time = AbsoluteToDuration(UpTime());

	// remember class-specific functions
	PMDMaster->reset = &dXPMDHID_HIDxReset;
	PMDMaster->callback = &dXPMDHID_HIDxCallback;

	// find PMD reporter devices
	masterDevice = PMDMaster->device;
	for(currentDevice=HIDGetFirstDevice(); currentDevice!=NULL; currentDevice=HIDGetNextDevice(currentDevice)){
		if(currentDevice->locID == masterDevice->locID && currentDevice->totalElements < 50){

			// store the reporters's HIDx indexes as children of the master device
			device_count++;
			PMDMaster->children[PMDMaster->children_count++] = device_count;
			
			// setup reporters with minimal info
			devices[device_count].device = currentDevice;
			devices[device_count].dXclass = NULL;
			devices[device_count].dXindex = -1;
			devices[device_count].rHIDPutDataArgs[0] = NULL;
			devices[device_count].rHIDPutDataArgs[1] = NULL;
			devices[device_count].zero_time = 0;
			devices[device_count].reset = NULL;
			devices[device_count].callback = NULL;
			devices[device_count].extras = NULL;

			// setup event notificatin for reporters
			interface = currentDevice->interface;
			(*interface)->setInterruptReportHandlerCallback(interface, PMD->raw_data, REPORT_SIZE, &dXPMDHID_HIDxCallback, (void*)device_count, PMDMaster);
			(*interface)->createAsyncEventSource(interface,&(devices[device_count].source));

			if(!CFRunLoopContainsSource(HIDxRunLoop, devices[device_count].source, HIDxRunLoopMode)){
				CFRunLoopAddSource(HIDxRunLoop, devices[device_count].source, HIDxRunLoopMode);
				CFRunLoopWakeUp(HIDxRunLoop);
			}
		}
	}
	
	if(PMDMaster->children_count == 3) return(master_index);
	else {
		mexPrintf("HIDx:dXPMDHID_HIDxSetup: failed to find exactly 3 PMD reporting devices\n");
		return(mxGetNaN());
	}
}

void dXPMDHID_HIDxReset(void *self){
	register int i;
	HIDxDeviceStruct *PMDMaster = (HIDxDeviceStruct*)self;
	PMDControl *PMD = (PMDControl*)PMDMaster->extras;
	IOHIDDeviceInterface122	**interface;

	// rezero event times
	PMDMaster->zero_time = AbsoluteToDuration(UpTime());

		// flush reports
	if(PMDMaster->children_count > 0){
		for(i=0;i<PMDMaster->children_count;i++){
			interface = devices[PMDMaster->children[i]].device->interface;
			(*interface)->setInterruptReportHandlerCallback(interface, PMD->raw_data, REPORT_SIZE, &flushReportsCallback, NULL, NULL);
			CFRunLoopRunInMode(HIDxRunLoopMode,HIDxRunLoopTime,false);
			(*interface)->setInterruptReportHandlerCallback(interface, PMD->raw_data, REPORT_SIZE, &dXPMDHID_HIDxCallback, (void*)device_count, PMDMaster);
		}
	}
	PMD->nReports = 0;
}

// dXPMDHID uses a Reports callback (IOHIDReportCallbackFunction)
void dXPMDHID_HIDxCallback(void *target, IOReturn result, void *refcon, void *sender, UInt32 N){

	HIDxDeviceStruct	*PMDMaster = (HIDxDeviceStruct*)refcon;
	PMDControl			*PMD = (PMDControl*)PMDMaster->extras;
	register int i, r;
	int serial, c, tzero=0, total_events=0;
	double *shipItOut;
	
	// dope check
	if(PMD->nReports >= QUEUE_DEPTH) PMD->nReports=0;
	
	// get the serial number of this report--the last two bytes--for sorting
	serial = (int) (PMD->raw_data[N-1]*256 + PMD->raw_data[N-2]);

	// Online insert by serial number to put incoming reports into a single buffer.
	for(r=PMD->nReports; r>0 && serial<PMD->report[r-1].serial; r--) PMD->report[r]=PMD->report[r-1];
	PMD->nReports++;
	
	// fill in new report entry.
	PMD->report[r].serial = serial;
	PMD->report[r].result = result;
	PMD->report[r].data_length = N;
	PMD->report[r].HIDxDeviceIndex = (int)sender;
	for(i=0;i<N && i<REPORT_SIZE;i++) PMD->report[r].data[i]=PMD->raw_data[i];

	//	time base for this set of data comes from serial number of first datum
	//	then, time increments are just indices into channel data
	tzero = PMD->report[0].serial * REPORT_SAMPLES / PMD->nChans;

	// sample #0 treated as old data
	for(c=0; c<PMD->nChans; c++){
		PMD->channel[c][0] = PMD->terminal[c];
		PMD->samples[c] = 1;
	}

	// always decode the first report
	//	and also decode any consecutively numbered reports that follow
	for(i=0; i<REPORT_SAMPLES; i++){
		c = ((PMD->report[0].serial*REPORT_SAMPLES)+i)%(PMD->nChans);
		PMD->channel[c][PMD->samples[c]++] = (double)((PMD->report[0].data[i*2+1])*256 + PMD->report[0].data[i*2]);
	}
	for(r=1; r<PMD->nReports && (PMD->report[r].serial-PMD->report[r-1].serial==1); r++){
		for(i=0; i<REPORT_SAMPLES; i++){
			c = ((PMD->report[r].serial*REPORT_SAMPLES)+i)%(PMD->nChans);
			PMD->channel[c][PMD->samples[c]++] = (double)((PMD->report[r].data[i*2+1])*256 + PMD->report[r].data[i*2]);
		}
	}
	
	// move non-consecutive reports to front of buffer
	for(i=0; r<PMD->nReports; r++, i++) PMD->report[i] = PMD->report[r];
	PMD->nReports = i;

	for(c=0; c<PMD->nChans; c++){
		// save last raw sample for next go around
		PMD->terminal[c] = PMD->channel[c][PMD->samples[c]-1];

		// transform the data samples into events
		total_events += PMD->samples[c] = channelizeData(&PMD->channelizer[c], PMD->channel[c], PMD->events[c], PMD->samples[c]);
	}
	
	// ship events to MATLAB via rHIDPutData
	if(total_events){

		PMDMaster->rHIDPutDataArgs[2] = mxCreateDoubleMatrix(total_events, 3, mxREAL);
		shipItOut = mxGetPr(PMDMaster->rHIDPutDataArgs[2]);
		
		for(c=0; c<PMD->nChans; c++){
			for(i=0;i<PMD->samples[c];i++,shipItOut++){
				*(shipItOut)				= (double)(c);
				*(shipItOut+total_events)	= (PMD->channel[c][PMD->events[c][i]]);
				*(shipItOut+2*total_events)	= (double)(tzero+PMD->events[c][i])/PMD->channelizer[c].freq;
			}
		}

		//ship data to MATLAB
		mexCallMATLAB(0, NULL, 3, PMDMaster->rHIDPutDataArgs, "rHIDPutValues");
	}
}