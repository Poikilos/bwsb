
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "gdmtype.h"
#include <dir.h>
#include <string.h>
#include <conio.h>
#include <alloc.h>

typedef unsigned char byte;
typedef unsigned int word;
typedef unsigned long dword;

extern word AmigaWord(word Ami);
extern dword AmigaLong(dword Ami);
extern void AmigaSam(byte far *Ptr,word Len);

void fcopy(FILE *dest,FILE *source,long len);
void fcopyamiga(FILE *dest,FILE *source,long len);
word freadword(FILE *fp);

//len is max length in ptr, INCLUDING nulls at end
//NO null is placed at end if no room
//LEN bytes ALWAYS read
void ftrimread(char far *ptr,int len,FILE *fp);
//len is max length in ptr, INCLUDING nulls at end
//reads in a string until a null OR len bytes. ALWAYS clipped with a null.
//(IE last byte is lost if len reached)
void fstrread(char far *ptr,int len,FILE *fp);
//len is max length in ptr, INCLUDING nulls at end
//Clips or fills to produce an ASCIIZ string of length len
void strfill(char far *ptr,int len);
//Clips any spaces off of end of string
void clipspace(char far *ptr);

FILE *fp=NULL;//File being processed (read)
FILE *destfp=NULL;//File being written to

void AbortProg(void) {
	if(fp) fclose(fp);
	if(destfp) fclose(destfp);
	printf("\n\nProgram Aborted!!\n\n");
	exit(2);
}

//Display a message of where in module conversion
void mesg(char far *str, ...) {
	va_list argptr;

	if(kbhit())
		if(getch()==27) AbortProg();

	va_start(argptr,str);

	gotoxy(38,wherey());
	clreol();
	vprintf(str,argptr);

	va_end(argptr);
}

void ConvertMED(void);
void ConvertSTM(void);
void ConvertULT(byte Type);
void ConvertS3M(void);
void ConvertMOD(byte NumChan,byte NumSam);//NumChan==0 for variable (10+)
void ConvertMTM(void);
void ConvertFAR(void);
void Convert669(void);
void ConvertXM(void);
void DetermineFile(void);

char GDMText[256];
GDMHeader GDMHead;
int FileType;//Type of file
byte OrderTable[256];
SamHeader2 SamHead[256];
byte PanTable[32];
struct ffblk find;//For file finding; ff_name is name of current file
char File[256];//Full pathname of file in conversion (for opening/etc.)
char File2[256];//Full pathname of target .GDM file
byte far patdata[32760];//Allocate at runtime, later. (dest info for GDM)
byte far Music[32760];//Same. (orig pattern info)

int PT[60]={
	1712, 1616, 1525, 1440, 1357, 1281, 1209, 1141, 1077, 1017, 961, 907,
	 856,  808,  762,  720,  678,  640,  604,  570,  538,  508, 480, 453,
	 428,  404,  381,  360,  339,  320,  302,  285,  269,  254, 240, 226,
	 214,  202,  190,  180,  170,  160,  151,  143,  135,  127, 120, 113,
	 107,  101,   95,   90,   85,   80,   76,   71,   67,   64,  60,  57 };

//File Types
#define tMTM	0
#define t669	1
#define tS3M	2
#define tSTM	3
#define tSTX	4
#define tFAR	5
#define tPSM	6
#define tMED0	7
#define t15MOD	8
#define t4MOD	9
#define t6MOD	10
#define t8MOD	11
//tXMOD- Module with variable channels; Identifier is "#CHN" or "##CH"
#define tXMOD	12
#define tIT		13
#define tULT1	14
#define tULT2	15
#define tULT3	16
#define tULT4	17
#define tGDM	18
#define tXM		19
#define tDMF	20
#define tDTM	21
#define tFNK	22
#define tPAC	23
#define tNONE  126

#define NUM_TYPES	24

//per file type- supported? (IE should we open a destination file?)
char FileTypeSupport[NUM_TYPES]={
	1,1,1,1,0,1,0,1,
	1,1,1,1,1,0,1,1,
	1,1,0,1,0,0,0,0 };

#define MAJOR		1
#define MINOR		21
#define VER_STR	"1.22"

#define NUM_EXTS	18
char *Exts[NUM_EXTS]={
	"MOD","NST","WOW","OCT","FAR","ULT","MMD","MED","MTM","669","STM","S3M",
	"8ME","DTM","FNK","PAC","XM","IT" };
#define NO_EXT		126

int main(int argc,char **argv) {

	int cmd_line=1;//Position on command line
	int curr_ext;//Current extension for testing (NO_EXT=don't use)
	char tempfile[256];//Current spec. being searched (w/wilds)
	int ext_st;//Position of extension in string
	int tmp,t2;//Temporary
	char conv;//Set to 1 once a conversion for a loop is done
	int numconv=0;//Number of modules converted total

	printf("\nModule -> GDM format converter\n");
	printf("Version "VER_STR"\n");
	printf("Original (1.21) in Basic by Edward Schlunder (C) 1994-95\n");
	printf("Converted to C and updated by Gregory Janson\n\n");

	if(argc<2) {
		printf("Usage: 2GDM filename[.ext] ...\n\n");
		printf("Wildcards and pathnames are accepted. Extensions are optional.\n");
		printf("2GDM will convert the following module types to GDM:\n\n");
		printf("MOD/NST, WOW, OCT, FAR, ULT, MMD, MED, MTM, 669, STM, S3M, 8ME,\n");
		printf("and XM. (XM is only partially supported.) Adlib instruments are\n");
		printf("not supported.\n");
		return 1;
		}

	GDMHead.ID[0]='G';
	GDMHead.ID[1]='D';
	GDMHead.ID[2]='M';
	GDMHead.ID[3]='þ';

	GDMHead.ID2[0]='G';
	GDMHead.ID2[1]='M';
	GDMHead.ID2[2]='F';
	GDMHead.ID2[3]='S';

	GDMHead.DOSEOF[0]=13;
	GDMHead.DOSEOF[1]=10;
	GDMHead.DOSEOF[2]=26;

	GDMHead.TrackID=0;
	GDMHead.TrackMajorVer=MAJOR;
	GDMHead.TrackMinorVer=MINOR;
	GDMHead.FormMajorVer=1;
	GDMHead.FormMinorVer=0;

	//Scan through command line. For each param-
	// If NO extension, test this with every extension
	// otherwise test as-is
	//  Per test- Search, allowing wildcards.
	//  Attempt to convert ALL files matching
	//  Ignore GDM format or non-formatted.
	//  15-instrument MODs, or other formats without ID codes,
	//  MUST have legit extension to be processed!

	do {
		conv=0;
		strcpy(tempfile,argv[cmd_line]);
		for(ext_st=strlen(tempfile);ext_st>0;ext_st--)
			if(tempfile[ext_st]=='.') break;
		if(!ext_st) {
			strcat(tempfile,".");
			ext_st=strlen(tempfile);
			curr_ext=0;
			}
		else curr_ext=NO_EXT;
		do {
			if(curr_ext!=NO_EXT) {
				tempfile[ext_st]=0;
				strcat(tempfile,Exts[curr_ext]);
				}
			//Do a file find-
			tmp=findfirst(tempfile,&find,0);
			while(!tmp) {
				//File found- create full pathname
				strcpy(File,argv[cmd_line]);
				//(clip after first \ or :, or at start of string)
				for(t2=strlen(File)-1;t2>=0;t2--)
					if((File[t2]=='\\')||(File[t2]==':')) break;
				//t2 = last char to keep
				File[t2+1]=0;//clip
				//(add on found file name)
				strcat(File,find.ff_name);
				//File found- determine file type and convert
				if((fp=fopen(File,"rb"))!=NULL) {
					//File opened correctly
					printf("Module %15.15s-  ",find.ff_name);
					DetermineFile();
					if((FileType!=tNONE)&&(FileTypeSupport[FileType])) {
						//Open target GDM file
						strcpy(File2,File);
						//clip extension
						for(t2=strlen(File2);t2>0;t2--)
							if(File2[t2]=='.') break;
						if(t2>=0) File2[t2]=0;
						//add GDM
						strcat(File2,".GDM");
						//open file
						destfp=fopen(File2,"wb");
						if(destfp==NULL) {
							printf("Error opening output GDM!");
							goto nodest;
							}
						//reset GDM header offsets
						GDMHead.MTOffset=0;
						GDMHead.SSOffset=0;
						GDMHead.TGOffset=0;
						}
					switch(FileType) {
						case tMTM:
							printf("MTM -> GDM");
							ConvertMTM();
							conv=1;
							break;
						case t669:
							printf("669 -> GDM");
							Convert669();
							conv=1;
							break;
						case tS3M:
							printf("S3M -> GDM");
							ConvertS3M();
							conv=1;
							break;
						case tSTM:
							printf("STM -> GDM");
							ConvertSTM();
							conv=1;
							break;
						case tSTX:
							printf("STX - Unsupported module format!");
							break;
						case tFAR:
							printf("FAR -> GDM");
							ConvertFAR();
							conv=1;
							break;
						case tPSM:
							printf("PSM - Unsupported module format!");
							break;
						case tMED0:
							printf("MED -> GDM");
							ConvertMED();
							conv=1;
							break;
						case t15MOD:
							printf("MOD -> GDM");
							ConvertMOD(4,15);
							conv=1;
							break;
						case t4MOD:
							printf("MOD -> GDM");
							ConvertMOD(4,31);
							conv=1;
							break;
						case t6MOD:
							printf("MOD -> GDM");
							ConvertMOD(6,31);
							conv=1;
							break;
						case t8MOD:
							printf("MOD -> GDM");
							ConvertMOD(8,31);
							conv=1;
							break;
						case tXMOD:
							printf("MOD -> GDM");
							ConvertMOD(0,31);
							conv=1;
							break;
						case tULT1:
							printf("ULT -> GDM");
							ConvertULT(1);
							conv=1;
							break;
						case tULT2:
							printf("ULT -> GDM");
							ConvertULT(2);
							conv=1;
							break;
						case tULT3:
							printf("ULT -> GDM");
							ConvertULT(3);
							conv=1;
							break;
						case tULT4:
							printf("ULT -> GDM");
							ConvertULT(4);
							conv=1;
							break;
						case tGDM:
							printf("GDM - Already converted!");
							break;
						case tIT:
							printf("IT  - Unsupported module format!");
							break;
						case tXM:
							printf("XM  -> GDM");
							ConvertXM();
							conv=1;
							break;
						case tDMF:
							printf("DMF - Unsupported module format!");
							break;
						case tDTM:
							printf("DTM - Unsupported module format!");
							break;
						case tFNK:
							printf("FNK - Unsupported module format!");
							break;
						case tPAC:
							printf("PAC - Unsupported module format!");
							break;
						case tNONE:
							printf("Unrecognized module format!");
							break;
						}
					if((FileType!=tNONE)&&(FileTypeSupport[FileType])) {
						fclose(destfp);
						destfp=NULL;
						mesg("Done!");
						printf("\n");
						numconv++;
						}
				nodest:
					fclose(fp);
					fp=NULL;
					}
				//Next file
				tmp=findnext(&find);
				};
			//Next extension, if appropriate
			if(conv) break;
		} while((++curr_ext)<NUM_EXTS);
		//Next command line parameter
	} while((++cmd_line)<argc);
	//Done!
	if(!numconv) printf("\nNo modules converted!\n\a");
	else if(numconv>1) printf("\n%d modules converted.\n",numconv);
	return 0;
}

void DetermineFile(void) {
	char id[18];
	word tmp;
	//XM
	fread(&id,17,1,fp);
	id[17]=0;
	if(!strcmp(id,"Extended Module: ")) {
		FileType=tXM;
		return;
		}
	//STM/S3M/STX
	fseek(fp,60,SEEK_SET);
	fread(&id,4,1,fp);
	id[4]=0;
	if(!strcmp(id,"SCRM")) {
		//STX??
		fseek(fp,20,SEEK_SET);
		fread(&id,8,1,fp);
		id[8]=0;
		if(!strcmp(id,"!Scream!")) {
			FileType=tSTX;
			return;
			}
		}
	fseek(fp,44,SEEK_SET);
	fread(&id,4,1,fp);
	id[4]=0;
	if(!strcmp(id,"SCRM")) {
		FileType=tS3M;
		return;
		}
	fseek(fp,20,SEEK_SET);
	fread(&id,8,1,fp);
	id[8]=0;
	if((!strcmp(id,"!Scream!"))||(!strcmp(id,"BMOD2STM"))) {
		FileType=tSTM;
		return;
		}
	//FAR
	fseek(fp,0,SEEK_SET);
	fread(&id,4,1,fp);
	id[4]=0;
	if(!strcmp(id,"FARþ")) {
		FileType=tFAR;
		return;
		}
	//PSM
	if(!strcmp(id,"PSMþ")) {
		FileType=tPSM;
		return;
		}
	//GDM
	if(!strcmp(id,"GDMþ")) {
		FileType=tGDM;
		return;
		}
	//DMF
	if(!strcmp(id,"DDMF")) {
		FileType=tDMF;
		return;
		}
	//DTM
	if(!strcmp(id,"SONG")) {
		FileType=tDTM;
		return;
		}
	//IT
	if(!strcmp(id,"IMPM")) {
		FileType=tIT;
		return;
		}
	//FNK
	if(!strcmp(id,"Funk")) {
		FileType=tFNK;
		return;
		}
	//PAC
	if(!strcmp(id,"PACG")) {
		FileType=tPAC;
		return;
		}
	//MTM
	id[3]=0;
	if(!strcmp(id,"MTM")) {
		FileType=tMTM;
		return;
		}
	//MMD
	if(!strcmp(id,"MMD")) {
		FileType=tMED0;
		return;
		}
	//ULT1/2/3/4
	if(!strcmp(id,"MAS")) {
		fseek(fp,14,SEEK_SET);
		tmp=fgetc(fp);
		if((tmp>='1')&&(tmp<='4')) {
			FileType=tULT1+(tmp-'1');
			return;
			}
		}
	//MOD/NST/WOW/OCT
	fseek(fp,1080,SEEK_SET);
	fread(&id,4,1,fp);
	id[4]=0;
	if(!strcmp(id,"M.K.")) {
		//WOW??
		tmp=strlen(find.ff_name);
		if(!stricmp(&find.ff_name[tmp-3],"WOW")) FileType=t8MOD;
		else FileType=t4MOD;
		return;
		}
	if((!strcmp(id,"M!K!"))||(!strcmp(id,"FLT4"))||
		(!strcmp(id,"4CHN"))) {
		FileType=t4MOD;
		return;
		}
	if((!strcmp(id,"8CHN"))||(!strcmp(id,"FLT8"))||
		(!strcmp(id,"OCTA"))) {
		FileType=t8MOD;
		return;
		}
	if((id[1]=='C')&&(id[2]=='H')&&(id[3]=='N')) {
		FileType=tXMOD;
		return;
		}
	if((id[2]=='C')&&(id[3]=='H')) {
		FileType=tXMOD;
		return;
		}
	//669
	fseek(fp,0,SEEK_SET);
	fread(&tmp,2,1,fp);
	if((tmp==0x6669)||(tmp==0x4E4A)) {
		FileType=t669;
		return;
		}
	//15 channel MOD
	tmp=strlen(find.ff_name);
	if(!stricmp(&find.ff_name[tmp-3],"MOD")) {
		FileType=t15MOD;
		return;
		}
	//Unknown
	FileType=tNONE;
}

void ConvertMED(void) {
}

void ConvertSTM(void) {
}

void ConvertULT(byte Type) {
}

void ConvertS3M(void) {
}

int MODSamC4Hertz[16]={
	8363, 8424, 8485, 8547, 8608, 8671, 8734, 8797, 7894,
	7951, 8009, 8067, 8125, 8184, 8244, 8303 };

void ConvertMOD(byte NumChan,byte NumSam) {//NumChan==0 for variable
	int tmp,tmp2,sam,NOP,patpos,pos,Note,LastFit;
	byte MaxChan,Patt,Row,Channel,FX1,FX1Data,
		Byte1,Byte2,Byte3,GDMNote,GDMIns,Chan,Ins,EvPos;
	byte Events[20];
	char id[5];
	//Determine number of channels
	mesg("Determining number of channels");
	if(!NumChan) {
		fseek(fp,1080,SEEK_SET);
		fread(id,4,1,fp);
		id[4]=0;
		if(id[3]=='N') NumChan=id[0]-'0';//1 through 9 channels
		else NumChan=(id[1]-'0')+((id[0]-'0')*10);//10 and up channels
		}
	NumChan--;
	NumSam--;
	GDMHead.FormOrigin=1;//MOD
	fseek(destfp,sizeof(GDMHeader),SEEK_SET);
	//Header conversion
	mesg("Header conversion");
	fseek(fp,0,SEEK_SET);
	ftrimread(GDMHead.SongTitle,20,fp);
	strfill(GDMHead.SongTitle,32);
	strcpy(GDMHead.SongMusician,"Unknown");
	strfill(GDMHead.SongMusician,32);
	GDMHead.Tempo=6;
	GDMHead.BPM=125;
	GDMHead.MastVol=64;
	for(tmp=0;tmp<=NumChan;tmp++) {
		if(((tmp&3)==1)||((tmp&3)==2)) PanTable[tmp]=15;
		else PanTable[tmp]=0;
		}
	GDMHead.NOS=NumSam;
	//Sample header conversion
	fseek(fp,20,SEEK_SET);
	GDMHead.SamHeadOffset=ftell(destfp);
	for(sam=0;sam<=NumSam;sam++) {
		//Convert sample header #sam
		mesg("Sample header conversion - %d",sam);
		tmp2=4;
		ftrimread(SamHead[sam].SamName,22,fp);
		strfill(SamHead[sam].SamName,32);
		SamHead[sam].Length=AmigaWord(freadword(fp))<<1;
		tmp=fgetc(fp);
		SamHead[sam].C4Hertz=MODSamC4Hertz[tmp&0xF];
		if((SamHead[sam].Volume=fgetc(fp))>64) SamHead[sam].Volume=64;
		SamHead[sam].LoopBegin=AmigaWord(freadword(fp))<<1;
		SamHead[sam].LoopEnd=SamHead[sam].LoopBegin+(AmigaWord(freadword(fp))<<1)+1;
		if((SamHead[sam].LoopEnd-SamHead[sam].LoopBegin)>8) tmp2|=1;
		if(SamHead[sam].LoopEnd>SamHead[sam].Length)
			SamHead[sam].LoopEnd=SamHead[sam].Length+1;
		SamHead[sam].Flags=tmp2;
		SamHead[sam].Pan=0xFF;
		}
	for(tmp=NumSam;tmp>=0;tmp--)
		if((SamHead[tmp].SamName[0])||(SamHead[tmp].Length)) break;
	GDMHead.NOS=tmp;
	for(sam=0;sam<=GDMHead.NOS;sam++)
		fwrite(&SamHead[sam],sizeof(SamHeader2),1,destfp);
	//Order conversion
	mesg("Order table conversion");
	GDMHead.NOO=fgetc(fp)-1;
	fgetc(fp);
	GDMHead.OrdOffset=ftell(destfp);
	fread(OrderTable,128,1,fp);
	NOP=0;
	for(tmp=0;tmp<128;tmp++)
		if(OrderTable[tmp]>NOP) NOP=OrderTable[tmp];
	GDMHead.NOP=NOP;
	fwrite(OrderTable,GDMHead.NOO+1,1,destfp);
	//Pattern conversion
	if(NumSam==14) fseek(fp,600,SEEK_SET);
	else fseek(fp,154+(NumSam+1)*30,SEEK_SET);
	GDMHead.PatOffset=ftell(destfp);
	MaxChan=0;
	for(Patt=0;Patt<=GDMHead.NOP;Patt++) {
		//Convert pattern #Patt
		mesg("Pattern conversion - %d",Patt);
		patpos=pos=0;
		fread(Music,(NumChan+1)<<8,1,fp);
		for(Row=0;Row<64;Row++) {
			for(Channel=0;Channel<=NumChan;Channel++) {
				GDMNote=GDMIns=0;
				Byte1=Music[pos++];
				Byte2=Music[pos++];
				Byte3=Music[pos++];
				FX1Data=Music[pos++];
				Note=((Byte1&15)<<8)+Byte2;
				Ins=(Byte3>>4)+(Byte1&0xF0);
				if((Note)||(Ins)) {
					GDMIns=Ins;
					if(Note) {
						LastFit=32767;
						for(tmp=0;tmp<60;tmp++) {
							if(abs(PT[tmp]-Note)<LastFit) {
								GDMNote=(((tmp/12)+2)<<4)+tmp%12+1;
								LastFit=abs(PT[tmp]-Note);
								}
							}
						}
					}
				FX1=Byte3&15;
				switch(FX1) {
					//Effects to leave as-is-
					//1 Portamento up
					//2 Portamento down
					//4 Vibrato
					//7 Tremolo
					//9 Sample offset
					//B Jump to order
					//D Pattern break
					case 0://Arpeggio or no-command
						if(FX1Data) FX1=0x10;
						break;
					case 3://Portamento to
						if(GDMNote) GDMNote=((GDMNote-1)|128)+1;
						break;
					case 5://Portamento to+Volume slide
						if(GDMNote) GDMNote=((GDMNote-1)|128)+1;
						if(FX1Data==0) FX1=3;
						break;
					case 6://Vibrato+Volume slide
						if(FX1Data==0) FX1=4;
						break;
					case 8://Pan
						if(FX1Data==0xA4) {
							FX1=0x1E;
							FX1Data=1;
							}
						else {
							if(FX1Data<0x80) {
								FX1Data>>=3;
								if(FX1Data>15) FX1Data=15;
								FX1=0x1E;
								FX1Data|=0x80;
								}
							else FX1=FX1Data=0;
							}
						break;
					case 0xA://Volume Slide
						if(FX1Data==0) FX1=0;
						break;
					case 0xC://Set Volume
						if(FX1Data>64) FX1Data=64;
						break;
					case 0xF://Set Tempo or BPM
						if(FX1Data>31) FX1=0x1F;
						else if(FX1Data==0) FX1=0;
						break;
					case 0xE://Extended effects
						switch(FX1Data&0xF) {
							//Effects to leave as-is-
							//0 Set filter
							//1 Fineslide Up
							//2 Fineslide Down
							//3 Glissando Control
							//4 Vibrato Waveform
							//5 Set C-4 finetune
							//6 Patttern Loop
							//7 Tremolo Waveform
							//A Fine Volume up
							//B Fine Volume down
							//C Note Cut
							//E Pattern Delay
							//F Invert Loop
							case 8://Pan Position
								FX1=0x1E;
								break;
							case 9://Retrigger
								FX1=0x12;
								FX1Data&=0xF;
								if(FX1Data==0) FX1=0;
								break;
							case 0xD://Note Delay
								if(GDMNote) GDMNote=((GDMNote-1)|128)+1;
								else FX1=FX1Data=0;
								break;
							}
						break;
					}
				if((GDMNote)||(GDMIns)||(FX1)) {
					Chan=Channel;
					if(Channel>=MaxChan) MaxChan=Channel+1;
					EvPos=1;
					if((GDMNote)||(GDMIns)) {
						Chan|=32;
						Events[EvPos++]=GDMNote;
						Events[EvPos++]=GDMIns;
						}
					if(FX1) {
						Chan|=64;
						Events[EvPos++]=FX1;
						Events[EvPos++]=FX1Data;
						}
					Events[0]=Chan;
					memcpy(&patdata[patpos],Events,EvPos);
					patpos+=EvPos;
					}
				}//Next channel
			patdata[patpos++]=0;
			}//Next row
		patpos+=2;
		fwrite(&patpos,2,1,destfp);
		fwrite(patdata,patpos-2,1,destfp);
		}//Next pattern
	for(tmp=MaxChan;tmp<32;tmp++)
		PanTable[tmp]=0xFF;
	memcpy(GDMHead.PanMap,PanTable,32);
	//Sample conversion
	GDMHead.SamOffset=ftell(destfp);
	for(tmp=0;tmp<=GDMHead.NOS;tmp++) {
		//Convert sample #tmp
		mesg("Sample conversion - %d",tmp);
		if(SamHead[tmp].Length)
			fcopyamiga(destfp,fp,SamHead[tmp].Length);
		}//Next sample
	fseek(destfp,0,SEEK_SET);
	fwrite(&GDMHead,sizeof(GDMHead),1,destfp);
	//Done!
}

void ConvertMTM(void) {
}

void ConvertFAR(void) {
}

void Convert669(void) {
	int tmp,tmp2,sam,NOS,NOP,patpos;
	long pos,SamLoc;
	int OldFX[8],OldData[8];
	byte MaxChan,Patt,Row,Channel,NoSpeed,FX1,FX2,FX1Data,FX2Data,Octave,
		Note,Byte1,Byte2,Byte3,Break,GDMNote,GDMIns,Chan,Tempo,EvPos;
	byte Events[20];
	GDMHead.FormOrigin=4;//669
	fseek(destfp,sizeof(GDMHeader),SEEK_SET);
	//Header conversion
	mesg("Header conversion");
	GDMHead.BPM=78;//669s have BPM of 78
	fseek(fp,2,SEEK_SET);
	ftrimread(GDMHead.SongTitle,32,fp);
	strcpy(GDMHead.SongMusician,"Unknown");
	strfill(GDMHead.SongMusician,32);
	GDMHead.MastVol=64;
	fseek(fp,0xF1,SEEK_SET);
	GDMHead.Tempo=fgetc(fp);
	fseek(fp,110,SEEK_SET);
	GDMHead.NOS=fgetc(fp)-1;
	GDMHead.NOP=fgetc(fp)-1;
	for(tmp=0;tmp<8;) {
		PanTable[tmp++]=0;
		PanTable[tmp++]=15;
		}
	//Message text- First fill with all nulls
	mesg("Message conversion");
	GDMText[0]=0;
	strfill(GDMText,256);
	//Now read in each line and concatenate
	fseek(fp,2,SEEK_SET);
	ftrimread(GDMText,36,fp);
	clipspace(GDMText);
	strcat(GDMText,"\xD\xA");
	ftrimread(&GDMText[strlen(GDMText)],36,fp);
	clipspace(GDMText);
	strcat(GDMText,"\xD\xA");
	ftrimread(&GDMText[strlen(GDMText)],36,fp);
	clipspace(GDMText);
	strcat(GDMText,"\x1A");
	GDMHead.MTLength=strlen(GDMText);
	GDMHead.MTOffset=ftell(destfp);
	fwrite(GDMText,GDMHead.MTLength,1,destfp);
	//Order conversion
	mesg("Order table conversion");
	fseek(fp,113,SEEK_SET);
	fread(OrderTable,128,1,fp);
	GDMHead.OrdOffset=ftell(destfp);
	for(tmp=0;tmp<128;tmp++) {
		tmp2=OrderTable[tmp];
		if(tmp2==0xFF) break;
		fputc(tmp2,destfp);
		}
	GDMHead.NOO=tmp-1;
	//Sample header conversion
	fseek(fp,0x1F1,SEEK_SET);
	GDMHead.SamHeadOffset=ftell(destfp);
	for(sam=0;sam<=GDMHead.NOS;sam++) {
		//Convert sample header #sam
		mesg("Sample header conversion - %d",sam);
		ftrimread(SamHead[sam].FileName,12,fp);
		memcpy(SamHead[sam].SamName,SamHead[sam].FileName,12);
		strfill(SamHead[sam].SamName,32);
		fgetc(fp);//Extra filename byte in 669 (null)
		fread(&SamHead[sam].Length,4,1,fp);
		fread(&SamHead[sam].LoopBegin,4,1,fp);
		fread(&SamHead[sam].LoopEnd,4,1,fp);
		SamHead[sam].Pan=0xFF;
		SamHead[sam].Volume=0xFF;
		SamHead[sam].C4Hertz=8363;
		if(SamHead[sam].LoopEnd!=0xFFFFFL) SamHead[sam].Flags=1;
		else {
			SamHead[sam].LoopEnd=0;
			SamHead[sam].Flags=0;
			}
		}
	NOS=GDMHead.NOS+1;//OLD NOS for later use
	for(tmp=GDMHead.NOS;tmp>=0;tmp--)
		if((SamHead[tmp].SamName[0])||(SamHead[tmp].Length)) break;
	GDMHead.NOS=tmp;
	for(sam=0;sam<=GDMHead.NOS;sam++)
		fwrite(&SamHead[sam],sizeof(SamHeader2),1,destfp);
	//Pattern conversion
	MaxChan=0;//Maximum channels used ever
	GDMHead.PatOffset=ftell(destfp);
	for(Patt=0;Patt<=GDMHead.NOP;Patt++) {
		//Convert pattern #Patt
		mesg("Pattern conversion - %d",Patt);
		patpos=0;
		pos=0x1F1+Patt*1536L+NOS*25L;
		fseek(fp,pos,SEEK_SET);
		fread(Music,1536,1,fp);
		fseek(fp,369+Patt,SEEK_SET);
		Break=fgetc(fp);
		fseek(fp,241+Patt,SEEK_SET);
		Tempo=fgetc(fp);
		pos=0;
		NoSpeed=1;
		for(Row=0;Row<=Break;Row++) {
			for(Channel=0;Channel<8;Channel++) {
				FX1=FX2=FX1Data=FX2Data=GDMNote=GDMIns=0;
				Byte1=Music[pos++];
				Byte2=Music[pos++];
				Byte3=Music[pos++];
				if((Row==0)&&(NoSpeed)) {
					FX2=0xF;
					FX2Data=Tempo;
					}
				if(Byte1<0xFE) {
					Octave=Byte1/48;
					Note=(Byte1>>2)%12;
					GDMNote=(((Octave+2)<<4)+Note)+1;
					GDMIns=(Byte2>>4)+((Byte1&3)<<4)+1;
					OldData[Channel]=0;
					}
				if(Byte1<=0xFE) {
					FX1=0xC;
					FX1Data=(((long)(Byte2&0xF))<<8)/60;//Multiply by 4.2666666~
					if(FX1Data>64) FX1Data=64;
					}
				if(Byte3<0xFF) {
					FX2=(Byte3>>4);
					FX2Data=(Byte3&0xF);
					switch(FX2) {
						case 0:
							OldFX[Channel]=FX2=1;//Portamento up
							OldData[Channel]=FX2Data;
							if(FX2Data==0) FX2=0;
							break;
						case 1:
							OldFX[Channel]=FX2=2;//Portamento down
							OldData[Channel]=FX2Data;
							if(FX2Data==0) FX2=0;
							break;
						case 2:
							OldFX[Channel]=FX2=3;//Portamento to
							OldData[Channel]=FX2Data;
							if(GDMNote) GDMNote=((GDMNote-1)|128)+1;
							if(FX2Data==0) FX2=0;
							break;
						case 3:
							FX2=0xE;//Frequency adjust
							FX2Data+=0x50;
							break;
						case 4:
							OldFX[Channel]=FX2;//Vibrato
							OldData[Channel]=FX2Data;
							if(FX2Data==0) FX2=0;
							break;
						case 5:
							FX2=0xF;//Set tempo
							break;
						case 6:
							FX2=0xE;//Fine Pan
							FX2Data=(0x61)+((FX2Data&1)<<4);
							break;
						case 7:
							FX2=0x12;//Retrig
							break;
						}
					}
				else {
					if((OldFX[Channel]>=1)&&(OldFX[Channel]<=4)) {
						if(OldData[Channel]) {
							FX2=OldFX[Channel];
							FX2Data=OldData[Channel];
							}
						}
					}
				if((Row==0)&&(FX2==0xF)) NoSpeed=0;
				if((GDMNote)||(GDMIns)||(FX1)||(FX2)) {
					Chan=Channel;
					if(Chan>=MaxChan) MaxChan=Chan+1;
					EvPos=1;
					if((GDMNote)||(GDMIns)) {
						Chan|=32;
						Events[EvPos++]=GDMNote;
						Events[EvPos++]=GDMIns;
						}
					if((FX1)&&(FX2)) {
						Chan|=64;
						Events[EvPos++]=FX1|32;
						Events[EvPos++]=FX1Data;
						Events[EvPos++]=FX2|64;
						Events[EvPos++]=FX2Data;
						}
					else if(FX1) {
						Chan|=64;
						Events[EvPos++]=FX1;
						Events[EvPos++]=FX1Data;
						}
					else if(FX2) {
						Chan|=64;
						Events[EvPos++]=FX2|64;
						Events[EvPos++]=FX2Data;
						}
					Events[0]=Chan;
					memcpy(&patdata[patpos],Events,EvPos);
					patpos+=EvPos;
					}
				}//Next channel
			patdata[patpos++]=0;
			}//Next row
		patpos+=2;
		fwrite(&patpos,2,1,destfp);
		fwrite(patdata,patpos-2,1,destfp);
		}//Next pattern
	for(tmp=MaxChan;tmp<32;tmp++)
		PanTable[tmp]=0xFF;
	memcpy(GDMHead.PanMap,PanTable,32);
	//Copy samples
	GDMHead.SamOffset=ftell(destfp);
	SamLoc=0;
	NOP=GDMHead.NOP+1;
	for(tmp=0;tmp<=GDMHead.NOS;tmp++) {
		//Copy sample #tmp
		mesg("Sample conversion - %d",tmp);
		if(SamHead[tmp].Length) {
			fseek(fp,0x1F1+NOS*25+NOP*1536+SamLoc,SEEK_SET);
			fcopy(destfp,fp,SamHead[tmp].Length);
			SamLoc+=SamHead[tmp].Length;
			}
		}//Next sample
	fseek(destfp,0,SEEK_SET);
	fwrite(&GDMHead,sizeof(GDMHead),1,destfp);
	//Done!
}

void ConvertXM(void) {
}

//len is max length in ptr, INCLUDING nulls at end
//NO null is placed at end if no room
//LEN bytes ALWAYS read
void ftrimread(char far *ptr,int len,FILE *fp) {
	int ln=0;
	for(;ln<len;)
		if(!(ptr[ln++]=fgetc(fp))) break;
	if(ln<len) {
		for(;ln<len;ln++) {
			ptr[ln]=0;
			fgetc(fp);
			}
		}
}

//len is max length in ptr, INCLUDING nulls at end
//reads in a string until a null OR len bytes. ALWAYS clipped with a null.
//(IE last byte is lost if len reached)
void fstrread(char far *ptr,int len,FILE *fp) {
	int ln=0;
	for(;ln<(len-1);ln++)
		if(!(ptr[ln]=fgetc(fp))) break;
	ptr[ln]=0;
}

//len is max length in ptr, INCLUDING nulls at end
//Clips or fills to produce an ASCIIZ string of length len
void strfill(char far *ptr,int len) {
	int ln=strlen(ptr);
	if(ln>=len) ptr[len-1]=0;
	else {
		for(;ln<len;ln++)
			ptr[ln]=0;
		}
}

void fcopy(FILE *dest,FILE *source,long len) {
	byte far *buff=NULL;
	word chunk=32000;
	buff=(byte far *)farmalloc(chunk);
	if(buff==NULL) {
		chunk=farcoreleft()-64;
		if(chunk>=128) buff=(byte far *)farmalloc(chunk);
		}
	if(buff==NULL) {
		//Copy byte by byte
		for(;len>0;len--)
			fputc(fgetc(source),dest);
		return;
		}
	//Copy buffer by buffer
	do {
		if(len<chunk) chunk=len;
		fread(buff,chunk,1,source);
		fwrite(buff,chunk,1,dest);
	} while((len-=chunk)>0);
}

//Clips any spaces off of end of string
void clipspace(char far *ptr) {
	int ln=strlen(ptr)-1;
	for(;ln>=0;ln--)
		if(ptr[ln]!=32) break;
	ptr[ln+1]=0;
}

word freadword(FILE *fp) {
	word t1=fgetc(fp);
	return t1+(fgetc(fp)<<8);
}

//Copys, converting an amiga sample to normal
void fcopyamiga(FILE *dest,FILE *source,long len) {
	byte far *buff=NULL;
	word chunk=32000;
	buff=(byte far *)farmalloc(chunk);
	if(buff==NULL) {
		chunk=farcoreleft()-64;
		if(chunk>=128) buff=(byte far *)farmalloc(chunk);
		}
	if(buff==NULL) {
		//Copy byte by byte
		for(;len>0;len--)
			fputc(fgetc(source)^128,dest);
		return;
		}
	//Copy buffer by buffer
	do {
		if(len<chunk) chunk=len;
		fread(buff,chunk,1,source);
		AmigaSam(buff,chunk);
		fwrite(buff,chunk,1,dest);
	} while((len-=chunk)>0);
}