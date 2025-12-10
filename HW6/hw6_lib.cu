#include "hw6_lib.h"

// usage(int i, char **argv, const char **opt_names, const char *opt, const char *type_name),
//     print an error message for bad command line arguments.
// Parameters
//   i:  the position of the command line argument that caused the error, i.e. argv[i].
//   opt_names:  an array of strings:
//     opt_names[0] is thename of the program
//     opt_names[1..argc-1] are descriptive names of the arguments (for error messages).
//   typename: the type we expected for the argument.
static void usage(int i, char **argv, const char **opt_names, const char *type_name)
{
    uint n_opt;
    for (n_opt = 0; (n_opt < 20) && opt_names[n_opt]; n_opt++)
        ;
    fprintf(stderr, "usage:");
    for (uint j = 0; j <= i; j++)
        if (j < n_opt)
            fprintf(stderr, " %s", opt_names[j]);
        else
            fprintf(stderr, " !unknown-option!");
    if (i + 1 < n_opt)
    {
        fprintf(stderr, " [");
        for (uint j = i + 1; j < n_opt; j++)
            fprintf(stderr, "%s%s", j > i + 1 ? " " : "", opt_names[j]);
        fprintf(stderr, "]");
    }
    fprintf(stderr, "\n");
    fprintf(stderr, "  %s must be %s, got %s.\n", opt_names[i], type_name, argv[i]);
    exit(-1);
}

// get_int(argc, argv, opt_names, i, v0): return the i^th command line argument as an int.
//   Parameters:
//     argc, argv:  the usual arguments to main().
//     opt_names: array of strings.
//         opt_names[i] when 1 <= i < argc should be a descriptive name
//         for what we expect for the i^th argument
//     i:  the index for the which command line argument we are processing.
//     v0: the default value to return if argc < i.
//
//   Return value:
//     If argv[i] == "-", then we return v0;
//     If argv[i] is of the form "2^" ++ <digits>, then we treat digits
//       as the decimal representation of an integer, k, and return 2^k.
//     Otherwise, we return argv[i] interpreted as a decimal integer.
//
int get_int(int argc, char **argv, const char **opt_names, int i, int v0)
{
    if (argc <= i)
        return (v0);
    const char *arg = argv[i];
    if (strcmp(arg, "-") == 0)
        return (v0);
    int j = 0;
    if (arg[j] == '-')
        j = 1;
    if (arg[j] == '2' && arg[j + 1] == '^')
        j += 2;
    // make argv[i] sure is an integer
    for (int m = j; arg[m]; m++)
    {
        if (!isdigit(arg[m]))
            usage(i, argv, opt_names, "an integer");
    }
    int k = atoi(arg + j);
    printf("j = %d, k = %d\n", j, k);
    if (j > 1)
        k = 1 << k;
    if (arg[0] == '-')
        k = -k;
    return (k);
}

// get_uint(argc, argv, opt_names, i, v0): return the i^th command line argument as an int.
//   like get_int(...) but returns an unsigned int.
//   Note, we allow argv[i] to be a signed integer -- we just cast it to unsigned.
//   If argv[i] is between 2^31 and 2^32-1, get_int(...) will return a negative integer,
//   but it will cast back to the intended value.
uint get_uint(int argc, char **argv, const char **opt_names, int i, uint v0)
{
    return ((uint)(get_int(argc, argv, opt_names, i, v0)));
}

// get_double(argc, argv, opt_names, i, v0): return the i^th command line argument as a double.
//   opt_names is an array of strings giving the name of the program
//     and descriptive names of the arguments (for error messages).
//   v0 is the default value to return if argc < i.
double get_double(int argc, char **argv, const char **opt_names, int i, double v0)
{
    if (argc <= i)
        return (v0);
    if (argv[i][0] == '-')
        return (v0);
    // might be nice if we checked to make sure argv[i] is a valid double.
    // more work than I want to do right now.
    return (atof(argv[i]));
}

// mean(n, sum): return the mean of n samples where sum is the sum of the samples.
double mean(uint n, double sum)
{
    return (sum / n);
}

// stdev(n, sum, sum_sq): return the standard-deviation of n samples
//   n: the number of samples
//   sum: the sum of the samples
//   sum_sq: the sum of the squares of the samples
// Remark: this is the simple, textbook formula.
//   there are other formulation that are less susceptible to round-off
//   if stdev << mean, but we should't be pushing extreme cases in CPSC 418.
double stdev(uint n, double sum, double sum_sq)
{
    return (sqrt((sum_sq - sum * sum / n) / (n - 1)));
}
