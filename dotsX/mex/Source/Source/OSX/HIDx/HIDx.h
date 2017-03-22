#include <stdlib.h>
#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/param.h>
#include <termios.h>
#include <CoreServices/CoreServices.h>

#include "mex.h"
#include "HID_Utilities_External.h"

// manage external global variables, only allocate them once, in HIDx.c, where ALLOCATE_EXTERNALS gets defined
#ifdef ALLOCATE_EXTERNALS
#define EXTERN
#else
#define EXTERN extern
#endif

#define QUEUE_DEPTH 128
#define MAX_DEVICES 128
#define MAX_ELEMENTS 2048

typedef void (*HIDxDeviceResetFunction)(void* self);
typedef int (*HIDxDeviceSetupFunction)(const mxArray *extras);

typedef struct HIDxDeviceStruct{
	pRecDevice				device;
	char					*dXclass;
	double					dXindex;
	mxArray					*rHIDPutDataArgs[3];
	IOHIDElementCookie		cookie_monster[MAX_ELEMENTS];
	int						cookie_count;
	void					*callback; //IOHIDReportCallbackFunction or IOHIDCallbackFunction
	HIDxDeviceResetFunction	reset;
	CFRunLoopSourceRef		source;
	Duration				zero_time;
	int						children[MAX_DEVICES];
	int						children_count;
	void					*extras;
} HIDxDeviceStruct;

// globals for HIDx.c and class-specific functions
EXTERN bool					initialized;
EXTERN CFRunLoopRef			HIDxRunLoop;
EXTERN CFStringRef			HIDxRunLoopMode;
EXTERN CFTimeInterval		HIDxRunLoopTime;
EXTERN HIDxDeviceStruct		devices[MAX_DEVICES];
EXTERN int					device_count;

// the queue-making process should be the same for all devices that use a queue
bool HIDxMakeDeviceQueue(HIDxDeviceStruct *HIDxDevice);

// utilities for getting device and element info structs
//	with big, dumb lists of fieldnames
mxArray *getDeviceInfoStruct(pRecDevice *device, int numDevices);
mxArray *getElementInfoStruct(pRecDevice device);

// free resources ("free" i.e. Tibet, i.n.e. pizza)
void releaseDevice();
void cleanup();
void fullClose();

// manipulate channel data
typedef struct HIDxChannelizer{
	double gain;
	double offset;
	double high;
	double low;
	double delta;
	double freq;
} HIDxChannelizer;
int channelizeData(HIDxChannelizer *channelizer, double *signal, int *eventIndices, int signal_length);

// class- and device- specific functions for setup, reset, and callback with data
//	each class should get its own file where these are defined
int dXgameHID_HIDxSetup(const mxArray *extras);
void dXgameHID_HIDxReset(void* self);
void dXgameHID_HIDxCallback(void *target,IOReturn result,void *refcon,void *sender);

int dXkbHID_HIDxSetup(const mxArray *extras);
void dXkbHID_HIDxReset(void* self);
void dXkbHID_HIDxCallback(void *target,IOReturn result,void *refcon,void *sender);

int dXPMDHID_HIDxSetup(const mxArray *extras);
void dXPMDHID_HIDxReset(void* self);
void dXPMDHID_HIDxCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 dataSize);

// queues and reports for any device can be flushed with these callbacks
void flushQueueCallback(void *target,IOReturn result,void *refcon,void *sender);
void flushReportsCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize);

// make paired lists of class names and setup-function function pointers
#ifdef ALLOCATE_EXTERNALS
const char					*dXClassList[] =	{"dXgameHID",			"dXkbHID",			"dXPMDHID"};
HIDxDeviceSetupFunction		dXClassSetup[] =	{&dXgameHID_HIDxSetup,	&dXkbHID_HIDxSetup,	&dXPMDHID_HIDxSetup};
int							num_classes = 3;
#else
extern const char			*dXClassList[];
extern void					*dXClassSetup[];
int							num_classes;
#endif