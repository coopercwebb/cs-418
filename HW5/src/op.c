#include "top.h"

/* op.c: a relatively simple example to demonstrate the impact of branch prediction.
 *     The basic idea is that we create an array of n_op "operations".  An operation
 *     is one of 8 predefined ways to update an accumulator.  The evaluator for an array
 *     of operations is ar_op in array.c.  It's a switch statement with a case for each
 *     operations.  If the operations are randomly chosen, the branch prediction fails
 *     7/8 of the time.  OTOH, if all operations are the same, then branch prediction
 *     will work very well.  The difference in the execution time with random operations
 *     and a single, fixed operation can be used to estimate the cost (execution time)
 *     of a mispredicted branch.  The point of this is to see how superscalar processors
 *     use branch prediction to achieve better performance.
 *
 *   Here's the instruction manual:
 *     0.  Make sure you have all the files from the hw3 source directory.
 *           In particular you need: op.c array.c util.c top.h Makefile.
 *     1.  Now that you have the files, build the executable:
 *           make op
 *     2.  To execute this give the command:
 *             ./op n_op n_trial runs_per_trial dist
 *           where:
 *             n_op: size of the array of operations to perform.
 *               Default, n_op=1000.
 *             n_trials: do the merge n_trials times to get a meaningful
 *               timing measurements.  Default, n_trials=100.
 *             runs_per_trial: call ar_op(a, n_op) runs_per_trial times for
 *               each timing trial.  Default, runs_per_trial=10000.
 *             dist: how create the values for the elements of the array
 *               of ops:
 *                 constNNN: where NNN is a sequence of digits.
 *                   Every element is the integer NN mod 8.
 *                   If NNN is omited, 0 is used.
 *                   "const" can be any sequence of letters starting with 'c'.
 *                   For example c5 will set every element of the ops array to 5.
 *                 random: each element is randomly chosen form 0..7.
 *           For any of these parameters, if the command line argument is "-",
 *           then the default is used.  If ./op is run with fewer than 4 arguments,
 *           then the remaining parameters get their default values.
 *     3.  ./op make ntrials measurements of the time to evaluation the sequence
 *            of n_op operations, runs_per_ops time.  For example, with
 *            n_op=1000, ntrials=100, and runs_per_trial=10000 (the default
 *            values), each trial will measure the time for performing
 *              ar_op(ops, n_op)
 *            and divide that time by 10000 to get the time for each call
 *            to ar_op.  Note that each call performs n_op operations, and
 *            thus has n_op branches that depend on the value of op. 
 *              ./op does this ntrials times and reports the mean and
 *            standard deviation of the time estimate for ar_op based on
 *            these trials.
 *  Why have n_op n_trial and runs_per_trial?
 *    n_op and runs_per_trial are to make sure that the time is long enough
 *      that we aren't just seeing clock quantization effects.  My observation
 *      is that with n_op = 1000, we get times on the order of 1 microsecond
 *      per call to ar_op.  Timing measurements of a microsecond seem to have
 *      large amounts of clock quantization "noise".  By measure the time for
 *      10000 calls to ar_op, the two calls to getrusage (to get timing numbers)
 *      are separated by about 10ms, which makes the timing numbers much more
 *      repeatable and plausible.
 *    I still like doing many runs to see the mean and standard deviation.
 *      The mean should be much larger than the standard deviation for the mean
 *      to be plausible.  That seems to be the case.  Choosing ntrials=100 gets
 *      a total execution time of around a second, which allows us all to be
 *      good citizens when using shared machines such as thetis.students.cs.ubc.ca.
 *      Please be a good student.
 *    Finally, I'll do 5 or 7 runs and then take the median. On thetis, I
 *      see outliers in that group of 5 or 7, but the median seems pretty stable
 *      if I try multiple batches of 5 or 7 runs.  On my laptop, the timing
 *      numbers that I see are much more stable.
 */

void do_time(int n_op, int n_trials, int runs_per_trial, const char *dist,
        double *avg_std) {
    int *op, c;
    struct rusage r0, r1;
    double *t;
    const char *s = dist+1;
    t = (double *)malloc(n_trials*sizeof(double));

    // Note: we actually build arrays of n_op+7 elements.  This is because
    // the code in ar_op has a hack to make the index into op depend on the
    // current accumulator value.  It also means ar_op(op, n) performs n-7
    // operations.  We create an array of n_op7 = n_op+7 elements so that
    // ar_op(op, n_op7) will perform n_op operations.
    int n_op7 = n_op+7;
    for(int i = 0; i < n_trials; i++) {
	switch(*dist) {
	    case 'c':
		while(*s && isalpha(*s)) s++;
		for(c = 0; *s && isdigit(*s); c = 10*c + (*s++ - '0'));
		if(i==0) printf("c = %d\n", c);
		op = ar_const(c & 7, n_op7);
		break;
	    case 'r':
		op = ar_random(n_op7);
		for(int j = 0; j < n_op7; j++) op[j] = op[j] & 7;
		break;
	    default:
		fprintf(stderr, "unknown distribution for array data: %s, *dist=%c\n", dist, *dist);
		exit(-1);
	}
	getrusage(RUSAGE_SELF, &r0);
        for(int j = 0; j < runs_per_trial; j++)
	    ar_op(op, n_op7);
	getrusage(RUSAGE_SELF, &r1);
	t[i] =   (   (r1.ru_utime.tv_sec - r0.ru_utime.tv_sec)
	           + 1.0e-6*(r1.ru_utime.tv_usec - r0.ru_utime.tv_usec))
	       / (double)(runs_per_trial);
    }
    if(n_trials > 0)
	avg_std[0] = mean(t, n_trials);
    else avg_std[0] = 0.0;
    if(n_trials > 1)
	avg_std[1] = stdev(t, n_trials);
    else avg_std[1] = 0.0;
}

// main(argc, argv): top level program
//   usage: main n_op n_trials runs_per_trial dist
int main(int argc, char **argv) {
    const char *opt_names[] = {
      "merge", "n_op", "n_trials", "runs_per_trial", "dist" };
    int n_op = get_int(argc, argv, opt_names, 1, 1000);
    int n_trials = get_int(argc, argv, opt_names, 2, 100);
    int runs_per_trial = get_int(argc, argv, opt_names, 3, 1000);
    const char *dist = argc == 5 ? argv[4] : "random"; 
    double avg_std[2];

    do_time(n_op, n_trials, runs_per_trial, dist, avg_std);
    printf("mean(times) = %10.4e, stdev(times) = %10.4e\n", avg_std[0], avg_std[1]);
    exit(0);
}
