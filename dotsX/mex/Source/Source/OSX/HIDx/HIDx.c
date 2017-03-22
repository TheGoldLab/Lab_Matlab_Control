/* 
 HIDx.c
 A mex function for DotsX.  Connect to USB HID devices and setup event notification with CFRunLoop.
 
 It goes like so:
 -HID devices all have unique ID numbers, and DotsX HID classes know the numbers of the device they want to use.
 -Also, HIDx('scan') will show a list of devices and numbers.
 -A DotsX HID class can call HIDx('add', ...) to gather info about the device and establish asynchronous event-based
 communications with the device.
 -When an event occurs on the device, the OS X Core Foundation will call a special DotsX device-specific callback.
 -The callback must read events out of the device's event queue, decode/buffer interesting event data, and send the data
 immediately to MATLAB.
 -Each DotsX HID class has a putValues method which is ready to receive event data and store them in its .values field.
 -Either the putValues method checks for input-output mappings and the query method just returns the current output,
 or the putValues method just adds data to .values and query functions as it does now.  I'll have to test.

 Copyright 2007 Benjamin Heasly at Univerity of Pennsylvania
*/

#define ALLOCATE_EXTERNALS
#include "HIDx.h"

/* HIDx had an existential design crisis, but BSH found a compromise:
	-There's a bunch of HID functionality that we want to use in common for HID Devices in DotsX.
	-There's also a lot of setup and decoding that's specific to each HID device: gamepad uses a queue, PMD uses reports, etc.
	-So either HIDx is one function that has to do serious branching for 'add', 'reset', and callback, or HIDx is a library
	that gets linked to separate mex functions for each HID device.
	-Branching is an ugly idea and would lead to lots and lots of subfunctions.
	-A library seems slightly more appealing, but not great.  HIDx would be a tiny library, and we're already using HIDUtilities.
	-So a compromise:
		-HIDx is one function, not a library.
		-It does string-switch branching once, at 'add' time.
		-Further branching is done with function pointers for 'reset' and callbacks.
		-For organization, each HID device gets its own source file which should contain three functions: 
			-void dX(class_name)_HIDxSetup();
			-void dX(class_name)_HIDxReset(HIDxDeviceStruct *HIDxDevice);
			-void dX(class_name)_HIDxCallback(...);
		-The source files for each device just get built into the project
*/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char *command=NULL;
	
	// If no arguments given, print usage string
	if(nrhs < 1) {
		mexPrintf("HIDx:\n %s\n %s\n %s\n %s\n %s\n %s\n %s\n %s\n %s\n %s \n",
			"[deviceInfo =] HIDx('scan'); % [Return device info struct array] or list a few key numbers.",
			"isInitialized = HIDx('init'); % Build HID device library.  Lock the HIDx mex function.  Redundant init's are ok.",
			"isInitialized = HIDx('close'); % Free HID library and device resources.",
			"isInitialized = HIDX('status'); % Boolean: is initialized or not.",
			"[deviceIndex, deviceInfo, elementInfo] = HIDx('add', className, classIndex, deviceCriteria, extras); % Setup a HID device and associate with a DotsX object.",
			"[deviceIndex =] HIDx('remove', deviceIndex); % Free device resources and stop incoming data.",
			"HIDx('reset', deviceIndex); % Zero time and forget old events for a device.",
			"HIDx('run', deviceIndex [,secs]); % Trigger callbacks to send any available data to MATLAB [set timeout other than 0.0005 sec].",
			"HIDx('setReport', deviceIndex, reportID, report, [,reportType] [,milisecs]); % Send UInt8 data to HID device [report type (0-3) other than 1=output] [use timeout other than 50ms].",
			"HIDx('unlock'); % Unlock HIDx mex function so MATLAB can clear it.  This may cause subsequent HIDx('add') calls to crash.");
		return;
	}

	// get subcommand argument as char*
	if(mxIsChar(prhs[0]) && mxGetM(prhs[0]) == 1 && mxGetN(prhs[0]) >= 1) {
		command = mxArrayToString(prhs[0]);
	} else {
		mexErrMsgTxt("HIDx needs a command string");
	}

	// command switch:
	//-------------------------------------------------------------------------------------------------------------------------
	if(!strcmp(command, "scan")) {

		// done with command
		mxFree(command);

		// let scan be independent of init
		if(!HIDHaveDeviceList()) HIDBuildDeviceList((int)NULL,(int)NULL);
		
		register int i;
		int numDevices=HIDCountDevices();
		pRecDevice currentDevice;

		//return struct of detailed device info, or just print a little info?
		if(nlhs>0){
			pRecDevice *devs;
			devs = calloc(numDevices, sizeof(pRecDevice));
			for(currentDevice=HIDGetFirstDevice(), i=0; currentDevice!=NULL && i<numDevices; currentDevice=HIDGetNextDevice(currentDevice),i++)
				devs[i] = currentDevice;
			plhs[0] = getDeviceInfoStruct(devs, numDevices);
			free(devs);
		} else {
			mexPrintf("Scanning all HID devices:\n");
			mexPrintf("\tvendorID\tproductID\tinputs\toutputs\tname(serial)\n");
			for(currentDevice=HIDGetFirstDevice(), i=0; currentDevice!=NULL && i<numDevices; currentDevice=HIDGetNextDevice(currentDevice),i++){
				mexPrintf("%d.\t%d\t\t%d\t\t%d\t%d\t%s(%s)\n",i, 
				currentDevice->vendorID, currentDevice->productID, currentDevice->inputs, 
				currentDevice->outputs, currentDevice->product, currentDevice->serial);
			}
			mexPrintf("Found %d HID devices.\n", i);
		}

	//-------------------------------------------------------------------------------------------------------------------------
	} else if(!strcmp(command, "init")) {

		// done with command
		mxFree(command);
		
		// allow reinitialization
		if(initialized!=(int)NULL && initialized) cleanup();
		
		// prevent "clear all" from screwing stuff up
		if(!mexIsLocked()) mexLock();
		
		// register exit routine
		if(mexAtExit(&fullClose) != 0 ) {
			fullClose();
			mexErrMsgTxt("HIDx('init'): failed to register exit routine.");
	    }

		//HID initialization is slow
		if(!HIDHaveDeviceList()) initialized = HIDBuildDeviceList((int)NULL,(int)NULL)==0;
		else initialized = TRUE;
		device_count = 0;
		
		//get run loop for this thread
		HIDxRunLoop = CFRunLoopGetCurrent();
		HIDxRunLoopMode = CFSTR("HIDxRunLoopMode_kthxlalala");
		HIDxRunLoopTime = (CFTimeInterval).0005;
		
		// report init success
        if(!(plhs[0] = mxCreateDoubleScalar((double)initialized)))
            mexErrMsgTxt("HIDx('init'): mxCreateDoubleScalar failed.");

	//-------------------------------------------------------------------------------------------------------------------------
	} else if(!strcmp(command, "close")) {

		// done with command
		mxFree(command);
		
		// from here, cleanup is easy
		cleanup();
		
		// report closure
        if(!(plhs[0] = mxCreateDoubleScalar((double)initialized)))
            mexErrMsgTxt("HIDx('init'): mxCreateDoubleScalar failed.");

	} else if(!strcmp(command, "status")) {

		// done with command
		mxFree(command);
		
		// report status
        if(!(plhs[0] = mxCreateDoubleScalar((double)initialized)))
            mexErrMsgTxt("HIDx('status'): mxCreateDoubleScalar failed.");

	} else if(!strcmp(command, "add")) {

		// done with command
		mxFree(command);

		if(!initialized) mexErrMsgTxt("HIDx('add' ...): HIDx is not initialized");
		
		char *class_name=NULL;
		const char *field_name;
		double index=0;
		const mxArray *deviceCriteria=NULL, *deviceProperties, *crit, *prop, *deviceExtras;
		pRecDevice currentDevice;
		int HIDxIndex=mxGetNaN(), num_fields;
		register int i;
		bool match=TRUE;
		
		/* check subcommand aruments:
			1-DotsX class_name of HID object
			2-DotsX index of HID object in ROOT_STRUCT
			3-*mxArray struct of device info ('like as returned by HidX('scan'))
			[4-*mxArray of more info for device setup]
		*/

		if(nrhs < 4) mexErrMsgTxt("HIDx('add' ...): needs (... className, classIndex, deviceCriteria)");

		//get class name
		if(mxIsChar(prhs[1]) && mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) > 0){
			class_name = mxArrayToString(prhs[1]);
		} else {
			mexErrMsgTxt("HIDx('add' ...): bad className");
		}

		//get ROOT_STRUCT index
		if(mxIsNumeric(prhs[2]) && mxGetM(prhs[2]) == 1 && mxGetN(prhs[2]) == 1){
			index = mxGetScalar(prhs[2]);
		} else {
			mexErrMsgTxt("HIDx('add' ...): bad classIndex");
		}

		//get MATLAB struct of device criteria
		if(mxIsStruct(prhs[3])){
			deviceCriteria = prhs[3];
		} else {
			mexErrMsgTxt("HIDx('add' ...): deviceCriteria must be a struct");
		}
		
		//check for MATLAB struct of device setup extras 
		if(nrhs >= 5){
			deviceExtras = prhs[4];
		} else {
			deviceExtras = NULL;
		}
		
		//find matching device
		for(currentDevice=HIDGetFirstDevice(); currentDevice!=NULL; currentDevice=HIDGetNextDevice(currentDevice)){

			// get info about current device in same format as deviceCriteria MATLAB struct
			//	missing or empty field counts as a match
			deviceProperties = getDeviceInfoStruct(&currentDevice, 1);
			num_fields = mxGetNumberOfFields(deviceCriteria);
			//mexPrintf("\nTrying %s\n\n", currentDevice->product);
			match = TRUE;
			for(i=0; i<num_fields && match==TRUE; i++){
				field_name = mxGetFieldNameByNumber(deviceCriteria, i);
				
				// does the criteria struct have this field?
				if(mxGetFieldNumber(deviceProperties, field_name) >= 0){

					// compare field values
					crit = mxGetField(deviceCriteria, 0, field_name);
					prop = mxGetField(deviceProperties, 0, field_name);
					if(mxIsEmpty(crit)){
						// empty criterion counts as a match
						//mexPrintf("%d: crit.%s empty\n", match, field_name);
						continue;
					} else if(mxIsNumeric(crit) && mxIsNumeric(prop)){
						//do numbers match?
						match = mxGetScalar(crit)==mxGetScalar(prop);
						//mexPrintf("%d: crit.%s=%f, prop.%s=%f\n", match, field_name, mxGetScalar(crit), field_name, mxGetScalar(prop));
					} else if(mxIsChar(crit) && mxIsChar(prop)){
						// do strings match?
						char *critStr = mxArrayToString(crit);
						char *propStr = mxArrayToString(prop);
						match = !strcmp(critStr, propStr);
						//mexPrintf("%d: crit.%s=%s, prop.%s=%s\n", match, field_name, critStr, field_name, propStr);
						mxFree(critStr);
						mxFree(propStr);
					} else {
						// mismatched or unrecognized types
						match = FALSE;
						//mexPrintf("%d: crit.%s and prop.%s unlike\n", match, field_name, field_name);
					}
				} else {
					//mexPrintf("%d: prop.%s DNE\n", match, field_name);
				}
			}

			// take first match and do device setup
			if(match) break;
		}			

		if(match) {
		
			// fill in info about matched device
			devices[device_count].device = currentDevice;
			devices[device_count].dXindex = index;
			devices[device_count].dXclass = class_name; // freed at remove time
			
			// preparation for callback to rHIDPutData in Matlab
			//	destroyed at remove time
			devices[device_count].rHIDPutDataArgs[0] = mxCreateString(class_name);
			devices[device_count].rHIDPutDataArgs[1] = mxCreateDoubleScalar(index);
			mexMakeArrayPersistent(devices[device_count].rHIDPutDataArgs[0]);
			mexMakeArrayPersistent(devices[device_count].rHIDPutDataArgs[1]);

			// start with no children (most devices have no children)
			devices[device_count].children_count = 0;

			devices[device_count].source = NULL;
			devices[device_count].extras = NULL;

			// search for class name and call matching HIDxDeviceSetupFunction
			for(i=0; i<num_classes; i++){
				if(!strcmp(class_name, dXClassList[i])){
					HIDxIndex = dXClassSetup[i](deviceExtras);
					break;
				}
			}

			if(!isnan(HIDxIndex)){

				// got a new device
				device_count++;

				// send back info about this device?
				if(nlhs>1) plhs[1] = getDeviceInfoStruct(&(devices[HIDxIndex].device), 1);
				if(nlhs>2) plhs[2] = getElementInfoStruct(devices[HIDxIndex].device);
			} else {

				//setup failed
				mexPrintf("HIDx('add' ...): class-specific HID setup failed for %s\n", class_name);
				if(nlhs>1) plhs[1] = mxCreateDoubleScalar(mxGetNaN());
				if(nlhs>2) plhs[2] = mxCreateDoubleScalar(mxGetNaN());
				releaseDevice(device_count);
			}
		} else {
		
			// found no matching device
			mexPrintf("HIDx('add' ...): failed to find a device match for %s\n", class_name);

			// we're not going to free this at remove time
			mxFree(class_name);

			if(nlhs>1) plhs[1] = mxCreateDoubleScalar(mxGetNaN());
			if(nlhs>2) plhs[2] = mxCreateDoubleScalar(mxGetNaN());
		}
		
		// report index of found device or error
        if(!(plhs[0] = mxCreateDoubleScalar((double)HIDxIndex)))
            mexErrMsgTxt("HIDx('add'): mxCreateDoubleScalar failed.");

	//-------------------------------------------------------------------------------------------------------------------------
	} else if(!strcmp(command, "remove")) {

		// done with command
		mxFree(command);

		if(!initialized) mexErrMsgTxt("HIDx('remove' ...): HIDx is not initialized");
		
		// get HIDx index of HIDx device to remove
		if(nrhs>1 && mxIsNumeric(prhs[1]) && mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 1){
			releaseDevice((int)mxGetScalar(prhs[1]));
		} else {
			mexErrMsgTxt("HIDx('remove' ...): needs a scalar index");
		}
		
		// report non-index of removed device
        if(!(plhs[0] = mxCreateDoubleScalar(mxGetNaN())))
            mexErrMsgTxt("HIDx('remove'): mxCreateDoubleScalar failed.");

	//-------------------------------------------------------------------------------------------------------------------------		
	} else if(!strcmp(command, "reset")) {

		// done with command
		mxFree(command);
		
		if(!initialized) mexErrMsgTxt("HIDx('reset' ...): HIDx is not initialized");

		int index=0;
		// get HIDx index of HIDx device to reset
		if(nrhs>1 && mxIsNumeric(prhs[1]) && mxGetM(prhs[1]) == 1 && mxGetN(prhs[1]) == 1){
			index = (int)mxGetScalar(prhs[1]);
		} else {
			mexErrMsgTxt("HIDx('reset' ...): needs a scalar index");
		}

		//delegate to the class-specific reset function
		devices[index].reset(&devices[index]);

	//-------------------------------------------------------------------------------------------------------------------------		
	} else if(!strcmp(command, "run")) {

		// done with command
		mxFree(command);

		if(!initialized) mexErrMsgTxt("HIDx('run' ...): HIDx is not initialized");

		// optionally set new run interval
		if(nrhs>1 && mxIsNumeric(prhs[1]) && mxGetM(prhs[1])==1 && mxGetN(prhs[1])==1) 
			HIDxRunLoopTime = (CFTimeInterval)mxGetScalar(prhs[1]);

		// trigger callbacks for all HIDx devices
		// true means return after triggering callbacks for one source
		// false means block for full duration
		if(initialized) CFRunLoopRunInMode(HIDxRunLoopMode,HIDxRunLoopTime,false);

	//-------------------------------------------------------------------------------------------------------------------------		
	} else if(!strcmp(command, "setReport")) {

		// done with command
		mxFree(command);
		
		if(!initialized) mexErrMsgTxt("HIDx('setReport' ...): HIDx is not initialized");
		
		/* setReport subcommand aruments:
			1-HIDx device index as returned by add
			2-device-specific report id
			3-report array, treated as unsigned char
			[4-report type 0-3 other than 1=output]
			[5-timeout other than 50ms]
		*/
		if(nrhs < 4) mexErrMsgTxt("HIDx('setReport' ...): needs (... deviceIndex, reportID, report)");
		UInt32 index=0, reportID=0, report_length=0, timeout=50;
		IOHIDReportType type=kIOHIDReportTypeOutput;
		unsigned char *report=NULL;
		IOHIDDeviceInterface122	**interface;

		//get HIDxIndex
		if(mxIsNumeric(prhs[1])){
			index = mxGetScalar(prhs[1]);
		} else {
			mexErrMsgTxt("HIDx('setReport' ...): bad deviceIndex");
		}

		//get reportID
		if(mxIsNumeric(prhs[2])){
			reportID = mxGetScalar(prhs[2]);
		} else {
			mexErrMsgTxt("HIDx('setReport' ...): bad reportID");
		}

		//get report
		if(mxIsUint8(prhs[3])){
			report = (unsigned char *)mxGetData(prhs[3]);
			report_length = mxGetNumberOfElements(prhs[3]);
		} else {
			mexErrMsgTxt("HIDx('setReport' ...): bad report.  Report must be UInt8");
		}		

		//get report type
		if(nrhs>=5 && mxIsNumeric(prhs[4])){
			switch((int)mxGetScalar(prhs[4])){
				case 0: type=kIOHIDReportTypeInput;
				case 1: type=kIOHIDReportTypeOutput;
				case 2: type=kIOHIDReportTypeFeature;
				case 3: type=kIOHIDReportTypeCount;
				default: mexErrMsgTxt("HIDx('setReport' ...): bad reportType.  Must be 0-3.");
			}
		}		
	
		//get new timeout?
		if(nrhs>=6 && mxIsNumeric(prhs[5])) timeout = mxGetScalar(prhs[5]);

		// now do
		interface = devices[index].device->interface;
		(*interface)->setReport(interface,type,reportID,report,report_length,timeout,NULL,NULL,NULL);

	} else if(!strcmp(command, "unlock")) {

		// done with command
		mxFree(command);
		
		mexPrintf("Unlocking HIDx mex function:\nNow MATLAB can clear it, but it might crash next time you use it.\n");
		while(mexIsLocked()) mexUnlock();

	} else {

		// done with command
		mxFree(command);
		mexErrMsgTxt("HIDx: Unknown command");
	}
}

mxArray *getDeviceInfoStruct(pRecDevice *device, int numDevices){

	const char *fname[] = {"transport", "vendorID", "productID", "version", 
					"manufacturer", "product", "serial", "locID", 
					"usage", "usagePage", "usageName", "totalElements", 
					"features", "inputs", "outputs", "collections", 
					"axis", "buttons", "hats", "sliders", 
					"dials", "wheels"};
	register int i;
	mwSize dims[2];
	dims[0] = 1;
	dims[1] = numDevices;
	char usageName[256];
	mxArray *deviceInfo = mxCreateStructArray(2, dims, 22, fname);
						
	for(i=0; i<numDevices; i++){
		
		HIDGetUsageName(device[i]->usagePage, device[i]->usage, usageName);
	
		// how tedious can you get?
		mxSetField(deviceInfo, i, "transport", mxCreateString(device[i]->transport));
		mxSetField(deviceInfo, i, "vendorID", mxCreateDoubleScalar(device[i]->vendorID));
		mxSetField(deviceInfo, i, "productID", mxCreateDoubleScalar(device[i]->productID));
		mxSetField(deviceInfo, i, "version", mxCreateDoubleScalar(device[i]->version));

		mxSetField(deviceInfo, i, "manufacturer", mxCreateString(device[i]->manufacturer));
		mxSetField(deviceInfo, i, "product", mxCreateString(device[i]->product));
		mxSetField(deviceInfo, i, "serial", mxCreateString(device[i]->serial));
		mxSetField(deviceInfo, i, "locID", mxCreateDoubleScalar(device[i]->locID));

		mxSetField(deviceInfo, i, "usage", mxCreateDoubleScalar(device[i]->usage));
		mxSetField(deviceInfo, i, "usagePage", mxCreateDoubleScalar(device[i]->usagePage));
		mxSetField(deviceInfo, i, "usageName", mxCreateString(usageName));
		mxSetField(deviceInfo, i, "totalElements", mxCreateDoubleScalar(device[i]->totalElements));

		mxSetField(deviceInfo, i, "features", mxCreateDoubleScalar(device[i]->features));
		mxSetField(deviceInfo, i, "inputs", mxCreateDoubleScalar(device[i]->inputs));
		mxSetField(deviceInfo, i, "outputs", mxCreateDoubleScalar(device[i]->outputs));
		mxSetField(deviceInfo, i, "collections", mxCreateDoubleScalar(device[i]->collections));

		mxSetField(deviceInfo, i, "axis", mxCreateDoubleScalar(device[i]->axis));
		mxSetField(deviceInfo, i, "buttons", mxCreateDoubleScalar(device[i]->buttons));
		mxSetField(deviceInfo, i, "hats", mxCreateDoubleScalar(device[i]->hats));
		mxSetField(deviceInfo, i, "sliders", mxCreateDoubleScalar(device[i]->sliders));

		mxSetField(deviceInfo, i, "dials", mxCreateDoubleScalar(device[i]->dials));
		mxSetField(deviceInfo, i, "wheels", mxCreateDoubleScalar(device[i]->wheels));
	}

	return(deviceInfo);
}

mxArray *getElementInfoStruct(pRecDevice device){

	const char *fname[] = {"type", "usagePage", "usage", "usageName", 
					"cookie", "min", "max", "scaledMin",  
					"scaledMax", "size", "relative", "wrapping", 
					"nonLinear", "preferredState", "nullState", "units",  
					"unitExp", "name", "calMin", "calMax",  
					"userMin", "userMax"};

	// report on elements of type input/output (not collections)
	int numElements = device->features + device->inputs + device->outputs;
	pRecElement element = HIDGetFirstDeviceElement(device, kHIDElementTypeIO);

	register int i;
	mwSize dims[2];
	dims[0] = 1;
	dims[1] = numElements;
	char usageName[256];
	mxArray *elementInfo = mxCreateStructArray(2, dims, 22, fname);
						
	for(i=0; i<numElements && element!=NULL; i++, element=HIDGetNextDeviceElement(element, kHIDElementTypeIO)){
	
		HIDGetUsageName(element->usagePage, element->usage, usageName);

		// how tedious can you get?
		mxSetField(elementInfo, i, "type", mxCreateDoubleScalar(element->type));
		mxSetField(elementInfo, i, "usagePage", mxCreateDoubleScalar(element->usagePage));
		mxSetField(elementInfo, i, "usage", mxCreateDoubleScalar(element->usage));
		mxSetField(elementInfo, i, "usageName", mxCreateString(usageName));

		mxSetField(elementInfo, i, "cookie", mxCreateDoubleScalar((int)(element->cookie)));
		mxSetField(elementInfo, i, "min", mxCreateDoubleScalar(element->min));
		mxSetField(elementInfo, i, "max", mxCreateDoubleScalar(element->max));
		mxSetField(elementInfo, i, "scaledMin", mxCreateDoubleScalar(element->scaledMin));

		mxSetField(elementInfo, i, "scaledMax", mxCreateDoubleScalar(element->scaledMax));
		mxSetField(elementInfo, i, "size", mxCreateDoubleScalar(element->size));
		mxSetField(elementInfo, i, "relative", mxCreateDoubleScalar(element->relative));
		mxSetField(elementInfo, i, "wrapping", mxCreateDoubleScalar(element->wrapping));

		mxSetField(elementInfo, i, "nonLinear", mxCreateDoubleScalar(element->nonLinear));
		mxSetField(elementInfo, i, "preferredState", mxCreateDoubleScalar(element->preferredState));
		mxSetField(elementInfo, i, "nullState", mxCreateDoubleScalar(element->nullState));
		mxSetField(elementInfo, i, "units", mxCreateDoubleScalar(element->units));

		mxSetField(elementInfo, i, "unitExp", mxCreateDoubleScalar(element->unitExp));
		mxSetField(elementInfo, i, "name", mxCreateString(element->name));
		mxSetField(elementInfo, i, "calMin", mxCreateDoubleScalar(element->calMin));
		mxSetField(elementInfo, i, "calMax", mxCreateDoubleScalar(element->calMax));

		mxSetField(elementInfo, i, "userMin", mxCreateDoubleScalar(element->userMin));
		mxSetField(elementInfo, i, "userMax", mxCreateDoubleScalar(element->userMax));
	}

	return(elementInfo);
}

int channelizeData(HIDxChannelizer *clzr, double *signal, int *eventIndices, int N){
	register int i;
	int event_count=0;

	// first, do linear transform on signal
	if(clzr->gain != 1) for(i=0; i<N; i++) signal[i] *= clzr->gain;
	if(clzr->offset != 0) for(i=0; i<N; i++) signal[i] += clzr->offset;
	
	// then do thresholding/banding
	switch((isnan(clzr->high))<<1 | isnan(clzr->low)){
		case 0: // both high and low provided, do band pass or band exclude
			if(clzr->high > clzr->low) for(i=0;i<N;i++) signal[i] = signal[i] >= clzr->low && signal[i] <= clzr->high; // band: 0 | 1 | 0
			else for(i=0;i<N;i++) signal[i] = (signal[i] >= clzr->low) - (signal[i] <= clzr->high); // region: -1 | 0 | +1
			break;
		case 1: // low not provided, do low pass
			for(i=0;i<N;i++) signal[i] = signal[i] <= clzr->high;
			break;
		case 2: // high not provided, do high pass
			for(i=0;i<N;i++) signal[i] = signal[i] >= clzr->low;
			break;
	}
	
	// check for events that meet the delta criterion
	//	a single sample always meets the delta criterion
	//  otherwise, 0 <= event_count <= N-1
	if(eventIndices!=NULL){
		if(N==1) eventIndices[event_count++] = 0;
		else for(i=1;i<N;i++) if(abs(signal[i]-signal[i-1]) >= clzr->delta) eventIndices[event_count++] = i;
	}
	return(event_count);
}

bool HIDxMakeDeviceQueue(HIDxDeviceStruct *HIDxDevice){
	pRecElement elm;
	register int i=0;
	IOHIDDeviceInterface122	**interface;
	IOHIDQueueInterface** queue;
	
	interface = HIDxDevice->device->interface;

	// try to allocate a queue
	queue = (*interface)->allocQueue(interface);
	
	if(queue){
	
		HIDxDevice->device->queue = queue;
	
		// make an actual queue with HIDx default depth
		(*queue)->create(queue, 0, QUEUE_DEPTH);

		// add all input, output, and feature device elements to the queue (ignore "collection" elements)
		for(elm=HIDGetFirstDeviceElement(HIDxDevice->device, kHIDElementTypeIO); elm!=NULL; elm=HIDGetNextDeviceElement(elm, kHIDElementTypeIO)){
			(*queue)->addElement(queue, elm->cookie, 0);
			HIDxDevice->cookie_monster[i++] = elm->cookie;
		}
		HIDxDevice->cookie_count = i;

		// fire up the queue
		(*queue)->start(queue);
		
		// create a source for event notification
		//	(or get the existing source)
		(*queue)->createAsyncEventSource(queue, &(HIDxDevice->source));

		// createAsyncEventSource behavior is unclear.
		//	is a new one getting allocated each call?
		//	looks like a new one gets allocated each HIDBuildDeviceList()
		//		then successive calls return the same instance
		//		so source should only be freed when HIDReleaseDeviceList() 
		//mexPrintf("%d\n", (int)HIDxDevice->source);

		// pass callback reference
		(*queue)->setEventCallout(queue, (IOHIDCallbackFunction)(HIDxDevice->callback), NULL, HIDxDevice);
		return(TRUE);
	} else {
		return(FALSE);
	}
}

// garbage cans for old queue events and reports
void flushQueueCallback(void *target,IOReturn result,void *refcon,void *sender){}
void flushReportsCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize){}

void cleanup(){

	if(initialized){
		// free device resources
		register int i;
		for(i=0; i<device_count; i++) releaseDevice(i);
		device_count = 0;
		initialized = FALSE;
		mexPrintf("HIDx cleaned up\n");
	}
}

void fullClose(){

		//only free the internal HID device list, interfaces, and queues when clearing the whole thing
		//	this is probably only when MATLAB exits
		
		// free the event sources
		//	there should be one event source allocated per device per HIDBuildDeviceList();
		//	and they should only be freed once per HIDReleaseDeviceList();
		int i;
		for(i=0; i<device_count; i++){
			if(devices[i].source != NULL){
				free(devices[i].source);
				devices[i].source = NULL;
			}
		}
		cleanup();
		HIDReleaseAllDeviceQueues();
		HIDReleaseDeviceList();
}

void releaseDevice(int HIDxIndex){

	// don't release any device twice
	if(HIDxIndex<=device_count && devices[HIDxIndex].device!=NULL){

		devices[HIDxIndex].device = NULL; // device memory can be freed by HIDReleaseDeviceList

		// recursively free any child devices (such as PMD reporters)
		if(devices[HIDxIndex].children_count > 0){
			int i;
			for(i=0;i<devices[HIDxIndex].children_count;i++) releaseDevice(devices[HIDxIndex].children[i]);
			devices[HIDxIndex].children_count = 0;
		}

		// take source out of CFRunLoop
		if(devices[HIDxIndex].source != NULL && CFRunLoopContainsSource(HIDxRunLoop, devices[HIDxIndex].source, HIDxRunLoopMode)){
			CFRunLoopRemoveSource(HIDxRunLoop, devices[HIDxIndex].source, HIDxRunLoopMode);
			CFRunLoopWakeUp(HIDxRunLoop);
		}
		
		// "invalidate" means take this source out of all CFRunLoop's and 'Modes, and possibly free the memory.
		//	"possibly" means only free if RunLoop contains only one reference to the source.  What does that mean?
		//if(devices[HIDxIndex].source != NULL && CFRunLoopSourceIsValid(devices[HIDxIndex].source)){
		//	CFRunLoopSourceInvalidate(devices[HIDxIndex].source);
		//	CFRunLoopWakeUp(HIDxRunLoop);
		//}

		// free the class name string
		if(devices[HIDxIndex].dXclass!=NULL){
			mxFree(devices[HIDxIndex].dXclass);
			devices[HIDxIndex].dXclass = NULL;
		}

		// destroy persistent mxArrays
		if(devices[HIDxIndex].rHIDPutDataArgs[0]!=NULL){
			mxDestroyArray(devices[HIDxIndex].rHIDPutDataArgs[0]);
			devices[HIDxIndex].rHIDPutDataArgs[0] = NULL;
		}
		if(devices[HIDxIndex].rHIDPutDataArgs[1]!=NULL){
			mxDestroyArray(devices[HIDxIndex].rHIDPutDataArgs[1]);
			devices[HIDxIndex].rHIDPutDataArgs[1] = NULL;
		}

		// free any device-custom allocation
		if(devices[HIDxIndex].extras!=NULL){
			free(devices[HIDxIndex].extras);
			devices[HIDxIndex].extras = NULL;
		}
	}
}