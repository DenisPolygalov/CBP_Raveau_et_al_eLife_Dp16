#!/usr/bin/env python

"""
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
"""

"""
Script for batch conversion of all *.nvt files located in the 
current directory into *_fixed.nvt files by using external Windows
binary nvtfix.exe. OS dependent. If the output file exist then no 
conversion will done.
"""

import os, sys

inputdir = "."

filelist = os.listdir(inputdir)
for item in filelist:
    if (item[-4:] == ".nvt"):
        if (item[-10:] == "_fixed.nvt"): continue
        out_filename = item[:-4] + "_fixed.nvt"
        if (os.path.isfile(out_filename)):
            sys.stdout.write(out_filename)
            sys.stdout.write(" Output file exist. Skip.\n")
        else:
            sCmd = "nvtfix.exe " + item + " " + out_filename + " " + item[:-4] + ".csv"
            sys.stdout.write(sCmd + "\n")
            os.system(sCmd)
#
sys.stdout.write("\n\n")
os.system("pause")
