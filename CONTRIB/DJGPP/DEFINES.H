/*
 * defines.h - general definitions, macros and types
 *
 * DESCRIPTION
 *
 * USAGE
 * #include "defines.h"
 *
 * NOTES
 *
 * REVISION HISTORY
 * Date         Reason
 * 27 Jun 95    Initial Release
 *
 */

#ifndef _DEFINES_H_
#define _DEFINES_H_

/* Types */
#define BYTE    unsigned char
#define WORD    unsigned short
#define LONG    unsigned long
#define BOOLEAN unsigned char

/* Constants */
#define TRUE    1
#define FALSE   0

/* Macros */
#define MIN(x,y)  ((x) < (y)) ? (x) : (y)
#define MAX(x,y)  ((x) > (y)) ? (x) : (y)

/* TRUE if a <= x <= b */
#define BETWEEN(x,a,b)  (((x) >= (a)) && ((x) <= (b))) 

/* TRUE if (x,y) is inside box defined by (x1,y1),(x2,y2)
** NOTE:  x2 > x1 and y2 > y1.
*/
#define IS_IN_BOX(x,y,x1,y1,x2,y2)  (((x) >= (x1)) && ((x) <= (x2)) && \
                                     ((y) >= (y1)) && ((y) <= (y2)))

/* splits a word into it's component bytes */
#define LOWBYTE(x)  ((x) & 0xff)
#define HIGHBYTE(x) (((x) >> 8) & 0xff)

#endif
