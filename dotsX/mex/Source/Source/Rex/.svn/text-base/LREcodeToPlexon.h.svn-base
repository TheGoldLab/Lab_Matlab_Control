/*
 *  LREcodeToPlexon.h
 *
 *  LabTools REX-specific code
 *		Tools for encoding messages (ecodes, dio commands, 
 *		or matlab commands/arguments)
 *		to send to ldevent to drop as ecodes and/or
 *		send to Harvey's magic box
 *
 *  See .c file for a detailed description of the encoding scheme
 *
 *  Prefix: EC
 *
 *  Created by jigold on Wed Jul 21 2004.
 *  Copyright (c) 2004 University of Pennsylvania. All rights reserved.
 *
*/

#ifndef _ECODE_TO_PLEXON_H_
#define _ECODE_TO_PLEXON_H_

/* PUBLIC ROUTINE PROTOTYPES */
void ec_send_code		(long);
void ec_send_code_lo (long);

void ec_send_dio		(unsigned long);
void ec_send_dio_hi  (unsigned long);

void ec_send_matlab(
						   
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <sys/types.h>

#include "LRRexHeader.h"

/* REX-SPECIFIC MACROS */
#ifdef COMPILE_FOR_REX

/* Send high-priority message (m) */
#define EC_SEND_HI(m)	{					\
	EVENT lev;									\
	lev.e_code = (unsigned short) (m);  \
	lev.e_key  = i_b->i_time;				\
	ldevent(&lev); }
/*	
** printf("HIGH PRIORITY MESSAGE: %hd\n", (short) msg); 
*/

/* send low-priority message
** flag: 0 == enter event into REX event queue AND write to efile
**			1 == do NOT enter event into REX event queue but still write to efile
*/
#define EC_SEND_LO(m,f) {					\
	EVENT lev;									\
	lev.e_code = (unsigned short) (m);  \
	lev.e_key  = i_b->i_time;				\
	ldevent_plexon_low(&lev, flag);  }
/*
** printf("LOW PRIORITY MESSAGE:  %hd\n", (short) msg); 
*/

#else		/* compile for debug */

#define EC_SEND_HI(m)	\
	printf("HIGH PRIORITY MESSAGE: %hd\n", (short) (m))
#define EC_SEND_LO(m,f) \
	printf("LOW PRIORITY MESSAGE: %hd (flag %d)\n", (short) (m), (int) (f))

#endif	/* COMPILE_FOR_REX	*/

/* macro for adding a field */
#define EC_FLD(v,b,s) (((unsigned short)( (1<<(b))-1) & (v) ) << (s))

/* EC_SEND_CODE*
**
**	message that is a "standard" REX code
** (i.e., value that we normally drop in the ecode file)
**
**	We have 13 bits -- 8192 codes -- to work with. 
**	So we could think about sending REX codes defined
**	in lcode.h as is....
**
** default priority: high
**
**	NOTE: In Plexon, these will appear as codes with prefix
**		SE00 or SE01
*/
#define EC_STD_CMD		(0x0000) /* message identifier				*/
#define EC_STD_FLD1		13			/* number of bits for "Message"	*/
#define EC_MAKE_STD(c)  (EC_STD_CMD | EC_FLD((m),EC_STD_FLD1,0))

/* argument "c": long code */
#define EC_SEND_CODE(c)		EC_SEND_HI(EC_MAKE_STD(m))
#define EC_SEND_CODE_HI(c) EC_SEND_HI(EC_MAKE_STD(m))
#define EC_SEND_CODE_LO(c) EC_SEND_LO(EC_MAKE_STD(m))

/* PUBLIC ROUTINE: ec_send_dio*
**
**	message that is a dio command
**	(i.e., something created by "Dio_id(PCDIO_DIO, <port>, <data>)")
**	-- according to REX, port can be 8 bits -- however, since
**			we only use up to port #19, we can get away with taking
**			only the ls 5 bits
**	-- according to REX, data can be 16 bits -- which frankly, I don't
**			understand because each port is only 8 bits... so here
**			we only use the ls 8 bits
**
**	argument:
**		dio_id_pattern	... the DIO_ID created by Dio_id
**
**	returns:
**		nada
**
** default priority: low
**
**	NOTE: In Plexon, these will appear as codes with prefix
**		SE02 or SE03
*/
#define EC_DIO_CMD	(0x2000) /* message identifier			*/
#define EC_DIO_FLD1	5			/* number of bits for "Port"  */
#define EC_DIO_FLD2	8			/* number of bits for "Data"  */
#define EC_MAKE_DIO(p,d) (EC_DC_CMD | 									\
								 EC_FLD((p),EC_DC_FLD1,EC_DC_FLD2) |  	\
			 					 EC_FLD((d),EC_DC_FLD2,0))
/* see hdr/device.h for details of the DIO_ID */
#define EC_DIO_PORT_MASK	 (0x1f0000)	/* only taking ms 5 bits */
#define EC_DIO_PORT_SHIFT   16			/* shift to high byte	 */
#define EC_DIO_DATA_MASK	 (0xff)		/* only taking ls 8 bits */
#define EC_DIO_DATA_SHIFT   0
#define EC_GET_DIO_PORT(id) ((unsigned short)(((id) & EC_DIO_PORT_MASK) \
											>> EC_DIO_PORT_SHIFT))
#define EC_GET_DIO_DATA(id) ((unsigned short)(((id) & EC_DIO_DATA_MASK) \
											>> EC_DIO_DATA_SHIFT))

/* argument p: DIO_ID (unsigned long) pattern */
#define EC_SEND_DIO(p)		EC_SEND_LO(EC_MAKE_DC(EC_GET_DIO_PORT(dio_id_pattern),		\
																 EC_GET_DIO_DATA(dio_id_pattern)), 1)
#define EC_SEND_DIO_HI(p)  EC_SEND_HI(EC_MAKE_DC(EC_GET_DIO_PORT(dio_id_pattern),		\
																 EC_GET_DIO_DATA(dio_id_pattern)))
#define EC_SEND_DIO_LO(p)  EC_SEND_LO(EC_MAKE_DC(EC_GET_DIO_PORT(dio_id_pattern),		\
																 EC_GET_DIO_DATA(dio_id_pattern)), 1)

/* PUBLIC ROUTINE: ec_send_matlab_command*
**
**	message that is a matlab command
**
**	Arguments:
** 	command  ... code of the command (defined in **)
**		num_args ... number of arguments
**
**	Returns:
**		none
**
**	Keep in mind that Matlab commands can take arrays/matrices
**	as arguments. Num_args is simply the number of separate
**	variables listed in the function declaration. e.g.,
**	showTarget([0 1], 0, [], [-80 80]) has 4 arguments.
**
** default priority: low
**
**	NOTE: In Plexon, these will appear as codes with prefix
**		SE04 or SE05
*/
#define EC_MLC_CMD		(0x4000)
#define EC_MLC_FLD1	10			/* number of bits for "Command"	*/
#define EC_MLC_FLD2	3			/* number of bits for "# args"	*/
#define EC_MAKE_MLC(c,n) (EC_MLC_CMD | 									\
								 EC_FLD((c),EC_MLC_FLD1,EC_MLC_FLD2) |  	\
			 					 EC_FLD((n),EC_MLC_FLD2,0))

/* argument c: int command
*  argument n: num arguments
*/
#define EC_SEND_MATLAB_COMMAND(c,n)		EC_SEND_LO(EC_MAKE_MLC((c),(n)),1)
#define EC_SEND_MATLAB_COMMAND_HI(c,n) EC_SEND_HI(EC_MAKE_MLC((c),(n)))
#define EC_SEND_MATLAB_COMMAND_LO(c,n) EC_SEND_LO(EC_MAKE_MLC((c),(n)),1)

/* PUBLIC ROUTINE: ec_send_matlab_arg*
**
**	message that is an argument to a matlab command. By convention,
**	we'll send Arg #0 as the last argument, marking the end of
**	a given cmd call
**
**	Arguments:
** 	arg #  ... which argument
**		value  ... duuh
**
**	Returns:
**		none
**
** default priority: low
**
**	NOTE: In Plexon, these will appear as codes with prefix
**		SE06 or SE07
**
*/
#define EC_MLA_CMD		(0x6000)
#define EC_MLA_FLD1	3			/* number of bits for "arg #"		*/
#define EC_MLA_FLD2	10			/* number of bits for "Value"		*/
#define EC_MAKE_MLA(n,v) (EC_MLA_CMD | 									\
								 EC_FLD((n),EC_MLA_FLD1,EC_MLA_FLD2) |  	\
			 					 EC_FLD((v),EC_MLA_FLD2,0))

/* argument n: argument number
*  argument v: argument value
*/
#define EC_SEND_MATLAB_ARG(n,v)    EC_SEND_LO(EC_MAKE_MLA((n),(v)),1)
#define EC_SEND_MATLAB_ARG_HI(n,v) EC_SEND_HI(EC_MAKE_MLA((n),(v)))
#define EC_SEND_MATLAB_ARG_LO(n,v) EC_SEND_LO(EC_MAKE_MLA((n),(v)),1)

#endif /* _ECODE_TO_PLEXON_H_ */
