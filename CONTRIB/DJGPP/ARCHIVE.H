/*
 * archive.h - declarations and defines for archive module
 *
 * DESCRIPTION
 * archive stores multiple data files end-to-end after a header which
 * contains the filenames and offsets (from top of file) of the files
 * stored.
 *
 * USAGE
 *
 * NOTES
 *
 * REVISION HISTORY
 * Date         Reason
 * 14 Mar 95    Initial Coding
 * 3  May 95    Changed to new layout style
 * 29 Jun 95    Recompile with DJGPP 2.0, add to xlib
 *
 */

#ifndef _ARCHIVE_H_
#define _ARCHIVE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "defines.h"

/* general definitions */

#define ARC_SUCCESS              0
#define ARC_NOT_FOUND           -1
#define FILE_NOT_FOUND          -2
#define FILE_EXISTS             -3
#define ARC_EXISTS              -4
#define FILE_CANT_WRITE         -5
#define ARC_MALLOC_ERROR        -6
#define ARC_FULL                -7

/* values used in archive header block */

#define ARC_MAX_FILES          200    /* header will be ~ 20 * max_files */

#define ARC_HEADER_SIZE          9

extern BYTE arc_maj_version;
extern BYTE arc_min_version;
extern int ArcNumFiles;

/* function prototypes */
int arc_create(char * arcname);
int arc_query(char * arcname, char * filename);
int arc_add(char * arcname, char * filename, char * data, int length);
int arc_remove(char * arcname, char * filename);
int arc_extract(char * arcname, char * filename);
int arc_read(char * arcname, char * filename, char * data);

/* Generic binary file utility functions */
int file_sizeof(char * filename);
int read_binary(char * filename, BYTE ** buffer);
int write_binary(char * filename, int mode, BYTE * buffer, int length);
int read_binary_archive(char * filename, char * arcname, BYTE ** buffer);

#ifdef __cplusplus
}
#endif

#endif
