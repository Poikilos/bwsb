#include <stdio.h>
#include <fstream.h>
#include <iostream.h>

int main(void) {
    FILE *fpOut;
    ifstream fpIn("oplay2.pal");
    char buffer[32767];
    int r, g, b, i;
    char palette[768];

    fpIn.getline(buffer, 32767);
    fpIn.getline(buffer, 32767);
    fpIn.getline(buffer, 32767);

    fpOut = fopen("oplay.pal", "wb");

    i = 0;
    do {
        fpIn >> r;
        fpIn >> g;
        fpIn >> b;
        palette[i++] = r >> 2;
        palette[i++] = g >> 2;
        palette[i++] = b >> 2;
    } while(i < 767);    

    fwrite(palette, 1, 768, fpOut);
    fclose(fpOut);
}

