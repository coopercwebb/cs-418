-module(hw2_tests).

-include_lib("eunit/include/eunit.hrl").

% We don't export whatever_test/0 because the EUnit macros do that and we'll
% provoke a warning message if we export them here as well.
-export([reduce_test/1, scan_test/1]).

% I added the export of plus_fun/0 so you can try the test
% cases interactively by cut-and-pasting code into the Erlang shell.
% I added the export of you_need_to_write_a_test/1 so this module
% will compile without warnings when you have added your tests and
% you_need_to_write_a_test/1 is no longer called.
-export([plus_fun/0, you_need_to_write_a_test_/1]).

-import(hw2_lib, [you_need_to_write_this/2]).


% When run as an EUnit test, e.g.,
%   3>  eunit:test(hw2).
% EUnit discards all output to stdout by default.  So, you won't see the
% "Hello world" output from this function.  OTOH, if invoke this by entering
%   4>   hw2_tests:create_test().
% at the Erlang command prompt (the prompt is shown as "4>" in the line
% above), then you will the the output.  I wrote it this way so you can see
% in more detail what the test is doing, or just run this as a pass-file
% test from EUnit.
%   If you change the bounds on the lists:seq(...), e.g. to
%     lists:seq(0, NProcs)
% you can force an error, if you want to see EUnit report an error or
% see the error when running hw2_tests:create_test().
create_test() ->
  MasterPid = self(),
  NProcs = 8,
  hw2:create(NProcs,
	     fun(ProcInfo) ->
		 I = hw2:proc_index(ProcInfo),
		 io:format("~w: Hello world!  My index is ~w~n", [self(), I]),
		 MasterPid ! {self(), create_test, I}
	     end),
  X = [ receive
	  {Pid, create_test, I} when is_pid(Pid) -> ok
	after 1000 -> lists:flatten(io_lib:format(
				      "no response from process ~w~n", [I]))
	end || I <- lists:seq(1, NProcs) ],
  ?assertEqual([], [ Y || Y  <- X, Y /= ok]).


% compute the sum of our process indices.  The process with
% proc_index(ProcInfo)==1 sends this total to the master process.
% Compare the answer with sum_{I=1}^N I.
reduce_test(NProcs) when is_integer(NProcs), 0 < NProcs ->
  MasterPid = self(),
  hw2:create(NProcs,
	     fun(ProcInfo) ->
		 I = hw2:proc_index(ProcInfo),
		 Total = hw2:reduce(ProcInfo, hw2_tests:plus_fun(), I),
		 case I of
		   1 -> MasterPid ! {self(), reduce_test, Total};
		   _ -> ok
		 end
	     end),
  V = receive
        {Pid, reduce_test, Total} when is_pid(Pid) -> Total
      after 1000 -> time_out
      end,
  ?assertEqual(lists:sum(lists:seq(1, NProcs)), V).

reduce_test() -> reduce_test(13).


scan_test(NProcs) when is_integer(NProcs), 0 < NProcs ->
  ConcatFun = fun(X, Y) -> X++Y end,
  RootPid = hw2:create(NProcs,
		       fun(ProcInfo) ->
			   I = hw2:scan(ProcInfo, hw2_tests:plus_fun(), 0, 1),
			   hw2_lib:swap_data_with_master(ProcInfo, I),
			   J = hw2:scan(ProcInfo, ConcatFun, [], [I]),
			   hw2_lib:swap_data_with_master(ProcInfo, J)
		       end),
  II = lists:seq(0, NProcs-1),
  ?assertEqual(II, hw2_lib:swap_data_with_tree(RootPid, [ok || _ <- II])),
  {JJ,_} = lists:mapfoldl(fun(X, Acc) -> {Acc, Acc++[X]} end, [], II),
  ?assertEqual(JJ, hw2_lib:swap_data_with_tree(RootPid, [ok || _ <- JJ])),

  % Q1.b  add a test case with a CombineFun that is both associative and commutative.
  % Multiplication
  RootPid2 = hw2:create(NProcs,
		       fun(ProcInfo) ->
         I = hw2:proc_index(ProcInfo),
			   K = hw2:scan(ProcInfo, prod_fun(), 1, I),
			   hw2_lib:swap_data_with_master(ProcInfo, K),
			   L = hw2:scan(ProcInfo, ConcatFun, [], [K]),
			   hw2_lib:swap_data_with_master(ProcInfo, L)
		       end),

  {KK_tail, _} = lists:mapfoldl(fun(X, Prod) -> {X*Prod, X*Prod} end, 1, lists:seq(1,NProcs - 1)),
  KK = [1 | KK_tail],
  ?assertEqual(KK, hw2_lib:swap_data_with_tree(RootPid2, [ok || _ <- KK])),
  {LL,_} = lists:mapfoldl(fun(X, Acc) -> {Acc, Acc++[X]} end, [], KK),
  ?assertEqual(LL, hw2_lib:swap_data_with_tree(RootPid2, [ok || _ <- LL])),

  % Q1.c  add a test case with a CombineFun that is associative but *not* commutative.
  % String Concatenation 
  RootPid3 = hw2:create(NProcs,
        fun(ProcInfo) ->
      I = integer_to_list(hw2:proc_index(ProcInfo)),
      M = hw2:scan(ProcInfo, ConcatFun, "", I),
      hw2_lib:swap_data_with_master(ProcInfo, M),
      N = hw2:scan(ProcInfo, ConcatFun, [], [M]),
      hw2_lib:swap_data_with_master(ProcInfo, N)
        end),

  MM_preconcat = [integer_to_list(X) || X <- lists:seq(1, NProcs)],
  {MM,_} = lists:mapfoldl(fun(X, Acc) -> {Acc, Acc++X} end, "", MM_preconcat),
  ?assertEqual(MM, hw2_lib:swap_data_with_tree(RootPid3, [ok || _ <- MM])),
  {NN,_} = lists:mapfoldl(fun(X, Acc) -> {Acc, Acc++[X]} end, [], MM),
  ?assertEqual(NN, hw2_lib:swap_data_with_tree(RootPid3, [ok || _ <- NN])).

scan_test() -> scan_test(8).

plus_fun() -> fun(X, Y) -> X+Y end.

prod_fun() -> fun(X, Y) -> X*Y end.

moose_leaf_test() ->
  you_need_to_write_this(moose_leaf_test,
    [ "Write at least three tests here for moose_leaf(ProcState, Key).",
      "I haven't provided any examples because these tests depends on " ++
      "the data structure that you came up with for using with moose_combine." ]).

moose_combine_test() ->
  you_need_to_write_this(moose_combine_test,
    [ "Write at least three tests here for moose_combine(Left, Right).",
      "I haven't provided any examples because these tests depends on " ++
      "the data structure that you came up with for using with moose_combine." ]).

moose_par_test_() ->
  [ moose_par_test_(4,
      [ "This is a test for moose_par_test",
	"How many times does the string \"moose\" appear in the strings in this list?",
	"alpaca, moose, bison, moose, cow, donkey, moose, moose, moose, elk, goat, horse, llama, moose moss, mouse, moose, zebra",
	"moose moose Moose MOOse moose" ]),
    moose_par_test_(4,
      [ "Lise Meitner was the first person to split the atom",
	"oo",
	"see what I did there?  Where's the moose?",
	"Why did Otto Hahn get the Nobel Prize but not Meitner?" ]),

    moose_par_test_(4, misc:cut(moose:data(seuss), 4)),
    moose_par_test_(8, misc:cut(moose:data(wikipedia), 8)),
    moose_par_test_(13, misc:cut(moose:data({random, 1234, 0.04, 0.08}), 13)),

    % you_need_to_write_a_test_("Add at least three more tests to moose_par_test_().")
    moose_par_test_(5, 
      ["m", "o", "o", "s", "e"]
    ),
    moose_par_test_(10, 
      ["m", "o", "o", "s", "e",
        "m", "o", "o", "s", "e"]
    ),
    % nodes must propegate up large value (moos)
    moose_par_test_(7,
      ["a", "b", "c", "moos",
        "emoo", "s", "e"]
    )
  ].

% moose_par_test is an example of an EUnit test fixture
moose_par_test_(NWorkers, Data)
    when is_integer(NWorkers), 0 < NWorkers, length(Data) == NWorkers ->
  { setup,
    fun() -> % set-up the test fixture
	WorkerTree = wtree:create(NWorkers),
	wtree:update(WorkerTree, data, Data),
	WorkerTree
    end,
    fun(WorkerTree) -> % clean-up after the tests are run.
	               %clean-up runs even if the tests fail or abort.
	wtree:reap(WorkerTree)
    end,
    fun(WorkerTree) -> % the test(s) to perform
      ?_assertEqual(hw2:moose_ref(WorkerTree, data),
		   hw2:moose_par(WorkerTree, data))
    end }.



you_need_to_write_a_test_(Msg) ->
  ?_assertEqual(Msg, missing).
