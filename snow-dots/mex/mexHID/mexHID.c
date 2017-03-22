/* mexHID.c
 * mexHID
 *
 * mexHID defines C "mex" routines for working with USB "Human Interface Devices" from Matlab.
 * mexHID can detect and configure HID devices and exchange data with them.
 *
 * mexHID.c defines the Matlab "mex" interface, only, and implements no functionality.
 *
 * The HID functionality required for mexHID is specified in some detail in mexHID.h.
 * The realization of that functionality must be platform-specific.  Any realization of mexHID 
 * should implement all the functions from mexHID.h, and incorporate mexHID.c.
 *
 * By Benjamin Heasly, University of Pennsylvania, 22 Feb. 2010
 */

#include "mexHID.h"
#include <string.h>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int status = mexHIDSuccess;
    char *command = NULL;
	
	mexAtExit(&mexHIDExit);
	
	// First argument should be a command string
    if(nrhs >= 1 && mxIsChar(prhs[0]) && mxGetM(prhs[0])==1)
        command = mxArrayToString(prhs[0]);
    
    if (command != NULL) {
		
        if(!strcmp(command, "initialize")) {
            //mexLock();
            status = mexHIDInitialize();
            
        } else if (!strcmp(command, "terminate")) {
            //while (mexIsLocked())
            //    mexUnlock();
            status = mexHIDTerminate();
			
		} else if (!strcmp(command, "isInitialized")) {
            status = mexHIDIsInitialized();
			
		} else if (!strcmp(command, "getOpenedDevices")) {
            mxArray* opened = mexHIDGetAllOpenDevices();
			if (opened != NULL)
				plhs[0] = opened;
			else
				plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
			mxFree(command);
			return;
			
		} else if (!strcmp(command, "check")) {
			double seconds = mexHIDCheck();
			plhs[0] = mxCreateDoubleScalar(seconds);
			mxFree(command);
			return;
            
        } else if (!strcmp(command, "summarizeDevices")) {
            mxArray* summary = mexHIDGetPropertiesForAllDevices();
			if (summary != NULL) {
				plhs[0] = summary;
				mxFree(command);
				return;
			} else
				status = mexHIDInternalFailure;
			
		} else if (!strcmp(command, "openMatchingDevice")) {
			if(nrhs >= 2 && mxIsStruct(prhs[1])) {
				int onlyFirstDevice = 1;
				int isExclusive = (nrhs >=3 && !mxIsEmpty(prhs[2]) && mxGetScalar(prhs[2]));
				mxArray* deviceIDs = mexHIDOpenDevicesMatchingProperties(prhs[1], onlyFirstDevice, isExclusive);
				if (deviceIDs != NULL) {
					plhs[0] = deviceIDs;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "openAllMatchingDevices")) {
			if(nrhs >= 2 && mxIsStruct(prhs[1])) {
				int onlyFirstDevice = 0;
				int isExclusive = (nrhs >=3 && !mxIsEmpty(prhs[2]) && mxGetScalar(prhs[2]));
				mxArray* deviceIDs = mexHIDOpenDevicesMatchingProperties(prhs[1], onlyFirstDevice, isExclusive);
				if (deviceIDs != NULL) {
					plhs[0] = deviceIDs;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "closeDevice")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				status = mexHIDCloseDevices(prhs[1]);
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "getDeviceProperties")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				mxArray* props = mexHIDGetPropertiesForDevices(prhs[1]);
				if (props != NULL) {
					plhs[0] = props;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;			
			
		} else if (!strcmp(command, "summarizeElements")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* elements = NULL;
				if(nrhs >= 3 && mxIsDouble(prhs[2]))
					elements = mexHIDGetAllPropertiesForDeviceElements(deviceID, prhs[2]);
				else
					elements = mexHIDGetAllPropertiesForAllDeviceElements(deviceID);
				
				if (elements != NULL) {
					plhs[0] = elements;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "findMatchingElements")) {
			if(nrhs >= 3 && mxIsDouble(prhs[1]) && mxIsStruct(prhs[2])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* elementCookies = mexHIDFindDeviceElementsMatchingProperties(deviceID, prhs[2]);
				if (elementCookies != NULL) {
					plhs[0] = elementCookies;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "getElementProperties")) {
			if(nrhs >= 4 && mxIsDouble(prhs[1]) && mxIsDouble(prhs[2]) && mxIsCell(prhs[3])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* values = mexHIDGetPropertiesForDeviceElements(deviceID, prhs[2], prhs[3]);
				if (values != NULL) {
					plhs[0] = values;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "setElementProperties")) {
			if(nrhs >= 4 && mxIsDouble(prhs[1]) && mxIsDouble(prhs[2]) && mxIsStruct(prhs[3])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				status = mexHIDSetPropertiesForDeviceElements(deviceID, prhs[2], prhs[3]);
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "readElementValues")) {
			if(nrhs >= 3 && mxIsDouble(prhs[1]) && mxIsDouble(prhs[2])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* timingData = NULL;
				mxArray* values = mexHIDReadValuesForDeviceElements(deviceID, prhs[2], &timingData);
				if (values != NULL) {
					plhs[0] = values;
					if (nlhs == 2)
						plhs[1] = timingData;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "writeElementValues")) {
			if(nrhs >= 4 && mxIsDouble(prhs[1]) && mxIsDouble(prhs[2]) && mxIsDouble(prhs[3])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* timingData = NULL;
				status = mexHIDWriteValuesForDeviceElements(deviceID, prhs[2], prhs[3], &timingData);
				if (status == mexHIDSuccess) {
					plhs[0] = mxCreateDoubleScalar((double)status);
					if (nlhs == 2)
						plhs[1] = timingData;
					mxFree(command);
					return;
				}
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "readDeviceReport")) {
			if(nrhs >= 3 && mxIsDouble(prhs[1]) && mxIsStruct(prhs[2]) 
			   && mxGetFieldNumber(prhs[2], kMexHIDReportType) >= 0
			   && mxGetFieldNumber(prhs[2], kMexHIDReportID) >= 0) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* timingData = NULL;
				mxArray* reportStruct = mexHIDReadDeviceReport(deviceID, prhs[2], &timingData);
				if (reportStruct != NULL) {
					plhs[0] = reportStruct;
					if (nlhs == 2)
						plhs[1] = timingData;
					mxFree(command);
					return;
				} else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "writeDeviceReport")) {
			if(nrhs >= 3 && mxIsDouble(prhs[1]) && mxIsStruct(prhs[2]) 
			   && mxGetFieldNumber(prhs[2], kMexHIDReportType) >= 0
			   && mxGetFieldNumber(prhs[2], kMexHIDReportID) >= 0
			   && mxGetFieldNumber(prhs[2], kMexHIDReportBytes) >= 0) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				mxArray* timingData = NULL;
				status = mexHIDWriteDeviceReport(deviceID, prhs[2], &timingData);
				if (status == mexHIDSuccess) {
					plhs[0] = mxCreateDoubleScalar((double)status);
					if (nlhs == 2)
						plhs[1] = timingData;
					mxFree(command);
					return;
				}
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "openQueue")) {
			if(nrhs >= 5 && mxIsDouble(prhs[1]) && mxIsDouble(prhs[2]) && mxIsCell(prhs[3]) && mxIsDouble(prhs[4])) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxGetScalar(prhs[1]);
				int queueDepth = mxGetScalar(prhs[4]);
				if (mxGetM(prhs[3]) * mxGetN(prhs[3]) == 2 && mxIsFunctionHandle(mxGetCell(prhs[3], 0)))
					status = mexHIDOpenQueueForDeviceElementsWithMatlabCallbackAndDepth(deviceID, prhs[2], prhs[3], queueDepth);
				else
					status = mexHIDInternalFailure;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "closeQueue")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				status = mexHIDCloseQueue(prhs[1]);
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "startQueue")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				status = mexHIDStartQueue(prhs[1]);
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "stopQueue")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				status = mexHIDStopQueue(prhs[1]);
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "flushQueue")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				status = mexHIDFlushQueue(prhs[1]);
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "getReportStructTemplate")) {
			plhs[0] = mexHIDGetReportStructTemplate();
			mxFree(command);
			return;
			
		} else if (!strcmp(command, "getNameForReportType")) {
			if(nrhs >= 2 && mxIsDouble(prhs[1])) {
				mexHIDReportType mexHIDType = (mexHIDReportType)mxGetScalar(prhs[1]);
				const char* name = mexHIDGetNameForReportType(mexHIDType);
				plhs[0] = mxCreateString(name);
				mxFree(command);
				return;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "getReportTypeForName")) {
			if(nrhs >= 2 && mxIsChar(prhs[1])) {
				char* name = mxArrayToString(prhs[1]);
				mexHIDReportType mexHIDType = mexHIDGetReportTypeForName((const char*)name);
				plhs[0] = mxCreateDoubleScalar((double)mexHIDType);
				mxFree(name);
				mxFree(command);
				return;
			} else
				status = mexHIDWrongArguments;
			
		} else if (!strcmp(command, "getDescriptionOfReturnValue")) {
			const char* description;
			if(nrhs >= 2) {
				description = mexHIDGetDescriptionOfReturnValue(prhs[1]);
			} else {
				description = mexHIDGetDescriptionOfReturnValue(NULL);
			}
			plhs[0] = mxCreateString(description);
			mxFree(command);
			return;
			
		} else
			status = mexHIDUnknownCommand;
		
		mxFree(command);
		plhs[0] = mxCreateDoubleScalar((double)status);
		if (nlhs == 2)
			plhs[1] = mxCreateDoubleScalar(mexHIDInternalFailure);
		
	} else {
		
		mexPrintf("mexHID basics:\n %s\n %s\n %s\n %s\n\n",
				  "status = mexHID('initialize')",
				  "status = mexHID('terminate')",
				  "timestamp = mexHID('check')",
				  "isInitialized = mexHID('isInitialized')");
		
		mexPrintf("mexHID devices:\n %s\n %s\n %s\n %s\n %s\n %s\n %s\n %s\n\n",
				  "deviceIDs = mexHID('getOpenedDevices')",
				  "infoStruct = mexHID('summarizeDevices')",
				  "deviceID = mexHID('openMatchingDevice', matchingStruct [,isExclusive])",
				  "deviceIDs = mexHID('openAllMatchingDevices', matchingStruct [,isExclusive])",
				  "infoStruct = mexHID('getDeviceProperties', deviceIDs)",
				  "[reportStruct, timing] = mexHID('readDeviceReport', deviceID, reportStruct)",
				  "[status, timing] = mexHID('writeDeviceReport', deviceID, reportStruct)",
				  "status = mexHID('closeDevice', deviceIDs)");
		
		mexPrintf("mexHID device elements:\n %s\n %s\n %s\n %s\n %s\n %s\n\n",
				  "infoStruct = mexHID('summarizeElements', deviceID [,matchingStruct]);",
				  "cookies = mexHID('findMatchingElements', deviceID, matchingStruct)",
				  "infoStruct = mexHID('getElementProperties', deviceID, cookies, propertyNameCell)",
				  "status = mexHID('setElementProperties', deviceID, cookies, propertyValueStruct)",
				  "[data, timing] = mexHID('readElementValues', deviceID, cookies)",
				  "[status, timing] = mexHID('writeElementValues', deviceID, cookies, values)");
		
		mexPrintf("mexHID device queues:\n %s\n %s\n %s\n %s\n %s\n\n",
				  "status = mexHID('openQueue', deviceID, cookies, callbackCell, queueDepth)",
				  "status = mexHID('closeQueue', deviceIDs)",
				  "status = mexHID('startQueue', deviceIDs)",
				  "status = mexHID('stopQueue', deviceIDs)",
				  "status = mexHID('flushQueue', deviceIDs)");
		
		mexPrintf("mexHID internals:\n %s\n %s\n %s\n %s\n\n",
				  "reportStruct = mexHID('getReportStructTemplate')",
				  "name = mexHID('getNameForReportType', reportType)",
				  "type = mexHID('getReportTypeForName', name)",
				  "description = mexHID('getDescriptionOfReturnValue', returnValue)");
	}
}

mxArray* mexHIDGetReportStructTemplate() {
	mxArray* reportStruct = NULL;
	static const char* mexHIDReportFields[] = { 
		kMexHIDReportID,
		kMexHIDReportType, 
		kMexHIDReportBytes,
	};
	int nFields = sizeof(mexHIDReportFields)/sizeof(mexHIDReportFields[0]);
	reportStruct = mxCreateStructMatrix(1, 1, nFields, mexHIDReportFields);
	if (reportStruct != NULL) {
		int ii;
		for (ii=0; ii<nFields; ii++) {
			mxSetFieldByNumber(reportStruct, 0, ii, mxCreateDoubleMatrix(0, 0, mxREAL));
		}
	}
	return(reportStruct);
}

const char* mexHIDGetNameForReportType(mexHIDReportType mexHIDType) {
	switch (mexHIDType) {
		case mexHIDInputReport:
			return(kMexHIDInputReportName);
			break;
		case mexHIDOutputReport:
			return(kMexHIDOutputReportName);
			break;
		case mexHIDFeatureReport:
			return(kMexHIDFeatureReportName);
			break;
		case mexHIDCountReport:
			return(kMexHIDCountReportName);
			break;
        case mexHIDUnknownReport:
            break;
	}
	return(kMexHIDUnknownReportName);
}

mexHIDReportType mexHIDGetReportTypeForName(const char* typeName) {	
	if (!strcmp(typeName, kMexHIDInputReportName)) {
		return(mexHIDInputReport); 
	} else 	if (!strcmp(typeName, kMexHIDOutputReportName)) {
		return(mexHIDOutputReport); 
	} else 	if (!strcmp(typeName, kMexHIDFeatureReportName)) {
		return(mexHIDFeatureReport); 
	} else 	if (!strcmp(typeName, kMexHIDCountReportName)) {
		return(mexHIDCountReport); 
	}
	return(mexHIDUnknownReport);
}

const char* mexHIDGetDescriptionOfReturnValue(const mxArray* returnValue) {
	if (returnValue!=NULL && !mxIsEmpty(returnValue)) {
		if (mxGetNumberOfElements(returnValue)==1 && mxIsNumeric(returnValue)) {
			mexHIDReturn scalar = mxGetScalar(returnValue);
			if (scalar < 0) {
				if (scalar==mexHIDSuccess) {
					return("success");
				} else if (scalar==mexHIDUnknownCommand) {
					return("unknown command");
				} else if (scalar==mexHIDWrongArguments) {
					return("wrong arguments");
				} else if (scalar % mexHIDInternalFailure == 0) {
					return("internal failure");
				} else if (scalar % mexHIDCantInitialize == 0) {
					return("can't initialize");
				} else if (scalar % mexHIDCantOpenDevice == 0) {
					return("can't open device");
				} else
					return("unrecognized error");
			} else
				return("not an error");
		} else
			return("looks like data");
	} else
		return("no value to describe");
}