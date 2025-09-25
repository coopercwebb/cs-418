
-module(playground).
-compile(export_all).

% [2*N || N <- [1,2,3,4]].
% output: [2,4,6,8]

% creates a list of random numbers from 1-100 of size N
rand_list(N) ->
    List = [rand:uniform(100) ||  _ <- lists:seq(1, N)],
    io:format("~w~n", List).

rm_decompose(N) when is_integer(N), N >= 1 ->
    rm_decompose_x(N, 0).
rm_decompose_x(N, Acc) when N rem 2 =:= 0 -> 
    rm_decompose_x(N div 2, Acc + 1);
rm_decompose_x(N, Acc) -> 
    {N, Acc}.




% ipow(X, N) -> X^N
%   We could use Russian Peasant as in mpow.  However, we're not taking the
%   result modulo-M; so, ipow will produce *very* big numbers if |X| > 1 and
%   N is large.  mpow would be slow as well -- Erlang has uses the brute-force
%   O(log(|X|)*log(|Y|) algorithm for multiplying large integers.
%     That means we won't call ipow with large N.  Thus, I'm providing the
%   simple algorithm, even though it's asymptotically sub-optimal.
ipow(X, N) when is_integer(X), is_integer(N), 0 < N ->
  X*ipow(X, N-1);
ipow(X, 0) when is_integer(X) -> 1.