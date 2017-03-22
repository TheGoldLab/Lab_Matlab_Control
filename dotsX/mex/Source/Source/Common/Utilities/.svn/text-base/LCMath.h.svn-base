/*
 *  LCMath.h
 *  LabTools Common
 *
 *  Description: Useful math utilities
 *  Prefix: MATH
 *
 *  Modified by jigold on Fri Jul 09 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 */

#ifndef _LC_MATH_H_
#define _LC_MATH_H_

#include <string.h>
#include <math.h>

/* PUBLIC CONSTANTS */
#define DEG2RAD	0.0174533
#define PI			3.141592654

/* PUBLIC MACROS */
#define MATH_RT_TO_X(x,r,t)	((int) ((double)(x) + ((double)(r)*cos(DEG2RAD*(double)(t)))))
#define MATH_RT_TO_Y(y,r,t)	((int) ((double)(y) + ((double)(r)*sin(DEG2RAD*(double)(t)))))
#define MATH_BOUND(x,b,t)		(x <= t ? (x >= b ? x : b) : t)
#define MATH_PCT(c,i)			((c)+(i)?100.*(float)(c)/((float)(i)+(float)(c)):0.)
#define MATH_RAND(r)				((int) ((r) * rand() / (RAND_MAX+1.0))) /* 0 --> r-1 */

/* PUBLIC ROUTINE PROTOTYPES */
int	  math_atan		(int, int);
int	  math_mag		(int, int);
long	  math_exp		(long, long, long);
int	  math_unique  (int, int *, int *);
void	  math_sort		(float*, int);
float	  math_median  (float*, int);

#endif /* _LC_MATH_H_ */
