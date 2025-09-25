Testing pattern i 
Match, X=[] 
Match, X=0 
Match, X=[cat] 
Match, X=[cat,fish] 
Match, X=[potoroo,bettong,wombat] 
Match, X=[10,8,6,4,2,0] 
Match, X={bat,wombat} 
Match, X=[{panda,3},{penguin,2},{potoroo,137}] 
Match, X=[{dog,2},{potoroo,137},{cat,3}] 
Match, X={[cat,dog,potoroo],[3,2,137]} 
Testing pattern ii 
Match
Match
Match
Match
Match
Match
Match
Match
Match
Match
Testing pattern iii 
Does not match 
Does not match 
Does not match 
Match, X=cat 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Testing pattern iv 
Does not match 
Does not match 
Match, X=cat 
Match, X=cat 
Match, X=potoroo 
Match, X=10 
Does not match 
Match, X={panda,3} 
Match, X={dog,2} 
Does not match 
Testing pattern v 
Does not match 
Does not match 
Does not match 
Match, X=cat 
Match, X=potoroo 
Match, X=10 
Does not match 
Match, X={panda,3} 
Match, X={dog,2} 
Does not match 
Testing pattern vi 
Does not match 
Match
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Testing pattern vii 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Testing pattern viii 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Match, X=bat 
Does not match 
Does not match 
Match, X=[cat,dog,potoroo] 
Testing pattern ix 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Does not match 
Match, X=2 
Match, X=137 
Does not match 
Testing pattern x 
Does not match 
Does not match 
Match
Match
Match
Match
Does not match 
Match
Match
Does not match 
true

q2.
i.
command to time the mpow functions

must test on the thetis server

time_it:t(fun() -> hw1:mpow_0(1234567, 1000, 10000000) end).

2> time_it:t(fun() -> hw1:mpow_0(1234567, 1000, 10000000) end).
[{mean,4.349414152748802e-5},{std,4.814629017786146e-5}]
3> time_it:t(fun() -> hw1:mpow_0(1234567, 10000, 10000000) end).
[{mean,5.047274616548935e-4},{std,1.034292260166725e-4}]
4> time_it:t(fun() -> hw1:mpow_0(1234567, 100000, 10000000) end).
[{mean,0.0040062643199999986},{std,7.811518421978448e-4}]
5> time_it:t(fun() -> hw1:mpow_0(1234567, 500000, 10000000) end).
[{mean,0.021620705531914898},{std,0.003099455203481401}]
6> time_it:t(fun() -> hw1:mpow(1234567, 1000, 10000000) end).
[{mean,8.943302401442417e-7},{std,2.1681135121328634e-6}]
7> time_it:t(fun() -> hw1:mpow(1234567, 10000, 10000000) end).
[{mean,7.594552119140906e-7},{std,1.936260350409366e-6}]
8> time_it:t(fun() -> hw1:mpow(1234567, 100000, 10000000) end).
[{mean,1.1073590720334442e-6},{std,1.9122611606372754e-6}]
9> time_it:t(fun() -> hw1:mpow(1234567, 500000, 10000000) end).
[{mean,1.1404655185981624e-6},{std,1.926671966514821e-6}]

```erlang
Ipow = fun F(_,0) -> 1;
    F(X,N) when is_integer(N), N > 0 -> X*F(X,N-1) end,
Googol = Ipow(10, 100),
BigInteger = lists:foldl(fun(X, Prod) -> 
    X*Prod end, 1, lists:seq(123456789, 123456800)).
```

ii.
time_it:t(fun() -> hw1:mpow(BigInteger+17, BigInteger, Googol) end).
[{mean,8.502577544604936e-4},{std,1.678907965555586e-4}]
8.503e-4

compared to soln (need to load the beam file)
l(hw1x).
time_it:t(fun() -> hw1x:mpow(BigInteger+17, BigInteger, Googol) end).
[{mean,6.624394377483451e-4},{std,3.359625986468393e-4}]

within the same range, good

3. 

c)

non-parallel: 

2> time_it:t(fun() -> hw1:find_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),4) end).
[{mean,1.010951936},{std,undefined}]
3> time_it:t(fun() -> hw1:find_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),4) end).
[{mean,0.93631317},{std,0.03694881833286614}]
4> time_it:t(fun() -> hw1:find_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),4) end).
[{mean,0.5988911935000001},{std,0.021902159492811404}]
5> time_it:t(fun() -> hw1:find_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),4) end).
[{mean,0.59173145},{std,0.01529354870823183}]
6> time_it:t(fun() -> hw1:find_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),4) end).
[{mean,1.127399569},{std,undefined}]

13> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),18, 4) end).
[{mean,0.929759773},{std,0.023240249474666436}]
14> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),18, 4) end).
[{mean,1.066448848},{std,undefined}]
15> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),18, 4) end).
[{mean,1.2910543600000002},{std,undefined}]
16> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),18, 4) end).
[{mean,0.9285235115000001},{std,0.03264299977616888}]
17> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),18, 4) end).
[{mean,0.9296156685000001},{std,0.02114872873217663}]

21> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),48, 16) end).
[{mean,1.228194118},{std,undefined}]
22> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),48, 16) end).
[{mean,0.8939060005000001},{std,0.10763763341695334}]
23> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),48, 16) end).
[{mean,1.089954106},{std,undefined}]
24> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),48, 16) end).
[{mean,0.8809250315000001},{std,0.005663600755270426}]
25> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),48, 16) end).
[{mean,0.880491354},{std,0.004560107590232452}]

35> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),40, 32) end).
[{mean,0.8118765680000001},{std,0.07544909258326583}]
36> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),40, 32) end).
[{mean,0.90504187},{std,0.08834395689880885}]
37> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),40, 32) end).
[{mean,0.9113469805000001},{std,0.021436671098753978}]
38> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),40, 32) end).
[{mean,0.8926901685},{std,0.06722578649328476}]
39> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),40, 32) end).
[{mean,1.123916501},{std,undefined}]

42> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 64) end).
[{mean,0.7787059625},{std,0.05017620314779329}]
43> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 64) end).
[{mean,1.110071623},{std,undefined}]
44> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 64) end).
[{mean,0.9423846475000001},{std,0.16996505718461435}]
45> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 64) end).
[{mean,1.025461248},{std,undefined}]
46> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 64) end).
[{mean,0.7653916685000001},{std,0.04402799029555271}]

47> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 128) end).
[{mean,0.8090906595},{std,0.06304988678681331}]
48> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 128) end).
[{mean,0.8336943505000001},{std,0.019962786209338928}]
49> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 128) end).
[{mean,0.724388188},{std,0.17102125763392487}]
50> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 128) end).
[{mean,0.751066255},{std,0.1545732001276972}]
51> time_it:t(fun() -> hw1:par_primes(3*hw1:ipow(2,126),5*hw1:ipow(2,126),5, 128) end).
[{mean,1.1454435980000002},{std,undefined}]

4 proc:

16 proc:

32 proc:

64 proc:

128 proc:

256 proc: