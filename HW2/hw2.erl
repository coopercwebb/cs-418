-module(hw2_lib).

-export([swap_data_with_master/2, swap_data_with_tree/2]).

-include_lib("eunit/include/eunit.hrl").


% swap_data_with_master(ProcInfo, UpData) -> DownData
%   called by worker processes.
%   Parameters:
%     ProcInfo is the ProcInfo object for the process (doh!)
%     UpData is our data to send to the master process.
%   Return Value:
%     DownData: our data from the master process.
%   Note: the master process will receive a list of UpData values, with
%     one element per worker process, in order of their process indices.
%     The master process provides a list of new data values, with one
%     element per worker process.  Each worker receives the DownData value
%     corresponding to its position in this list.
swap_data_with_master(ProcInfo, UpData) ->
  swap_data_with_master(hw2:parent_pid(ProcInfo), hw2:child_pids(ProcInfo), {UpData}).

swap_data_with_master({MasterPid}, [], UpData) ->
  MasterPid ! {self(), data_up, UpData},
  receive
    {MasterPid, data_down, DownData} -> DownData
  end;
swap_data_with_master(ParentPid, [], UpData) ->
  ParentPid ! {self(), data_up, UpData},
  receive
    {ParentPid, data_down, DownData} -> DownData
  end;
swap_data_with_master(Parent, [ChildHd | ChildTl], LeftUp) ->
  receive
    {ChildHd, data_up, RightUp} ->
      [LeftDown, RightDown] =
        swap_data_with_master(Parent, ChildTl, [LeftUp, RightUp]),
      ChildHd ! {self(), data_down, RightDown},
      LeftDown
  end.

swap_data_with_tree(RootPid, ListDown) ->
  receive
    {RootPid, data_up, DataUp} ->
      try
	case swap_magic(DataUp, [], ListDown) of
	  {DataDown, ListUpRev, []} ->
	    RootPid ! {self(), data_down, DataDown},
	    lists:reverse(ListUpRev);
	  _ -> io:format("swap_data_with_tree: too many values in ListDown" ++
			 "  length(ListDown) = ~w, should be ~w~n",
			 [length(ListDown), length(lists:flatten(DataUp))]),
	       error(bad_arg)
	end
      catch error:not_enough_data ->
	      io:format("swap_data_with_tree: not enough values in ListDown" ++
			"  length(ListDown) = ~w, should be ~w~n",
			[length(ListDown), length(lists:flatten(DataUp))]),
	      error(bad_arg)
      end
  end.

swap_magic({Leaf1}, Rev1, [Hd2 | Tl2]) ->
  {Hd2, [Leaf1 | Rev1], Tl2};
swap_magic(_, _, []) ->
  error(not_enough_data);
swap_magic([L1, R1], Rev1, List2) ->
  {NewL1, Rev1a, List2a} = swap_magic(L1, Rev1, List2),
  {NewR1, Rev1b, List2b} = swap_magic(R1, Rev1a, List2a),
  {[NewL1, NewR1],  Rev1b, List2b}.


swap_data_test(NProcs) ->
  RootPid = hw2:create(NProcs,
		       fun(ProcInfo) ->
			   I = hw2:proc_index(ProcInfo),
			   J = swap_data_with_master(ProcInfo, I*I),
			   X = hw2:reduce(ProcInfo, fun(X, Y) -> X+Y end, I-J),
			   swap_data_with_master(ProcInfo, X =:= 0)
		       end),
  S = swap_data_with_tree(RootPid, lists:seq(NProcs, 1, -1)),
  ?assertEqual([I*I || I <- lists:seq(1,NProcs)], S),
  ?assert(lists:all(fun(X) -> X end,
		    swap_data_with_tree(RootPid, lists:seq(1, NProcs)))).

swap_data_test() -> swap_data_test(6).

swap_magic_test() ->
  ?assertEqual({[[[1,2],3],[[4,5],[6,7]]],[g,f,e,d,c,b,a],[]},
	       swap_magic([[[{a},{b}],{c}],[[{d},{e}],[{f},{g}]]], [], lists:seq(1,7))),
  ?assertError(not_enough_data,
	       swap_magic([[[{a},{b}],{c}],[[{d},{e}],[{f},{g}]]], [], lists:seq(1,6))),
  ?assertEqual({[[[1,2],3],[[4,5],[6,7]]],[g,f,e,d,c,b,a],[8]},
	       swap_magic([[[{a},{b}],{c}],[[{d},{e}],[{f},{g}]]], [], lists:seq(1,8))).
