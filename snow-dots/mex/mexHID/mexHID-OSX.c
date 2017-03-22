/* mexHID-OSX.c
 * mexHID
 *
 * mexHID defines C "mex" routines for working with USB "Human Interface Devices" from Matlab.
 * mexHID can detect and configure HID devices and exchange data with them.
 *
 * mexHID-OSX.c realizes the functions from mexHID.h using the Core Foundation and IOKit frameworks of OS-X.
 *
 * By Benjamin Heasly, University of Pennsylvania, 22 Feb. 2010
 */

#include "mexHID-OSX.h"

#pragma mark mexHID.h implementation
mexHIDReturn mexHIDInitialize(void) {
	
	if (mexHIDManager != NULL || mexHIDOpenDevices != NULL)
		mexHIDTerminate();
	
	mexHIDOpenDevices = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
	if (mexHIDOpenDevices == NULL)
		return(mexHIDInternalFailure);
	
	mexHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
	if (mexHIDManager != NULL && CFGetTypeID(mexHIDManager) == IOHIDManagerGetTypeID())	{
		return(mexHIDSuccess);
	} else {
		mexHIDTerminate();
		return(mexHIDCantInitialize);
	}
}

mexHIDReturn mexHIDTerminate(void) {
	if (mexHIDOpenDevices != NULL && CFGetTypeID(mexHIDOpenDevices) == CFDictionaryGetTypeID()) {
		CFDictionaryApplyFunction(mexHIDOpenDevices, &mexHIDCloseEntryDevice, NULL);
		CFRelease(mexHIDOpenDevices);
	}
	mexHIDOpenDevices = NULL;
	mexHIDOpenDeviceCount = 0;
	
	if (mexHIDManager != NULL && CFGetTypeID(mexHIDManager) == IOHIDManagerGetTypeID()) {
		CFRelease(mexHIDManager);
	}
	mexHIDManager = NULL;
	return(mexHIDSuccess);
}

void mexHIDExit(void) {
	mexHIDTerminate();
}

int mexHIDIsInitialized(void) {
	int isInitialized = 0;
	if (mexHIDOpenDevices != NULL && CFGetTypeID(mexHIDOpenDevices) == CFDictionaryGetTypeID()) {
		if (mexHIDManager != NULL && CFGetTypeID(mexHIDManager) == IOHIDManagerGetTypeID()) {
			isInitialized = 1;
		}
	}
	return(isInitialized);
}

mxArray* mexHIDGetAllOpenDevices(void) {
	mexHIDArrayElement mxElement;
	mxElement.mx = NULL;
	mxElement.elementIndex = 0;
	if (mexHIDOpenDevices != NULL && CFGetTypeID(mexHIDOpenDevices) == CFDictionaryGetTypeID()) {
		int nDevices = (int)CFDictionaryGetCount(mexHIDOpenDevices);
		mxElement.mx = mxCreateDoubleMatrix(1, nDevices, mxREAL);
		CFDictionaryApplyFunction(mexHIDOpenDevices, &mexHIDCopyKeyNumberToMxDouble, &mxElement);
	}
	return(mxElement.mx);
}

double mexHIDCheck(void) {
	double seconds = 0;
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, FALSE);
	seconds = mexHIDGetOSAbsoluteTimeInSeconds();
	return(seconds);
}

mxArray* mexHIDGetPropertiesForAllDevices(void) {
	
	if (mexHIDManager == NULL || CFGetTypeID(mexHIDManager) != IOHIDManagerGetTypeID())
		return(NULL);
	
	// match all HID devices
	IOHIDManagerSetDeviceMatching(mexHIDManager, NULL);
	CFSetRef allDevices = IOHIDManagerCopyDevices(mexHIDManager);
	if (allDevices == NULL || CFGetTypeID(allDevices) != CFSetGetTypeID())
		return(NULL);
	
	int nDevices = (int)CFSetGetCount(allDevices);
	mexHIDStructSlice slice;
	slice.mxStruct = mxCreateStructMatrix(1, nDevices, mexHIDDevicePropertyCount, mexHIDDevicePropertyKeys);
	slice.sliceIndex = 0;
	
	if (slice.mxStruct != NULL)
		CFSetApplyFunction(allDevices, &mexHIDCopyDevicePropertiesToMxStructSlice, &slice);
	
	CFRelease(allDevices);
	return(slice.mxStruct);
}

mxArray* mexHIDOpenDevicesMatchingProperties(const mxArray* propStruct, int onlyFirstDevice, int isExclusive) {
	mxArray* deviceIDs = NULL;
	
	if (mexHIDManager != NULL && CFGetTypeID(mexHIDManager) == IOHIDManagerGetTypeID()) {
		if (propStruct != NULL && mxIsStruct(propStruct)) {
			CFDictionaryRef deviceMatching = mexHIDCreateCFDictionaryFromMxStructScalar(propStruct);
			if (deviceMatching != NULL && CFGetTypeID(deviceMatching) == CFDictionaryGetTypeID()) {
				if (CFDictionaryGetCount(deviceMatching) > 0)
					IOHIDManagerSetDeviceMatching(mexHIDManager, deviceMatching);
				else
					IOHIDManagerSetDeviceMatching(mexHIDManager, NULL);
				
				CFSetRef allDevices = IOHIDManagerCopyDevices(mexHIDManager);
				if (allDevices != NULL && CFGetTypeID(allDevices) == CFSetGetTypeID()) {
					int nDevices = (int)CFSetGetCount(allDevices);
					if (nDevices > 0) {
						// copy all devices.
						const void** devicePtrs = mxCalloc(nDevices, sizeof(void*));
						CFSetGetValues(allDevices, devicePtrs);
						
						// Open, retain, and return all devices, or just the first device.
						int ii, nReturns;
						if (onlyFirstDevice)
							nReturns = 1;
						else
							nReturns = nDevices;	
						
						// Optionally sieze the device(s) to get exclusive comminucation
						IOOptionBits openOptions = kIOHIDOptionsTypeNone;
						if (isExclusive)
							openOptions = kIOHIDOptionsTypeSeizeDevice;
						
						deviceIDs = mxCreateDoubleMatrix(1, nReturns, mxREAL);
						double* mxDoublePtr = mxGetPr(deviceIDs);
						if (mxDoublePtr != NULL) {
							for (ii=0; ii<nReturns; ii++) {
								IOHIDDeviceRef device = (IOHIDDeviceRef)devicePtrs[ii];
								IOReturn openResult = IOHIDDeviceOpen(device, openOptions);
								if (openResult == kIOReturnSuccess) {
									mexHIDDeviceID deviceID = mexHIDRetainDevice(device);
									mexHIDSetDefaultCalibrationsForAllElements(deviceID);
									mxDoublePtr[ii] = (double)deviceID;
								} else {
									mxDoublePtr[ii] = (double)mexHIDCantOpenDevice;
								}
							}
						}
						mxFree(devicePtrs);
					} 
					CFRelease(allDevices);
				}
				CFRelease(deviceMatching);
			}
		}
	}
	return(deviceIDs);
}

mxArray* mexHIDGetPropertiesForDevices(const mxArray* deviceIDs) {
	mexHIDStructSlice deviceProps;
	deviceProps.mxStruct = NULL;
	deviceProps.sliceIndex = 0;
	
	double* mxDoublePtr = mxGetPr(deviceIDs);
	if (deviceIDs != NULL && mxIsDouble(deviceIDs) && mxDoublePtr != NULL) {
		int nDevices = mxGetN(deviceIDs) * mxGetM(deviceIDs);
		
		deviceProps.mxStruct = mxCreateStructMatrix(1, nDevices, mexHIDDevicePropertyCount, mexHIDDevicePropertyKeys);
		if (deviceProps.mxStruct != NULL) {
			int ii;
			for (ii=0; ii<nDevices; ii++) {
				mexHIDDeviceID deviceID = (mexHIDDeviceID)mxDoublePtr[ii];
				mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
				if (info != NULL && info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
					deviceProps.sliceIndex = ii;
					mexHIDCopyDevicePropertiesToMxStructSlice(info->device, &deviceProps);					
				}
			}
		}
	}
	return(deviceProps.mxStruct);
}

mexHIDReturn mexHIDCloseDevices(const mxArray* deviceIDs) {
	mexHIDReturn status = mexHIDSuccess;
	
	double* mxDoublePtr = mxGetPr(deviceIDs);
	if (deviceIDs != NULL && mxIsDouble(deviceIDs) && mxDoublePtr != NULL) {
		int nDevices = mxGetN(deviceIDs) * mxGetM(deviceIDs);
		
		int ii;
		for (ii=0; ii<nDevices; ii++) {
			mexHIDDeviceID deviceID = (mexHIDDeviceID)mxDoublePtr[ii];
			mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
			if (info != NULL && info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
				IOHIDDeviceClose(info->device, kIOHIDOptionsTypeNone);
				status += mexHIDReleaseDevice(deviceID);
			}
		}
	}
	return(status);
}

mxArray* mexHIDFindDeviceElementsMatchingProperties(mexHIDDeviceID deviceID, const mxArray* propStruct) {
	mxArray* elementCookies = NULL;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->elementsByCookie != NULL && CFGetTypeID(info->elementsByCookie) == CFDictionaryGetTypeID()) {
			if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
				if (propStruct != NULL && mxIsStruct(propStruct)) {
					CFDictionaryRef elementMatching = mexHIDCreateCFDictionaryFromMxStructScalar(propStruct);
					if (elementMatching != NULL && CFGetTypeID(elementMatching) == CFDictionaryGetTypeID()) {
						if (CFDictionaryGetCount(elementMatching) > 0) {
							CFArrayRef elements = IOHIDDeviceCopyMatchingElements(info->device, elementMatching, kIOHIDOptionsTypeNone);
							if (elements != NULL && CFGetTypeID(elements) == CFArrayGetTypeID()) {
								int nElements = (int)CFArrayGetCount(elements);
								if (nElements > 0) {
									elementCookies = mxCreateDoubleMatrix(1, nElements, mxREAL);
									if (elementCookies != NULL) {
										double* mxDoublePtr = mxGetPr(elementCookies);
										int ii;
										for (ii=0; ii<nElements; ii++) {
											IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, ii);
											CFNumberRef cfCookie = (CFNumberRef)mexHIDWorkaround_IOHIDElementCopyProperty(element, CFSTR(kIOHIDElementCookieKey));
											double d;
											CFNumberGetValue(cfCookie, kCFNumberDoubleType, &d);
											mxDoublePtr[ii] = d;
										}
									}
								}
								CFRelease(elements);
							}
						}
						CFRelease(elementMatching);
					}
				}
			}
		}
	}
	return(elementCookies);
}

mxArray* mexHIDGetAllPropertiesForAllDeviceElements(mexHIDDeviceID deviceID) {
	mxArray* propStruct = NULL;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->elementsByCookie != NULL && CFGetTypeID(info->elementsByCookie) == CFDictionaryGetTypeID()) {
			CFArrayRef allElements = mexHIDCreateCFArrayFromCFDictionaryValues(info->elementsByCookie);
			if (allElements != NULL && CFGetTypeID(allElements) == CFArrayGetTypeID()) {
				propStruct = mexHIDCopyElementsPropertiesToMxStruct(allElements, mexHIDElementPropertyKeys, mexHIDElementPropertyCount);
				CFRelease(allElements);
			}
		}
	}
	return(propStruct);
}

mxArray* mexHIDGetAllPropertiesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies) {
	mxArray* propStruct = NULL;
	CFArrayRef elementsInOrder = mexHIDCopyDeviceElementsForCookies(deviceID, elementCookies);
	if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
		propStruct = mexHIDCopyElementsPropertiesToMxStruct(elementsInOrder, mexHIDElementPropertyKeys, mexHIDElementPropertyCount);
		CFRelease(elementsInOrder);
	}
	return(propStruct);
}

mxArray* mexHIDGetPropertiesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* propNames) {
	mxArray* propStruct = NULL;
	if (propNames != NULL && mxIsCell(propNames)) {
		int nProps = mxGetM(propNames) * mxGetN(propNames);
		if (nProps > 0) {
			char* propString;
			char** validPropNames = mxCalloc(nProps, sizeof(propString));
			if (validPropNames != NULL) {
				int ii;
				int nValidProps = 0;
				for (ii=0; ii<nProps; ii++) {
					mxArray* propNameMx = mxGetCell(propNames, ii);
					if (propNameMx != NULL && mxIsChar(propNameMx)) {
						propString = mxArrayToString(propNameMx);
						if (propString != NULL) {
							validPropNames[nValidProps] = propString;
							nValidProps++;
						}
					}
				}
				if (nValidProps > 0) {
					CFArrayRef elementsInOrder = mexHIDCopyDeviceElementsForCookies(deviceID, elementCookies);
					if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
						propStruct = mexHIDCopyElementsPropertiesToMxStruct(elementsInOrder, (const char **)validPropNames, nValidProps);
						CFRelease(elementsInOrder);
					}
					for (ii=0; ii<nValidProps; ii++)
						mxFree(validPropNames[ii]);
				}
				mxFree(validPropNames);
			}
		}
	}
	return(propStruct);
}

mexHIDReturn mexHIDSetPropertiesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* propStruct) {
	mexHIDReturn status = mexHIDInternalFailure;
	if (propStruct != NULL && mxIsStruct(propStruct)) {
		int nProps = mxGetNumberOfFields(propStruct);
		if (nProps > 0) {
			CFArrayRef elementsInOrder = mexHIDCopyDeviceElementsForCookies(deviceID, elementCookies);
			if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
				int nElements = (int)CFArrayGetCount(elementsInOrder);
				if (nElements > 0) {
					int nSlices = mxGetM(propStruct) * mxGetN(propStruct);
					int sliceIndex = 0;
					int ii, jj;
					for (ii=0; ii<nProps; ii++) {
						const char* propString = mxGetFieldNameByNumber(propStruct, ii);
						CFStringRef cfKey = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, propString, kCFStringEncodingUTF8, kCFAllocatorNull);
						if (cfKey != NULL) {
							for(jj=0; jj<nElements; jj++) {
								if (nElements == nSlices)
									sliceIndex = jj;
								IOHIDElementRef el = (IOHIDElementRef)CFArrayGetValueAtIndex(elementsInOrder, jj);
								mxArray* mxValue = mxGetFieldByNumber(propStruct, sliceIndex, ii);
								if (mxValue != NULL) {
									CFTypeRef cfValue = mexHIDCreateCFValueFromMxArray(mxValue);
									if (cfValue != NULL) {
										IOHIDElementSetProperty(el, cfKey, cfValue);
										CFRelease(cfValue);
										status = mexHIDSuccess;
									}
								}
							}
							CFRelease(cfKey);
						}
					}
				}
				CFRelease(elementsInOrder);
			}
		}
	}
	return(status);
}

// Would like to use IOHIDTransaction or IOHIDDeviceCopyValueMultiple 
// but IOHIDDeviceGetValue, one element, works more often.
mxArray* mexHIDReadValuesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, mxArray** timingData) {
	mxArray* elementValues = NULL;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
			CFArrayRef elementsInOrder = mexHIDCopyDeviceElementsForCookies(deviceID, elementCookies);
			if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
				int nElements = (int)CFArrayGetCount(elementsInOrder);
				elementValues = mxCreateDoubleMatrix(nElements, 3, mxREAL);
				double* mxDoublePtr = mxGetPr(elementValues);
				
				*timingData = mxCreateDoubleMatrix(nElements, 5, mxREAL);
				double* mxTimingPtr = mxGetPr(*timingData);
				if (elementValues != NULL && mxDoublePtr != NULL && *timingData != NULL && mxTimingPtr != NULL) {
					int ii;
					for(ii=0; ii<nElements; ii++) {
						IOHIDElementRef el = (IOHIDElementRef)CFArrayGetValueAtIndex(elementsInOrder, ii);
						IOHIDValueRef elValue;
						CFIndex elCookie = (CFIndex)IOHIDElementGetCookie(el);
						mxDoublePtr[ii] = (double)elCookie;
						mxTimingPtr[ii] = (double)elCookie;
						
						mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+1*nElements+ii, mxTimingPtr+2*nElements+ii);
						IOReturn getResult = IOHIDDeviceGetValue(info->device, el, &elValue);
						mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+3*nElements+ii, mxTimingPtr+4*nElements+ii);
						
						if (getResult == kIOReturnSuccess) {
							double_t elCalibrated = IOHIDValueGetScaledValue(elValue, kIOHIDValueScaleTypeCalibrated);
							mxDoublePtr[nElements + ii] = (double)elCalibrated;
							
							uint64_t elTimeStamp = IOHIDValueGetTimeStamp(elValue);
							mxDoublePtr[2*nElements + ii] = mexHIDOSAbsoluteTimeToSeconds(elTimeStamp);
						}
					}
				}
				CFRelease(elementsInOrder);
			}
		}
	}
	return(elementValues);
}

// Would like to use IOHIDTransaction or IOHIDDeviceSetValueMultiple 
// but IOHIDDeviceSetValue, one element, works more often.
mexHIDReturn mexHIDWriteValuesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* elementValues, mxArray** timingData) {
	mexHIDReturn status = mexHIDSuccess;	
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
			CFArrayRef elementsInOrder = mexHIDCopyDeviceElementsForCookies(deviceID, elementCookies);
			if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
				int nElements = (int)CFArrayGetCount(elementsInOrder);
				*timingData = mxCreateDoubleMatrix(nElements, 5, mxREAL);
				double* mxTimingPtr = mxGetPr(*timingData);
				if (elementValues != NULL && mxIsDouble(elementValues) && *timingData != NULL && mxTimingPtr != NULL) {
					int nValues = mxGetM(elementValues) * mxGetN(elementValues);
					int valueIndex = 0;
					double* mxDoublePtr = mxGetPr(elementValues);
					if (nValues > 0 && mxDoublePtr != NULL) {
						int ii;
						for(ii=0; ii<nElements; ii++) {
							if (nValues == nElements)
								valueIndex = ii;
							double d = mxDoublePtr[valueIndex];
							
							IOHIDElementRef el = (IOHIDElementRef)CFArrayGetValueAtIndex(elementsInOrder, ii);
							CFIndex elCookie = (CFIndex)IOHIDElementGetCookie(el);
							mxTimingPtr[ii] = (double)elCookie;
							
							IOHIDValueRef elValue = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault, el, 0, (CFIndex)d);
							if (elValue != NULL) {
								mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+1*nElements+ii, mxTimingPtr+2*nElements+ii);
								IOReturn setResult = IOHIDDeviceSetValue(info->device, el, elValue);
								mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+3*nElements+ii, mxTimingPtr+4*nElements+ii);
								CFRelease(elValue);
								
								if (setResult != kIOReturnSuccess)
									status += mexHIDInternalFailure;
							}
						}
					}
				}
				CFRelease(elementsInOrder);
			}
		}
	}
	return(status);
}

mxArray* mexHIDReadDeviceReport(mexHIDDeviceID deviceID, const mxArray* reportStruct, mxArray** timingData) {
	mxArray* newReportStruct = NULL;
	
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
			newReportStruct = mxDuplicateArray(reportStruct);
			if (mxGetFieldNumber(newReportStruct, kMexHIDReportBytes) < 0)
				mxAddField(newReportStruct, kMexHIDReportBytes);
			
			int nReports = mxGetM(reportStruct) * mxGetN(reportStruct);
			*timingData = mxCreateDoubleMatrix(nReports, 5, mxREAL);
			double* mxTimingPtr = mxGetPr(*timingData);
			
			int ii;
			for(ii=0; ii<nReports; ii++) {
				double reportID = mxGetScalar(mxGetField(reportStruct, ii, kMexHIDReportID));
				mxTimingPtr[ii] = reportID;
				
				mexHIDReportType mexHIDType = (mexHIDReportType)mxGetScalar(mxGetField(reportStruct, ii, kMexHIDReportType));
				IOHIDReportType IOHIDType;
				int reportLength = -1;
				reportLength = mexHIDGetReportLengthAndIOHIDTypeForDeviceAndMexHIDType(&IOHIDType, info->device, mexHIDType);
				
				if (reportLength >= 0 && reportID >= 0) {
					char* bytes = mxMalloc(reportLength);
					if (bytes != NULL) {
						mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+1*nReports+ii, mxTimingPtr+2*nReports+ii);
						IOReturn readResult = IOHIDDeviceGetReport(info->device, IOHIDType, (CFIndex)reportID, (uint8_t*)bytes, (CFIndex*)&reportLength);
						mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+3*nReports+ii, mxTimingPtr+4*nReports+ii);
						
						if (readResult == kIOReturnSuccess) {
							mxArray* reportBytes = mxCreateNumericMatrix(1, reportLength, mxUINT8_CLASS, mxREAL);
							char* mxBytePrt = mxGetData(reportBytes);
							memcpy(mxBytePrt, bytes, reportLength);
							mxSetField(newReportStruct, ii, kMexHIDReportBytes, reportBytes);
						}//else mexPrintf("bad report reading: %x\n", readResult);
						
						mxFree(bytes);
						bytes = NULL;
					}
				}
			}
		}
	}
	return(newReportStruct);
}

mexHIDReturn mexHIDWriteDeviceReport(mexHIDDeviceID deviceID, const mxArray* reportStruct, mxArray** timingData) {
	mexHIDReturn status = mexHIDSuccess;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
			int nReports = mxGetM(reportStruct) * mxGetN(reportStruct);
			*timingData = mxCreateDoubleMatrix(nReports, 5, mxREAL);
			double* mxTimingPtr = mxGetPr(*timingData);
			
			int ii;
			for(ii=0; ii<nReports; ii++) {
				double reportID = mxGetScalar(mxGetField(reportStruct, ii, kMexHIDReportID));
				mxTimingPtr[ii] = reportID;
				
				mexHIDReportType mexHIDType = (mexHIDReportType)mxGetScalar(mxGetField(reportStruct, ii, kMexHIDReportType));
				IOHIDReportType IOHIDType;
				int reportLength = -1;
				reportLength = mexHIDGetReportLengthAndIOHIDTypeForDeviceAndMexHIDType(&IOHIDType, info->device, mexHIDType);
				if (reportLength >= 0 && reportID >= 0) {
					mxArray* reportBytes = mxGetField(reportStruct, ii, kMexHIDReportBytes);
					char* bytes = mxGetData(reportBytes);
					reportLength = mxGetN(reportBytes) * mxGetM(reportBytes);
					
					mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+1*nReports+ii, mxTimingPtr+2*nReports+ii);
					IOReturn writeResult = IOHIDDeviceSetReport(info->device, IOHIDType, reportID, (uint8_t*)bytes, reportLength);
					mexHIDGetUSBFrameNumberAndSeconds(info, mxTimingPtr+3*nReports+ii, mxTimingPtr+4*nReports+ii);
					
					if (writeResult != kIOReturnSuccess) {
						status += mexHIDInternalFailure;
					} //else mexPrintf("bad report writing: %x\n", writeResult);
				}
			}
		}
	}
	return(status);
}


mexHIDReturn mexHIDOpenQueueForDeviceElementsWithMatlabCallbackAndDepth(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* matlabCallback, int queueDepth) {
	mexHIDReturn status = mexHIDInternalFailure;
	mexHIDCloseQueue(mxCreateDoubleScalar((double)deviceID));
	
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
			if (matlabCallback != NULL && mxIsCell(matlabCallback) && mxGetM(matlabCallback) * mxGetN(matlabCallback) == 2) {
				info->queueCallbackMatlabFcn = mxDuplicateArray(mxGetCell(matlabCallback, 0));
				info->queueCallbackMatlabContext = mxDuplicateArray(mxGetCell(matlabCallback, 1));
				if (info->queueCallbackMatlabFcn != NULL && info->queueCallbackMatlabContext != NULL) {
					mexMakeArrayPersistent(info->queueCallbackMatlabFcn);
					mexMakeArrayPersistent(info->queueCallbackMatlabContext);
					if (queueDepth > 0) {
						CFArrayRef elementsInOrder = mexHIDCopyDeviceElementsForCookies(deviceID, elementCookies);
						if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
							int nElements = (int)CFArrayGetCount(elementsInOrder);
							if (nElements > 0) { 
								info->queue = IOHIDQueueCreate(kCFAllocatorDefault, info->device, (CFIndex)queueDepth, kIOHIDOptionsTypeNone);
								if (info->queue != NULL && CFGetTypeID(info->queue) == IOHIDQueueGetTypeID()) {
									IOHIDQueueRegisterValueAvailableCallback(info->queue, &mexHIDQueueDataToMatlab, info);
									IOHIDQueueScheduleWithRunLoop(info->queue, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
									mexHIDCheck();
									int ii;
									for (ii=0; ii<nElements; ii++)
										IOHIDQueueAddElement(info->queue, (IOHIDElementRef)CFArrayGetValueAtIndex(elementsInOrder, ii));
									status = mexHIDSuccess;
								}
							}
							CFRelease(elementsInOrder);
						}
					}
				}
			}
		}
	}
	if (status != mexHIDSuccess)
		mexHIDCloseQueue(mxCreateDoubleScalar((double)deviceID));
	return(status);
}

mexHIDReturn mexHIDCloseQueue(const mxArray* deviceIDs) {
	mexHIDReturn status = mexHIDSuccess;
	
	double* mxDoublePtr = mxGetPr(deviceIDs);
	if (deviceIDs != NULL && mxIsDouble(deviceIDs) && mxDoublePtr != NULL) {
		int nDevices = mxGetN(deviceIDs) * mxGetM(deviceIDs);
		int ii;
		for (ii=0; ii<nDevices; ii++) {
			mexHIDDeviceID deviceID = (mexHIDDeviceID)mxDoublePtr[ii];
			mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
			if (info != NULL) {
				if (info->queue != NULL && CFGetTypeID(info->queue) == IOHIDQueueGetTypeID()) {
					IOHIDQueueStop(info->queue);
					IOHIDQueueRegisterValueAvailableCallback(info->queue, NULL, NULL);
					IOHIDQueueUnscheduleFromRunLoop(info->queue, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
					mexHIDCheck();
					CFRelease(info->queue);
				}
				info->queue = NULL;
				
				if (info->queueCallbackMatlabContext != NULL) {
					mxDestroyArray(info->queueCallbackMatlabContext);
				}
				info->queueCallbackMatlabContext = NULL;
				
				if (info->queueCallbackMatlabFcn != NULL) {
					mxDestroyArray(info->queueCallbackMatlabFcn);
				}
				info->queueCallbackMatlabFcn = NULL;
			}
		}
	}
	return(status);
}

mexHIDReturn mexHIDStartQueue(const mxArray* deviceIDs) {
	mexHIDReturn status = mexHIDInternalFailure;
	
	double* mxDoublePtr = mxGetPr(deviceIDs);
	if (deviceIDs != NULL && mxIsDouble(deviceIDs) && mxDoublePtr != NULL) {
		int nDevices = mxGetN(deviceIDs) * mxGetM(deviceIDs);
		int ii;
		for (ii=0; ii<nDevices; ii++) {
			mexHIDDeviceID deviceID = (mexHIDDeviceID)mxDoublePtr[ii];
			mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
			if (info != NULL) {
				if (info->queue != NULL && CFGetTypeID(info->queue) == IOHIDQueueGetTypeID()) {
					IOHIDQueueStart(info->queue);
					status = mexHIDSuccess;
				}
			}
		}
	}
	return(status);
}

mexHIDReturn mexHIDStopQueue(const mxArray* deviceIDs) {
	mexHIDReturn status = mexHIDInternalFailure;
	
	double* mxDoublePtr = mxGetPr(deviceIDs);
	if (deviceIDs != NULL && mxIsDouble(deviceIDs) && mxDoublePtr != NULL) {
		int nDevices = mxGetN(deviceIDs) * mxGetM(deviceIDs);
		int ii;
		for (ii=0; ii<nDevices; ii++) {
			mexHIDDeviceID deviceID = (mexHIDDeviceID)mxDoublePtr[ii];			
			mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
			if (info != NULL) {
				if (info->queue != NULL && CFGetTypeID(info->queue) == IOHIDQueueGetTypeID()) {
					IOHIDQueueStop(info->queue);
					status = mexHIDSuccess;
				}
			}	
		}
	}
	return(status);
}

mexHIDReturn mexHIDFlushQueue(const mxArray* deviceIDs) {
	mexHIDReturn status = mexHIDInternalFailure;
	
	double* mxDoublePtr = mxGetPr(deviceIDs);
    
	if (deviceIDs != NULL && mxIsDouble(deviceIDs) && mxDoublePtr != NULL) {
		int nDevices = mxGetN(deviceIDs) * mxGetM(deviceIDs);
		int ii;
		for (ii=0; ii<nDevices; ii++) {
			mexHIDDeviceID deviceID = (mexHIDDeviceID)mxDoublePtr[ii];
			mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
			if (info != NULL) {
				if (info->queue != NULL && CFGetTypeID(info->queue) == IOHIDQueueGetTypeID()) {
					IOHIDQueueStop(info->queue);
					// jig changed April 2016 
					//IOHIDQueueRegisterValueAvailableCallback(info->queue, &mexHIDQueueFlushData, info);
					//mexHIDCheck();
					IOHIDQueueRegisterValueAvailableCallback(info->queue, &mexHIDQueueDataToMatlab, info);
					mexHIDCheck();
					status = mexHIDSuccess;
				}
			}
		}
	}
	return(status);
}

#pragma mark UIKit HID device utilities

mexHIDDeviceID mexHIDRetainDevice(IOHIDDeviceRef device) {
	mexHIDDeviceID deviceID = -1;
	if (mexHIDOpenDevices != NULL && CFGetTypeID(mexHIDOpenDevices) == CFDictionaryGetTypeID()) {
		if (device != NULL && CFGetTypeID(device) == IOHIDDeviceGetTypeID()) {
			// hashing from devices is not unique enough to distinguish them (!?)
			//	instead, count devices and forget about reusing them
			mexHIDOpenDeviceCount++;
			CFNumberRef deviceKey = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongType, &mexHIDOpenDeviceCount);
			if (deviceKey != NULL) {
				if (CFDictionaryContainsKey(mexHIDOpenDevices, deviceKey)) {
					CFNumberGetValue(deviceKey, kCFNumberDoubleType, &deviceID);
					
				} else {
					mexHIDDeviceInfo* info = mexHIDCreateDeviceInfo();
					if (info != NULL) {
						info->device = device;
						CFRetain(info->device);
						
						CFNumberGetValue(deviceKey, kCFNumberDoubleType, &deviceID);
						info->deviceID = deviceID;
						
						info->elementsByCookie = mexHIDCreateElementCookieDictionaryForDevice(info->device);
						info->usbDevice = mexHIDGetUSBDeviceInterfaceForDevice(info->device);
						
						CFDictionaryAddValue(mexHIDOpenDevices, deviceKey, info);
					}
				}
			}
			CFRelease(deviceKey);
		}
	}
	return(deviceID);
}

int mexHIDReleaseDevice(mexHIDDeviceID deviceID) {
	int status = mexHIDInternalFailure;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		mexHIDDestroyDeviceInfo(info);
		status = mexHIDSuccess;
	}
	
	CFNumberRef deviceKey = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &deviceID);
	if (deviceKey != NULL) {
		CFDictionaryRemoveValue(mexHIDOpenDevices, deviceKey);
		CFRelease(deviceKey);
	}
	return(status);
}

mexHIDDeviceInfo* mexHIDCreateDeviceInfo(void) {
	mexHIDDeviceInfo* info = mxCalloc(1, sizeof(mexHIDDeviceInfo));
	if (info != NULL) {
		mexMakeMemoryPersistent(info);
		info->deviceID = -1;
		info->device = NULL;
		info->queue = NULL;
		info->queueCallbackMatlabContext = NULL;
		info->queueCallbackMatlabFcn = NULL;
		info->elementsByCookie = NULL;
		info->usbDevice = NULL;
	}
	return(info);
}

void mexHIDDestroyDeviceInfo(mexHIDDeviceInfo* info) {
	if (info != NULL) {
		info->deviceID = -1;
		
		if (info->queue != NULL && CFGetTypeID(info->queue) == IOHIDQueueGetTypeID()) {
			mexHIDFlushQueue(mxCreateDoubleScalar((double)info->deviceID));
			IOHIDQueueRegisterValueAvailableCallback(info->queue, NULL, NULL);
			mexHIDCheck();
			IOHIDQueueUnscheduleFromRunLoop(info->queue, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
			mexHIDCheck();
			CFRelease(info->queue);
		}
		info->queue = NULL;
		
		if (info->elementsByCookie != NULL && CFGetTypeID(info->elementsByCookie) == CFDictionaryGetTypeID()) {
			CFRelease(info->elementsByCookie);
		}
		info->elementsByCookie = NULL;
		
		if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
			CFRelease(info->device);
		}
		info->device = NULL;
		
		if (info->queueCallbackMatlabContext != NULL) {
			mxDestroyArray(info->queueCallbackMatlabContext);
		}
		info->queueCallbackMatlabContext = NULL;
		
		if (info->queueCallbackMatlabFcn != NULL) {
			mxDestroyArray(info->queueCallbackMatlabFcn);
		}
		info->queueCallbackMatlabFcn = NULL;
		
		if (info->usbDevice != NULL) {
			(*info->usbDevice)->Release(info->usbDevice);
		}
		info->usbDevice = NULL;
		
		mxFree(info);
	}
	info = NULL;
}

IOUSBDeviceInterface** mexHIDGetUSBDeviceInterfaceForDevice(IOHIDDeviceRef device) {
	IOUSBDeviceInterface** deviceInterface = NULL;
	
	if (device != NULL && CFGetTypeID(device) == IOHIDDeviceGetTypeID()) {
		CFMutableDictionaryRef deviceMatching = IOServiceMatching(kIOUSBDeviceClassName);
		if (deviceMatching != NULL && CFGetTypeID(deviceMatching) == CFDictionaryGetTypeID()) {
			CFTypeRef cfProduct = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey));
			CFTypeRef cfVendor = IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey));
			if (cfProduct != NULL && cfVendor != NULL) {
				CFDictionaryAddValue(deviceMatching, CFSTR(kUSBProductID), cfProduct);
				CFDictionaryAddValue(deviceMatching, CFSTR(kUSBVendorID), cfVendor);
				io_service_t deviceService = IOServiceGetMatchingService(kIOMasterPortDefault, deviceMatching);
				if (deviceService) {
					IOCFPlugInInterface** intermediateInterface = NULL;
					IOReturn result;
					SInt32 unusedInt;
					result = IOCreatePlugInInterfaceForService(deviceService, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &intermediateInterface, &unusedInt);
					if (result == kIOReturnSuccess) {
						result = (*intermediateInterface)->QueryInterface(intermediateInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID*)&deviceInterface);
						IODestroyPlugInInterface(intermediateInterface);
					}
					IOObjectRelease(deviceService);
				}
			}
		}
	}	
	return(deviceInterface);
}

mexHIDDeviceInfo* mexHIDGetDeviceInfoByDeviceID(mexHIDDeviceID deviceID) {
	mexHIDDeviceInfo* info = NULL;
	if (mexHIDOpenDevices != NULL && CFGetTypeID(mexHIDOpenDevices) == CFDictionaryGetTypeID()) {
		CFNumberRef deviceKey = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &deviceID);
		if (deviceKey != NULL && CFGetTypeID(deviceKey) == CFNumberGetTypeID()) {
			if (CFDictionaryContainsKey(mexHIDOpenDevices, deviceKey)) {
				info = (mexHIDDeviceInfo*)CFDictionaryGetValue(mexHIDOpenDevices, deviceKey);
			}
			CFRelease(deviceKey);
		}
	}	
	return(info);
}

int mexHIDGetReportLengthAndIOHIDTypeForDeviceAndMexHIDType(IOHIDReportType* IOHIDType, IOHIDDeviceRef device, mexHIDReportType mexHIDType) {
	int length = -1;
	IOHIDReportType IOHIDTypeTemp = -1;
	CFStringRef cfLengthKey = NULL;
	
	switch (mexHIDType) {
		case mexHIDInputReport:
			IOHIDTypeTemp = kIOHIDReportTypeInput;
			cfLengthKey = CFSTR(kIOHIDMaxInputReportSizeKey);
			break;
			
		case mexHIDOutputReport:
			IOHIDTypeTemp = kIOHIDReportTypeOutput;
			cfLengthKey = CFSTR(kIOHIDMaxOutputReportSizeKey);
			break;
			
		case mexHIDFeatureReport:
			IOHIDTypeTemp = kIOHIDReportTypeFeature;
			cfLengthKey = CFSTR(kIOHIDMaxFeatureReportSizeKey);
			break;
			
		case mexHIDCountReport:
			IOHIDTypeTemp = kIOHIDReportTypeCount;
			cfLengthKey = CFSTR(kIOHIDMaxInputReportSizeKey); //??
			break;
            
        case mexHIDUnknownReport:
            break;
	}
	
	if (IOHIDType != NULL)
		*IOHIDType = IOHIDTypeTemp;
	
	if (cfLengthKey != NULL && device != NULL && CFGetTypeID(device) == IOHIDDeviceGetTypeID()) {
		CFTypeRef cfReportLength = IOHIDDeviceGetProperty(device, cfLengthKey);
		if (cfReportLength != NULL && CFGetTypeID(cfReportLength) == CFNumberGetTypeID()) {
			CFNumberGetValue(cfReportLength, kCFNumberIntType, &length);
		}
	}
	return(length);
}


#pragma mark UIKit HID element utilities

CFDictionaryRef mexHIDCreateElementCookieDictionaryForDevice(IOHIDDeviceRef device) {
	CFDictionaryRef elementsByCookie = NULL;
	
	if (device != NULL && CFGetTypeID(device) == IOHIDDeviceGetTypeID()) {
		CFArrayRef allElements = IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);
		if (allElements != NULL) {
			int nElements = (int)CFArrayGetCount(allElements);
			if (nElements > 0) {
				CFMutableDictionaryRef tempDict = CFDictionaryCreateMutable(kCFAllocatorDefault, (CFIndex)nElements, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
				if (tempDict != NULL) {
					int ii;
					for (ii=0; ii<nElements; ii++) {
						IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(allElements, ii);
						CFNumberRef elementCookieKey = (CFNumberRef)mexHIDWorkaround_IOHIDElementCopyProperty(element, CFSTR(kIOHIDElementCookieKey));
						CFDictionaryAddValue(tempDict, elementCookieKey, element);
						CFRelease(elementCookieKey);
					}
					elementsByCookie = CFDictionaryCreateCopy(kCFAllocatorDefault, tempDict);
					CFRelease(tempDict);
				}	
			}
			CFRelease(allElements);
		}
	}
	return(elementsByCookie);
}

CFArrayRef mexHIDCopyDeviceElementsForCookies(mexHIDDeviceID deviceID, const mxArray* elementCookies) {
	CFArrayRef elementsInOrder = NULL;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->elementsByCookie != NULL && CFGetTypeID(info->elementsByCookie) == CFDictionaryGetTypeID()) {
			if (elementCookies != NULL && mxIsDouble(elementCookies)) {
				int nElements = mxGetM(elementCookies) * mxGetN(elementCookies);
				if (nElements > 0) {
					CFMutableArrayRef tempArray = CFArrayCreateMutable(kCFAllocatorDefault, nElements, &kCFTypeArrayCallBacks);
					if (tempArray != NULL) {
						double* mxDoublePtr = mxGetPr(elementCookies);
						int ii;
						for (ii=0; ii<nElements; ii++) {
							double elementCookie = mxDoublePtr[ii];
							CFNumberRef elementCookieKey = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &elementCookie);
							if (CFDictionaryContainsKey(info->elementsByCookie, elementCookieKey)){
								IOHIDElementRef element = (IOHIDElementRef)CFDictionaryGetValue(info->elementsByCookie, elementCookieKey);
								CFArraySetValueAtIndex(tempArray, ii, element);
							}
							CFRelease(elementCookieKey);
						}
						elementsInOrder = CFArrayCreateCopy(kCFAllocatorDefault, tempArray);
						CFRelease(tempArray);
					}
				}
			}
		}
	}
	return(elementsInOrder);
}

mxArray* mexHIDCopyElementsPropertiesToMxStruct(CFArrayRef elementsInOrder, const char** propertyNames, int nProperties) {
	mxArray* elementProperties = NULL;
	
	if (elementsInOrder != NULL && CFGetTypeID(elementsInOrder) == CFArrayGetTypeID()) {
		int nElements = (int)CFArrayGetCount(elementsInOrder);
		elementProperties = mxCreateStructMatrix(1, nElements, nProperties, propertyNames);
		if (elementProperties != NULL) {
			int ii, jj;
			for(ii=0; ii<nProperties; ii++) {
				CFStringRef cfKey = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, propertyNames[ii], kCFStringEncodingUTF8, kCFAllocatorNull);
				if (cfKey != NULL) {
					for(jj=0; jj<nElements; jj++) {
						IOHIDElementRef el = (IOHIDElementRef)CFArrayGetValueAtIndex(elementsInOrder, jj);
						CFTypeRef cfValue = mexHIDWorkaround_IOHIDElementCopyProperty(el, cfKey);
						if (cfValue != NULL) {
							mxArray* mxValue = mexHIDCreateMxArrayFromCFValue(cfValue);
							if (mxValue != NULL)
								mxSetField(elementProperties, jj, propertyNames[ii], mxValue);
							CFRelease(cfValue);
						}
					}
				}
				CFRelease(cfKey);
			}
		}
	}
	return(elementProperties);
}

CFArrayRef mexHIDCreateCFArrayFromCFDictionaryValues(const CFDictionaryRef cfDict) {
	CFArrayRef cfArray = NULL;
	if (cfDict != NULL && CFGetTypeID(cfDict) == CFDictionaryGetTypeID()) {
		CFIndex nValues = CFDictionaryGetCount(cfDict);
		if (nValues > 0) {
			void** values = mxCalloc(nValues, sizeof(void*));
			CFDictionaryGetKeysAndValues(cfDict, NULL, (const void**)values);
			cfArray = CFArrayCreate(kCFAllocatorDefault, (const void**)values, nValues, &kCFTypeArrayCallBacks);
		}
	}
	return(cfArray);
}

mexHIDReturn mexHIDSetDefaultCalibrationsForAllElements(mexHIDDeviceID deviceID) {
	mexHIDReturn status = mexHIDInternalFailure;
	mexHIDDeviceInfo* info = mexHIDGetDeviceInfoByDeviceID(deviceID);
	if (info != NULL) {
		if (info->elementsByCookie != NULL && CFGetTypeID(info->elementsByCookie) == CFDictionaryGetTypeID()) {
			CFDictionaryApplyFunction(info->elementsByCookie, &mexHIDSetElementDefaultCalibrations, NULL);
			status = mexHIDSuccess;
		}
	}
	return(status);
}

#pragma mark UIKit HID queue callbacks

void mexHIDQueueDataToMatlab(void* context, IOReturn result, void* sender) {
	if (result == kIOReturnSuccess) {
		mexHIDDeviceInfo* info = (mexHIDDeviceInfo*)context;
		if (info != NULL) {
            IOHIDQueueRef q = (IOHIDQueueRef)sender;
			if (q != NULL) {
				// account for all new values
                CFIndex qDepth = IOHIDQueueGetDepth(q);
				CFMutableArrayRef tempArray = CFArrayCreateMutable(kCFAllocatorDefault, qDepth, &kCFTypeArrayCallBacks);
				if (tempArray != NULL) {
                    IOHIDValueRef qVal;
					while (NULL != (qVal=IOHIDQueueCopyNextValueWithTimeout(q, 0))) {
						CFArrayAppendValue(tempArray, qVal);
						CFRelease(qVal);
					}
					
					// package values for Matlab
					int nValues = (int)CFArrayGetCount(tempArray);
					if (nValues > 0) {
						mxArray* elementValues = mxCreateDoubleMatrix(nValues, 3, mxREAL);
						if (elementValues != NULL) {
                            double* mxDoublePtr = mxGetPr(elementValues);
							if (mxDoublePtr != NULL) {
                                int ii;
                                for(ii=0; ii<nValues; ii++) {
									qVal = (IOHIDValueRef) CFArrayGetValueAtIndex(tempArray, ii);
									if (qVal != NULL && CFGetTypeID(qVal) == IOHIDValueGetTypeID()) {
										IOHIDElementRef el = IOHIDValueGetElement(qVal);
										CFIndex elCookie = (CFIndex)IOHIDElementGetCookie(el);
										mxDoublePtr[ii] = (double)elCookie;

										double_t elCalibrated = IOHIDValueGetScaledValue(qVal, kIOHIDValueScaleTypeCalibrated);
										mxDoublePtr[nValues + ii] = (double)elCalibrated;
										
										uint64_t elTimeStamp = IOHIDValueGetTimeStamp(qVal);
										mxDoublePtr[2*nValues + ii] = mexHIDOSAbsoluteTimeToSeconds(elTimeStamp);
									}
								}
							}
							
							// invoke Matlab callback with context and packaged values
							mxArray* mxArgs[3];
							mxArgs[0] = info->queueCallbackMatlabFcn;
							mxArgs[1] = info->queueCallbackMatlabContext;
							mxArgs[2] = elementValues;
							mxArray* exception = mexCallMATLABWithTrap(0, NULL, 3, mxArgs, "feval");
							if (exception != NULL)
								mexPrintf("Error executing queue callback for deviceID %d\n", (int)info->deviceID);
						}
					}
					CFRelease(tempArray);
				}
			}
		}
	}
}

void mexHIDQueueFlushData(void* context, IOReturn result, void* sender) {
	if (result == kIOReturnSuccess) {
		mexHIDDeviceInfo* info = (mexHIDDeviceInfo*)context;
		if (info != NULL) {
			IOHIDQueueRef q = (IOHIDQueueRef)sender;
			if (q != NULL) {
				IOHIDValueRef qVal;
				while (NULL != (qVal=IOHIDQueueCopyNextValueWithTimeout(q, 0)))
					CFRelease(qVal);
			}
		}
	}
}


#pragma mark CF <-> mx currency conversion 

CFTypeRef mexHIDCreateCFValueFromMxArray(const mxArray* mx) {
	CFTypeRef cfValue = NULL;
	if (mx != NULL) {
		if (mxIsEmpty(mx)) {
			// don't attempt to represent empty values in the CF world
			//  Especially in matching dictionaries, which should not attempt to match against empty
			cfValue = NULL;
			
		} else if (mxIsNumeric(mx)) {
			double d = mxGetScalar(mx); 
			cfValue = (CFTypeRef)CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &d);
			
		} else if (mxIsChar(mx)) {
			char* c = mxArrayToString(mx);
			cfValue = (CFTypeRef)CFStringCreateWithCString(kCFAllocatorDefault, (const char*)c, kCFStringEncodingUTF8);
			mxFree(c);
			
		} else if (mxIsCell(mx)) {
			int n = mxGetM(mx) * mxGetN(mx);
			CFMutableArrayRef tempArray = CFArrayCreateMutable(kCFAllocatorDefault, (CFIndex)n, &kCFTypeArrayCallBacks);
			int ii;
			for (ii=0; ii<n; ii++) {
				CFTypeRef cfValue = mexHIDCreateCFValueFromMxArray(mxGetCell(mx, ii));
				CFArraySetValueAtIndex(tempArray, (CFIndex)ii, cfValue);
			}
			cfValue = CFArrayCreateCopy(kCFAllocatorDefault, tempArray);
			CFRelease(tempArray);
			
		} else if (mxIsStruct(mx)) {
			cfValue = mexHIDCreateCFDictionaryFromMxStructScalar(mx);
		}
	}
	return(cfValue);
}

mxArray* mexHIDCreateMxArrayFromCFValue(const CFTypeRef cfValue){
	mxArray *mx = NULL;
	if(cfValue != NULL) {
		CFTypeID cfType = CFGetTypeID(cfValue);
		if (cfType == CFNumberGetTypeID()) {
			double d;
			CFNumberGetValue((CFNumberRef)cfValue, kCFNumberDoubleType, &d);
			mx = mxCreateDoubleScalar(d);
			
		} else if (cfType == CFStringGetTypeID()) {
			CFIndex nChars = CFStringGetLength((CFStringRef) cfValue);
			char* c = mxCalloc(nChars+1, sizeof(char));
			CFStringGetCString((CFStringRef)cfValue, c, nChars+1, kCFStringEncodingUTF8);
			mx = mxCreateString(c);
			mxFree(c);
			
		} else if (cfType == CFArrayGetTypeID()) {
			int n = (int)CFArrayGetCount(cfValue);
			mx = mxCreateCellMatrix(1, n);
			int ii;
			for(ii=0; ii<n; ii++) {
				mxArray* mxValue = mexHIDCreateMxArrayFromCFValue(CFArrayGetValueAtIndex(cfValue, ii));
				mxSetCell(mx, ii, mxValue);
			}
			
		} else if (cfType == CFDictionaryGetTypeID()) {
			mx = mexHIDCreateMxStructScalarFromCFDictionary(cfValue);
			
		} else {
			CFStringRef whatKind = CFCopyTypeIDDescription(cfType);
			CFIndex nChars = CFStringGetLength(whatKind);
			char* kindInfo = mxCalloc(nChars+1, sizeof(char));
			CFStringGetCString(whatKind, kindInfo, nChars+1, kCFStringEncodingUTF8);
			mexPrintf("unhandled cfType: %s\n", kindInfo);
			mxFree(kindInfo);			
		}
	} else
		mx = mxCreateDoubleMatrix(0, 0, mxREAL);
	
	return(mx);
}

CFDictionaryRef mexHIDCreateCFDictionaryFromMxStructScalar(const mxArray* mxStruct){
	CFIndex nFields = (CFIndex)mxGetNumberOfFields(mxStruct);
	
	CFMutableDictionaryRef tempDict = CFDictionaryCreateMutable(kCFAllocatorDefault, nFields, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	if (tempDict == NULL || CFGetTypeID(tempDict) != CFDictionaryGetTypeID())
		return(NULL);
	
	int ii;
	for (ii=0; ii<nFields; ii++) {
		const char* fieldName = mxGetFieldNameByNumber(mxStruct, ii);
		if (fieldName != NULL) { 
			CFStringRef cfKey = CFStringCreateWithCString(kCFAllocatorDefault, fieldName, kCFStringEncodingUTF8);
			if (cfKey != NULL || CFGetTypeID(cfKey) == CFStringGetTypeID()) {
				mxArray* mxValue = mxGetFieldByNumber(mxStruct, 0, ii);
				if (mxValue != NULL) {
					CFTypeRef cfValue = mexHIDCreateCFValueFromMxArray(mxValue);
					if (cfValue != NULL) {
						CFDictionaryAddValue(tempDict, cfKey, cfValue);
						CFRelease(cfValue);
					}
				}
				CFRelease(cfKey);
			}
		}
	}
	
	CFDictionaryRef immutable = CFDictionaryCreateCopy(kCFAllocatorDefault, (CFDictionaryRef)tempDict);
	CFRelease(tempDict);
	return(immutable);
}


mxArray* mexHIDCreateMxStructScalarFromCFDictionary(CFDictionaryRef cfDictionary){
	mexHIDStructSlice slice;
	slice.mxStruct = mxCreateStructMatrix(1, 1, 0, NULL);
	slice.sliceIndex = 0;
	CFDictionaryApplyFunction(cfDictionary, &mexHIDCopyEntryToMxStructSlice, &slice);
	return(slice.mxStruct);
}

#pragma mark OS and USB timing

double mexHIDGetOSAbsoluteTimeInSeconds() {
	uint64_t absTime = mach_absolute_time();
	double seconds = mexHIDOSAbsoluteTimeToSeconds(absTime);
	return(seconds);
}

double mexHIDOSAbsoluteTimeToSeconds(uint64_t absTime) {
    static mach_timebase_info_data_t sTimebaseInfo;
    if(sTimebaseInfo.denom == 0) 
            (void) mach_timebase_info(&sTimebaseInfo);
    return((double) (absTime * sTimebaseInfo.numer / sTimebaseInfo.denom) / (double) A_BILLION);
	//Nanoseconds nanosecs = AbsoluteToNanoseconds(*(AbsoluteTime*)&absTime);
	//absTime = *(uint64_t*)&nanosecs;
	//double seconds = (double)absTime/(double)A_BILLION;
	//return(seconds);
}

IOReturn mexHIDGetUSBFrameNumberAndSeconds(mexHIDDeviceInfo* info, double* frameNumberPtr, double* frameTimePtr) {
	IOReturn result = kIOReturnError;
	UInt64 frameNumberInt = 0;
	AbsoluteTime frameTimeAbs = {0,0};
	if (info->usbDevice != NULL)
		result = (*info->usbDevice) -> GetBusFrameNumber(info->usbDevice, &frameNumberInt, &frameTimeAbs);
	*frameNumberPtr = (double)frameNumberInt;
	*frameTimePtr = mexHIDOSAbsoluteTimeToSeconds(*(uint64_t*)&frameTimeAbs);
	return(result);
}

#pragma mark CF collection callbacks

void mexHIDCopyDevicePropertiesToMxStructSlice(const void* value, void* context) {
	
	const IOHIDDeviceRef dev = (const IOHIDDeviceRef)value;
	if (dev == NULL || CFGetTypeID(dev) != IOHIDDeviceGetTypeID())
		return;
	
	mexHIDStructSlice* slice = (mexHIDStructSlice*)context;
	int ii;
	for(ii=0; ii<(int)mexHIDDevicePropertyCount; ii++) {
		CFStringRef cfKey = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, mexHIDDevicePropertyKeys[ii], kCFStringEncodingUTF8, kCFAllocatorNull);
		CFTypeRef cfValue = IOHIDDeviceGetProperty(dev, cfKey);
		CFRelease(cfKey);
		
		mxArray* mxValue = mexHIDCreateMxArrayFromCFValue(cfValue);
		if (mxValue != NULL) {
			if (mxGetFieldNumber(slice->mxStruct, mexHIDDevicePropertyKeys[ii]) < 0)
				mxAddField(slice->mxStruct, mexHIDDevicePropertyKeys[ii]);
			mxSetField(slice->mxStruct, slice->sliceIndex, mexHIDDevicePropertyKeys[ii], mxValue);
		}
	}
	slice->sliceIndex++;
}

void mexHIDCopyEntryToMxStructSlice(const void* key, const void* value, void* context) {
	
	CFStringRef k = (CFStringRef)key;
	if (k == NULL || CFGetTypeID(k) != CFStringGetTypeID())
		return;
	
	CFTypeRef v = (CFTypeRef)value;
	if (v == NULL)
		return;
	
	mexHIDStructSlice* slice = (mexHIDStructSlice*)context;
	if (slice == NULL)
		return;	
	
	CFIndex nChars = CFStringGetLength(key);
	char* fieldName = mxCalloc(nChars+1, sizeof(char));
	if(CFStringGetCString(k, fieldName, nChars+1, kCFStringEncodingUTF8)) {
		if (mxGetFieldNumber(slice->mxStruct, fieldName) < 0)
			mxAddField(slice->mxStruct, fieldName);
		mxArray* mxValue = mexHIDCreateMxArrayFromCFValue(v);
		mxSetField(slice->mxStruct, slice->sliceIndex, fieldName, mxValue);
	}
	mxFree(fieldName);	
}

void mexHIDCloseEntryDevice(const void* key, const void* value, void* context) {
	mexHIDDeviceInfo* info = (mexHIDDeviceInfo*)value;		
	if (info->device != NULL && CFGetTypeID(info->device) == IOHIDDeviceGetTypeID()) {
		IOHIDDeviceClose(info->device, kIOHIDOptionsTypeNone);
		mexHIDDestroyDeviceInfo(info);
	}
}

void mexHIDCopyKeyNumberToMxDouble(const void* key, const void* value, void* context) {
	mexHIDArrayElement* element = (mexHIDArrayElement*)context;
	if (element != NULL && mxIsDouble(element->mx)) {
		CFNumberRef k = (CFNumberRef)key;
		if (k != NULL && CFGetTypeID(k) == CFNumberGetTypeID()) {
			double* mxDoublePtr = mxGetPr(element->mx);
			double d;
			if (CFNumberGetValue(k, kCFNumberDoubleType, &d))
				mxDoublePtr[element->elementIndex] = d;
		}
		element->elementIndex++;
	}
}

void mexHIDSetElementDefaultCalibrations(const void* key, const void* value, void* context) {
	IOHIDElementRef el = (IOHIDElementRef)value;
	if (el != NULL && CFGetTypeID(el) == IOHIDElementGetTypeID()) {
		
		int min = -1;
		CFNumberRef cfMin = mexHIDWorkaround_IOHIDElementCopyProperty(el, CFSTR(kIOHIDElementMinKey));
		if (cfMin != NULL) {
			IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationMinKey), cfMin);
			IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationSaturationMinKey), cfMin);
			CFNumberGetValue(cfMin, kCFNumberIntType, &min);
			CFRelease(cfMin);
		}
		
		int max = 1;
		CFNumberRef cfMax = mexHIDWorkaround_IOHIDElementCopyProperty(el, CFSTR(kIOHIDElementMaxKey));
		if (cfMax != NULL) {
			IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationMaxKey), cfMax);
			IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), cfMax);
			CFNumberGetValue(cfMax, kCFNumberIntType, &max);
			CFRelease(cfMax);
		}
		
		/*
		 int mean = (max-min)/2;
		 CFNumberRef cfMean = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &mean);
		 if (cfMean != NULL) {
		 IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), cfMean);
		 IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), cfMean);
		 CFRelease(cfMean);
		 }
		 
		 int one = 1;
		 CFNumberRef cfOne = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &one);
		 if (cfOne != NULL) {
		 IOHIDElementSetProperty(el, CFSTR(kIOHIDElementCalibrationGranularityKey), cfOne);
		 CFRelease(cfOne);
		 }
		 */
	}
}

#pragma mark UIKit HID bug workaround

CFTypeRef mexHIDWorkaround_IOHIDElementCopyProperty(IOHIDElementRef element, CFStringRef key) {
	
	// IOHIDElementGetProperty is broken, as Apple reports in Technical Note TN2187.
	CFTypeRef cfValue = IOHIDElementGetProperty(element, key);
	
	// Use the supplied "convenience" functions as workaround
	if (cfValue == NULL) {
		CFIndex number;
		if (CFStringCompare(key, CFSTR(kIOHIDElementCollectionTypeKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetCollectionType(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementCookieKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetCookie(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementMinKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetLogicalMin(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementMaxKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetLogicalMax(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementScaledMinKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetPhysicalMin(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementScaledMaxKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetPhysicalMax(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementTypeKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetType(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementUsageKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetUsage(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementUsagePageKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetUsagePage(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementUnitKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetUnit(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementUnitExponentKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetUnitExponent(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementNameKey), 0) == kCFCompareEqualTo) {
			cfValue = (CFTypeRef)IOHIDElementGetName(element);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementIsArrayKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementIsArray(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementIsRelativeKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementIsRelative(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementIsWrappingKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementIsWrapping(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementIsNonLinearKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementIsNonLinear(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementReportSizeKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetReportSize(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementReportCountKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetReportCount(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementReportIDKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementGetReportID(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementHasPreferredStateKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementHasPreferredState(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
			
		} else if (CFStringCompare(key, CFSTR(kIOHIDElementHasNullStateKey), 0) == kCFCompareEqualTo) {
			number = (CFIndex)IOHIDElementHasNullState(element);
			cfValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &number);
		}
	} else {
		CFRetain(cfValue);
	}
	return(cfValue);
}
