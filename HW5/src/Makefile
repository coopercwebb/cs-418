CC      = gcc
CFLAGS  = -O3
NVCC      := /cs/local/lib/pkg/cudatoolkit/bin/nvcc
CUFLAGS   := -O3

OBJS    = array.o op.o util.o cuprop.o henon.o hw5_lib.o

all:  op cuprop henon

clean:
	rm -f $(OBJS) op cuprop henon

op:   op.o array.o util.o
	$(CC) op.o array.o util.o -lm -o op

cuprop: cuprop.cu
	${NVCC} ${CUFLAGS} cuprop.cu -o cuprop

henon: henon.o hw5_lib.o
	${NVCC} ${CUFLAGS} henon.o hw5_lib.o -o henon

.SUFFIXES: .c .cu .o
%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<
%.o: %.cu
	${NVCC} -c ${CUFLAGS} -o $@ $<
