/*
 *  LCVariables.c
 *  LabTools Common/VariableObjects
 *
 *  Data structures for variables and data objects (lists of variables)
 *
 *  Prefix: var
 *
 *  Created by jigold on Fri Jul 09 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include "LCVariable.h"
#include "LCMessages.h"
#include "LCSafeAlloc.h"

/* PUBLIC ROUTINES
*
*/

/* PUBLIC ROUTINE: var_init
*
* Arguments: none
* Returns: a pointer to the created variable structure
*/
_VARvariable var_init(void)
{
	_VARvariable var = SAFE_STALLOC(_VARvariable_struct);
	
	var->name				= NULL;
	var->tag					= 0;
	var->value				= VDEFAULT;
	var->default_value	= VDEFAULT;
	var->str					= NULL;
	var->history			= NULL;
	var->num_history		= 0;
	var->history_index	= -1;

	return(var);
}

/* PUBLIC ROUTINE: var_build
*
* Builds a _VARvariable_struct from the given arguments
*	Note that the history array is created but not initialized to any particular value(s)
*
* Arguments: name, tag, type, value, default value, string, history length
* Returns: a pointer to the created variable structure
*/
_VARvariable var_build(char *name, _VARtag tag, _VARtype value, _VARtype default_value, char *str, int num_history)
{
	_VARvariable var		= var_init();
	
	var->name				= SAFE_STRCPY(name);
	var->tag					= tag;
	var->value				= value;
	var->default_value	= default_value;
	var->str					= SAFE_STRCPY(str);
	
	if(num_history > 0) {
		var->num_history		= num_history;
		var->history_index	= -1;
		var->history			= SAFE_ZALLOC(_VARtype, num_history);
	}
	
	return(var);
}

/* PUBLIC ROUTINE: var_copy
*
*/
_VARvariable var_copy(_VARvariable in)
{
	if(in)
		return(var_build(in->name, in->tag, in->value, in->default_value, in->str, in->num_history));
	return(NULL);
}

/* PUBLIC ROUTINE: var_get
*
*/
_VARtype var_get(_VARvariable var)
{
	if(var)
		return(var->value);
	return(NULL);
}

/* PUBLIC ROUTINE: var_reset_history
*
*/
void var_reset_history(_VARvariable var)
{
	/* simply set history index to -1, just before the start of the array */
	if(var)
		var->history_index = -1;
}

/* PUBLIC ROUTINE: var_set_history
*
* sets the history buffer to the given length. If it already exists, 
*	adds the given length. If it already exists and the given
*	length is 0, clears the history.
*/
void var_set_history(_VARvariable var, int length)
{
	if(!var)
		return;
		
	if(var->num_history > 0 && length == 0) {

		SAFE_FREE(var->history);
		var->num_history		= 0;
		var->history_index	= -1;

	} else if(length > 0) {
	
		var->history = SAFE_MRALLOC(_VARtype, var->num_history, length, var->history);
		var->num_history++;
	}
}

/* PUBLIC ROUTINE: var_set_as_default
*
*/
void var_set_as_default(_VARvariable var, _VARtype value)
{
	if(!var)
		return;
		
	var->default_value = value;
}

/* PUBLIC ROUTINE: var_set_to_default
*
*	Sets the variable's value to its default value.
*	If necessary, saves the old value in the history array
*/
BOOLEAN var_set_to_default(_VARvariable var)
{
	if(!var)
		return(NO);

	return(var_set(var, var->default_value));
}

/* PUBLIC ROUTINE: var_set
*
*/
BOOLEAN var_set(_VARvariable var, _VARtype value)
{
	if(!var)
		return(NO);
		
	/* add to history, if necessary */
	if(var->history != NULL) {
		if(++(var->history_index) >= var->num_history)
			var->history_index = 0;
		var->history[var->history_index] = var->value;
	}
	
	/* check for special "VSETDEF" keyval */
	if(value == VSETDEF)
		value = var->default_value;
		
	/* set to given value, checking whether the value changes */
	if(var->value != value) {
		var->value = value;
		return(YES);
	} else {
		return(NO);
	}
}

/* PUBLIC ROUTINE: var_print
*
*/
void var_print(_VARvariable var)
{
	if(!var)
		return;
	
	printf("\t%s: value=%lf, default=%lf\n", var->name, var->value, var->default_value);
}

/* PUBLIC ROUTINE: var_read
*
*/
void var_read(_VARvariable var, char **str)
{

}

/* PUBLIC ROUTINE: var_write
*
*/
void var_write(_VARvariable var, char **str)
{

}

/* PUBLIC ROUTINE: var_free
*
*/
void var_free(_VARvariable var)
{
	if(!var)
		return;
	
	/* free the name */
	SAFE_FREE(var->name);

	/* free the string */
	SAFE_FREE(var->str);
	
	/* free the history */
	SAFE_FREE(var->history);
	
	/* free the variable struct */
	SAFE_FREE(var);
}
