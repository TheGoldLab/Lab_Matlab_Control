/*
 *  LCMath.c
 *  LabTools Common
 *
 *  Description: Useful utilities (mostly math)
 *
 *  Prefix: math
 *
 *  Created by jig
 *  3/16/02: JD added sort and median
*/

#include <stdlib.h>
#include <stdio.h>
#include "LCMath.h"
#include "LCSafeAlloc.h"

/* PUBLIC ROUTINE: math
 *
*/
int math_atan(int x, int y)
{
	double val;

	if(!x && !y) return(0);

	val = 180.0/PI*atan2((double)y, (double)x);

	if(val < 0) val+= 360.;

	return((int) (val + 0.5));
}

/* PUBLIC ROUTINE: math_mag
 *
*/
int math_mag(int x, int y)
{
	return((int) (sqrt(pow((double) x, 2.) + pow((double) y, 2.))));
}

/* PUBLIC ROUTINE: math_exp
 *
*/
long math_exp(long min, long max, long mean)
{
	long ret;
	double tmp = ((double) rand()) / ((double) RAND_MAX);

	ret = min + (long) ((double) mean * -1 * log(tmp));

	if(ret > max)
		ret = max;

	return(ret);
}

/* PUBLIC ROUTINE: math_unique
**
**	finds the unique members of an array
*/
int math_unique(int num_in, int *array_in, int *array_out)
{
	register int i, j, keep, num_out=0;

	for(i=num_in;i>0;i--, array_in++) {
		for(keep=1,j=0;j<num_out;j++)
			keep *= (*array_in != array_out[j]);
		if(keep)
			array_out[num_out++] = *array_in;
	}
	return(num_out);
}

/* PUBLIC ROUTINE: math_sort
 *
 * sorts a float array
 * (just a straight insertion sort, quite slow, not for large arrays!!!)
 *
 * vec is a pointer to the float array
 * vec_len is the number of elements in the array
*/
void math_sort(float* vec,int vec_len)
{
	int i,j;
	float a;

	if (vec_len>1){
		for (j=1;j<vec_len;j++) {
			a=vec[j];
			i=j-1;
		
			while(i>=0 && vec[i]>a) {
				vec[i+1]=vec[i];
				i--;
			}

			vec[i+1]=a;
		}
	}
}

/* PUBLIC ROUTINE: math_median
 *
 * returns the median of a float array
 *
 * vec is a pointer to the float array
 * vec_len is the number of elements in the array
 * (returns 0 if vec_len < 1)
*/
float math_median(float* vec,int vec_len)
{
	float* fp;
	int i;
	float ret_val;

	if (vec_len<1) 
		return 0;

	if (vec_len==1)
		return *vec;

	if (vec_len==2)
		return (vec[0]+vec[1])/2;

	fp=SAFE_ZALLOC(float,vec_len); /* allocate a copy of the vector */
	
	for (i=0;i<vec_len;i++)
		fp[i]=vec[i]; /* make a copy of the vector (We do not want to sort the original vector.) */	

	math_sort(fp,vec_len); /* sort vector */ 

	if ((vec_len/2)*2!=vec_len) /* odd length? */
		ret_val=fp[(vec_len-1)/2];
	else /* even length */
		ret_val=(fp[vec_len/2-1]+fp[vec_len/2])/2;

	SAFE_FREE(fp); /* release memory */
	return ret_val;
}
