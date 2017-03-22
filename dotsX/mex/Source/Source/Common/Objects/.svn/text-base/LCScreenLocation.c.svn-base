/*
 *  LCScreenLocation.c
 *  LabTools Common/Objects
 *
 *  Created by jigold on Wed Jan 19 2005.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include "LCObject.h"

/* PROTOTYPES */
void update_screen_location(_OBJobject);

/* PUBLIC GLOBAL VARIABLE */
struct _OBJregistry_struct screen_location = {
	"screen_location",			/* name				*/
	{									/* variables		*/
	 {"x",				1, kDva, 0.0, 0.0},
	 {"y",				1, kDva, 0.0, 0.0},
	 {"amplitude",		1, kDva, 0.0, 0.0},
	 {"angle",			1, kAng, 0.0, 0.0},
	 {"d_amplitude",	1, kDva, 0.0, 0.0},
	 {"d_angle",		1, kAng, 0.0, 0.0}},
	{NULL},							/* children			*/
	{NULL},							/* connections		*/
	0,									/* tag flag			*/
	NULL,								/* free extras fn	*/
	NULL,								/* update string	*/
	&update_screen_location};	/* update fn		*/
	
/* PUBLIC ROUTINES */

/* PUBLIC ROUTINE: update_screen_location
*
*/
void update_screen_location(_OBJobject obj)
{
	printf("update_screen_location\n");
}
