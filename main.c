static char const cvsid[] = "$Id: main.c,v 2.1 2005/06/14 22:16:50 jls Exp $";

/*
 * Copyright 2005 SRC Computers, Inc.  All Rights Reserved.
 *
 *	Manufactured in the United States of America.
 *
 * SRC Computers, Inc.
 * 4240 N Nevada Avenue
 * Colorado Springs, CO 80907
 * (v) (719) 262-0213
 * (f) (719) 262-0223
 *
 * No permission has been granted to distribute this software
 * without the express permission of SRC Computers, Inc.
 *
 * This program is distributed WITHOUT ANY WARRANTY OF ANY KIND.
 */

#include <libmap.h>
#include <stdlib.h>

#define MAXVECS 1024 
#define MAXVEC_LEN 8192 

void subr (int64_t A[], int64_t B[], int64_t Out[], int32_t Counts[], int nvec, int nspin, int64_t *time, int mapnum);

int main (int argc, char *argv[]) {
    FILE *res_map, *res_cpu;
    int i,n, maxlen,nvec;
    int64_t *A, *B, *Out;
    int32_t *Counts;
    int64_t tm,i64;
    int cnt,cnta,cntb,j;
    int total_nsampA, ijA;
    int total_nsampB, ijB;
    int total_nsamp;
    int nspin;
    int mapnum = 0;
    int64_t temp;

    if ((res_map = fopen ("res_map", "w")) == NULL) {
        fprintf (stderr, "failed to open file 'res_map'\n");
        exit (1);
        }

    if ((res_cpu = fopen ("res_cpu", "w")) == NULL) {
        fprintf (stderr, "failed to open file 'res_cpu'\n");
        exit (1);
        }

    nspin = 1;

    if (argc < 2) {
	fprintf (stderr, "need number of vectors (up to %d) as arg\n", MAXVECS);
	exit (1);
	}

    if (sscanf (argv[1], "%d", &nvec) < 1) {
	fprintf (stderr, "need number of vectors (up to %d) as arg\n", MAXVECS);
	exit (1);
	}

    if (nvec > MAXVECS) {
	fprintf (stderr, "need number of vectors (up to %d) as arg\n", MAXVECS);
	exit (1);
	}

    if (argc < 3) {
	fprintf (stderr, "need max vector length (up to %d) as arg\n", MAXVEC_LEN);
	exit (1);
	}

    if (sscanf (argv[2], "%d", &maxlen) < 1) {
	fprintf (stderr, "need number of elements (up to %d) as arg\n", MAXVEC_LEN);
	exit (1);
	}

    if (maxlen > MAXVEC_LEN) {
	fprintf (stderr, "need number of elements (up to %d) as arg\n", MAXVEC_LEN);
	exit (1);
	}

    if (argc > 3) {
       if (sscanf (argv[3], "%d", &nspin) < 1) {
      	fprintf (stderr, "need clocks to spin before Buffer A starts in MAP) as arg\n");
	   exit (1);
       }
    }

    Counts = (int32_t*) malloc (nvec * sizeof (int64_t));

 printf ("Number vectors                     %4i\n",nvec);
 printf ("Maximum vector length              %4i\n",maxlen);
 printf ("Number of clocks to delay Buffer A %4i\n",nspin);
    
    srandom (973);

    total_nsampA = 0;
    total_nsampB = 0;
    for (i=0; i<nvec; i++) {
        cnta = random () % maxlen;
        cntb = random () % maxlen;
        cntb = cntb/4;
        if (cnta==0) cnta = 1;
        if (cntb==0) cntb = 1;
        Counts[2*i]   = cnta;
        Counts[2*i+1] = cntb;
        
  printf ("Line %2i Buffer A Samples %4i Buffer B Samples %4i\n",i,Counts[2*i],Counts[2*i+1]);
        total_nsampA = total_nsampA + Counts[2*i];
        total_nsampB = total_nsampB + Counts[2*i+1];

         fprintf (res_cpu, "vec %i cnta %i cntb %i\n", i,cnta,cntb);
         fprintf (res_map, "vec %i cnta %i cntb %i\n", i,cnta,cntb);
	}

    A      = (int64_t*) malloc (total_nsampA * sizeof (int64_t));
    B      = (int64_t*) malloc (total_nsampB * sizeof (int64_t));


    total_nsamp = total_nsampA + total_nsampB;
 printf ("total sampA %i\n",total_nsampA);
 printf ("total sampB %i\n",total_nsampB);
 printf ("total samp %i\n",total_nsamp);
    Out    = (int64_t*) malloc (total_nsamp * sizeof (int64_t));

    ijA = 0;
    ijB = 0;
    for (i=0;i<nvec;i++) {
      cnt = Counts[2*i];
      n = i+1;

      for (j=0;j<cnt;j++) {
         i64 = j+1;
         A[ijA] = i64;
         ijA++;
         fprintf (res_cpu, "%10lld\n", i64 + n*10000);
      }

      cnt = Counts[2*i+1];
      n = i+1000+1;

      for (j=0;j<cnt;j++) {
         i64 = j+1;
         B[ijB] = i64;
         ijB++;
         fprintf (res_cpu, "%10lld\n", i64 + n*1000000);
      }
    }

    map_allocate (1);

    // call the MAP routine
    subr (A, B, Out,  Counts, nvec, nspin, &tm, mapnum);

    printf ("compute on MAP: %10lld clocks\n", tm);

    for (i=0; i<total_nsamp; i++) {
        fprintf (res_map, "%10lld\n", Out[i]);
	}

    map_free (1);

    exit(0);
    }
