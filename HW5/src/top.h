#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <ctype.h>
#include <sys/time.h>
#include <sys/resource.h>

// from util.c
extern double twiddle(int);
void usage(int i, const char **opt_names, int pos);
int get_int(int argc, char **argv, const char **opt_names, int i, int v0);
double mean(double *data, int n);
double stdev(double *data, int n);

// from array.c
// functions that create arrays
int *ar_random(int n); // random elements
int *ar_const(int c, int n); // all elemenrts initialized to c
//
void ar_free(int * a); // free an array
void ar_merge(int *a0, int *a1, int *b, int n); // see array.c or hw3 Question 2.
int ar_op(int *a, int n); // see array.c or hw3 Question 2.
