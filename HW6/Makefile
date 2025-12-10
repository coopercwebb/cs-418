CC      = gcc
C++     = g++
CFLAGS  = -O3
NVCC    := /cs/local/lib/pkg/cudatoolkit/bin/nvcc
CUFLAGS := -O3

OBJS    = hw6.o hw6_lib.o hw6_mem.o

all:  mem

clean:
	rm -f $(OBJS) op cuprop henon

mem:   hw6.o hw6_lib.o hw6_mem.o
	$(NVCC) hw6.o hw6_lib.o hw6_mem.o -o mem


.SUFFIXES: .c .cu .o
%.o: %.c
	$(CC) -c --device-c $(CFLAGS) -o $@ $<
%.o: %.cpp
	$(C++) -c --device-c $(CFLAGS) -o $@ $<
%.o: %.cu
	${NVCC} -c --device-c ${CUFLAGS} -o $@ $<
