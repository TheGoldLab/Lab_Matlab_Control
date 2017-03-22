/* mxGram.c
 *
 * C-routines for converting Matlab mxArrays to byte arrays and back,
 * suitable for UDP/IP datagrams.
 *
 *  2010
 *  benjamin.heasly@gmail.com
 *	University of Pennsylvania
 *
 */

#include "mxGram.h"

int mxToBytes(const mxArray *mx, char *byteArray, int byteArrayLength) {
    int ii;
    int nInfoBytes=0, nDataBytes=0, nFreeBytes=0;
    mxGramInfo info;
    
    // for complex types
    int jj;
    int nElements;
    mxArray *elementData, *elementName;
    char *elementByteArray;
    int elementGramLength;
    
    mxArray *callMatlabError;
    
    if (mx == NULL)
        return(0);
    
    info.gramBytes = byteArray;
    setInfoFieldsFromMx(&info, mx);
    
    info.dataBytes = byteArray + MX_GRAM_OFFSET_DATA;
    nFreeBytes = byteArrayLength - MX_GRAM_OFFSET_DATA;
    
    if (info.gramType==mxGramDouble) {
        nDataBytes = writeMxDoubleDataToBytes(mx, &info, nFreeBytes);
        
    } else if (info.gramType==mxGramChar) {
        nDataBytes = writeMxCharDataToBytes(mx, &info, nFreeBytes);
        
    } else if (info.gramType==mxGramLogical) {
        nDataBytes = writeMxLogicalDataToBytes(mx, &info, nFreeBytes);
        
    } else if (info.gramType==mxGramCell) {
        // recur to write data for each cell element
        nElements = info.dataM * info.dataN;
        
        elementByteArray = info.dataBytes;
        elementGramLength = 0;
        for (ii=0; ii<nElements; ii++) {
            elementData = mxGetCell(mx, ii);
            elementGramLength = mxToBytes((const mxArray*)elementData, elementByteArray, nFreeBytes);
            
            if (elementGramLength < 0)
                return(elementGramLength);
            
            nDataBytes += elementGramLength;
            elementByteArray += elementGramLength;
            nFreeBytes -= elementGramLength;
        }
        
    } else if (info.gramType==mxGramStruct) {
        
        // struct arrays resized to 1xn, with m fields
        nElements = mxGetNumberOfFields(mx);
        info.dataM = nElements;
        info.dataN = mxGetM(mx) * mxGetN(mx);
        
        // recur to write data for each field name
        elementByteArray = info.dataBytes;
        elementGramLength = 0;
        for (ii=0; ii<nElements; ii++) {
            elementName = mxCreateString(mxGetFieldNameByNumber(mx, ii));
            elementGramLength = mxToBytes(elementName, elementByteArray, nFreeBytes);
            mxDestroyArray(elementName);
            
            if (elementGramLength < 0)
                return(elementGramLength);
            
            nDataBytes += elementGramLength;
            elementByteArray += elementGramLength;
            nFreeBytes -= elementGramLength;
        }
        
        // recur to write data for each field datum
        for (ii=0; ii<nElements; ii++) {
            for (jj=0; jj<info.dataN; jj++) {
                elementData = mxGetFieldByNumber(mx, jj, ii);
                elementGramLength = mxToBytes((const mxArray*)elementData, elementByteArray, nFreeBytes);
                
                if (elementGramLength < 0)
                    return(elementGramLength);
                
                nDataBytes += elementGramLength;
                elementByteArray += elementGramLength;
                nFreeBytes -= elementGramLength;
            }
        }
        
    } else if (info.gramType==mxGramFunctionHandle) {
        // recur to write stringified version of function
        callMatlabError = mexCallMATLABWithTrap(1, &elementData, 1, (mxArray**)&mx, MX_GRAM_FUNCTION_TO_STRING);
        if (callMatlabError == NULL && elementData != NULL) {
            nDataBytes = mxToBytes((const mxArray*)elementData, info.dataBytes, nFreeBytes);
            if (nDataBytes < 0)
                return(nDataBytes);
        } else
            return(-1);
        
    } else {
        return(mxGramUnsupported);
        
    }
    
    //mexPrintf("nDataBytes = %d\n", nDataBytes);
    if (nDataBytes < 0)
        return(nDataBytes);
    
    info.gramLength = MX_GRAM_OFFSET_DATA + nDataBytes;
    nInfoBytes = writeInfoFieldsToBytes(&info, byteArray, byteArrayLength);
    //mexPrintf("nInfoBytes = %d\n", nInfoBytes);
    //printMxGramInfo(&info);
    //printBytes(info.gramBytes, info.gramLength);
    return(info.gramLength);
}

int bytesToMx(mxArray **mx, const char *byteArray, int byteArrayLength) {
    int ii;
    int nInfoBytes=0, nFreeBytes=0, nBytesRead=0;
    mxGramInfo info;
    
    // for complex types
    int jj;
    int nElements;
    mxArray *elementData;
    mxArray *elementName;
    const char *elementByteArray;
    int elementBytesRead;
    char **fieldNames;
    
    mxArray *callMatlabError;
    
    info.gramBytes = (char *)byteArray;
    nInfoBytes = readInfoFieldsFromBytes(&info, byteArray, byteArrayLength);
    nBytesRead += nInfoBytes;
    
    info.dataBytes = (char *)byteArray + MX_GRAM_OFFSET_DATA;
    nFreeBytes = byteArrayLength - MX_GRAM_OFFSET_DATA;
    
    //printMxGramInfo(&info);
    //printBytes(info.gramBytes, info.gramLength);
    
    if (info.gramType==mxGramDouble) {
        *mx = mxCreateDoubleMatrix(info.dataM, info.dataN, mxREAL);
        nBytesRead += readMxDoubleDataFromBytes(*mx, &info, nFreeBytes);
        
    } else if (info.gramType==mxGramChar) {
        mwSize dims[2];
        dims[0] = info.dataM;
        dims[1] = info.dataN;
        *mx = mxCreateCharArray(2, dims);
        nBytesRead += readMxCharDataFromBytes(*mx, &info, nFreeBytes);
        
    } else if (info.gramType==mxGramLogical) {
        *mx = mxCreateLogicalMatrix(info.dataM, info.dataN);
        nBytesRead += readMxLogicalDataFromBytes(*mx, &info, nFreeBytes);
        
    } else if (info.gramType==mxGramCell) {
        *mx = mxCreateCellMatrix(info.dataM, info.dataN);
        
        nElements = info.dataM * info.dataN;
        elementByteArray = info.dataBytes;
        elementBytesRead = 0;
        
        for (ii=0; ii<nElements; ii++) {
            elementBytesRead = bytesToMx(&elementData, elementByteArray, nFreeBytes);
            if (elementBytesRead > 0) {
                mxSetCell(*mx, ii, elementData);
                nBytesRead += elementBytesRead;
                elementByteArray += elementBytesRead;
                nFreeBytes -= elementBytesRead;
            }
        }
        
    } else if (info.gramType==mxGramStruct) {
        
        // struct arrays may have size 1xn, with m fields
        nElements = info.dataM;
        fieldNames = mxMalloc(nElements*sizeof(char*));
        
        // recur to read out fieldNames
        elementByteArray = info.dataBytes;
        for (ii=0; ii<nElements; ii++) {
            elementBytesRead = bytesToMx(&elementName, elementByteArray, nFreeBytes);
            fieldNames[ii] = mxArrayToString(elementName);
            mxDestroyArray(elementName);
            
            nBytesRead += elementBytesRead;
            elementByteArray += elementBytesRead;
            nFreeBytes -= elementBytesRead;
        }
        
        *mx = mxCreateStructMatrix(1, info.dataN, info.dataM, (const char **)fieldNames);
        mxFree(fieldNames);
        
        // recur to fill in field data
        for (ii=0; ii<nElements; ii++) {
            for (jj=0; jj<info.dataN; jj++) {
                elementBytesRead = bytesToMx(&elementData, elementByteArray, nFreeBytes);
                mxSetFieldByNumber(*mx, jj, ii, elementData);
                
                nBytesRead += elementBytesRead;
                elementByteArray += elementBytesRead;
                nFreeBytes -= elementBytesRead;
            }
        }
        
    } else if (info.gramType==mxGramFunctionHandle) {
        // recur to read out stringified version of function
        elementBytesRead = bytesToMx(&elementData, info.dataBytes, nFreeBytes);
        if (elementBytesRead > 0) {
            nBytesRead += elementBytesRead;
            callMatlabError = mexCallMATLABWithTrap(1, mx, 1, &elementData, MX_GRAM_STRING_TO_FUNCTION);
        }
        
    } else {
        *mx = mxCreateDoubleScalar(-1);
        nBytesRead = 0;
    }
    
    return(nBytesRead);
}

void setInfoFieldsFromMx(mxGramInfo *info, const mxArray *mx) {
    info->gramType = (MX_GRAM_UINT16)getMxGramTypeForMx(mx);
    info->dataSize = (MX_GRAM_UINT16)mxGetElementSize(mx);
    info->dataM = (MX_GRAM_UINT16)mxGetM(mx);
    info->dataN = (MX_GRAM_UINT16)mxGetN(mx);
    info->dataLength = (MX_GRAM_UINT16)(info->dataSize*info->dataM*info->dataN);
}

int readInfoFieldsFromBytes(mxGramInfo *info, const char *byteArray, int byteArrayLength) {
    if (byteArrayLength >= MX_GRAM_INFO_HEAD) {
        info->gramLength = readInt16FromBytes(byteArray+MX_GRAM_OFFSET_GRAMLENGTH);
        info->gramType = readInt16FromBytes(byteArray+MX_GRAM_OFFSET_GRAMTYPE);
        info->dataLength = readInt16FromBytes(byteArray+MX_GRAM_OFFSET_DATALENGTH);
        info->dataSize = readInt16FromBytes(byteArray+MX_GRAM_OFFSET_DATASIZE);
        info->dataM = readInt16FromBytes(byteArray+MX_GRAM_OFFSET_M);
        info->dataN = readInt16FromBytes(byteArray+MX_GRAM_OFFSET_N);
        return(MX_GRAM_INFO_HEAD);
    } else
        return(-1);
}

int writeInfoFieldsToBytes(const mxGramInfo *info, char *byteArray, int byteArrayLength) {
    if (byteArrayLength >= MX_GRAM_INFO_HEAD) {
        writeInt16ToBytes(info->gramLength, byteArray+MX_GRAM_OFFSET_GRAMLENGTH);
        writeInt16ToBytes(info->gramType, byteArray+MX_GRAM_OFFSET_GRAMTYPE);
        writeInt16ToBytes(info->dataLength, byteArray+MX_GRAM_OFFSET_DATALENGTH);
        writeInt16ToBytes(info->dataSize, byteArray+MX_GRAM_OFFSET_DATASIZE);
        writeInt16ToBytes(info->dataM, byteArray+MX_GRAM_OFFSET_M);
        writeInt16ToBytes(info->dataN, byteArray+MX_GRAM_OFFSET_N);
        return(MX_GRAM_INFO_HEAD);
    } else
        return(-1);
}

int writeMxDoubleDataToBytes(const mxArray *mx, mxGramInfo *info, int nBytes) {
    int ii;
    int numel = info->dataM * info->dataN;
    double* mxData = mxGetPr(mx);
    char *gramData = info->dataBytes;
    
    if (nBytes >= info->dataSize*numel) {
        // write 8-byte doubles to data bytes
        for(ii=0; ii<numel; ii++) {
            writeDouble64ToBytes(mxData[ii], gramData);
            gramData += info->dataSize;
        }
        return(info->dataSize*numel);
    } else
        return(-1);
}

int readMxDoubleDataFromBytes(mxArray *mx, mxGramInfo *info, int nBytes) {
    int ii;
    int numel = info->dataM * info->dataN;
    double* mxData = mxGetPr(mx);
    const char *gramData = info->dataBytes;
    
    if (nBytes >= mxGetElementSize(mx)*numel) {
        // read 8-byte doubles from data bytes
        for(ii=0; ii<numel; ii++) {
            mxData[ii] = readDouble64FromBytes(gramData);
            gramData += info->dataSize;
        }
        return(info->dataSize*numel);
    } else
        return(-1);
}

int writeMxCharDataToBytes(const mxArray *mx, mxGramInfo *info, int nBytes) {
    int ii;
    int numel = info->dataM * info->dataN;
    mxChar* mxData = mxGetChars(mx);
    char *gramData = info->dataBytes;
    
    if (nBytes >= info->dataSize*numel) {
        // write 1- or 2-byte chars to data bytes
        for(ii=0; ii<numel; ii++) {
            *((mxChar*)gramData) = mxData[ii];
            gramData += info->dataSize;
        }
        return(info->dataSize*numel);
    } else
        return(-1);
}

int readMxCharDataFromBytes(mxArray *mx, mxGramInfo *info, int nBytes) {
    int ii;
    int numel = info->dataM * info->dataN;
    mxChar* mxData = mxGetChars(mx);
    const char *gramData = info->dataBytes;
    
    if (nBytes >= mxGetElementSize(mx)*numel) {
        if (info->dataSize == 1) {
            // read 1-byte characters from data bytes
            for(ii=0; ii<numel; ii++) {
                mxData[ii] = *gramData;
                gramData += info->dataSize;
            }
            
        } else {
            // read 2-byte characters from data bytes
            for(ii=0; ii<numel; ii++) {
                mxData[ii] = *((mxChar*)gramData);
                gramData += info->dataSize;
            }
        }
        return(info->dataSize*numel);
    } else
        return(-1);
}

int writeMxLogicalDataToBytes(const mxArray *mx, mxGramInfo *info, int nBytes) {
    int ii;
    int numel = info->dataM * info->dataN;
    mxLogical *mxData = mxGetLogicals(mx);
    char *gramData = info->dataBytes;
    
    if (nBytes >= info->dataSize*numel) {
        for(ii=0; ii<numel; ii++) {
            *((mxLogical*)gramData) = mxData[ii];
            gramData += info->dataSize;
        }
        return(info->dataSize*numel);
    } else
        return(-1);
}

int readMxLogicalDataFromBytes(mxArray *mx, mxGramInfo *info, int nBytes) {
    int ii;
    int numel = info->dataM * info->dataN;
    mxLogical *mxData = mxGetLogicals(mx);
    const char *gramData = info->dataBytes;
    
    if (nBytes >= mxGetElementSize(mx)*numel) {
        for(ii=0; ii<numel; ii++) {
            mxData[ii] = (mxLogical)*gramData;
            gramData += info->dataSize;
        }
        return(info->dataSize*numel);
    } else
        return(-1);
}

mxGramType getMxGramTypeForMx(const mxArray *mx) {
    mxClassID mxType = mxGetClassID(mx);
    if (mxType==mxDOUBLE_CLASS) return(mxGramDouble);
    else if (mxType==mxLOGICAL_CLASS) return(mxGramLogical);
    else if (mxType==mxCHAR_CLASS) return(mxGramChar);
    else if (mxType==mxCELL_CLASS) return(mxGramCell);
    else if (mxType==mxSTRUCT_CLASS) return(mxGramStruct);
    else if (mxType==mxFUNCTION_CLASS) return(mxGramFunctionHandle);
    else return(mxGramUnsupported);
}

void writeInt16ToBytes(const MX_GRAM_UINT16 sourceInt, char* bytes) {
    // little endian
    bytes[0] = (MX_GRAM_UINT8)(sourceInt%256);
    bytes[1] = (MX_GRAM_UINT8)(sourceInt/256);
}

MX_GRAM_UINT16 readInt16FromBytes(const char* bytes) {
    // little endian
    MX_GRAM_UINT16 readInt = (MX_GRAM_UINT8)bytes[0] + (MX_GRAM_UINT16)(256*(MX_GRAM_UINT8)bytes[1]);
    return(readInt);
}

void writeDouble64ToBytes(const double sourceDouble, char* bytes) {
    // assume consistent byte order, until it breaks
    memcpy((void*)bytes, (const void*)&sourceDouble, 8);
}

double readDouble64FromBytes(const char* bytes) {
    double readDouble;
    memcpy((void*)&readDouble, (const void*)bytes, 8);
    return(readDouble);
}

void printMxGramInfo(const mxGramInfo *info) {
    mexPrintf("mxGramInfo:\n");
    mexPrintf(" gramLength = %d\n", info->gramLength);
    mexPrintf(" gramType = %d\n", info->gramType);
    mexPrintf(" dataLength = %d\n", info->dataLength);
    mexPrintf(" dataSize = %d\n", info->dataSize);
    mexPrintf(" dataM = %d\n", info->dataM);
    mexPrintf(" dataN = %d\n", info->dataN);
}

void printBytes(const char *bytes, int nBytes) {
    int ii;
    mexPrintf("bytes: [");
    for(ii=0; ii<nBytes; ii++)
        mexPrintf(" %d", bytes[ii]);
    mexPrintf("]\n");
}
