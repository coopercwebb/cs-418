/* cx.c -- a lock based on atomic compare-and-exchange operations */

#include "lock.h"

static void cx_destroy(Lock *);
static void cx_acquire(Lock *, int);
static void cx_release(Lock *, int);
static void cx_info(Lock *);

Lock *cx_create() {
  Lock *lock = (Lock *)malloc(sizeof(Lock));
  lock->destroy = cx_destroy;
  lock->acquire = cx_acquire;
  lock->release = cx_release;
  lock->data = (void *)malloc(sizeof(int));
  *((int *)(lock->data)) = 0; // lock is initially free
  return (lock);
}

static void cx_destroy(Lock *lock) {
  int *data = (int *)(lock->data);
  assert(!*data);     // make sure that no thread currently holds the lock
  lock->data = NULL;  // cause any attempt to use a freed lock to crash.
  free((void *)lock); // actually free it
}

static void cx_acquire(Lock *lock, int thread_id) {
  int zero;
  int id1 = thread_id + 1;
  int *data = (int *)(lock->data);
  do {
    zero = 0;
    while (__atomic_load_n(data, __ATOMIC_SEQ_CST))
      ;
  } while (!__atomic_compare_exchange_n(data, &zero, id1, false,
                                        __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST));
}

static void cx_release(Lock *lock, int thread_id) {
  int zero = 0;
  int id1 = thread_id + 1;
  int *data = (int *)(lock->data);
  assert(*data == id1); // make sure we own the lock
  __atomic_store_n(data, zero, __ATOMIC_SEQ_CST);
}
