/* mexHID.h
 * mexHID
 *
 * mexHID defines C "mex" routines for working with USB "Human Interface Devices" from Matlab.
 * mexHID can detect and configure HID devices and exchange data with them.
 *
 * mexHID.h specifies several mex-friendly functions for use by mexHID.c.  But it leaves the
 * implementation of these functions up to platform-specific code, defined elsewhere.
 *
 * By Benjamin Heasly, University of Pennsylvania, 22 Feb. 2010
 */

#ifndef _MEX_HID_H_
#define _MEX_HID_H_

#include "mex.h"

// field names for HID report info
#define kMexHIDReportType "type"
#define kMexHIDReportID "ID"
#define kMexHIDReportBytes "bytes"

#define kMexHIDInputReportName "input"
#define kMexHIDOutputReportName "output"
#define kMexHIDFeatureReportName "feature"
#define kMexHIDCountReportName "count"
#define kMexHIDUnknownReportName "unknown"

typedef enum mexHIDReportType {
	mexHIDInputReport = 1,
	mexHIDOutputReport = 2,
	mexHIDFeatureReport = 3,
	mexHIDCountReport = 4,
	mexHIDUnknownReport = -1,
} mexHIDReportType;

typedef enum mexHIDReturn {
	mexHIDSuccess = 0,
	mexHIDUnknownCommand = -2,
	mexHIDWrongArguments = -3,
	mexHIDInternalFailure = -5,
	mexHIDCantInitialize = -7,
	mexHIDCantOpenDevice = -11,
} mexHIDReturn;

typedef double mexHIDDeviceID;
typedef double mexHIDElementCookie;

typedef struct mexHIDStructSlice {
	mxArray* mxStruct;
	int sliceIndex;
} mexHIDStructSlice;

typedef struct mexHIDArrayElement {
	mxArray* mx;
	int elementIndex;
} mexHIDArrayElement;

// global status for mexHID
mexHIDReturn mexHIDInitialize(void);
mexHIDReturn mexHIDTerminate(void);
void mexHIDExit(void);
int mexHIDIsInitialized(void);
mxArray* mexHIDGetAllOpenDevices(void);
double mexHIDCheck(void);

// Inspect all attached HID devices
// Open, close, or inspect a single HID device
mxArray* mexHIDOpenDevicesMatchingProperties(const mxArray* propStruct, int onlyFirstDevice, int isExclusive);
mxArray* mexHIDGetPropertiesForAllDevices(void);
mxArray* mexHIDGetPropertiesForDevices(const mxArray* deviceIDs);
mexHIDReturn mexHIDCloseDevices(const mxArray* deviceIDs);

// Find devices that match given properties
// Get all or some properties of all or some device elements
// Set properties of device elements
mxArray* mexHIDFindDeviceElementsMatchingProperties(mexHIDDeviceID deviceID, const mxArray* propStruct);
mxArray* mexHIDGetAllPropertiesForAllDeviceElements(mexHIDDeviceID deviceID);
mxArray* mexHIDGetAllPropertiesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies);
mxArray* mexHIDGetPropertiesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* propNames);
mexHIDReturn mexHIDSetPropertiesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* propStruct);

// Read and write values of device elements (such as button states or voltages)
// Get USB frame times and frame numbers before and after each element
mxArray* mexHIDReadValuesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, mxArray** timingData);
mexHIDReturn mexHIDWriteValuesForDeviceElements(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* elementValues, mxArray** timingData);

// Read and write byte arrays to and from device reports
// Get USB frame times and frame numbers before and after each report
mxArray* mexHIDReadDeviceReport(mexHIDDeviceID deviceID, const mxArray* reportStruct, mxArray** timingData);
mexHIDReturn mexHIDWriteDeviceReport(mexHIDDeviceID deviceID, const mxArray* reportStruct, mxArray** timingData);

// build/replace/close/start/stop/reset a queue for certain device elements, with a given queue depth and a given MATLAB callback
//	the MATLAB callback should have the form: function myCallback(deviceID, data),
//  where data is an nX3 array with rows of the form [elementCookies, eventValue, eventTime]
mexHIDReturn mexHIDOpenQueueForDeviceElementsWithMatlabCallbackAndDepth(mexHIDDeviceID deviceID, const mxArray* elementCookies, const mxArray* matlabCallback, int queueDepth);
mexHIDReturn mexHIDCloseQueue(const mxArray* deviceIDs);
mexHIDReturn mexHIDStartQueue(const mxArray* deviceIDs);
mexHIDReturn mexHIDStopQueue(const mxArray* deviceIDs);
mexHIDReturn mexHIDFlushQueue(const mxArray* deviceIDs);

// get info about internally used values
mxArray* mexHIDGetReportStructTemplate();
const char* mexHIDGetNameForReportType(mexHIDReportType mexHIDType);
mexHIDReportType mexHIDGetReportTypeForName(const char* typeName);
const char* mexHIDGetDescriptionOfReturnValue(const mxArray* returnValue);

#endif