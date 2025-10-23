#include "top.h"
#include <ctype.h>
#include <math.h>

double twiddle(int n) {
  double sum = 0.0;
  for (int i = 0; i < n; i++)
    sum += sin((double)(i));
  return (sum);
}

// usage(i, opt_names, pos) -- report a command-line usage error
//   i is the index of argv that caused the error.
//   opt_names is an NULL-terminated array of strings for the option names.
//     opt_names[0] is the name of the program.
//     opt_names[i] is a descriptive name for argv[i]
//   pos: if true, the argument must be a postive integer.
//        otherwise, the argument must be a non-negative integer.
void usage(int i, const char **opt_names, int pos) {
  int n_opt;
  for (n_opt = 0; (n_opt < 20) && opt_names[n_opt]; n_opt++)
    ;
  fprintf(stderr, "usage:");
  for (int j = 0; j <= i; j++)
    if (j < n_opt)
      fprintf(stderr, " %s", opt_names[j]);
    else
      fprintf(stderr, " !unknown-option!");
  if (i + 1 < n_opt) {
    fprintf(stderr, " [");
    for (int j = i + 1; j < n_opt; j++)
      fprintf(stderr, "%s%s", j > i + 1 ? " " : "", opt_names[j]);
    fprintf(stderr, "]");
  }
  fprintf(stderr, "\n");
  fprintf(stderr, "  %s must be a %s integer\n", opt_names[i],
          pos ? "positive" : "non-negative");
  exit(-1);
}

// get_int(argc, argv, opt_names, i, v0, pos): return the i^th command line
// argument as an int.
//   opt_names is an array of strings giving the name of the program
//     and descriptive names of the arguments (for error messages).
//   v0 is the default value to return if argc < i.
int get_int(int argc, char **argv, const char **opt_names, int pos, int v0) {
  if (argc <= pos)
    return (v0);
  int neg = argv[pos][0] == '-';
  if (neg && !(argv[pos][1]))
    return (v0);
  // is argv[i] an integer ?
  for (int j = 0; argv[pos][j]; j++)
    if (!isdigit(argv[pos][j]))
      usage(argc, opt_names,
            pos); // argv[i] is not an integer, print an error message and exit
  return ((int)(atof(argv[pos])));
}

// mean(n, sum): return the mean of n samples where sum is the sum of the
// samples.
double mean(double *data, int n) {
  double sum = 0.0;
  for (int i = 0; i < n; i++)
    sum += data[i];
  return (sum / n);
}

// stdev(n, sum, sum_sq): return the standard-deviation of n samples
//   n: the number of samples
//   sum: the sum of the samples
//   sum_sq: the sum of the squares of the samples
// Remark: there are other formulations that are less susceptible to round-off
//   if stdev << mean, but we should't be pushing extreme cases in CPSC 418.
double stdev(double *data, int n) {
  double sum = 0.0, sum_sq = 0.0;
  for (int i = 0; i < n; i++) {
    sum += data[i];
    sum_sq += data[i] * data[i];
  }
  return (sqrt((sum_sq - sum * sum / n) / (n - 1)));
}
