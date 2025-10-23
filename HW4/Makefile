CC      = gcc
CFLAGS  = -O3

OBJS    = array.o cx.o dekker.o lock.o merge.o op.o util.o

all: lock op

clean:
	rm -f $(OBJS) lock op


lock: lock.o cx.o dekker.o util.o 
	$(CC) lock.o cx.o dekker.o util.o -lm -o lock

op:   op.o array.o util.o
	$(CC) op.o array.o util.o -lm -o op

.SUFFIXES: .c .cu .o
.c.o:
	$(CC) -c $(CFLAGS) $<
