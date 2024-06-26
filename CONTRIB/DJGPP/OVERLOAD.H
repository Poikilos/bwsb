/*
    OverLoader/32
    Copyright (c) 1993-97, Edward T. Schlunder

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>

typedef struct {
    char Name[13];
    long Offset;
    long Length;
} OLEntryType;

typedef struct {
    char ID[11];
    unsigned char Entries;
    long TopOffs;
} OLHeaderType;

long OverLoad(char *Name, FILE *fpFile);
