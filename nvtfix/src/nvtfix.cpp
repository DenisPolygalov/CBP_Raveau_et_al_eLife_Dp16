/*
 *  Copyright (C) 2010 Denis Polygalov,
 *  Lab for Circuit and Behavioral Physiology,
 *  RIKEN Brain Science Institute, Saitama, Japan.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, a copy is available at
 *  http://www.fsf.org/
*/

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <cstring>
#include <deque>

#ifdef __GNUC__
#include <stdint.h>
#else
#error "Compiler not supported"
#endif

#include "nlx.h"

typedef struct {
   uint32_t rec_num;
   int32_t  x;
   int32_t  y;
   int32_t  angle;
} POS;

typedef struct {
   uint32_t start;
   int32_t  x_start;
   int32_t  y_start;
   uint32_t stop;
   int32_t  x_stop;
   int32_t  y_stop;
   int32_t  angle_start;
   int32_t  angle_stop;
} INTERV;

using namespace std;

int main (int argc, char *argv[]) {
   FILE *f_in = NULL;
   FILE *f_out = NULL;
   FILE *f_out_csv = NULL;
   // char *hdr_token = NULL;
   char  hdr_buf[NLX_HEADER_SIZE];
   NLX_NVT_RECORD nvt_record;
   POS pos_prev;
   INTERV zint;
   memset(&nvt_record, 0, sizeof(nvt_record));
   memset(&pos_prev, 0, sizeof(pos_prev));
   memset(&zint, 0, sizeof(zint));
   std::deque<INTERV> zint_fifo;
   FILE *f_dbg = NULL;
   uint32_t dsp_cnt = 0;
   uint32_t dsp_Ks_cnt = 0;
   //
   if (argc != 4 && argc != 3) {
      fprintf(stdout, "ncs2wav, %s %s\n", __DATE__, __TIME__);
      fprintf(stdout, "Scan Neuralynx *.nvt file for zero position entries\n");
      fprintf(stdout, "and replace them by average value calculated based on\n");
      fprintf(stdout, "position data taken from right and left side entries\n");
      fprintf(stdout, "Usage: nvtfix.exe VT1.nvt [VT1_fixed.nvt] VT1.csv\n");
      fprintf(stdout, "If output *.nvt file name did not provided\n");
      fprintf(stdout, "then only CSV file will be generated\n");
      exit(EXIT_SUCCESS);
   }
   f_in = fopen(argv[1], "rb");
   if (f_in == NULL) {
      fprintf(stdout, "Can't open file %s for reading\n", argv[1]);
      exit(EXIT_FAILURE);
   }
   if (argc == 4) {
      f_out = fopen(argv[2], "w+b");
   } else if (argc == 3) {
      f_out = fopen("VT1_TMP0945809.nvt", "w+b");
   }
   if (f_out == NULL) {
      fprintf(stdout, "Can't open file %s for writing\n", argv[2]);
      exit(EXIT_FAILURE);
   }

   if (argc == 4) {
      f_out_csv = fopen(argv[3], "w");
   } else if (argc == 3) {
      f_out_csv = fopen(argv[2], "w");
   }

   if (f_out_csv == NULL) {
      fprintf(stdout, "Can't open file %s for writing\n", argv[3]);
      exit(EXIT_FAILURE);
   }
   f_dbg = fopen("debug.txt", "r");
   if (f_dbg != NULL) {
      fclose(f_dbg);
      f_dbg = NULL;
      f_dbg = fopen("debug.txt", "w");
   }
   if (f_dbg) {
      fprintf(f_dbg, "nvtfix %s %s\n", __DATE__, __TIME__);
      fprintf(f_dbg, "Input file: %s\n", argv[1]);
      fprintf(f_dbg, "Output file: %s\n", argv[2]);
      fprintf(f_dbg, "Record size: %lu\n", (long unsigned int)sizeof(NLX_NVT_RECORD));
      fprintf(f_dbg, "Scan for zero-entry intervals...\n\n");
   }
   fprintf(stdout, "nvtfix, CBP RIKEN BSI %s %s\n", __DATE__, __TIME__);
   // copy header from f_in to f_out
   fseek(f_in, 0, SEEK_SET);
   fread(hdr_buf, NLX_HEADER_SIZE, 1, f_in);
   fseek(f_out, 0, SEEK_SET);
   fwrite(hdr_buf, sizeof(hdr_buf), 1, f_out);
   // first stage, search for zero intervals and save they parameters in the zint_fifo
   uint32_t rec_num = 0;
   uint32_t f_start_zeros = 0;
   while (fread(&nvt_record, 1, sizeof(NLX_NVT_RECORD), f_in) == sizeof(NLX_NVT_RECORD)) {
      if (++dsp_cnt == 1000) {
         dsp_cnt = 0;
         fprintf(stdout, "Detecting: %i\r", ++dsp_Ks_cnt);
      }
      if (f_start_zeros == 1) {
         if (nvt_record.dnextracted_x != 0 && nvt_record.dnextracted_y != 0) {
            f_start_zeros = 0;
            zint.stop = rec_num;
            zint.x_stop = nvt_record.dnextracted_x;
            zint.y_stop = nvt_record.dnextracted_y;
            zint.angle_stop = nvt_record.dnextracted_angle;
            zint_fifo.push_back(zint);
            if (f_dbg) {
               fprintf(f_dbg, "%i\n", zint.stop);
               fprintf(f_dbg, "-------- Zero-interval end --------\n\n");
            }
         }
      } else {
         if (nvt_record.dnextracted_x == 0 && nvt_record.dnextracted_y == 0) {
            f_start_zeros = 1;
            zint.start = pos_prev.rec_num;
            zint.x_start = pos_prev.x;
            zint.y_start = pos_prev.y;
            zint.angle_start = pos_prev.angle;
            if (f_dbg) {
               fprintf(f_dbg, "------- Zero-interval start -------\n");
               fprintf(f_dbg, "%i\n", zint.start);
            }
         }
      }
      pos_prev.rec_num = rec_num;
      pos_prev.x = nvt_record.dnextracted_x;
      pos_prev.y = nvt_record.dnextracted_y;
      pos_prev.angle = nvt_record.dnextracted_angle;
      rec_num++;
      //
      if (f_dbg) {
         // printf("%ld%ld\n", (long)(i / 1000000000), (long)(i % 1000000000));
         #ifdef _WIN32
         fprintf(f_dbg, "TimeStamp %I64u\n", nvt_record.qwTimeStamp);
         #else
         fprintf(f_dbg, "TimeStamp %llu\n", nvt_record.qwTimeStamp);
         #endif
         fprintf(f_dbg, "Xpos %i\n", nvt_record.dnextracted_x);
         fprintf(f_dbg, "Ypos %i\n", nvt_record.dnextracted_y);
         fprintf(f_dbg, "Angle %i\n\n", nvt_record.dnextracted_angle);
      }
   }
   fprintf(stdout, "\n");
   if (f_dbg) fprintf(f_dbg, "zero intervals found: %lu\n", (long unsigned int)zint_fifo.size());
   // second stage
   fseek(f_in, NLX_HEADER_SIZE, SEEK_SET); // input file, go back
   // make a full binary copy f_in -> f_out
   dsp_cnt = 0;
   dsp_Ks_cnt = 0;
   while (fread(&nvt_record, 1, sizeof(NLX_NVT_RECORD), f_in) == sizeof(NLX_NVT_RECORD)) {
      if (++dsp_cnt == 1000) {
         dsp_cnt = 0;
         fprintf(stdout, "Copying: %i\r", ++dsp_Ks_cnt);
      }
      fwrite(&nvt_record, sizeof(NLX_NVT_RECORD), 1, f_out);
   }
   fprintf(stdout, "\n");
   fseek(f_out, 0, SEEK_SET);
   fflush(f_out);
   //
   rec_num = 0;
   size_t offset = 0;
   size_t byte_readed = 0;
   dsp_cnt = 0;
   dsp_Ks_cnt = 0;
   for (unsigned int i = 0; i < zint_fifo.size(); i++) {
      if (++dsp_cnt == 1000) {
         dsp_cnt = 0;
         fprintf(stdout, "Correction: %i\r", ++dsp_Ks_cnt);
      }
      if (zint_fifo[i].start >= zint_fifo[i].stop) {
         fprintf(stderr, "Algorithm error. ");
         fprintf(stderr, "zint_fifo[i].start (%d) >= zint_fifo[i].stop (%d)\n",
                 zint_fifo[i].start, zint_fifo[i].stop);
         exit(EXIT_FAILURE);
      }
      rec_num = zint_fifo[i].start + 1;
      while (rec_num <= zint_fifo[i].stop) {
         offset = NLX_HEADER_SIZE + rec_num * sizeof(NLX_NVT_RECORD);
         fseek(f_out, offset, SEEK_SET);
         byte_readed = fread(&nvt_record, 1, sizeof(NLX_NVT_RECORD), f_out);
         if ((byte_readed != sizeof(NLX_NVT_RECORD)) && (byte_readed != 0)) {
            fprintf(stderr, "Algorithm error. Wrong record size.\n");
            exit(EXIT_FAILURE);
         }
         nvt_record.dnextracted_x = (zint_fifo[i].x_start + zint_fifo[i].x_stop)/2;
         nvt_record.dnextracted_y = (zint_fifo[i].y_start + zint_fifo[i].y_stop)/2;
         nvt_record.dnextracted_angle = (zint_fifo[i].angle_start + zint_fifo[i].angle_stop)/2;
         fseek(f_out, offset, SEEK_SET);
         fwrite(&nvt_record, sizeof(NLX_NVT_RECORD), 1, f_out);
         rec_num++;
      }
   }
   fprintf(stdout, "\n");
   // stage 3, dump x,y,angle into text csv file
   dsp_cnt = 0;
   dsp_Ks_cnt = 0;
   fprintf(f_out_csv, "TimeStamp,x,y,angle\n");
   fseek(f_out, NLX_HEADER_SIZE, SEEK_SET); // output file, go back
   while (fread(&nvt_record, 1, sizeof(NLX_NVT_RECORD), f_out) == sizeof(NLX_NVT_RECORD)) {
      if (++dsp_cnt == 1000) {
         dsp_cnt = 0;
         fprintf(stdout, "Dumping: %i\r", ++dsp_Ks_cnt);
      }
      #ifdef _WIN32
      fprintf(f_out_csv, "%I64u,%i,%i,%i\n",
              nvt_record.qwTimeStamp,
              nvt_record.dnextracted_x,
              nvt_record.dnextracted_y,
              nvt_record.dnextracted_angle);
      #else
      fprintf(f_out_csv, "%llu,%i,%i,%i\n",
              nvt_record.qwTimeStamp,
              nvt_record.dnextracted_x,
              nvt_record.dnextracted_y,
              nvt_record.dnextracted_angle);
      #endif
   }
   fprintf(stdout, "\n");
   fclose(f_in);
   fclose(f_out);
   fclose(f_out_csv);
   if (f_dbg) fclose(f_dbg);
   if (argc == 3) {
      remove("VT1_TMP0945809.nvt");
   }
   return EXIT_SUCCESS;
}

