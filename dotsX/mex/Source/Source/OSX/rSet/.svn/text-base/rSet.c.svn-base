/* 
*	rSet.c
 *	Matlab Mex file
 *
 *  rSet
 *
 *  Created by jigold on 5/10/2005
 *
 */

#include <stdlib.h>
#include <math.h>
#include "mex.h"

/* 
* Usage:
 *	rSet('class_name', <optional tags>, <property>, <value> ...)
 *		
 */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	char			*class_name, buf[256];
	int				buflen, status, num_tags, num_objects;
	register int	i;
	mxArray			*ROOT_STRUCT, *class, *objects, *objs, **rhs, *lhs[1];
	double			*tags;
	
	// check first arg -- char class_name
	if(nrhs < 1)
		mexErrMsgTxt("Not enough inputs.");
	
	if(mxIsChar(prhs[0]) != 1)
		mexErrMsgTxt("Input must be a string.");
	
	if(mxGetM(prhs[0]) != 1)
		mexErrMsgTxt("Input must be a row vector.");
	
	// Get the length of the input string
	buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;
	
	// Allocate memory for input string
	class_name = mxCalloc(buflen, sizeof(char));
	
	// Copy the string data from prhs[0] into a C string 
	if((status = mxGetString(prhs[0], class_name, buflen)) != 0)
		mexWarnMsgTxt("Not enough space. String is truncated.");
	
	// get ROOT_STRUCT
	if(!(ROOT_STRUCT = mexGetVariable("global", "ROOT_STRUCT")))
		mexErrMsgTxt("ROOT_STRUCT does not exist.");
	
	// if no arguments (or just indices) given, return defaults
	if(nrhs < 3) {
		mexPrintf("object %s:\n", class_name);
		mexPrintf("    Fieldnames\tTypes\tRanges\tDefaults\n");
		mexPrintf("    ----------\t-----\t------\t--------\n");
		//disp([cellstr(ROOT_STRUCT.(class_name).fieldnames) ...
		//	struct2cell(ROOT_STRUCT.(class_name).types) ...
		//	struct2cell(ROOT_STRUCT.(class_name).ranges) ...
		//	struct2cell(ROOT_STRUCT.(class_name).defaults)])
		//return
		//end
	}
	
	// get "class_name" field of ROOT_STRUCT
	if(!(class = mxGetField(ROOT_STRUCT, 0, class_name))) {
		sprintf(buf, "ROOT_STRUCT field %s does not exist\n", class_name);
		mexErrMsgTxt(buf);
	}
	
	// get "objects" field of ROOT_STRUCT.(class_name)
	if(!(objects = mxGetField(class, 0, "objects"))) {
		sprintf(buf, "No objects in ROOT_STRUCT field %s\n", class_name);
		mexErrMsgTxt(buf);
	}
	
	// check dimensions -- should be row vector
	if(mxGetM(objects) != 1)
		mexErrMsgTxt("Bad number of objects (rows != 1).");
	
	// get number of objects
	if(!(num_objects = mxGetN(objects)))
		mexErrMsgTxt("Bad number of objects (no columns).");
	
	mexPrintf("%d objects\n", num_objects);
	
	// parse tags
	if(mxIsEmpty(prhs[1])) {
		const char **fieldnames;
		int num_fields;
		
//		rhs = (mxArray **) calloc(nrhs-1, sizeof(mxArray *));

		// create data object
		num_fields = mxGetNumberOfFields(objects);
		mexPrintf("%d fields\n", num_fields);
		fieldnames = (char **) mxCalloc(num_fields, sizeof(char *));
		for(i=0;i<num_fields;i++)
			fieldnames[i] = mxGetFieldNameByNumber(objects, i);
			
		if(!(objs = mxCreateStructMatrix(1,1,num_fields,fieldnames)))
			mexErrMsgTxt("Could not create arg object.");
			
			mxFree(fieldnames);
			
			mexPrintf("about to copy data\n");
			
		// copy data from appropriate object
		for(i=num_fields-1;i>=0;i--)
			mxSetFieldByNumber(objs, 0, i, mxDuplicateArray(mxGetFieldByNumber(objects, 0, i)));

		mexPrintf("Created, setting name to %s\n", mxGetClassName(objects));
		
		mxSetClassName(objs, mxGetClassName(objects));

			mexPrintf("new class name is %s\n", mxGetClassName(objs));
	
						mexCallMATLAB(0,NULL,1,&objs,"set");
						return;					
		// fill in first object
		rhs[0] = objs;
		
		// fill in args
		for(i=2;i<nrhs;i++)
			rhs[i-1] = prhs[i];
			
	mexPrintf("about to call\n");

		mexCallMATLAB(1, lhs, nrhs-1, rhs, "set");
		mexPrintf("get first object\n");
		
	} else if(nrhs % 2 == 1) {
	
		mexCallMATLAB(1, lhs, nrhs-1, &(prhs[1]), "set");
		mexPrintf("get first object2\n");
				
		/* Fill cell matrix with input arguments */
//		for(i=1; i<nrhs-1; i++)
//			mxSetCell(args, i, mxDuplicateArray(prhs[i+1]));
		
//		mexCallMATLAB(1, lhs, 1, &args, "set");
	}
}
