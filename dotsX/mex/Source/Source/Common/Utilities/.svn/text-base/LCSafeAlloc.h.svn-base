/*
 * LCSafeAlloc.h
 * LabTools Common
 *
 * Description: Header file for LTSafeAlloc.c
 *   Wrapper functions for memory allocation
 *
 * Prefix: SAFE
 *
 * Revision history:
 *  created by mazer Sun Mar 19 10:56:29 1995 mazer@asio
 *  revised by jigold 2002/02/08 01:42:05
 *  revised by jigold 7/9/04
*/
 
#ifndef _LC_SAFE_ALLOC_H_
#define _LC_SAFE_ALLOC_H_

#include <stdlib.h>

/* PUBLIC ROUTINE PROTOTYPES */
void *safe_calloc (size_t, size_t, char *, int);
void *safe_malloc (size_t, char *, int);
void *safe_realloc(void *, size_t, char *, int);

/* PUBLIC MACROS */
#define SAFE_CALLOC(a,b)  	safe_calloc((size_t) (a), (size_t) (b), __FILE__, __LINE__)
#define SAFE_MALLOC(a) 	  	safe_malloc((size_t) (a), __FILE__, __LINE__)
#define SAFE_REALLOC(a,b) 	safe_realloc((void *) (a), (size_t) (b), __FILE__, __LINE__)
#define SAFE_FREE(p) 		{if ((p)) {free((p)); (p) = NULL;}}

#define SAFE_STALLOC(st)	((struct st *)SAFE_MALLOC(sizeof(struct st)))
#define SAFE_ZALLOC(s,num) ((num)?((s*)SAFE_MALLOC((sizeof(s)) * (long)(num))):NULL)
#define SAFE_MRALLOC(p,o,n,a) ((p*) \
	((!o)?SAFE_MALLOC(n*sizeof(p)):SAFE_REALLOC(a,(o+n)*sizeof(p))))

#define SAFE_STRCPY(s)		((s) ? (char *)strcpy(SAFE_MALLOC(strlen(s)+1),s) : NULL)
#define SAFE_STRCAT(f1,f2) ((f1) ? (f2) ? (char *) strcat((char *) \
					SAFE_REALLOC((f1), (strlen(f1) + strlen(f2) + 2)), (f2)) : (f1) : NULL)


#endif /* _LC_SAFE_ALLOC_H_ */
