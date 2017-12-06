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

#ifndef _NLX_H
#define _NLX_H

#define NLX_HEADER_SIZE       0x4000
#define NLX_CSC_SAMPLES_SIZE  512
#define NLX_NVT_POINTS_SIZE   400
#define NLX_NVT_TARGETS_SIZE  50
#define NLX_NTT_FEATURE_SIZE  8
#define NLX_SPIKE_DATAPOINTS  32
#define NLX_NTT_NUM_CH        4
#define NLX_NEV_EXTRA_SIZE    8
#define NLX_NEV_STR_LEN       128

#ifdef __GNUC__
#include <stdint.h>
#else
#error "Compiler not supported"
#endif

#pragma pack(push, 1)

typedef struct {
   uint64_t qwTimeStamp;
   uint32_t dwChannelNumber;
   uint32_t dwSampleFreq;
   uint32_t dwNumValidSamples;
   int16_t  snSamples[NLX_CSC_SAMPLES_SIZE];
} NLX_CSC_RECORD;

typedef struct {
   int16_t nstx;
   int16_t npkt_id;
   int16_t npkt_data_size;
   uint64_t qwTimeStamp;
   int16_t nevent_id;
   int16_t nttl;
   int16_t ncrc;
   int16_t ndummy1;
   int16_t ndummy2;
   int32_t dnExtra[NLX_NEV_EXTRA_SIZE];
   int8_t  EventString[NLX_NEV_STR_LEN];
} NLX_NEV_RECORD;

typedef struct {
   uint64_t qwTimeStamp;
   uint32_t dwScNumber;
   uint32_t dwCellNumber;
   uint32_t dnParams[NLX_NTT_FEATURE_SIZE];
   int16_t  snData[NLX_SPIKE_DATAPOINTS * NLX_NTT_NUM_CH]; // bug in documentation
} NLX_NTT_RECORD;

typedef struct {
   uint16_t swstx;
   uint16_t swid;
   uint16_t swdata_size;
   uint64_t qwTimeStamp;
   uint32_t dwPoints[NLX_NVT_POINTS_SIZE];
   int16_t sncrc; // weird
   int32_t dnextracted_x;
   int32_t dnextracted_y;
   int32_t dnextracted_angle;
   int32_t dntargets[NLX_NVT_TARGETS_SIZE];
} NLX_NVT_RECORD;

#pragma pack(pop)

#endif // _NLX_H
