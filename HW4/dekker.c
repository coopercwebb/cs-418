#include "lock.h"

typedef struct dk_data {
  int flag[2], turn;
} dk_data;

static void dk_destroy(Lock *);
static void dk_acquire(Lock *, int);
static void dk_release(Lock *, int);
static void dk_info(Lock *);

Lock *dk_create() {
  Lock *lock = (Lock *)malloc(sizeof(Lock));
  dk_data *data = (dk_data *)malloc(sizeof(dk_data));
  lock->destroy = dk_destroy;
  lock->acquire = dk_acquire;
  lock->release = dk_release;
  data->flag[0] = data->flag[1] = false;
  data->turn = 0;
  lock->data = (void *)data;
  return (lock);
}

static void dk_destroy(Lock *lock) {
  dk_data *data = (dk_data *)(lock->data);
  assert(!(data->flag[0] || data->flag[1])); // neither thread holds the lock
                                             // nor is trying to acquire it.
  free((void *)data);
  lock->data = NULL;  // cause any attempts to use a freed lock to crash
  free((void *)lock); // actually free lock
}

static void dk_acquire(Lock *lock, int thread_id) {
  // assert(lock->create == dk_create); // make sure this is a dk lock
  volatile dk_data *data = (dk_data *)(lock->data);
  assert((thread_id == 0) || (thread_id == 1));
  assert(!data->flag[thread_id]);
  data->flag[thread_id] =
      true; /* indicate intention to enter critical region */
  while (data->flag[!thread_id]) {
    if (data->turn != thread_id) {
      data->flag[thread_id] = false;  /* give the other thread a chance */
      while (data->turn != thread_id) /* spin waiting for turn */
        ;
      data->flag[thread_id] = true; /* try again */
    }
  }
}

static void dk_release(Lock *lock, int thread_id) {
  dk_data *data = (dk_data *)(lock->data);
  assert(data->flag[thread_id]);
  data->turn = !thread_id;
  data->flag[thread_id] = false;
}
