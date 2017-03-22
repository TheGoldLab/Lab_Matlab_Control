/*
 * LCSafeAlloc.h
 * LabTools Common
 *
 * Description: Wrapper functions for memory allocation
 *
 * Prefix: safe
 *
 * Revision history:
 *  created by mazer Sun Mar 19 10:56:29 1995 mazer@asio
 *  cleaned up a little by jig 12/12/95
 *  revised by jigold 7/9/04
 */

/* INCLUDES */
#include <stdlib.h>
#include "LCSafeAlloc.h"
#include "LCMessages.h"

/* PUBLIC ROUTINES */
void *safe_calloc(size_t nmemb, size_t size, char *file, int line)
{
	void *x;

	if(nmemb < 1 || size < 1)
		return(NULL);
	
	x = calloc(nmemb, size);
	
#ifdef SHOW_ERRORS
	if(!x)
		msg_error("Calloc error", file, line);
#endif
	
	return(x);
}

void *safe_malloc(size_t size, char *file, int line)
{
	void *x;

	if(size < 1)
		return(NULL);
	
	x = malloc(size);
	
#ifdef SHOW_ERRORS
	if(!x)
		msg_error("Malloc error", file, line);
#endif
	
	return(x);
}

void *safe_realloc(void *ptr, size_t size, char *file, int line)
{
	void *x;

	if(ptr && size < 1)
		return(ptr);
	
	if(!ptr && size < 1)
		return(NULL);
	
	x = realloc(ptr, size);
	
#ifdef SHOW_ERRORS
	if(!x)
		msg_error("Realloc error", file, line);
#endif
	
	return(x);
} 
