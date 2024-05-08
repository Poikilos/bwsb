/*
    OverLoader/32 Version 1.02
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
#include <string.h>

#include "overload.h"

int main(int argc, char *argv[]) {
    OLEntryType OLEntry[256];
    OLHeaderType OLHeader;
    FILE *fpWad, *fpData;
    int i;
    char Buffer[16000];

    if(argc < 3) {
        printf("OverLoader/32 v1.02 by Edward Schlunder\n");
        printf("\nUsage: OL wadfile datafile");
        return(1);
    }

    fpWad = fopen(argv[1], "rb");
    fpData = fopen(argv[2], "rb");

    fseek(fpWad, -sizeof(OLHeaderType), SEEK_END);
    fread(&OLHeader, 1, sizeof(OLHeaderType), fpWad);
    if(strncmp(OLHeader.ID, "OverLoader", 11) == 0) {
        fseek(fpWad, OLHeader.TopOffs, SEEK_SET);
        for(i = 0; i <= OLHeader.Entries; i++) {
            fread(&OLEntry[i], 1, sizeof(OLEntryType), fpWad);
        }
        OLHeader.Entries++;
        fseek(fpWad, OLHeader.TopOffs, SEEK_SET);
    }
    else {
        strcpy(OLHeader.ID, "OverLoader");
        OLHeader.Entries = 0;
        fseek(fpWad, 0, SEEK_END);
    }

    strcpy(OLEntry[OLHeader.Entries].Name, argv[2]);
    fseek(fpData, 0, SEEK_END);
    OLEntry[OLHeader.Entries].Length = ftell(fpData);
    fseek(fpData, 0, SEEK_SET);
    OLEntry[OLHeader.Entries].Offset = ftell(fpWad);

    fclose(fpWad);
    fpWad = fopen(argv[1], "ab");
    fseek(fpWad, OLEntry[OLHeader.Entries].Offset, SEEK_SET);

    for(i = OLEntry[OLHeader.Entries].Length;;) {
        if(i > 16000) {
            i -= 16000;
            fread(Buffer, 1, 16000, fpData);
            fwrite(Buffer, 1, 16000, fpWad);
        }
        else {
            fread(Buffer, 1, i, fpData);
            fwrite(Buffer, 1, i, fpWad);
            break;
        }
    }

    OLHeader.TopOffs = ftell(fpWad);
    for(i = 0; i <= OLHeader.Entries; i++) {
        fwrite(&OLEntry[i], 1, sizeof(OLEntryType), fpWad);
    }
    fwrite(&OLHeader, 1, sizeof(OLHeaderType), fpWad);

    fclose(fpWad);
    fclose(fpData);
    return(0);
}
