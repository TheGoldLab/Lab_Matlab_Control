/*
 *  LCVariable.h
 *  LabTools Common/VariableObjects
 *
 *  Data structures for variables and data objects (lists of variables)
 *
 *  Prefix: VAR
 *
 *  Created by jigold on Fri Jul 09 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#ifndef _LC_VARIABLE_H_
#define _LC_VARIABLE_H_

/* INCLUDED FILES */
#include "LCCommon.h"

/* PUBLIC MACROS/CONSTANTS */
#define VDEFAULT	0.0
#define VNULL		-9999.9
#define VSETDEF	-9999.8
#define NT 0		/* no tag */
#define NH 0		/* no history */
#define VH -1		/* variable history */

/* PUBLIC DATA TYPES */
typedef int		 _VARtag;
typedef double	 _VARtype;
typedef struct	 _VARvariable_struct  *_VARvariable;

/* A _VARvariable structure is the workhorse -- a variable of arbitrary type
** with a name (string), tag ("ecode" of type _VARtag), and
** a default value that can be set automatically
*/
struct _VARvariable_struct {
	
	char				*name;				/* identifier		*/
	_VARtag			tag;					/* used as ecode	*/
	
	_VARtype			value;				/* current value	*/
	_VARtype			default_value;		/* default value	*/
	
	char				*str;					/* possible string value			*/
	
	_VARtype			*history;			/* possibly circular buffer		*/
	int				num_history;		/* to store history of values		*/
	int				history_index;
};

/* PUBLIC ROUTINE PROTOTYPES */
_VARvariable	var_init					(void);
_VARvariable	var_build				(char *, _VARtag, _VARtype, _VARtype, char *, int);
_VARvariable	var_copy					(_VARvariable);

_VARtype			var_get					(_VARvariable);
void				var_reset_history		(_VARvariable);
void				var_set_history		(_VARvariable, int);
void				var_set_as_default	(_VARvariable, _VARtype);
BOOLEAN			var_set_to_default	(_VARvariable);
BOOLEAN			var_set					(_VARvariable, _VARtype);

void				var_print				(_VARvariable);
void				var_read					(_VARvariable, char **);
void				var_write				(_VARvariable, char **);

void				var_free					(_VARvariable);

#endif /* _LC_VARIABLES_H_ */
