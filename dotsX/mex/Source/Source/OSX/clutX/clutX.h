#include <stdio.h>
//#include <string.h>
//#include <errno.h>
//#include <unistd.h>
//#include <sys/param.h>
//#include <termios.h>

#include "mex.h"

typedef struct {
	unsigned char r;
	unsigned char g;
	unsigned char b;
	unsigned char a;
} colorQuad;

#define BYTEMAX 255

static colorQuad clut[BYTEMAX+1] = {
	{BYTEMAX,	BYTEMAX,	BYTEMAX,	BYTEMAX	},
	{BYTEMAX,	0,			0,			BYTEMAX	},
	{0,			BYTEMAX,	0,			BYTEMAX	},
	{0,			0,			BYTEMAX,	BYTEMAX	},
	{BYTEMAX,	BYTEMAX,	0,			BYTEMAX	},
	{BYTEMAX,	0,			BYTEMAX,	BYTEMAX	},
	{0,			BYTEMAX,	BYTEMAX,	BYTEMAX	},
	{0,			0,			0,			BYTEMAX	},};