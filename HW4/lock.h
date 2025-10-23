// lock.h: define a struct for generic locks.
//   I should probably do this with some kind of C++ stuff, but
//   I'm a lousy C++ programmer; so, I'll kludge it in C.
//   C++ implementations are welcome.

#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>

#ifndef LOCK_H
#define LOCK_H

/* struct Lock: really an abstract class.  This would probably be prettier
 * in C++, but my C++ skilz are somewhere between non-existent and ugly.
 *  So, I wrote it in C.  The three function pointers are the operations on
 * locks.  We don't have a field for the create() function because by the
 * time you have a Lock object, you've already created it (e.g. using
 * cx_create() or dk_create()).
 */
typedef struct Lock {
  void (*destroy)(struct Lock *);
  void (*acquire)(struct Lock *, int);
  void (*release)(struct Lock *, int);
  void *data; // lock specific data
} Lock;

extern Lock *cx_create();   // from cx.c
extern Lock *dk_create();   // from dekker.c
extern double twiddle(int); // from util.c

#endif
