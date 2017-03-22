/*
 *  LCPerformance.c
 *  LabTools
 *
 *  Created by jigold on Fri Jul 23 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include "LCPerformance.h"

/* PUBLIC ROUTINE: pfm_init
*
*/
_PFMrec pfm_init(void)
{
	_PFMrec rec = SAFE_STALLOC(_PFMrec_struct);
	
	rec->scores				= NULL;
	rec->num_history		= 0;
	rec->history_index	= 0;
	rec->history			= NULL;
	
	rec->num_vals			= 0;
	rec->vals				= NULL;
	
	return(rec);
}

/* PUBLIC ROUTINE: pfm_make_scores
*
* Convenience function to make a performance struct with SCORES only
*
* Arguments:
*			num_history ... length of history to keep track of
*			num_scores  ... number of scores in the succeeding list
*			vararg		... list of scores (char *names)
* Returns:
*  the _PFMrec
*/
_PFMrec pfm_make_scores(int num_history, int num_scores, ...)
{
	va_list ap;
	_PFMrec rec = pfm_init();
	
	/* add the history */
	if(num_history > 0)
		pfm_add_history(rec, num_history);
	
	/* add the scores with the variable length arg list */
	if(num_scores > 0) {
		va_start(ap, num_scores);
		pfm_add_scores(rec, num_scores, ap);
		va_end(ap);
	}
}

/* PUBLIC ROUTINE: pfm_make_values
*
* Convenience routine to make a performance struct with VALUES only
*
* Arguments:
*			num_history ... length of history to keep track of
*			num_vals		... number of entries in the succeeding list
*			vararg		... list of values (char *names)
* Returns:
*  the _PFMrec
*/
_PFMrec pfm_make_values(int num_history, int num_vals, ...)
{
	va_list ap;
	_PFMrec rec = pfm_init();
	
	/* add the history */
	if(num_history > 0)
		pfm_add_history(rec, num_history);
	
	/* add the values with the variable length arg list */
	if(num_scores > 0) {
		va_start(ap, num_values);
		pfm_add_values(rec, num_values, ap);
		va_end(ap);
	}
}

/* PUBLIC ROUTINE: pfm_add_history
*
*/
void pfm_add_history(_PFMrec rec, int num_history)
{
	/* clear it if it exists */
	SAFE_FREE(rec->history);
	
	/* add the new history array */
	rec->num_history		= num_history;
	rec->history_index	= 0;
	rec->history			= SAFE_ZALLOC(long, num_history);	
}

/* PUBLIC ROUTINE: pfm_print
*
*/
void pfm_print(_PFMrec rec)
{
	pfm_print_scores(rec);
	pfm_print_values(rec);
}

/* PUBLIC ROUTINE: pfm_free
*
*/
void pfm_free(_PFMrec rec)
{
	register int i;
	
	if(!rec)
		return;
	
	/* free scores */
	vara_free(rec->scores);
	
	/* free history */
	SAFE_FREE(rec->history);
	
	/* free values */
	for(i=0;i<rec->num_vals;i++) {
		SAFE_FREE(rec->vals[i]->name);
		SAFE_FREE(rec->vals[i]->values);
	}
	SAFE_FREE(rec->vals);
}

/* PUBLIC ROUTINE: pfm_add_scores
*
*  Arguments:
*		rec			... duh
*		num_scores  ... length of subsequent list
*		vaarg			... list of char *names of scores
*  Returns:
*		nada
*/
void pfm_add_scores(_PFMrec rec, int num_scores, ...)
{
	va_list ap;
	register int i;
	
	if(!rec || num_scores < 1)
		return;
	
	/* allocate mem */
	rec->scores->variables = SAFE_ALLOC(_VARvariable, rec->scores->num_variables, 
									 num_scores, rec->scores->variables);

	/* loop through the va_args, adding a _VARvariable_struct for each */
	va_start(ap, num_scores);
	for(i=num_scores;i>0;i--)
		rec->scores->variables[rec->scores->num_variables++] = 
		var_make(va_arg(ap, char *), PFM_DEF_TAG, PFM_DEF_ENAB, PFM_DEF_UNIT, 
					PFM_DEF_VAL, PFM_DEF_DVAL, PFM_DEF_MIN, PFM_DEF_MAX);

	return(rec);
}

/* PUBLIC ROUTINE: pfm_reset_scores
*
*/
void pfm_reset_scores(_PFMrec rec)
{
	if(!rec || !rec->scores || !rec->scores->num_variables)
		return;
	
	vara_set_defaults(rec->scores);
}

/* PUBLIC ROUTINE: pfm_update_score_by_index
*
*/
void pfm_update_score_by_index(_PFMrec rec, long index)
{
	if(!rec || !rec->scores || index < 0 || index >= rec->scores->num_variables)
		return;

	rec->scores->variables[index]->value++;
}

/* PUBLIC ROUTINE: pfm_update_scores_by_index
*
* Arguments:
*		rec			... duh
*		num_scores  ... length of subsequent list
*		va_arg		... list of (long) indices
*/
void pfm_update_scores_by_index(_PFMrec rec, int num_scores, ...)
{
	register int i;
	va_list ap;
	
	if(!rec || !rec->scores)
		return;
	
	va_start(ap, num_scores);
	for(i=num_scores;i>0;i--)
		pfm_update_score_by_index(rec, va_arg(ap, long));
	va_end(ap);
}

/* PUBLIC ROUTINE: pfm_update_score_by_name
*
*/
void pfm_update_score_by_name(_PFMrec rec, char *name)
{
	_VARvariable var;
	
	if(!rec || !rec->scores || !name)
		return;
	
	if(var = vara_getv_by_name(rec->scores, name))
		var->value++;
}

/* PUBLIC ROUTINE: pfm_update_scores_by_name
*
* Arguments:
*		rec			... duh
*		num_scores  ... length of subsequent list
*		va_arg		... list of (char *) names
*/
void pfm_update_scores_by_name(_PFMrec rec, int num_names, ...)
{
	register int i;
	va_list ap;
	
	if(!rec || !rec->scores)
		return;
	
	va_start(ap, num_scores);
	for(i=num_scores;i>0;i--)
		pfm_update_score_by_name(rec, va_arg(ap, char *));
	va_end(ap);
}

/* PUBLIC ROUTINE: pfm_add_values
 *
 *  Arguments:
 *		rec			... duh
 *		array_size	... size of each value array
 *		num_scores  ... length of subsequent list (number of value arrays)
 *		va_arg		... (char *) names of values
 *				
 *  Returns:
 *		nada
*/
void pfm_add_values(_PFMrec rec, int array_size, int num_values, ...)
{
	va_list ap;
	register int i;
	
	if(!rec)
		return;
	
	rec->
	/* loop through the va_args, adding a _VARvariable_struct for each */
	va_start(ap, num_scores);
	for(i=num_scores;i>0;i--)
		vara_addv(rec->scores, 
					 var_make(va_arg(ap, char *), PFM_DEF_TAG, PFM_DEF_ENAB, PFM_DEF_UNIT, 
								 PFM_DEF_VAL, PFM_DEF_DVAL, PFM_DEF_MIN, PFM_DEF_MAX));
	return(rec);
}

