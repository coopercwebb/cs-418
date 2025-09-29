-module(hw2).

-export([create/2, child_pids/1, parent_pid/1, proc_index/1]).
-export([reduce/3, scan/4]).
-export([moose_seq/1, moose_ref/2, moose_leaf/2, moose_combine/2, moose_par/2]).
-export([stats/2, par_stats/3]).

-import(hw2_lib, [you_need_to_write_this/2]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
% Template code for Q1: reduce by the book.                                %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Each process in the process-trees we create has a ProcInfo object.
% Currently, this is a tuple with three fields:
%   {ParentPid, ChildPids, Index}
% If this node is the root of the process tree, then ParentPid is a tuple
% of the form {MasterPid} where MasterPid is the pid of the process that
% created this tree.
% This structure might change as we add more functionality to process trees.
% Thus, ProcInfo objects should only be created by create and only accessed
% by the functions below:
child_pids({_,CPids,_}) -> CPids.
parent_pid({PPid,_,_}) -> PPid.
proc_index({_,_,I}) -> I.

% create(NProcs, Task) -> RootPid
%   RootPid is the pid for the process at the root of the tree.
create(NProcs, Task)
    when is_integer(NProcs), 0 < NProcs, is_function(Task, 1) ->
  MyPid = self(),
    spawn(fun() -> create(NProcs, {MyPid}, 1, [], Task) end).
  
create(1, Parent, MyIndex, ChildPids, Task) ->
  Task({Parent, ChildPids, MyIndex});
create(N, Parent, MyIndex, ChildPids, Task) when is_integer(N), 1 < N ->
  NLeft = N div 2,
  NRight = N - NLeft,
  MyPid = self(),
  RightPid = spawn(fun() ->
		       create(NRight, MyPid, MyIndex+NLeft, [], Task)
		   end),
  create(NLeft, Parent, MyIndex, [RightPid | ChildPids], Task).

% Lin & Snyder style reduce:
%   called by the leaves.
%   returns the GrandTotal to each leaf.
reduce(ProcInfo, CombineFun, Value) ->
  reduce(parent_pid(ProcInfo), child_pids(ProcInfo), CombineFun, Value).

reduce({_MasterPid}, [], _, GrandTotal) -> GrandTotal;
reduce(ParentPid, [], _, MyTotal) ->
  ParentPid ! {self(), reduce_up, MyTotal},
  receive
    {ParentPid, reduce_down, GrandTotal} -> GrandTotal
    % maybe we should have an after clause to check for time-outs
  end;
reduce(Parent, [ChildHd | ChildTl], CombineFun, LeftTotal) ->
  receive
    {ChildHd, reduce_up, RightTotal} ->
      GrandTotal =
        reduce(Parent, ChildTl, CombineFun, CombineFun(LeftTotal, RightTotal)),
      ChildHd ! {self(), reduce_down, GrandTotal},
      GrandTotal
  end.

% Q1: Implement a Lin & Snyder style exclusive scan.
scan(ProcInfo, CombineFun, AccIn, Value) -> % CombineFun of all values preceding this one
  scan(parent_pid(ProcInfo), child_pids(ProcInfo), CombineFun, AccIn, Value).

scan({_MasterPid}, [], _, AccIn, _) -> AccIn;
scan(ParentPid, [], _, _, MyTotal) ->
  ParentPid ! {self(), scan_up, MyTotal},
  receive
    {ParentPid, scan_down, ScanVal} -> 
      ScanVal
  end;
scan(Parent, [ChildHd | ChildTl], CombineFun, AccIn, LeftTotal) ->
  receive
    {ChildHd, scan_up, RightTotal} ->
      ParentVal =
        scan(Parent, ChildTl, CombineFun, AccIn, CombineFun(LeftTotal, RightTotal)),
      ChildHd ! {self(), scan_down, CombineFun(ParentVal, LeftTotal)},
      ParentVal
  end.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
% Template code for Q2: Help find my moose.                                %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

moose_seq(String) when is_list(String) -> moose_seq(String, 0).

moose_seq([], Count) -> Count;
moose_seq([$m, $o, $o, $s, $e | Tl], Count) -> moose_seq(Tl, Count+1);
moose_seq([_ | Tl], Count) -> moose_seq(Tl, Count).

moose_ref(WorkerTree, Key) ->
  moose_seq(lists:append(wtree:retrieve(WorkerTree, Key))).


% Q2.a:  Write a comment (probably 5-10 lines) giving a high-level
% description of your implementation of moose_leaf, moose_combine
% and moose_par below.
%
% Your design documentation comment goes here.


% Q2.b: implement moose_leaf
% Returns {Overall, Prefix, Suffix}
moose_leaf(ProcState, Key) ->
  Val = workers:get(ProcState, Key),
  {moose_seq(Val), lists:sublist(Val, 4), suffix_n(Val, 4)}.

suffix_n(String, N) ->
    Length = length(String),
    Start = max(1, Length - N + 1),
    lists:sublist(String, Start, Length).

% Q2.c: implement moose_combine
moose_combine(Left, Right) ->
  {Left_Overall, Left_Prefix, Left_Suffix} = Left,
  {Right_Overall, Right_Prefix, Right_Suffix} = Right,
  Prefix = case length(Left_Prefix) < 4 of
      true -> lists:sublist(lists:append(Left_Prefix, Right_Prefix), 4);
      false -> Left_Prefix
    end,
  Suffix = case length(Right_Suffix) < 4 of 
      true -> suffix_n(lists:append([Left_Suffix, Right_Suffix]), 4);
      false -> Right_Suffix
    end,
  { Left_Overall + Right_Overall + moose_seq(lists:append(Left_Suffix, Right_Prefix)),
    Prefix, Suffix }.

% Q2.d: implement moose_par
%
% moose_par(WorkerTree, Key): return the number of occurrences of "moose"
%   in the list associated with Key distributed across the workers of WorkerTree.
%   Your solution should use wtree:reduce.
moose_par(WorkerTree, Key) ->
  {Overall, _, _} = wtree:reduce(WorkerTree, 
    fun(ProcState) -> moose_leaf(ProcState, Key) end,
    fun moose_combine/2),
  Overall.


% Q2.e: Now edit hw2_tests.erl and add test cases for moose_leaf,
% moose_combine, and moose_par



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
% Template code for Q3: Stranded on an island.                             %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% stats(C0, N_trials)
% Return the estimated mean and standard deviation of the number of generations
% it takes for the island population to reach a generation where everyone has
% the same surname starting from the distribution given by C0.  N_trials is
% the number of runs of sim/1 to make to calculate these statistics.
stats(C0, N_trials) ->
  A = stats(C0, N_trials, stat:create()),
  [{mean, stat:mean(A)}, {std, stat:std(A)}].

stats(_C0, 0, Acc) -> Acc;
stats(C0, N, Acc) ->
  stats(C0, N-1, stat:accum(island:sim(C0), Acc)).


% Q3.a: implement par_stats(W, C0, N_trials)
%   A parallel implementation of stats(C0, N_trials).
%
%   Parameters:
%     W:   a worker tree created by wtree:create
%     C0:  the intial census.  See island:rand_census/3.
%     N_trials:  Run a total of N_trials runs of island_sim(C0).  If W as NW workers,
%       then each worker should perform roughly N_trials/NW simulations, rounded up or down
%       to get the total to be N_trials.
%   Return value:
%     [{mean, Mean}, {std, StandardDeviation}]
%     Where
%       Mean is the average number of generations needed to reach generation with a single surname;
%       StandardDeviation is the standard deviation of the number of generations needed.
%
%   Note: your solution should use wtree:reduce.  More hints and guidelines
%     are provided in the PDF for the homework questions.
par_stats(W, C0, N_trials) ->
  you_need_to_write_this(par_stats, [W, C0, N_trials]).


% Q3.b: measure speed-up.
%   Add code here for making your timing measurements.
%   Report your timing measurements and speed-up calculations in the hw2.pdf
%   file that you submit.
