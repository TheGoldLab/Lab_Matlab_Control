/*
 *  LCPerformance.h
 *  LabTools
 *
 *  Description: Data structures for keeping track of performance
 *		(and any other variables to save during a task)
 *
 *  Prefix: PFM
 *
 *  Created by jigold on Fri Jul 23 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#ifndef _LC_PERFORMANCE_H_
#define _LC_PERFORMANCE_H_

#include <Carbon/Carbon.h>
#include "LCVariables.h"

/* PUBLIC CONSTANTS */
/* Standard set of scores.. you don't need to use these */
enum scores {
	kWRONG,
	kCORRECT,
	kNO_CHOICE,
	kBR_FIX,
	kNO_FIX,
};

#define PFM_DEF_TAG  0
#define PFM_DEF_ENAB 1
#define PFM_DEF_UNIT 0
#define PFM_DEF_VAL  0
#define PFM_DEF_DVAL 0
#define PFM_DEF_MIN  -99999
#define PFM_DEF_MAX  99999

#define PFM_HISTORY 5
#define PFM_NUM_SCORES sizeof(scores)
#define PFM_MAKE_STD pfm_make_scores(PFM_HISTORY, PFM_NUM_SCORES, "err", "cor", "nc", "bf", "nf")

/* PUBLIC DATA STRUCTURES */
typedef struct _PFMscore_struct  *_PFMscore;
typedef struct _PFMval_struct		*_PFMval;
typedef struct _PFMrec_struct		*_PFMrec;

struct _PFMscore_struct {
	char			*name;
	long			 count;
	_PFMscore	 group;
};

struct _PFMval_struct {
	char			*name;
	double		*values;
};

struct _PFMrec_struct {
	
	_VARarray	 scores;

	int			 trial_index;	
	int			 total_trials;
	int			 total_vals;
	_PFMvalue	*vals;
};

/* PUBLIC ROUTINE PROTOTPYES */
_PFMrec	pfm_init							(void);
_PFMrec  pfm_make							(int, int, ...);
void		pfm_print						(_PFMrec, ...);
void		pfm_free							(_PFMrec);

void		pfm_reset						(_PFMrec);
void		pfm_reset_scores				(_PFMrec);
void		pfm_reset_values				(_PFMrec);

void		pfm_add_by_index				(_PFMrec, long, ...);
void		pfm_add_score_by_index		(_PFMrec, long);
void		pfm_add_values_by_index		(_PFMrec, ...);

void		pfm_add_by_name				(_PFMrec, char *, ...);
void		pfm_add_score_by_name		(_PFMrec, char *);
void		pfm_add_values_by_name		(_PFMrec, ...);

#endif /* _LC_PERFORMANCE_H_ */
