/*
 *  LCObject.h
 *  LabTools Common
 *
 *  Basic "object" that stores variables, exists in a hierarchy
 *		of "parents" and "children", and points to other objects
 *	 Uses only one method: "update"
 *
 *  Prefix: OBJ
 *
 *  Created by jigold on Wed Jan 19 2005.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#ifndef _LC_OBJECT_H_
#define _LC_OBJECT_H_

/* INCLUDED FILES */
#include "LCCommon.h"
#include "LCVariable.h"

/* PUBLIC CONSTANTS/MACROS */
enum TAG_FLAGS {
	kALL_TAGS_PLUS_CHILDREN,
	kALL_TAGS,
	kNO_TAGS,
};

#define MAX_NAME_LEN		32
#define MAX_VARIABLES	16
#define MAX_CHILDREN		16
#define MAX_CONNECTIONS 16

/* Tokens to read hierarchy strings. 
** Example:
**		"<object1>:<object2>;<object3>,<object4>:[3].var"
**	means:
**		start with object named "object 1"
**		find CHILD named "object 2"
**		find CONNECTION named "object 3"
**		find PARENT (name ignored)
**		find 3rd CHILD
**		find variable named "var"
*/
#define VARIABLE_TOKEN		'.'
#define CHILD_TOKEN			':'
#define CONNECTION_TOKEN	';'
#define PARENT_TOKEN			','
#define NUM_TOKEN				'['
#define OBJ_TOKENS			":;,"
#define TOKENS					".:;,["

#define OBJ_GET(o,s)		var_get(obj_getv(o,s))

/* PUBLIC DATA TYPES */

typedef struct _OBJregistry_struct	*_OBJregistry;
typedef struct _OBJobject_struct		*_OBJobject;
typedef void (*_OBJfn) (_OBJobject);

struct _OBJregistry_struct {
	char								*type;
	
	struct _VARvariable_struct	variables[MAX_VARIABLES];	
	char								*children[MAX_CHILDREN];
	char								*connections[MAX_CONNECTIONS*2];
	short								tag_flag;
	_OBJfn							free_extras_fn;
	char								*update_str;
	_OBJfn							update_fn;
};

struct _OBJobject_struct {
	char								*name;
	char								*type;
	
	int								num_variables;
	_VARvariable					*variables;
	
	_OBJobject						parent;
	int								num_children;
	_OBJobject						*children;
	
	int								num_connections;
	_OBJobject						*connections;
	
	short								tag_flag;

	void								*extras;
	_OBJfn							free_extras_fn;	
	
	char								*update_str;
	_OBJfn							update_fn;
};

/* PUBLIC ROUTINE PROTOTYPES */
void				obj_reg_add							(_OBJregistry);
_OBJregistry	obj_reg_get_bytype				(char *);
_OBJobject		obj_reg_build						(_OBJregistry, char *);
_OBJobject		obj_reg_build_bytype				(char *, char *);
void				obj_reg_build_children			(_OBJobject, _OBJregistry, int);
void				obj_reg_build_children_bytype	(_OBJobject, char *, int);

_OBJobject		obj_init								(void);
_OBJobject		obj_build							(char *, char *, int, _VARvariable, void *,	_OBJobject, 
															int, _OBJobject *, short, char *, _OBJfn, _OBJfn);
_OBJobject		obj_copy								(_OBJobject, char *, int);

void				obj_add_variable					(_OBJobject, _VARvariable);
void				obj_add_connection				(_OBJobject, _OBJobject);
void				obj_add_child						(_OBJobject, _OBJobject);

_VARtype			obj_get								(_OBJobject, char *);
_VARvariable	obj_get_var							(_OBJobject, char *);
int				obj_get_var_index					(_OBJobject, char *);
_OBJobject		obj_get_obj							(_OBJobject, char *);
int				obj_get_child_index				(_OBJobject, char *);
int				obj_get_connect_index			(_OBJobject, char *);

BOOLEAN			obj_set								(_OBJobject, char *, _VARtype);
BOOLEAN			obj_set_to_default				(_OBJobject, char *);
BOOLEAN			obj_set_values						(_OBJobject, char *, ...);
void				obj_set_values_update			(_OBJobject, char *, ...);
BOOLEAN			obj_set_children					(_OBJobject, int, int *, ...);
void				obj_set_children_update			(_OBJobject, int, int *, ...);


void				obj_update							(_OBJobject);
void				obj_drop_tags						(_OBJobject);

void				obj_free_variables				(_OBJobject);
void				obj_clear_connections			(_OBJobject);
void				obj_free_children					(_OBJobject);
void				obj_free_extras					(_OBJobject);
void				obj_free								(_OBJobject);

#endif /* _LC_OBJECT_H_ */