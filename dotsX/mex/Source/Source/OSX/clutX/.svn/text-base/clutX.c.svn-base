/* 
*	clutX.c
 *	Matlab Mex file
 *
 *  We want to do fast lookups of colors for Dots X.
 *  We could do this in MATLAB, but it would be slower.
 *  We could do this on the graphics card, but that is a bad use of the gamma table, 
 *  which on modern machines should be used for gamma correction, and especially on our
 *  psychophisics rig needs to be set in a particular linear pattern so as to 'talk' to 
 *	the Bits++ 14-bit video processor.
 *
 *  Therefore we have this mex function which does the followong:
 *		-Stores 256 color as 8-bit rgba quads which are suitable for drawing in Psychtoolbox/openGL.
 *		-First argument should be a column vector (mX1) of 1-based indices.	
 *			If it's anything else, returns first argument verbatim.
 *		-Returns one quad, as a row in an mx4 matrix, per index in the first argument.
 *		-If the second argument contains an mx1 vector of indices or an mx3 or mx4 matrix of colors, 
 *			overwrites clut quads corresponding to indices in the first argument.
*/

#include "clutX.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	
	// If no arguments given, print usage string
	if(nrhs < 1) {
		mexPrintf("clutX usage:\n\tcolorQuads = clutX(indices) %% get m quads from m indices\n\toldColorQuads = clutX(indices, newIndicesOrColors) %% set m values in color table\n");
		return;
	} else {
	
		// got at least one argument
		register int i;
		static int m;
		static unsigned char cluti;
		static double *dataPr, *indexPr;

		// what does the first argument look like?
		m = (int)mxGetM(prhs[0]);
		if(m >= 1 && (int)mxGetN(prhs[0]) == 1) {
			// first argument is a mx1 column vector of clut indices, return indexed clut entries
			if(!(plhs[0] = mxCreateDoubleMatrix(m, 4, mxREAL)))
				mexErrMsgTxt("clutX: mxCreateDoubleMatrix for color values failed");

			// read clut data into MATLAB array.
			dataPr = mxGetPr(plhs[0]);
			indexPr = mxGetPr(prhs[0]);
			for(i=0;i<m;i++,indexPr++,dataPr++){
				cluti = (unsigned char)(*indexPr)-1;
				*(dataPr)		=	(double)clut[cluti].r;
				*(dataPr+m)		=	(double)clut[cluti].g;	
				*(dataPr+2*m)	=	(double)clut[cluti].b;
				*(dataPr+3*m)	=	(double)clut[cluti].a;
			}

			// replace table entries with new colors?
			if(nrhs == 2){

				// must be same number of rows in first and second arguments
				if(m == (int)mxGetM(prhs[1])){
			
					// find the two argument matrices
					indexPr = mxGetPr(prhs[0]);
					dataPr = mxGetPr(prhs[1]);
				
					switch((int)mxGetN(prhs[1])){

						case 1 :; // rearrange clut rows by passed indices
							unsigned char clutj;
							for(i=0;i<m;i++,indexPr++,dataPr++){
								cluti = (unsigned char)(*indexPr)-1;
								clutj = (unsigned char)(*dataPr)-1;
								clut[cluti].r = clut[clutj].r;
								clut[cluti].g = clut[clutj].g;
								clut[cluti].b = clut[clutj].b;
								clut[cluti].a = clut[clutj].a;
							}
							break;

						case 3 :; // assign new colors, defaulting to totaly opaque alpha channel
							for(i=0;i<m;i++,indexPr++,dataPr++){
								cluti = (unsigned char)(*indexPr)-1;
								clut[cluti].r = (unsigned char)*(dataPr);
								clut[cluti].g = (unsigned char)*(dataPr+m);
								clut[cluti].b = (unsigned char)*(dataPr+2*m);
								clut[cluti].a = BYTEMAX;
							}
							break;

						case 4 :; // assign new colors, including alpha channel
							for(i=0;i<m;i++,indexPr++,dataPr++){
								cluti = (unsigned char)(*indexPr)-1;
								clut[cluti].r = (unsigned char)*(dataPr);
								clut[cluti].g = (unsigned char)*(dataPr+m);
								clut[cluti].b = (unsigned char)*(dataPr+2*m);
								clut[cluti].a = (unsigned char)*(dataPr+3*m);
							}
							break;

						default :
							mexPrintf("clutX: Color rows must have 1, 3, or 4 colums, not %d\n",(int)mxGetN(prhs[1]));
							mexWarnMsgTxt("clutX: No colors set.");
							break;
					}
				} else {
						mexPrintf("clutX: Indices and colors must have same number of rows, not %d and %d\n",m,(int)mxGetM(prhs[1]));
						mexWarnMsgTxt("clutX: No colors set.");
				}
			}
			
		} else {

			// first argument was not a column of indices, so return it verbatim.
			plhs[0] = mxDuplicateArray(prhs[0]);

		}
	}
}
