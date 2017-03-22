/* mexHID-OSX.h
 * mexHID
 *
 * mexHID defines C "mex" routines for working with USB "Human Interface Devices" from Matlab.
 * mexHID can detect and configure HID devices and exchange data with them.
 *
 * mexHID-OSX.h supports the realization of the functions from mexHID.h using the Core Foundation and 
 * IOKit frameworks of OS-X.  It specifies the OS X-specific types and utilities used by mexHID-OSX.c.
 *
 * By Benjamin Heasly, University of Pennsylvania, 22 Feb. 2010
 */

#ifndef _MEX_HID_OS_X_H_
#define _MEX_HID_OS_X_H_

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>

#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>

#include <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

#include "mexHID.h"

#define A_BILLION 1000000000

// the global IOKIT HID manager object
IOHIDManagerRef mexHIDManager = NULL;

// dictionary with CFNumber keys and mexHIDDeviceInfo* values
// values are not retained nor freed (no value callbacks)
CFMutableDictionaryRef mexHIDOpenDevices = NULL;

// would prefer to compare devices
unsigned long mexHIDOpenDeviceCount = 0;

typedef struct mexHIDDeviceInfo {
	mexHIDDeviceID deviceID;
	IOHIDDeviceRef device;
	IOHIDQueueRef queue;
	mxArray* queueCallbackMatlabFcn;
	mxArray* queueCallbackMatlabContext;
	CFDictionaryRef elementsByCookie;
	IOUSBDeviceInterface **usbDevice;
} mexHIDDeviceInfo;

typedef struct mexHIDElementPropertyInfo {
	CFStringRef	key;
	mexHIDArrayElement mxValue;
} mexHIDElementPropertyInfo;

// device property keys for easy iteration/summary
static const char* mexHIDDevicePropertyKeys[] = { 
	kIOHIDTransportKey,
	kIOHIDVendorIDKey, 
	kIOHIDVendorIDSourceKey, 
	kIOHIDProductIDKey, 
	kIOHIDVersionNumberKey,
	kIOHIDManufacturerKey, 
	kIOHIDProductKey, 
	kIOHIDSerialNumberKey, 
	kIOHIDCountryCodeKey, 
	kIOHIDDeviceUsageKey, 
	kIOHIDDeviceUsagePageKey,
	kIOHIDDeviceUsagePairsKey,
	kIOHIDPrimaryUsageKey,
	kIOHIDPrimaryUsagePageKey,
	kIOHIDMaxInputReportSizeKey,
	kIOHIDMaxOutputReportSizeKey,
	kIOHIDMaxFeatureReportSizeKey,
	kIOHIDReportIntervalKey,
};
static const CFIndex mexHIDDevicePropertyCount = sizeof(mexHIDDevicePropertyKeys)/sizeof(mexHIDDevicePropertyKeys[0]);

// element property keys for easy iteration/summary
static const char* mexHIDElementPropertyKeys[] = {
	kIOHIDElementCookieKey, 
	kIOHIDElementTypeKey, 
	kIOHIDElementCollectionTypeKey, 
	kIOHIDElementUsageKey, 
	kIOHIDElementUsagePageKey, 
	kIOHIDElementMinKey, 
	kIOHIDElementMaxKey, 
	kIOHIDElementScaledMinKey, 
	kIOHIDElementScaledMaxKey, 
	kIOHIDElementSizeKey, 
	kIOHIDElementReportSizeKey, 
	kIOHIDElementReportIDKey, 
	
	kIOHIDElementIsArrayKey, 
	kIOHIDElementIsRelativeKey, 
	kIOHIDElementIsWrappingKey, 
	kIOHIDElementIsNonLinearKey, 
	kIOHIDElementHasPreferredStateKey, 
	
	kIOHIDElementFlagsKey, 
	kIOHIDElementUnitKey, 
	kIOHIDElementUnitExponentKey, 
	kIOHIDElementNameKey, 
	kIOHIDElementValueLocationKey, 
	kIOHIDElementDuplicateIndexKey, 
	kIOHIDElementParentCollectionKey,
	kIOHIDElementVendorSpecificKey,
	
	kIOHIDElementCalibrationMinKey, 
	kIOHIDElementCalibrationMaxKey, 
	kIOHIDElementCalibrationSaturationMinKey, 
	kIOHIDElementCalibrationSaturationMaxKey, 
	kIOHIDElementCalibrationDeadZoneMinKey, 
	kIOHIDElementCalibrationDeadZoneMaxKey, 
	kIOHIDElementCalibrationGranularityKey,
};
static const CFIndex mexHIDElementPropertyCount = sizeof(mexHIDElementPropertyKeys)/sizeof(mexHIDElementPropertyKeys[0]);

// UIKit device utilities
mexHIDDeviceID mexHIDRetainDevice(IOHIDDeviceRef device);
mexHIDReturn mexHIDReleaseDevice(mexHIDDeviceID deviceID);
mexHIDDeviceInfo* mexHIDCreateDeviceInfo(void);
void mexHIDDestroyDeviceInfo(mexHIDDeviceInfo* info);
IOUSBDeviceInterface** mexHIDGetUSBDeviceInterfaceForDevice(IOHIDDeviceRef device);
mexHIDDeviceInfo* mexHIDGetDeviceInfoByDeviceID(mexHIDDeviceID deviceID);
int mexHIDGetReportLengthAndIOHIDTypeForDeviceAndMexHIDType(IOHIDReportType* IOHIDType, IOHIDDeviceRef device, mexHIDReportType mexHIDType);

// UIKit element utilities
CFDictionaryRef mexHIDCreateElementCookieDictionaryForDevice(IOHIDDeviceRef device);
CFArrayRef mexHIDCopyDeviceElementsForCookies(mexHIDDeviceID deviceID, const mxArray* elementCookies);
mxArray* mexHIDCopyElementsPropertiesToMxStruct(CFArrayRef elementsInOrder, const char** propertyNames, int nProperties);
CFArrayRef mexHIDCreateCFArrayFromCFDictionaryValues(const CFDictionaryRef cfDict);
int mexHIDSetDefaultCalibrationsForAllElements(mexHIDDeviceID deviceID);

// CF <-> mx currency conversion 
CFTypeRef mexHIDCreateCFValueFromMxArray(const mxArray* mx);
mxArray* mexHIDCreateMxArrayFromCFValue(const CFTypeRef cfValue);
CFDictionaryRef mexHIDCreateCFDictionaryFromMxStructScalar(const mxArray* mxStruct);
mxArray* mexHIDCreateMxStructScalarFromCFDictionary(CFDictionaryRef cfDictionary);

// OS and USB timing
double mexHIDOSAbsoluteTimeToSeconds(uint64_t absTime);
double mexHIDGetOSAbsoluteTimeInSeconds();
IOReturn mexHIDGetUSBFrameNumberAndSeconds(mexHIDDeviceInfo* info, double* frameNumberPtr, double* frameTimePtr);

// CF collection callbacks
void mexHIDCopyDevicePropertiesToMxStructSlice(const void* value, void* context);
void mexHIDCopyEntryToMxStructSlice(const void* key, const void* value, void* context);
void mexHIDCloseEntryDevice(const void* key, const void* value, void* context);
void mexHIDCopyKeyNumberToMxDouble(const void* key, const void* value, void* context);
void mexHIDSetElementDefaultCalibrations(const void* key, const void* value, void* context);

// callbacks for device queues
void mexHIDQueueDataToMatlab(void* context, IOReturn result, void* sender);
void mexHIDQueueFlushData(void* context, IOReturn result, void* sender);

// UIKit HID bug workaround
CFTypeRef mexHIDWorkaround_IOHIDElementCopyProperty(IOHIDElementRef element, CFStringRef key);

#endif