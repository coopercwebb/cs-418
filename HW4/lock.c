// lock: test our locks

#include "lock.h"

#include<stdio.h>
#include<string.h>
#include<pthread.h>
#include<sys/resource.h>
#include<sys/time.h>
#include<unistd.h>


#define DEFAULT_LOCK "cx"
#define DEFAULT_N 10000

#define TRUE 1
#define FALSE 0


typedef struct { /* thread parameters */
  int id;
  Lock *lock;
  int ntrials;
} my_args;

int go = 0;
int count[2] = {0,0};
int error_count = 0;

void *my_thread(void *void_arg) { 
  my_args *args = (my_args *)(void_arg);
  int me = args->id;
  Lock *lock = args->lock;
  int ntrials = args->ntrials;

  int thread_id = args->id;
  int r = 5 + thread_id;
  int zero = 0;

  while(!(__atomic_load_n(&go, __ATOMIC_SEQ_CST))); /* wait for both threads to be spawned */

  for(int i = 0; i < ntrials ; i++) { /* try a bunch of times */
    /* do a random amount of "work" before critical region */
    r = 23*r & 0x3f;
    twiddle(r);

    /* aquire the lock */
    lock->acquire(lock, thread_id);

    /* critical section */
    for(int j = 0; j < 10; j++) {
      count[thread_id] = j;
      if(count[!thread_id]) {
	error_count++;
	break;
      }
    }
    count[thread_id] = 0;

    /* release the lock */
    lock->release(lock, thread_id);
  }
  return(NULL);
}

void my_test(Lock * lock, int ntrials) {
  struct rusage r0, r1;
  pthread_t *threadId = (pthread_t *)(malloc(2*sizeof(pthread_t)));
  my_args *args = (my_args *)(malloc(2*sizeof(my_args)));

  for(int i = 0; i < 2; i++) { /* create per-thread data */
    args[i].id = i;
    args[i].lock = lock;
    args[i].ntrials = ntrials;
    if(pthread_create(&threadId[i], NULL, my_thread, args+i) != 0) {
      perror("my_test: ");
      exit(-1);
    }
  }

  getrusage(RUSAGE_SELF, &r0);
  go = 1; /* start the threads going */

  /* reap the threads */
  for(int i = 0; i < 2; i++) {
    if(pthread_join(threadId[i], NULL) != 0) {
      perror("my: ");
      exit(-2);
    }
  }
  getrusage(RUSAGE_SELF, &r1);
  if(error_count == 0)
    printf("no errors detected\n");
  else if(error_count == 1)
    printf("1 critical region violation detected\n");
  else
    printf("%d critical region violations detected\n", error_count);
  printf("utime = %8.3g, stime = %8.3g\n",
      (r1.ru_utime.tv_sec - r0.ru_utime.tv_sec) + 1.0e-6*(r1.ru_utime.tv_usec - r0.ru_utime.tv_usec),
      (r1.ru_stime.tv_sec - r0.ru_stime.tv_sec) + 1.0e-6*(r1.ru_stime.tv_usec - r0.ru_stime.tv_usec));
  free((void *)(args));
}


int main(int argc, const char **argv) {
  /* get parameters from the command line (or defaults) */
  const char *lock_type = (argc >= 2) ? argv[1] : DEFAULT_LOCK;
  int ntrials = (argc >= 3) ? atoi(argv[2]) : DEFAULT_N;
  struct Lock *lock;

  if(strcmp(lock_type, "cx") == 0)
    lock = cx_create();
  else if(strcmp(lock_type, "dekker") == 0)
    lock = dk_create();
  else {
    fprintf(stderr, "unknown lock type: %s\n", lock_type);
    exit(-2);
  }

  my_test(lock, ntrials);
  
  lock->destroy(lock);
  exit(0);
}
