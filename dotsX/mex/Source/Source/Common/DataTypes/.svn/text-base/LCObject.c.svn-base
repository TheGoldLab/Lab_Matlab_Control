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

/* PRIVATE CONSTANTS/VARIABLES */
#define BAD_INDEX -1
#define EXTR(v)	extern struct _OBJregistry_struct v
EXTR(screen_location);

static _OBJregistry gl_registry[] = {
		&screen_location,
		};
static int gl_registry_length = sizeof(gl_registry)/sizeof(_OBJregistry);

/* PUBLIC ROUTINES */

/* PUBLIC ROUTINE: obj_reg_add
*
*/
void obj_reg_add(_OBJregistry reg)
{
	/* add to the global registry */
	gl_registry = SAFE_MRALLOC(_OBJregistry, gl_registry_length, 1, gl_registry);
	gl_registry[gl_registry_length++] = reg;	
}

/* PUBLIC ROUTINE: obj_reg_get_bytype
*
*/
_OBJregistry obj_reg_get_bytype(char *type)
{
	register int i;
	_OBJregistry *rPtr=gl_registry;
	
	/* quick check */
	if(!type)
		return(NULL);
		
	/* loop through the registry, looking for the given "type" */
	for(i=gl_registry_length;i>0;i--,rPtr++)
		if(!strcmp((*rPtr)->type, type))
			return(*rPtr);

	/* did not find it */
	return(NULL);
}

/* PUBLIC ROUTINE: obj_reg_build
*
*/
_OBJobject obj_reg_build(_OBJregistry reg, char *name)
{
	register int i;
	int num_variables=0, num_children=0, num_connections=0;
	
	if(!reg)
		return(NULL);

	/* count number of variables */
	while(reg->variables[num_variables++]->name) ;
		
	/* count number of children */
	while(reg->children[num_children++]) ;
		
	/* count number of connections */
	while(reg->connections[num_connections++]) ;
		
	return(obj_build(name, reg->type, num_variables, &(reg->variables), NULL, NULL,
				num_children, reg->children, num_connections, reg->connections,
				reg->tag_flag, reg->free_extras_fn, reg->update_str, reg->update_fn));
}

/* PUBLIC ROUTINE: obj_reg_build_bytype
*
* Search the gl_registry for the named object;
* if found, build and return it
*/
_OBJobject obj_reg_build_bytype(char *type, char *name)
{
	return(obj_reg_build(obj_reg_get_bytype(type), name));	
}

/* PUBLIC ROUTINE: obj_reg_build_children
*
* Use the given _OBJregistry to build "num" number of objects, making
* them children of the given parent
*/
void obj_reg_build_children(_OBJobject parent, _OBJregistry reg, int num)
{
	register int	i;
	_OBJobject		*cPtr;
	char				cbuf[32];
	
	/* do nothing if any NULL args */
	if(!parent || !reg || !num)
		return;
		
	/* alloc mem - this adds to given children */
	cPtr = parent->children = 
		SAFE_MRALLOC(_OBJobject, parent->num_children, num, parent->children);
	cPtr += parent->num_children;
	parent->num_children += num;
	
	/* loop through the new children, adding a copy of given reg */
	for(i=0;i<num;i++) {
		sprintf(cbuf, "child%d", i);
		(*cPtr++) = obj_reg_build(reg, cbuf);
	}
}

/* PUBLIC ROUTINE: obj_reg_build_children_bytype
*
* Use the given _OBJregistry type to build "num" number of objects, making
* them children of the given parent
*/
void obj_reg_build_children_bytype(_OBJobject parent, char *type, int num)
{
	obj_reg_build_children(parent, obj_reg_get_bytype(type), num);
}

/* PUBLIC ROUTINE: obj_init
*
*/
_OBJobject obj_init(void)
{
	_OBJobject obj			= SAFE_STALLOC(_OBJobject_struct);

	obj->name				= NULL;
	obj->type				= NULL;
	
	obj->num_variables	= 0;
	obj->variables			= NULL;
	
	obj->parent				= NULL;
	obj->num_children		= 0;
	obj->children			= NULL;
	
	obj->num_connections	= 0;
	obj->connections		= NULL;
	
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
_OBJobject obj_build(char *name, char *type, int num_vars, _VARvariable vars, 
		_OBJobject parent, int num_children, char *children[], int num_connections,
		_OBJobject *connections, short tag_flag, void *extras, _OBJfn free_extras_fn, 
		char *update_str, _OBJfn update_fn)
{
	char cbuf[32];
	register int i;
	_OBJobject out			= SAFE_STALLOC(_OBJobject_struct);

	obj->name				= SAFE_STRCPY(name);
	obj->type				= SAFE_STRCPY(type);

	/* copy variables */
	if((out->num_variables = num_vars) > 0) {
		out->variables = SAFE_ZALLOC(_VARvariable, num_vars);
		for(i=0;i<num_vars;i++)
			out->variables[i] = var_copy(vars[i]);
	}

	/* family tree */
	out->parent				= parent;
	out->num_children		= num_children;
	if(num_children) {
		out->children			= SAFE_ZALLOC(_OBJobject, num_children);
		/* children is list of types */
		for(i=0;i<num_children;i++) {
			sprintf(cbuf, "child%d", i);
			out->children[i] = obj_reg_build_bytype(children[i], cbuf);
		}
	} else {
		out->children = NULL;
	}
	
	out->num_connections	= num_connections;
	if(num_connections) {
		out->connections = SAFE_ZALLOC(_OBJobject, num_connections);
		for(i=0;i<num_connections;i++)
			out->connections[i] = connections[i];
	} else {
		out->connections		= NULL;
	}
	
	out->tag_flag			= tag_flag;
	
	out->extras				= extras;
	out->free_extras_fn	= free_extras_fn;
	
	out->update_str		= update_str;
	out->update_fn			= update_fn;
	
	return(out);
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

/* PUBLIC ROUTINE: obj_get
*
* gets the value of a named variable in the given object
* vstr can be a "compound" string but must end
* with the variable name preceded by VAR_TOKEN;
* e.g., "<object>:<object>.<var>"
*/
_VARvalue obj_get(_OBJobject obj, char *vstr)
{
	_VARvariable var;
	
	if(!obj || !vstr || !(var = obj_get_var(obj, vstr))
		return(VNULL);

	return(var->value);
}

/* PUBLIC ROUTINE: obj_get_var
*
* gets the named variable in the given object.
* vstr can be a "compound" string but must end
* with the variable name preceded by VAR_TOKEN;
* e.g., "<object>:<object>.<var>"
*/
_VARvariable obj_get_var(_OBJobject obj, char *vstr)
{	
	int index;
	
	if(!obj || !vstr || (index = obj_get_var_index(obj, vstr)) == -1)
	 return(NULL);
	 
	return(obj->variables[index]);	
}

/* PUBLIC ROUTINE: obj_get_var_index
*
* gets the index of the named variable in the given object.
* vstr can be a "compound" string but must end
* with the variable name preceded by VAR_TOKEN;
* e.g., "<object>:<object>.<var>"
*/
int obj_get_var_index(_OBJobject obj, char *vstr)
{
	register int i;
	
	/* check input */
	if(!obj || !vstr)
		return(BAD_INDEX);
		
	/* check for "compound" string that contains object info */
	if(strpbrk(vstr, OBJ_TOKENS)) {

		/* find correct object */
		obj  = obj_get_obj(obj, vstr);

		/* check for var token, indicating variable name */
		if(!(vstr = strpbrk(vstr, VAR_TOKEN)))
			return(BAD_INDEX)	
	}

	/* check for beginning "var token" */
	if(vstr[0] == VAR_TOKEN)
		vstr++;
	
	/* check for "num" token; i.e, sstr = "[<index>]" */
	if(vstr[0] == NUM_TOKEN) {
		int index;
		
		/* scan string for index */
		if(sscanf(vstr, "[%d]", index) == EOF)
			return(BAD_INDEX);
			
		/* return the index */
		return(index);
	}
	
	/* loop through the variables, checking the names */
	for(i=0;i<obj->num_variables;i++)
		if(!strcmp(obj->variables[i]->name, vstr))
			return(i);
			
	return(BAD_INDEX);
}

/* PUBLIC ROUTINE: obj_get_obj
*
* gets the named object from a compound string. This is
* the big Kahuna for parsing vstr.
*
* oh yeah, this baby recurses.
*/
_OBJobject obj_get_obj(_OBJobject obj, char *vstr)
{
	int index;
	
	/* check for object and string */
	if(!obj || !vstr)
		return(obj);
	
	switch(vstr[0]) {
	
		case VARIABLE_TOKEN:
			/* found variable -- return */
			return(obj);
			
		case PARENT_TOKEN:
			/* recurse on parent */
			if(obj_parent)
					return(obj_get_obj(obj->parent, strbrk(vstr, OBJ_TOKENS)));
			break;
			
		case CONNECTION_TOKEN:
			/* recurse on connection */
			if((index = obj_get_connect_index(obj, vstr) != BAD_INDEX)
				return(obj_get_obj(obj->connections[index], strbrk(vstr, OBJ_TOKENS)));
			break;

		default: /* case CHILD_TOKEN: */
			/* recurse on child */
			if((index = obj_get_child_index(obj, vstr) != BAD_INDEX)
				return(obj_get_obj(obj->children[index], strbrk(vstr, OBJ_TOKENS)));
			break;
	}
	
	return(obj);
}

/* PUBLIC ROUTINE: obj_get_child_index
*
* returns the index of the first child described in vstr; looks
* only to the next token
*/
int obj_get_child_index(_OBJobject obj, char *vstr)
{
	register int i;
	int len;
	
	if(!obj || !sstr)
		return(BAD_INDEX);
		
	/* check for beginning "child token" */
	if(vstr[0] == CHD_TOKEN)
		vstr++;
		
	/* look only until next token */
	if(!(len = strpbrk(vstr, TOKENS)))
		len = strlen(vstr);
		
	/* check for "num" token; i.e, sstr = "[<index>]" */
	if(vstr[0] == NUM_TOKEN) {
		int index;
		sscanf(vstr, "[%d]", index);
		return(index);
	}
	
	/* loop through the children, checking the names */
	for(i=0;i<obj->num_children;i++)
		if(!strncmp(obj->children[i]->name, vstr, len))
			return(i);
			
	/* if nothing found */
	return(BAD_INDEX);
}

/* PUBLIC ROUTINE: obj_get_connect_index
*
* returns the index of the first connection described in vstr; looks
* only to the next token
*/
int obj_get_connect_index(_OBJobject obj, char *vstr)
{
	register int i;
	int len;
	
	if(!obj || !sstr)
		return(BAD_INDEX);
		
	/* check for beginning "child token" */
	if(vstr[0] == CON_TOKEN)
		vstr++;
		
	/* look only until next token */
	if(!(len = strpbrk(vstr, TOKENS)))
		len = strlen(vstr);
		
	/* check for "num" token; i.e, sstr = "[<index>]" */
	if(vstr[0] == NUM_TOKEN) {
		int index;
		sscanf(vstr, "[%d]", index);
		return(index);
	}
	
	/* loop through the children, checking the names */
	for(i=0;i<obj->num_connections;i++)
		if(!strncmp(obj->num_connections[i]->name, vstr, len))
			return(i);
			
	/* if nothing found */
	return(BAD_INDEX);
}

/* PUBLIC ROUTINE: obj_set
*
* sets a named variable (using a possibly compound string; see obj_get_var)
* to the given value, returning whether or not the variable
* changed value
*/
BOOLEAN obj_set(_OBJobject obj, char *vstr, _VARtype val)
{
	return(var_set(obj_get_var(obj, vstr), val));	
}

/* PUBLIC ROUTINE: obj_set_to_default
*
* sets a named variable (using a possibly compound string; see obj_get_var)
* to the default value, returning whether or not the variable
* changed value
*/
BOOLEAN obj_set_to_default(_OBJobject obj, char *vstr)
{
	return(var_set_to_default(obj_get_var(obj, vstr)));
}

/* PUBLIC ROUTINE: obj_set_values
*
* gets a NULL-terminated list of pairs of:
*		(char *) name
*		_VARtype value
* and sets each
* returns whether any changed
*/
BOOLEAN obj_set_values(_OBJobject obj, ...)
{
	BOOLEAN changed=0;
	char		*vstr;
	_VARtype val;
	va_list	ap;
	
	/* start the va list */
	va_start(ap, obj);
	
	/* loop through the pairs of arguments */
	while((vstr = va_arg(ap, char *  )) != NULL &&
			(val  = va_arg(ap, _VARtype)) != NULL)
			
		/* call obj_set to set the value, checking for change */
		changed = changed || obj_set(obj, vstr, val);
	}
	
	/* end the va list */
	va_end(ap);

	/* return whether anything changed */
	return(changed);
}

/* PUBLIC ROUTINE: obj_set_values_update
*
* same as obj_set_many, except calls the given
* object's update function if anything changed
*/
void obj_set_values_update(_OBJobject, ...);
{
	BOOLEAN changed=0;
	char		*vstr;
	_VARtype val;
	va_list	ap;
	
	/* start the va list */
	va_start(ap, obj);
	
	/* loop through the pairs of arguments */
	while((vstr = va_arg(ap, char *  )) != NULL &&
			(val  = va_arg(ap, _VARtype)) != NULL)
			
		/* call obj_set to set the value, checking for change */
		changed = changed || obj_set(obj, vstr, val);
	}
	
	/* end the va list */
	va_end(ap);

	/* if anything changed, call update */
	if(changed)
		obj_update(obj);
}

/* PUBLIC ROUTINE: obj_set_children
*
*/
void obj_set_children(_OBJobject obj, int num_indices, int *indices, ...)
{

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
		
#ifdef FOR_MEX
	else if(obj->update_str != NULL)
		/* otherwise try to use the update str to call matlab */
		/* CALL_MATLAB(obj->update_str, obj); */
		return;
#endif
}

/* PUBLIC ROUTINE: obj_tag
*
*/
void obj_drop_tags(_OBJobject obj)
{
#ifdef FOR_REX
	/* drop rex ecodes */
	
#elif FOR_MEX
	/* drop mex ecodes */
	
#endif
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
