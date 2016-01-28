/* $Id: ex05.mc,v 2.1 2005/06/14 22:16:47 jls Exp $ */

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


void subr (int64_t A[], int64_t B[], int64_t Out[], int32_t Counts[], int nvec, int nspin, int64_t *time, int mapnum) {

    OBM_BANK_A (AL,      int64_t, MAX_OBM_SIZE)
    OBM_BANK_B (BL,      int64_t, MAX_OBM_SIZE)
    OBM_BANK_C (CountsL, int64_t, MAX_OBM_SIZE)

    int64_t t0, t1, t2;
    int i,n,total_nsamp,istart,cnt;
    int total_nsampA;
    int total_nsampB;
    
    Stream_64 SB,SA,SC,SOut;
    Stream_32 SAC,SBC;
    Vec_Stream_64 VSA,VSB,VSM;
    Vec_Stream_64 VSA_op,VSB_op;

    read_timer (&t0);

#pragma src parallel sections
{
#pragma src section
{
    streamed_dma_cpu_64 (&SC, PORT_TO_STREAM, Counts, nvec*sizeof(int64_t));
}
#pragma src section
{
    int i,cnta,cntb;
    int64_t i64;

    for (i=0;i<nvec;i++)  {
       get_stream_64 (&SC, &i64);
       CountsL[i] = i64;
       split_64to32 (i64, &cntb, &cnta);
       cg_accum_add_32 (cnta, 1, 0, i==0, &total_nsampA);
       cg_accum_add_32 (cntb, 1, 0, i==0, &total_nsampB);
    }
 
 printf ("nsampA %i\n",total_nsampA);
 printf ("nsampB %i\n",total_nsampB);
 total_nsamp = total_nsampA + total_nsampB;
 printf ("total %i\n",total_nsamp);
}
}

#pragma src parallel sections
{
#pragma src section
{
    streamed_dma_cpu_64 (&SA, PORT_TO_STREAM, A, total_nsampA*sizeof(int64_t));
}
#pragma src section
{
    int i;
    int64_t i64;

    for (i=0;i<total_nsampA;i++)  {
       get_stream_64 (&SA, &i64);
       AL[i] = i64;
    }
}
}

#pragma src parallel sections
{
#pragma src section
{
    streamed_dma_cpu_64 (&SB, PORT_TO_STREAM, B, total_nsampB*sizeof(int64_t));
}
#pragma src section
{
    int i;
    int64_t i64;

    for (i=0;i<total_nsampB;i++)  {
       get_stream_64 (&SB, &i64);
       BL[i] = i64;
    }
}
}

#pragma src parallel sections
{
#pragma src section
{
    int n,i,cnta,cntb;
    int64_t i64;

    for (n=0;n<nvec;n++)  {
      i64 = CountsL[n];
      split_64to32 (i64, &cntb, &cnta);

      put_stream_32 (&SAC, cnta, 1);
      put_stream_32 (&SBC, cntb, 1);
   }
}
    
#pragma src section
{
    int n,nn,i,cnt,istart;
    int64_t i64;

    istart = 0;
    for (n=0;n<nvec;n++)  {
      get_stream_32 (&SAC, &cnt);

   if (n==0) spin_wait(nspin);

      nn = n+1;
      comb_32to64 (nn, cnt, &i64);
      put_vec_stream_64_header (&VSA, i64);

      for (i=0; i<cnt; i++) {
        put_vec_stream_64 (&VSA, AL[i+istart], 1);
      }
      istart = istart + cnt;

      put_vec_stream_64_tail   (&VSA, 1234);
    }
    vec_stream_64_term (&VSA);
}
#pragma src section
{
    int n,nn,i,cnt,istart;
    int64_t i64;

    istart = 0;
    for (n=0;n<nvec;n++)  {
      get_stream_32 (&SBC, &cnt);

   if (n==0) spin_wait(1);

      nn = n+1;
      comb_32to64 (nn, cnt, &i64);
      put_vec_stream_64_header (&VSB, i64);

      for (i=0; i<cnt; i++) {
        put_vec_stream_64 (&VSB, BL[i+istart], 1);
      }
      istart = istart + cnt;

      put_vec_stream_64_tail   (&VSB, 1234);
    }
    vec_stream_64_term (&VSB);
}

// *****************************
// perform operation unique to A stream
// add line number * 10000 
// *****************************
#pragma src section
{
    int i,n,cnt;
    int64_t v0,v1,i64;

    while (is_vec_stream_64_active(&VSA)) {
      get_vec_stream_64_header (&VSA, &i64);
      split_64to32 (i64, &n, &cnt);

      put_vec_stream_64_header (&VSA_op, i64);

      for (i=0;i<cnt;i++)  {
        get_vec_stream_64 (&VSA, &v0);

        v1 = v0 + n*10000;
        put_vec_stream_64 (&VSA_op, v1, 1);
      }

      get_vec_stream_64_tail   (&VSA, &i64);
      put_vec_stream_64_tail   (&VSA_op, 0);
    }
    vec_stream_64_term (&VSA_op);
}

// *****************************
// perform operation unique to B stream
// add line number * 1000000 
// *****************************
#pragma src section
{
    int i,n,cnt;
    int64_t v0,v1,i64;

    while (is_vec_stream_64_active(&VSB)) {
      get_vec_stream_64_header (&VSB, &i64);
      split_64to32 (i64, &n, &cnt);

// bumped n to see after merge
      n = n+1000;
      comb_32to64 (n, cnt,&i64);

      put_vec_stream_64_header (&VSB_op, i64);

      for (i=0;i<cnt;i++)  {
        get_vec_stream_64 (&VSB, &v0);

        v1 = v0 + n*1000000;
        put_vec_stream_64 (&VSB_op, v1, 1);
      }

      get_vec_stream_64_tail   (&VSB, &i64);
      put_vec_stream_64_tail   (&VSB_op, 0);
    }
    vec_stream_64_term (&VSB_op);
}

// *****************************
// merge A and B streams
// *****************************
#pragma src section
{
    vec_stream_merge_nd_2_64_term (&VSA_op, &VSB_op, &VSM);
    //vec_stream_merge_2_64_term (&VSA_op, &VSB_op, &VSM);
}

#pragma src section
{
    int i,n,cnt;
    int64_t i64,j64,v0;

    istart = 0;
    while (is_vec_stream_64_active(&VSM)) {
      get_vec_stream_64_header (&VSM, &i64);
      split_64to32 (i64, &n, &cnt);
 
 if (n>1000) printf ("                                    ");
 printf ("get after merge VSM n %i  cnt %i\n",n,cnt);

      for (i=0;i<cnt;i++)  {
      vdisplay_32 (n, 1001,i==0);
        get_vec_stream_64 (&VSM, &v0);
        put_stream_64 (&SOut, v0, 1);
      }

      get_vec_stream_64_tail   (&VSM, &i64);

    }
}
#pragma src section
{
    streamed_dma_cpu_64 (&SOut, STREAM_TO_PORT, Out, total_nsamp*sizeof(int64_t));
}
}
    read_timer (&t1);
    *time = t1 - t0;
    }
