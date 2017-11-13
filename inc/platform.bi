#ifndef __platform__
	#define __platform__
	
	/'
		platform specific definitions
	'/
	#ifdef __fb_64bit__
		/'
			64-bit definitions
		'/
		type int32 as long
		type int64 as integer
		type uint32 as ulong
		type uint64 as integer
		const as string fbVersion = "FreeBasic 64-bit"
	#else
		/'
			32-bit definitions
		'/
		type int32 as integer
		type int64 as longint
		type uint32 as uinteger
		type uint64 as ulongint
		const as string fbVersion = "FreeBasic 32-bit"
	#endif
#endif
