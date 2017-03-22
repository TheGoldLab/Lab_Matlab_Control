/*
 *  LCRoot.h
 *  LabTools Common
 *
 *
 *  Prefix: RT
 *
 *  Created by jigold on Wed Jan 19 2005.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#ifndef _LC_ROOT_H_
#define _LC_ROOT_H_

/* INCLUDED FILES */
#include "LCCommon.h"
#include "LCObject.h"

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

#define OBJ_GET(o,s)		var_get(obj_getv(o,s))

/* PUBLIC DATA TYPES */

typedef struct _RTroot_struct *_RTroot;

struct _RTroot_struct {
	_OBJobject	*root_object;
	
	_OBJfn		*
typedef struct _OBJregistry_struct	*_OBJregistry;
typedef struct _OBJobject_struct		*_OBJobject;
typedef void (*_OBJfn) (_OBJobject);

struct _OBJregistry_struct {
	char								*name;
	
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
void				obj_registry_init			(void);
void				obj_registry_add			(_OBJregistry);
_OBJobject		obj_registry_build		(_OBJregistry);
_OBJobject		obj_registry_get_by_name(char *);

_OBJobject		obj_init						(void);
_OBJobject		obj_build					(char *, int, _VARvariable, void *,	_OBJobject, 
													int, _OBJobject *, short, char *, _OBJfn, _OBJfn);
_OBJobject		obj_copy						(_OBJobject, char *, int);

void				obj_add_variable			(_OBJobject, _VARvariable);
void				obj_add_connection		(_OBJobject, _OBJobject);
void				obj_add_child				(_OBJobject, _OBJobject);

_OBJobject		obj_geto_from_string		(_OBJobject, char *);
_VARvariable	obj_getv_from_string		(_OBJobject, char *);
BOOLEAN			obj_setv						(_OBJobject, ...);
BOOLEAN			obj_setvu					(_OBJobject, ...);
BOOLEAN			obj_setv_to_default		(_OBJobject, ...);
BOOLEAN			obj_setvu_to_default		(_OBJobject, ...);

void				obj_update					(_OBJobject);
void				obj_drop_tags				(_OBJobject);

void				obj_free_variables		(_OBJobject);
void				obj_clear_connections	(_OBJobject);
void				obj_free_children			(_OBJobject);
void				obj_free_extras			(_OBJobject);
void				obj_free						(_OBJobject);

#endif /* _LC_OBJECT_H_ */