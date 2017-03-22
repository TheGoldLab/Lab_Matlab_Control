/*
 *  LRGraphicsMessages.c
 *  LabTools -- REX-specific code
 *		Messages via pcmsg to the Mac (running MATLAB)
 *		and to Plexon (to save as ecodes)
 *
 *  Created by jigold on Wed Jul 21 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include "LRGraphicsMessages.h"
#include "LCVariables.h"
#include "LCMessages.h"

/* PRIVATE VARIABLES */
/* REGISTRY OF KNOWN GRAPHIC OBJECTS */
static struct _VARbuild_group_struct gl_graphics_registry[] = {
{"screen",
	{{"monitorWidth",		NT, 0, 0,		 0,	  100, kDcm, NULL, 0, 0},
	 {"monitorRefresh",  NT, 0, 0,		 0,	  500, kFHz, NULL, 0, 0},
	 {"viewingDistance", NT, 0, 0,		 0,	  500, kDcm, NULL, 0, 0},
	 {"screenNumber",		NT, 0, 0,		 0,	   10, kObI, NULL, 0, 0},
	 {VAR_END},
	}},

{"target",
	{{"visible",			NT, 0, 0, BOO_MIN, BOO_MAX, kBoo, NULL, 0, 0},
	 {"x",					NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"y",					NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"diameter",			NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"clut_index",		NT, 0, 0, CLI_MIN, CLI_MAX, kCLI, NULL, 0, 0},
	 {VAR_END},
	}},

{"dots",
	{{"visible",			NT, 0, 0, BOO_MIN, BOO_MAX, kBoo, NULL, 0, 0},
	 {"ap_x",				NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"ap_y",				NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"ap_diameter",		NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"clut_index",		NT, 0, 0, CLI_MIN, CLI_MAX, kCLI, NULL, 0, 0},
	 {"coherence",			NT, 0, 0, PCT_MIN, PCT_MAX, kPct, NULL, 0, 0},
	 {"direction",			NT, 0, 0, DVA_MIN, DVA_MAX, kDVA, NULL, 0, 0},
	 {"speed",				NT, 0, 0, DVA_MIN, DVA_MIN, kDVA, NULL, 0, 0},
	 {"novar_pct",			NT, 0, 0, PCT_MIN, PCT_MAX, kPct, NULL, 0, 0},
	 {"seed_base",			NT, 0, 0,		 0,	 9999, kVal, NULL, 0, 0},
	 {VAR_END},
	}},};

static int			gl_dummy_went_flag	= 0;
static _VARgroup  gl_graphics				= NULL;

/* PUBLIC ROUTINES */

/* PUBLIC ROUTINE: gr_init
 *
 * Arguments:
 *		set_dummy_went_flag  ... if 0, don't really check for went
 *		num_graphics			... number of objects in rest of
 *											argument list
 *		va_arg					... "num_graphics" list of string names
*/
void gm_init(int set_dummy_went_flag, int num_graphics, ...)
{
	register int i;
	va_list ap;
	_VARgroup group = varg_build("graphics", gl_graphics_registry, 0);
	varg_print(group);
	return;
	
	/* this really shouldn't happen ... */
	if(!num_graphics) {
		MSG_ERROR("gr_init called with no graphics initializers");
		varg_free(gl_graphics);
		gl_graphics = NULL;
		return;
	}
	
	/* loop through each of the given types */
	
	
}

void gm_init(int, int, ...);
void gm_set(BOOLEAN, BOOLEAN, int, ...);
void gm_check_went(void);
void gm_free(void);