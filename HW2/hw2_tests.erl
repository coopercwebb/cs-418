-module(hw2_tests).

-include_lib("eunit/include/eunit.hrl").

% We don't export whatever_test/0 because the EUnit macros do that and we'll
% provoke a warning message if we export them here as well.
-export([reduce_test/1, scan_test/1, light_actions/1, light_actions/2, light_ref/3]).

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
		 Total = hw2:reduce(ProcInfo, plus_fun(), I),
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
			   I = hw2:scan(ProcInfo, plus_fun(), 0, 1),
			   hw2_lib:swap_data_with_master(ProcInfo, I),
			   J = hw2:scan(ProcInfo, ConcatFun, [], [I]),
			   hw2_lib:swap_data_with_master(ProcInfo, J)
		       end),
  II = lists:seq(0, NProcs-1),
  ?assertEqual(II, hw2_lib:swap_data_with_tree(RootPid, [ok || _ <- II])),
  {JJ,_} = lists:mapfoldl(fun(X, Acc) -> {Acc, Acc+X} end, 0, I),
  ?assertEqual(JJ, hw2_lib:swap_data_with_tree(RootPid, [ok || _ <- JJ])),

  % Q1.b  add a test case with a CombineFun that is both associative and commutative.
  you_need_to_write_this(q1b,
    ["test hw2:scan with a CombineFun that is both associative and commutative"]),
  
  % Q1.c  add a test case with a CombineFun that is associative but *not* commutative.
  you_need_to_write_this(q1c,
    ["test hw2:scan with a CombineFun that is both associative but not commutative"]).

scan_test() -> scan_test(8).

plus_fun() -> fun(X, Y) -> X+Y end.


moose_leaf_test() ->
  you_need_to_write_this(moose_leaf_test,
    [ "Write at least three tests here for moose_leaf(ProcState, Key).",
      "I haven't provided any examples because these tests depends on the data structure " ++
      "that you came up with for using with moose_combine." ]).

moose_combine_test() ->
  you_need_to_write_this(moose_combine_test,
    [ "Write at least three tests here for moose_combine(Left, Right).",
      "I haven't provided any examples because these tests depends on the data structure " ++
      "that you came up with for using with moose_combine." ]).

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

    you_need_to_write_a_test_("Add at least three more tests to moose_par_test_().")
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



% light_combine_test()
%   Exhaustively test light_combine.
light_combine_test() ->
  F = [turn_off, slack, flip, turn_on],
  [    ?assertEqual(hw2:light(F2, hw2:light(F1, X)),
		     hw2:light(hw2:light_combine(F1, F2), X))
    || F1 <- F, F2 <- F, X <- [false, true] ].

% light_combine_test()
%   Show that light_combine is associative using exhausitive tests.
light_combine_assoc_test() ->
  you_need_to_write_this(light_combine_assoc_test, []).


light_par_test_() ->
  [ light_par_test_(4,
      [ [slack,flip,turn_off,slack,turn_on],
	[slack,slack,slack,flip,turn_off],
	[slack,flip,flip,slack,slack],
	[turn_on,turn_off,slack,turn_on,flip]], false)
  ].


% moose_par_test is an example of an EUnit test fixture
light_par_test_(NWorkers, Data, LightInit)
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
      ?_assertEqual(light_ref(WorkerTree, data, LightInit),
		    hw2:light_par(WorkerTree, data, LightInit))
    end }.

% reference version for testing light_par_test.
light_ref(WorkerTree, Key, LightInit) ->
  Data = lists:append(wtree:retrieve(WorkerTree, Key)),
  hw2:light_seq(Data, LightInit).


% light_actions(N) -> ActionList
%   Generate a list of actions for testing the light_XXX functions.
%   If 1 =< N =< 3, light_actions generates a pre-defind list of actions.
%   If N > 3, then light_actions generates a random list of N actions.
light_actions(1) ->
  [ slack, flip, slack, flip, flip];
light_actions(2) ->
  [ slack, flip, turn_on, flip, flip];
light_actions(3) ->
  [ slack, flip, turn_on, flip, turn_on, flip];
light_actions(N) when is_integer(N), 0 =< N ->
  light_actions(N, {slack, flip, turn_on, turn_off}).

% light_actions(N, A_tuple) -> ActionList
%   Generate a random list of N actions where each action is an element
%   of A_tuple.  This lets you generate test cases that only use a subset
%   of the possible actions.
light_actions(N, A) when is_integer(N), 0 =< N, is_tuple(A) ->
  [ element(rand:uniform(tuple_size(A)), A) || _ <- lists:seq(1, N)]. 



you_need_to_write_a_test_(Msg) ->
  ?_assertEqual(Msg, missing).
