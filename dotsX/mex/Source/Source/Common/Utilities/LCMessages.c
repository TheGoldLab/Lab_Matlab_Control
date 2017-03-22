/*
 *  LCMessages.c
 *  LabTools Common
 *
 *  Description:
 *		  Prints several kinds of messages:
 *				- ERROR
 *				- WARNING
 *				- DEBUG
 *				- MESSAGE
 * 
 *  Prefix: msg
 *
 *  Created by jigold on Fri Jul 09 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#include "LCMessages.h"

/* PUBLIC ROUTINES */
void msg_error(char *msg, char *file, int line)
{
	printf("ERROR in file <%s>, line <%d>: %s\n", file, line, msg);
}

void msg_warning(char *msg, char *file, int line)
{
	printf("WARNING in file <%s>, line <%d>: %s\n", file, line, msg);
}

void msg_debug(char *msg, char *file, int line)
{
	printf("DEBUG in file <%s>, line <%d>: %s\n", file, line, msg);
}

void msg_message(char *msg, char *file, int line)
{
	printf("MESSAGE in file <%s>, line <%d>: %s\n", file, line, msg);
}