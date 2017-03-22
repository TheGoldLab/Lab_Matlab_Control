// gohangasalamiimalasagnahog
// sitonapotatopanotis
// lewottohasahottowel

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/param.h>
#include <termios.h>

#include "mex.h"
#include "HID_Utilities_External.h"

void HandleReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize);
void FlushReportCallback(void *target,IOReturn result,void *refcon,void *sender,UInt32 bufferSize);
void cleanup();

#define DEFAULT_REPORT_SIZE 64
#define MATLAB_BUFFER_SIZE 1000
#define NUM_REPORTING_DEVICES 3
#define DEFAULT_NUM_REPORTS 100

typedef struct ReportStruct{
	int deviceIndex;
	int serialNumber;
	IOReturn error;
	UInt32 bytes;
	unsigned char report[DEFAULT_REPORT_SIZE];
} ReportStruct;


static CFRunLoopRef			myRunLoop;
static CFStringRef			myRunLoopMode;
static CFTimeInterval		myRunLoopTime=(CFTimeInterval)0.0005;
static CFRunLoopSourceRef	source[NUM_REPORTING_DEVICES]; 
static pRecDevice			PMDMaster=NULL,
							PMDReporters[NUM_REPORTING_DEVICES];
static IOHIDDeviceInterface122** interface;
static ReportStruct			reportsBuffer[DEFAULT_NUM_REPORTS];
static int					freeReportIndex=0,
							zeroTime=0,
							resetZeroTimeFlag=0,
							channelOldState[]={0,0,0,0},
							initialized=0;
static unsigned char		rawBuffer[DEFAULT_REPORT_SIZE],
							loadQueueReport[]={19,4,8,0,9,0,10,0,11,0},//tells PMD to scan channels 8-11 at gain mode 0
							startScanReport[]={17,0,0,0,0,0,0,0,196,9,16},//tells PMD to start scanning until infinity
							stopScanReport[]={18};//tell PMD to stop scanning