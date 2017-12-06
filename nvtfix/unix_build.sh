#!/bin/sh

g++ -Wall -c ./src/nvtfix.cpp -o ./obj/nvtfix.o
g++ -o ./bin/nvtfix  ./obj/nvtfix.o -static -s
