/*
 *  LCGraphics.h
 *  LabTools
 *
 *  Created by jigold on Tue Aug 17 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

#ifndef _LC_GRAPHICS_H_
#define _LC_GRAPHICS_H_

#include "LCVariables.h"

void		gr_init(int, ...);
_VARtype gr_get(int);
void		gr_set(BOOLEAN, BOOLEAN, int, ...);
void		gr_clear(void);
void		gr_free(void);