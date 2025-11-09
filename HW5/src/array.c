// array.c:  create arrays and a few simple operations on arrays

#include "top.h"

// ar_const(c,  n): an array n ints all with value c.
int *ar_const(int c, int n) {
  int *a;
  a = (int *)malloc(n * sizeof(int));
  for (int i = 0; i < n; i++)
    a[i] = c;
  return (a);
}

// ar_random(n): an array of n random ints
int *ar_random(int n) {
  int *a;
  a = (int *)malloc(n * sizeof(int));
  for (int i = 0; i < n; i++)
    a[i] = rand();
  return (a);
}

// ar_free(a): free an array.
//   Yeah, we just call free, but this means we could change the representation
//   of arrays later if we want to add more operations.
void ar_free(int *a) { free(a); }

// ar_op(int *op, int n)
//
int ar_op(int *op, int n) {
  int prev = 0, acc = 0, next = 0;
  for (int i = 0; i < n - 7; i++) {
    switch (op[i + (acc & 7)]) {
    case 0:
      next = prev + acc;
      break;
    case 1:
      next = prev - acc;
      break;
    case 2:
      next = prev & acc;
      break;
    case 3:
      next = prev | acc;
      break;
    case 4:
      next = prev ^ acc;
      break;
    case 5:
      next = acc + 0x1357;
      break;
    case 6:
      next = acc ^ 0x1357;
      break;
    case 7:
      next = acc << 11;
      break;
    }
    prev = acc;
    acc = next;
  }
  return (acc);
}

// ar_merge: Not used in HW3, but the optimizations done by clang on an ARM
//   are really cool.  I might mention them later, and I'm including the source
//   here in case I do.  ar_merge is merges two, sorted arrays into a single,
//   sorted array as in for merge sort.
void ar_merge(int *a0, int *a1, int *b, int n) {
  int i = 0, j = 0, k = 0;
  while ((i < n) && (j < n)) {
    if (a0[i] <= a1[j])
      b[k++] = a0[i++];
    else
      b[k++] = a1[j++];
  }
  while (i < n)
    b[k++] = a0[i++];
  while (j < n)
    b[k++] = a1[j++];
}
