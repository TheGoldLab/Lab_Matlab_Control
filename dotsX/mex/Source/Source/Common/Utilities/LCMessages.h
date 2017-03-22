/*
 *  LCMessages.h
 *  LabTools Common
 *
 *  Description: Header function for LTMessages.c
 *		  Prints several kinds of messages:
 *				- ERROR
 *				- WARNING
 *				- DEBUG
 *				- MESSAGE
 *
 *  Prefix: MSG
 *
 *  Created by jigold on Fri Jul 09 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
 */

#ifndef _LC_MESSAGES_H_
#define _LC_MESSAGES_H_

#include <Carbon/Carbon.h>

#define SHOW_ERRORS
#define SHOW_WARNINGS
#define SHOW_DEBUGS
#define SHOW_MESSAGES

#ifdef SHOW_ERRORS
#define MSG_ERROR(msg) msg_error(msg, __FILE__, __LINE__)
#else
#define MSG_ERROR(msg) {}
#endif

#ifdef SHOW_WARNINGS
#define MSG_WARNING(msg) msg_warning(msg, __FILE__, __LINE__)
#else
#define MSG_WARNING(msg) {}
#endif

#ifdef SHOW_DEBUGS
#define MSG_DEBUG(msg) msg_debug(msg, __FILE__, __LINE__)
#else
#define MSG_DEBUG(msg) {}
#endif

#ifdef SHOW_MESSAGES
#define MSG_MESSAGE(msg) msg_message(msg, __FILE__, __LINE__)
#else
#define MSG_MESSAGE(msg) {}
#endif

/* PUBLIC ROUTINE PROTOTYPES */
void msg_error		(char *, char *, int);
void msg_warning  (char *, char *, int);
void msg_debug		(char *, char *, int);
void msg_message  (char *, char *, int);

#endif
