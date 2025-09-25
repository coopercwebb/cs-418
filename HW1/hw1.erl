-module(hw1).

-export([mpow_0/3, mpow/3]).  % functions for Q2
-export([rabin_miller/1, rabin_miller/2, rm_decompose/1, rm_check/4, rm_check/3]).  % functions for Q3
-export([find_primes/3]).  % function for Q4.
-export([par_primes/4]). % function for Q5.

% A few more functions provided for your convenience
-export([all_adjacent/2, ipow/2, p/1, sieve/3]). % useful for the Rabin-Miller questions

% you_need_to_write_this(FunAtom, Args)
%  I've included the you_need_to_write_this function at the end of this
%  file.  It is a place-holder for code that you need to write.  Often,
%  it is a function body that you need to write.  You should have no calls
%  to you_need_to_write_this in the version of your code that you submit.
%    If I have used you_need_to_write_this(...) as a function body that you
%  need to write, I will usually include it just once.  My solution may use
%  multiple patterns to implement the function.  You should use patterns to
%  write clear, well-organized code.  Just because there is only one call to
%  you_need_to_write_this(...) for a function, doesn't mean that you should
%  write that function with a single pattern.
-export([you_need_to_write_this/2]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Functions for Q2:                                                       %
%    mpow_0(X, N, M): brute-force implementation of modular exponentiation %
%    mpow(X, N, M): efficient implementation of modular exponentiation     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% mpow_0(X, N, M) -> X^N mod M
%   This is an initial version for Q2
%   01/15/2025: changed to a tail-recursive version to
%     avoid the default process limits for student accounts.
mpow_0(1, N, M) when is_integer(N), 0 =< N, is_integer(M), 0 < M -> 1;
mpow_0(X, 0, M) when is_integer(X), 0 < M -> 1;
mpow_0(0, N, M) when is_integer(N), 0 < N, is_integer(M), 0 < M -> 0;
mpow_0(X, N, M) when is_integer(X), is_integer(N), 0 < N, is_integer(M), 0 < M ->
  mpow_0(X, N, M, 1).

% Having done thorough guard checking in mpow_0/3, we don't
% need guards here.  :)
mpow_0(_X, 0, _M, Prod) -> Prod;
mpow_0(X, N, M, Prod) -> mpow_0(X, N-1, M, misc:mod(Prod*X, M)).

% mpow(X, N, M) -> X^N mod M
%   Use the Russian Peasant algorithm
%   Note: my solution uses a helper function mpow_x so I can write the guard
%     for valid arguments once (for mpow), and not have to repeat it for the
%     two patterns for the main computation (in mpow_x).  You don't have to
%     do that, but I found it convenient.
%   My version is not tail-recursive, but if you're making enough recursive
%     calls for this to be an issue, you're not implementing Russian Peasant
%     correctly.
mpow(X, N, M) when is_integer(X), is_integer(N), 0 =< N, is_integer(M), 0 < M ->
  mpow_x(X, N, M).

mpow_x(_X, N, _M) when N =:= 0 ->
    1;
mpow_x(X, N, M) when N rem 2 =:= 0 ->
    mpow_x((X*X) rem M, N div 2, M);
mpow_x(X, N, M) when N rem 2 =:= 1 ->
    (X * mpow_x((X*X) rem M, (N-1) div 2, M)) rem M.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Functions for Q3:                                                       %
%    rabin_miller(Q, K): Rabin-Miller primality test.  The implementation  %
%      is provided but it calls other functions you need to implement.     %
%    rabin_miller(Q): Rabin-Miller primality test.  Runs 50 rounds of the  %
%      test.                                                               %
%    rm_decompose(N) -> {D, S}                                             %
%      N = D*ipow(2, S)                                                    %
%    rm_check(Q, D, S, K) ->                                               %
%      K rounds of Rabin-Miller, where Q = D*ipow(2,S).                    %
%      rm_check generates a new random value for A for each round.         %
%    rm_check(Q, B, S) ->                                                  %
%      One round of Rabin-Miller, where Q = B*ipow(2,S).                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rabin_miller(Q, K):
% Return value:
%   true if Q is probably prime;
%   false if Q is definitely composite.
% Arguments:
%   Q: the number to test
%   K: the number of "rounds" to try.
% Notes: if Q is prime, every round of Rabin-Miller will pass.
%   If Q is composite, then most rounds fail.  Rabin-Miller proved
%   that a round will fail with probability of at least 0.75.  In
%   practice, the accuracy is much better.  This means that after
%   K rounds, the probability of incorrectly identifying a composite
%   number as a prime is at most 4^(-K).  For example, with K=50,
%   the probability of incorrectly identifying a composite number as
%   prime is less than 7.9*10^(-31).
rabin_miller(Q, _) when is_integer(Q), Q =< 1 -> false;  % two is the smallest prime
rabin_miller(2, _) -> true;  % two is prime
rabin_miller(Q, _) when is_integer(Q), (Q rem 2) == 0 -> false; % all other even number are composite
rabin_miller(3, _) -> true;  % three is prime
rabin_miller(Q, K) when is_integer(Q), Q > 3, is_integer(K), K > 0 ->
  {D, S} = rm_decompose(Q-1),  % Q-1 = D*(2^S).  D is odd
  rm_check(Q, D, S, K).

rabin_miller(Q) -> rabin_miller(Q, 50).

% rm_decompose(N) -> {D, S}
%   N must be a positive integer.
%   D is a positive, odd integer, and S is a natural number such that
%       N = D*ipow(2, S).
rm_decompose(N) -> rm_decompose_x(N, 0).
rm_decompose_x(N, Acc) when N rem 2 =:= 0 -> 
    rm_decompose_x(N div 2, Acc + 1);
rm_decompose_x(N, Acc) -> 
    {N, Acc}.

% rm_check(Q, D, S, K) -> boolean
%   Perform K rounds of the Rabin-Miller test to check the primality of Q.
%   Return true iff all K rounds pass.
%   Q-1 must equal D*ipow(2, S) as described for rm_decompose.
rm_check(Q, D, S, K) ->
  K_List = [rm_check(Q,D,S) || _ <- lists:seq(1,K)],
  lists:all(fun(X) -> X end, K_List).

% rm_check(Q, D, S) -> boolean
%   Perform 1 round of the Rabin-Miller test to check the primality of Q.
%   Return true iff the round passes.
%   Q-1 must equal B*ipow(2, S).
rm_check(Q, D, S) ->
  A = (rand:uniform(Q - 3) + 1), % Pick a random integer, A with 1 < A < Q-1.
  B_0 = mpow(A, D, Q), % Raise A to the Dth power, mod Q. Let B0 = mpow(A, D, Q).
  rm_check_x(B_0, S, Q).
rm_check_x(B_0, _S, _Q) when B_0 =:= 1 -> % If B0 == 1, then continue with the next of the K iterations.
  true;
rm_check_x(B_0, S, Q) -> 
  square_check(B_0, mpow(B_0, 2, Q), Q, 1, S).

square_check(BI_m1, BI, Q, _Acc, _S) when BI =:= 1, BI_m1 =/= 1, BI_m1 =/= Q-1 ->
  false;
square_check(_BI_m1, BI, _Q, Acc, S) when Acc =:= S, BI =/= 1 ->
  false;
square_check(_BI_m1, _BI, _Q, Acc, S) when Acc =:= S ->
  true;
square_check(_BI_m1, BI, Q, Acc, S) ->
  square_check(BI, mpow(BI, 2, Q), Q, Acc+1, S).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Function for Q4:                                                        %
%    find_primes(Lo, Hi, N) -> a list of primes in the interval [Lo, Hi]   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find_primes(Lo, Hi, N) -> a list of N primes in the interval [Lo, Hi].
%   Return all primes in the interval [Lo, Hi] if there are at most N
%   primes in the interval.  All elements of the list returned should be
%   prime, and there should be no duplicates.
find_primes(Lo, Hi, N) when N >= 0 -> 
  find_primes_x(Lo, Hi, [], 0, N).
find_primes_x(Cur, Hi, Result, _, _) when Cur > Hi ->
  Result;
find_primes_x(_Cur, _Hi, Result, Acc, N) when Acc =:= N ->
  Result;
find_primes_x(Cur, Hi, Result, Acc, N) ->
  case rabin_miller(Cur) of
    true -> find_primes_x(Cur+1, Hi, [Cur|Result], Acc+1, N);
    false -> find_primes_x(Cur+1, Hi, Result, Acc, N)
  end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Function for Q5:                                                           %
%    par_primes(Lo, Hi, N, NW) -> a list of primes in the interval [Lo, Hi]   %
%      parallel search for primes using NW worker processes.                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

par_primes(Lo, Hi, N, NW) ->
  Chunk_Size = (Hi - Lo) div NW,
  Dist_N = N div NW,
  Process_Params = determine_process_params([], Lo, Hi, Chunk_Size, N, Dist_N, NW, 1),
  distribute(self(), Process_Params),
  retrieve_results(0, NW, []).

% Creates a list with NW elements
% Each element contains a tuple {Lo, Hi, N} for an individual process to find primes
determine_process_params(Process_Params, Lo, Hi, _Chunk_Size, N, _Dist_N, NW, Acc) when Acc == NW -> 
  [{Lo, Hi, N} | Process_Params];
determine_process_params(Process_Params, Lo, Hi, Chunk_Size, N, Dist_N, NW, Acc) -> 
  determine_process_params(
    [{Lo, Lo + Chunk_Size, Dist_N}|Process_Params],
    Lo + Chunk_Size + 1, Hi, Chunk_Size, N - Dist_N, Dist_N, NW, Acc+1
  ).

% Spawn len(Process_Params) workers each with their associated param tuple
distribute(_Pid, []) -> ok;
distribute(Pid, [Process_Param|T]) ->
  spawn(fun() -> find_primes_process(Pid, Process_Param) end),
  distribute(Pid, T).

find_primes_process(PPid, {Lo, Hi, N}) ->
  Primes = find_primes(Lo, Hi, N),
  PPid ! Primes.

retrieve_results(Acc, NW, Result) when Acc =:= NW ->
  lists:flatten(Result);
retrieve_results(Acc, NW, Result) ->
  receive 
    X -> retrieve_results(Acc+1, NW, [X|Result])
  end.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Some functions I found to be helpful:                                      %
%    all_adjacent(Pred, List) -> boolean                                      %
%      true iff Pred is satisfied for all pairs of adjacent elements of List. %
%                                                                             %
%    ipow(X, N) -> X^N.                                                       %
%      X is an integer.  N is a non-negative integer.                         %
%      This means that X^N is an integer, and we can compute it without       %
%      floating point round-off or overflow issues.                           %
%                                                                             %
%    p(N) -> list of integers =< N.                                           %
%      Sieve of Erosthenes.  Simple.  Handy for testing the rabin_miller/2,   %
%        find_primes/3, and par_find_primes/4.  Not suitable for use when N   %
%        is large.                                                            %
%                                                                             %
%    you_need_to_write_this(Fun, Args)                                        %
%      A placeholder for code that you need to write.                         %
%      If you_need_to_write_this(...) is called, an error message will be     %
%      printed, and you need finish your solution to the assignment.          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% all_adjacent(Pred, List):
%   Return true iff Pred holds for all pairs of adjacent elements of List.
%   Examples:
%     all_adjacent(fun(A, B) -> A =< B end, [1, 4, 9, 16, 25]) -> true;
%     all_adjacent(fun(A, B) -> A =< B end, [1, 4, 16, 9, 25]) -> false;
%     all_adjacent(_, []) -> true;
%     all_adjacent(_, [_]) -> true;
%     all_adjacent(Pred, [X1, X2, ... XN_1, XN] ->
%       Pred(X1, X2) andalso Pred(X2, X2) andalso ...
%                    andalso pred(XN_1, XN).
all_adjacent(Pred, [A, B | Tl]) ->
  Pred(A, B) andalso all_adjacent(Pred, [B | Tl]);
all_adjacent(_, X) -> is_list(X).

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

% p(N) -> list of all primes =< N
p(N) when is_integer(N) and (N < 2) -> [];
p(N) when is_integer(N) -> sieve([2], lists:seq(3, N, 2), N).

% sieve(KnownPrimes, MaybePrime, Max)
%    helper for p/1.
%    invariants of do_primes(Known, Maybe):
%      All elements of Known are prime.
%      No element of MaybePrime is divisible by any element of Known
%      lists:reverse(Known) ++ Maybe is an ascending list.
%      Known ++ MaybePrime contains all primes =< N, where N is from p(N).
%      lists:max(MaybePrime) =< Max.
sieve(KnownPrimes, [P | Etc], Max) when P*P =< Max ->
  sieve([P | KnownPrimes],
	lists:filter(fun(E) -> (E rem P) /= 0 end, Etc),
        Max);
sieve(KnownPrimes, MaybePrime, _) -> lists:reverse(KnownPrimes, MaybePrime).


you_need_to_write_this(Fun, Args) ->
    io:format("Missing implementation for ~w~s.~n", [Fun, args_string(Args)]).

args_string([]) -> "()";
args_string([Arg1 | Args]) ->
  [ "(", io_lib:format("~p", [Arg1]),
    [ io_lib:format(", ~p", [Arg]) || Arg <- Args],
    ")"].
