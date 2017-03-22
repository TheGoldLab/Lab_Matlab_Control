/* mxGram.h
 *
 * C-routines for converting Matlab mxArrays to byte arrays and back,
 * suitable for UDP/IP datagrams.
 *
 *  2010
 *  benjamin.heasly@gmail.com
 *	University of Pennsylvania
 *
 */

#ifndef _MX_GRAM_H_
#define _MX_GRAM_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "mex.h"

// use fixed-width types worked out by Matlab
#include "tmwtypes.h"
#define MX_GRAM_UINT16 uint16_T
#define MX_GRAM_UINT8 uint8_T

// declare the fixed structure of the mxGram byte header
#define MX_GRAM_OFFSET_GRAMLENGTH 0
#define MX_GRAM_OFFSET_GRAMTYPE 2
#define MX_GRAM_OFFSET_DATALENGTH 4
#define MX_GRAM_OFFSET_DATASIZE 6
#define MX_GRAM_OFFSET_M 8
#define MX_GRAM_OFFSET_N 10
#define MX_GRAM_OFFSET_DATA 12
#define MX_GRAM_FIELD_SIZE 2
#define MX_GRAM_INFO_HEAD 12

// builtin function names for string <-> function
#define MX_GRAM_STRING_TO_FUNCTION "str2func"
#define MX_GRAM_FUNCTION_TO_STRING "func2str"

// struct to mirror the mxGram byte header
typedef struct var {
    char            *gramBytes;
    MX_GRAM_UINT16  gramLength;
    MX_GRAM_UINT16	gramType;
    MX_GRAM_UINT16  dataLength;
    MX_GRAM_UINT16  dataSize;
    MX_GRAM_UINT16	dataM;
    MX_GRAM_UINT16	dataN;
    char            *dataBytes;
} mxGramInfo;

typedef enum {
    mxGramDouble,
    mxGramChar,
    mxGramLogical,
    mxGramCell,
    mxGramStruct,
    mxGramFunctionHandle,
    mxGramUnsupported=-1
} mxGramType;

int mxToBytes(const mxArray *mx, char *byteArray, int byteArrayLength);
int bytesToMx(mxArray **mx, const char *byteArray, int byteArrayLength);

void setInfoFieldsFromMx(mxGramInfo *info, const mxArray *mx);
int readInfoFieldsFromBytes(mxGramInfo *info, const char *byteArray, int byteArrayLength);
int writeInfoFieldsToBytes(const mxGramInfo *info, char *byteArray, int byteArrayLength);

int writeMxDoubleDataToBytes(const mxArray *mx, mxGramInfo *info, int nBytes);
int readMxDoubleDataFromBytes(mxArray *mx, mxGramInfo *info, int nBytes);

int writeMxCharDataToBytes(const mxArray *mx, mxGramInfo *info, int nBytes);
int readMxCharDataFromBytes(mxArray *mx, mxGramInfo *info, int nBytes);

int writeMxLogicalDataToBytes(const mxArray *mx, mxGramInfo *info, int nBytes);
int readMxLogicalDataFromBytes(mxArray *mx, mxGramInfo *info, int nBytes);

mxGramType getMxGramTypeForMx(const mxArray *mx);

void writeInt16ToBytes(const MX_GRAM_UINT16 sourceInt, char* bytes);
MX_GRAM_UINT16 readInt16FromBytes(const char* bytes);

void writeDouble64ToBytes(const double sourceDouble, char* bytes);
double readDouble64FromBytes(const char* bytes);

void printMxGramInfo(const mxGramInfo *info);
void printBytes(const char *bytes, int nBytes);

#endif
