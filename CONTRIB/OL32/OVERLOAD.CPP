/*
    OverLoader/32
    Copyright (c) 1993-97, Edward T. Schlunder

    This program is free software; you can redistribute it and/or modify
    it freely. Feel free to use it freely in your own programs, as
    long as the above copyright notice is unaltered.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */
#include <stdio.h>
#include <string.h>

#include "overload.h"

long OverLoad(char *Name, FILE *fpFile) {
    OLHeaderType OLHeader;
    OLEntryType OLEntry;
    int i;

    fseek(fpFile, -sizeof(OLHeaderType), SEEK_END);

    fread(&OLHeader, 1, sizeof(OLHeaderType), fpFile);
    if(strncmp(OLHeader.ID, "OverLoader", 11))
        return(0);

    fseek(fpFile, OLHeader.TopOffs, SEEK_SET);

    for(i = 0; i <= OLHeader.Entries; i++) {
        fread(&OLEntry, 1, sizeof(OLEntryType), fpFile);

        if(strncmp(OLEntry.Name, Name, 13) == 0)
            break;
        else if(i == OLHeader.Entries)
            return(0);
    }

    fseek(fpFile, OLEntry.Offset, SEEK_SET);
    return(OLEntry.Length);
}
