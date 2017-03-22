/*
 *  LCObject.c
 *  LabTools Common/Objects
 *
 *  Prefix: obj
 *
 *  Created by jigold on Wed Jan 19 2005.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include <stdio.h>
#include "LCMessages.h"
#include "LCSafeAlloc.h"
#include "LCObject.h"

/* PRIVATE VARIABLES */
static _OBJregistry *gl_registry=NULL;
static int				gl_registry_length=0;

#define EXTR(v)	struct _OBJregistry_struct (v)
EXTR(screen_location);

/* PUBLIC ROUTINES */

/* PUBLIC ROUTINE: obj_registry_init
*
*/
void obj_registry_init(void)
{
	obj_registry_add(screen_location);
}

/* PUBLIC ROUTINE: obj_registry_add
*
*/
void obj_registry_add(_OBJregistry reg)
{
	gl_registry = SAFE_MRALLOC(_OBJregistry, gl_registry_length, 1, gl_registry);
	gl_registry[gl_registry_length++] = reg;	
}

/* PUBLIC ROUTINE: obj_registry_build
*
*/
_OBJobject obj_registry_build(_OBJregistry reg)
{
	register int i;
	int num_variables=0, num_children=0, num_connections=0;
	
	if(!reg)
		return(NULL);

	/* count number of variables */
	num_variables = 0;
	while(reg->variables[num_variables]->name != NULL) 
		num_variables++;
		
	/* count number of children */
	num_children = 0;
	while(reg->children[num_children] != NULL) 
		num_children++;
		
	/* count number of connections */
	num_connections = 0;
	while(reg->connections[num_connections] != NULL) 
		num_connections++;	
		
	return(obj_build(reg->name, num_variables, &(reg->variables), NULL, NULL,
				num_children, reg->children, num_connections, reg->connections,
				reg->tag_flag, reg->free_extras_fn, reg->update_str, reg->update_fn));
}

/* PUBLIC ROUTINE: obj_registry_get_by_name
*
* Search the gl_registry for the named object;
* if found, build and return it
*/
_OBJobject obj_registry_get_by_name(char *name)
{
	register int i;
	_OBJregistry *rPtr=gl_registry;
	
	for(i=gl_registry_length;i>0;i--)
		if(!strcmp((*rPtr)->name, name))
			return(obj_registry_build(*rPtr));

	return(NULL);
}

/* PUBLIC ROUTINE: obj_init
*
*/
_OBJobject obj_init(void)
{
	_OBJobject obj			= SAFE_STALLOC(_OBJobject_struct);

	obj->name				= NULL;
	
	obj->num_variables	= 0;
	obj->variables			= NULL;
	
	obj->parent				= NULL;
	obj->num_children		= 0;
	obj->children			= NULL;
	
	obj->num_connections		= 0;
	obj->connections			= NULL;
	
	obj->tag_flag			= 0;
	
	obj->extras				= NULL;
	obj->free_extras_fn	= NULL;
	
	obj->update_str		= NULL;
	obj->update_fn			= NULL;
	
	return(obj);
}

/* PUBLIC ROUTINE: obj_build
*
*/
_OBJobject obj_build(char *name, int num_vars, _VARvariable vars, void *extras,
		_OBJobject parent, int num_children, char *children[], int num_connections,
		char *connections, short tag_flag, _OBJfn free_extras_fn, char *update_str, 
		_OBJfn update_fn)
{

}

/* PUBLIC ROUTINE: obj_copy
*
* Make a copy of an object (in->out)
*
* Arguments:
*	in			... the given object
*	name		... name of the new object
*	flag		... 0=ignore children; 1=build new children; 2=point to same children
*
* Careful -- ignores extras. And this baby's RECURSIVE
*/
_OBJobject obj_copy(_OBJobject in, char *new_name, int child_flag)
{
	_OBJobject out = obj_init();
	register int i;
	
	/* name */
	out->name = new_name ? SAFE_STRCPY(new_name) : SAFE_STRCPY(in->name);
	
	/* variables */
	if((out->num_variables = in->num_variables) > 0) {
		out->variables = SAFE_ZALLOC(_VARvariable, out->num_variables);
		for(i=0;i<out->num_variables;i++)
			out->variables[i] = var_copy(in->variables[i]);
	}
	
	/* family tree */
	out->parent = in->parent;
	if(child_flag > 0) {
		if((out->num_children = in->num_children) > 0) {
			out->children = SAFE_ZALLOC(_OBJobject, out->num_children);
			
			if(child_flag == 1) {
				/* RECURSIVELY make new copies of children */
				for(i=0;i<out->num_children;i++)
					out->children[i] = obj_copy(in->children[i], NULL, 1);
					
			} else if(child_flag == 2) {
				/* just point to same old children */
				for(i=0;i<out->num_children;i++)
					out->children[i] = in->children[i];
			}
		}
	}
	
	/* connections */
	if((out->num_connections = in->num_connections) > 0) {
		out->children = SAFE_ZALLOC(_OBJobject, out->num_children);
		for(i=0;i<out->num_children;i++)
			out->children[i] = in->children[i];
	}
	
	/* tag flag */
	out->tag_flag		= in->tag_flag;
	
	/* methods */
	out->free_extras_fn	= in->free_extras_fn;
	out->update_str		= SAFE_STRCPY(in->update_str);
	out->update_fn			= in->update_fn;	
}

/* PUBLIC ROUTINE: obj_add_variable
*
* adds a COPY of the variable to the object's variable list
*/
void obj_add_variable(_OBJobject obj, _VARvariable var)
{
	if(!obj || !var)
		return;
		
	obj->variables = SAFE_MRALLOC(_VARvariable, obj->num_variables, 1, obj->variables);
	obj->variables[obj->num_variables++] = var_copy(var);
}

/* PUBLIC ROUTINE: obj_add_connection
*
*	adds the given pointer to a connected object to the given object's
*	connection list
*/
void obj_add_connection(_OBJobject obj, _OBJobject connect)
{
	if(!obj || !connect)
		return;
		
	obj->connections = SAFE_MRALLOC(_OBJobject, obj->num_connections, 1, obj->connections);
	obj->connections[obj->num_connections++] = connect;
}

/* PUBLIC ROUTINE: obj_add_child
*
* Adds the given child to the given object
*/
void obj_add_child(_OBJobject obj, _OBJobject child)
{
	if(!obj || !child)
		return;

	obj->children = SAFE_MRALLOC(_OBJobject, obj->num_children, 1, obj->children);
	obj->children[obj->num_children++] = child;
	child->parent = obj;
}

/* PUBLIC ROUTINE: obj_geto_from_string
*
*/
_OBJobject obj_geto_from_string(_OBJobject obj, char *ostr)
{

}

/* PUBLIC ROUTINE: obj_getv_from_string
*
*	Gets a _VARvariable from the variable list of the given object
*
*	Arguments:
*		obj	... the parent object
*		vstr	... string 
*
*	Returns:
*		a _VARvariable, which is a pointer to a _VARvariable_struct
*/
_VARvariable obj_getv_from_string(_OBJobject obj, char *vstr)
{
	if(!obj || !obj->variables || !vstr)
		return(NULL);
}

/* PUBLIC ROUTINE: obj_setv
*
*	sets given variables to the given values
*
*	Arguments:
*		obj		... the parent object
*		va_list	... NULL-terminated list of char *name, _VARtype value pairs
*
*	Returns:
*		BOOLEAN whether or not ANY of the given variables changed values
*/
BOOLEAN obj_setv(_OBJobject obj, ...)
{
	BOOLEAN changed = NO;
	char *vstr;
	va_list ap;
	
	va_start(ap, obj);
	while((vstr = va_arg(ap, char *)) != NULL)
		changed = changed | var_set(obj_getv_from_string(obj, vstr), va_arg(ap, _VARtype));
	va_end(ap);
	
	return(changed);
}

/* PUBLIC ROUTINE: obj_setvu
*
*	sets given variables to the given values. Same as obj_setv
*	except here, if any argument changed then the parent object's
*	"update" method gets called
*
*	Arguments:
*		obj		... the parent object
*		va_list	... NULL-terminated list of char *name, _VARtype value pairs
*
*	Returns:
*		BOOLEAN whether or not ANY of the given variables changed values
*/
BOOLEAN obj_setvu(_OBJobject obj, ...)
{
	BOOLEAN changed = NO;
	char *vstr;
	va_list ap;
	
	va_start(ap, obj);
	while((vstr = va_arg(ap, char *)) != NULL)
		changed = changed | var_set(obj_getv_from_string(obj, vstr), va_arg(ap, _VARtype));
	va_end(ap);
	
	if(changed)
		obj_update(obj);
	
	return(changed);
}

/* PUBLIC ROUTINE: obj_setv_to_default
*
*	sets given variables to their default values
*
*	Arguments:
*		obj		... the parent object
*		va_list	... NULL-terminated list of char *names of variables
*
*	Returns:
*		BOOLEAN whether or not ANY of the given variables changed values
*/
BOOLEAN obj_setv_to_default(_OBJobject obj, ...)
{
	BOOLEAN changed = NO;
	char *vstr;
	va_list ap;
	
	va_start(ap, obj);
	while((vstr = va_arg(ap, char *)) != NULL)
		changed = changed | var_set_to_default(obj_getv_from_string(obj, vstr));
	va_end(ap);
	
	return(changed);
}

/* PUBLIC ROUTINE: obj_setvu_to_default
*
*	sets given variables to their default values. Same as obj_setv
*	except here, if any argument changed then the parent object's
*	"update" method gets called
*
*	Arguments:
*		obj		... the parent object
*		va_list	... NULL-terminated list of char *name, _VARtype value pairs
*
*	Returns:
*		BOOLEAN whether or not ANY of the given variables changed values
*/
BOOLEAN obj_setvu_to_default(_OBJobject obj, ...)
{
	BOOLEAN changed = NO;
	char *vstr;
	va_list ap;
	
	va_start(ap, obj);
	while((vstr = va_arg(ap, char *)) != NULL)
		changed = changed | var_set_to_default(obj_getv_from_string(obj, vstr));
	va_end(ap);
	
	if(changed)
		obj_update(obj);
	
	return(changed);
}

/* PUBLIC ROUTINE: obj_update
*
* Call the object's update function
*/
void obj_update(_OBJobject obj)
{
	if(!obj)
		return;

	if(obj->update_fn != NULL)
		/* use the given update function */
		(*(obj->update_fn)) (obj);
		
	else if(obj->update_str != NULL)
		/* otherwise try to use the update str to call matlab */
		/* CALL_MATLAB(obj->update_str, obj); */
		return;
}

/* PUBLIC ROUTINE: obj_tag
*
*/
void obj_drop_tags(_OBJobject obj)
{

}

/* PUBLIC ROUTINE: obj_free_variables
*
*/
void obj_free_variables(_OBJobject obj)
{
	register int i;
	
	if(!obj || !obj->num_variables)
		return;
	
	/* free each variable */	
	for(i=0;i<obj->num_variables;i++)
		var_free(obj->variables[i]);
	
	/* free the array of pointers */
	SAFE_FREE(obj->variables);	
}

/* PUBLIC ROUTINE: obj_clear_connections
*
*	Clears the list of connections
*	NOTE this is "clear" and not "free" because these
*		connections exists elsewhere in the family tree and thus
*		are not free'd; the pointers are just cleared
*/
void obj_clear_connections(_OBJobject obj)
{
	if(!obj || !obj->num_connections)
		return;
		
	SAFE_FREE(obj->connections);
	obj->num_connections = 0;
}

/* PUBLIC ROUTINE: obj_free_children
*
* Frees the memory associated with each child
*/
void obj_free_children(_OBJobject obj)
{
	register int i;
	
	if(!obj || !obj->num_children)
		return;
	
	/* free each child */	
	for(i=0;i<obj->num_children;i++)
		obj_free(obj->children[i]);
	
	/* free the array of pointers */
	SAFE_FREE(obj->children);	
}

/* PUBLIC ROUTINE: obj_free_extras
*
* Frees the memory associated with "extras", using the object-specific
*	free_extras method
*/
void obj_free_extras(_OBJobject obj)
{	
	if(!obj || !obj->extras || !obj->free_extras_fn)
		return;
	
	(*(obj->free_extras_fn)) (obj);
	obj->extras = NULL;
}

/* PUBLIC ROUTINE: obj_free
*
*/
void obj_free(_OBJobject obj)
{
	/* free name */
	SAFE_FREE(obj->name);
	
	/* free variables */
	obj_free_variables(obj);
	
	/* clear connections */
	obj_clear_connections(obj);
	
	/* free children ... note that this can become REURSIVE */
	obj_free_children(obj);
	
	/* free extras */
	obj_free_extras(obj);
	
	/* free update string */
	SAFE_FREE(obj->update_str);
	
	/* free the object */
	SAFE_FREE(obj);
}
