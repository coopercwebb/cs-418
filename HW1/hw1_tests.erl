% hw1_tests.erl a few EUnit tests for hw1.
%   For EUnit documentation see:
%     Learn You Some Erlang:
%       https://learnyousomeerlang.com/eunit
%     or, the Erlang.org documentation:
%       https://www.erlang.org/doc/apps/eunit/chapter.html
%
%   To run these tests, give the following command at the Erlang shell prompt:
%     eunit:test(hw1).

-module(hw1_tests).

-include_lib("eunit/include/eunit.hrl").


-import(hw1, [mpow/3, rm_decompose/1, rm_check/4, find_primes/3, par_primes/4]).


% Q2
mpow_test() ->
  ?assertEqual(4,   mpow(5, 8, 7)),
  ?assertEqual(33,  mpow(3, 8, 64)),
  ?assertEqual(1,   mpow(12345, 65536, 65537)), % 65537 = 2^16+1, a Fermat Prime
  ?assertEqual(622, mpow(123, 2046, 2047)). % 2047 = 2^11 - 1, the smallest Mersenne number that isn't prime.


% Q3
rm_decompose_test() ->
  ?assertEqual({3,2}, rm_decompose(12)),
  ?assertEqual({25,0}, rm_decompose(25)),
  ?assertEqual({65535,16}, rm_decompose(4294901760)),
  ?assertEqual({1,0}, rm_decompose(1)).


rm_check_test() ->
  F = fun(Q) ->
	  {D, S} = rm_decompose(Q-1),
	  rm_check(Q, D, S, 50)
      end,
  ?assert(F(43)),
  ?assert(F(65537)),
  ?assertNot(F(529)),
  ?assertNot(F(2047)).


% Q4
find_primes_test() ->
  ?assertEqual([1009,1013,1019,1021,1031,1033,1039,1049,1051,1061],
	       lists:sort(find_primes(1000, 1000000, 10))),
  ?assertEqual(hw1x:find_primes(avogadro(), 2*avogadro(), 10),
	       lists:sort(find_primes(avogadro(), 2*avogadro(), 10))),
  ?assertError(_, find_primes(1000, 1000000, -1)).


% Q5
par_primes_test() ->
  N = 100,
  NW = 4,
  P = lists:sort(par_primes(avogadro(), 2*avogadro(), N, NW)),
  DeDup = fun DD([]) -> [];
	      DD([A]) -> [A];
	      DD([A | Tl=[A|_]]) -> DD(Tl);
	      DD([A | Tl]) -> [A | DD(Tl)]
	  end,
  % check that par_primes returned the right number of primes
  ?assertEqual(length(P), 100),
  % make sure there are no duplicates
  ?assert(DeDup(P) == P),
  % make sure that every entry is prime
  ?assert(lists:all(fun(X) -> hw1x:rabin_miller(X) end, P)).

avogadro() -> 602214076000000000000000.
