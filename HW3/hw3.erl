-module(hw3).

% functions you need to write -- depending on which questions you choose to answer.
-export([count3s_q1b/1]).  % your version of count3s if you choose to answer Q1.
-export([q3_leaf/2, q3_combine/2]).

% functions we provide
-export([count3s/1, q3_reduce/2, you_might_need_to_write_this/2]).


% Q1
% version of count3s from the question
count3s([]) -> 0;
count3s([3 | Tl]) -> 1 + count3s(Tl);
count3s([_ | Tl]) -> count3s(Tl).

% your version for Q1.b
count3s_q1b(List) ->
  count3s_q1b_helper(List, 0).

count3s_q1b_helper([], Acc) -> Acc;
count3s_q1b_helper([3 | Tl], Acc) -> count3s_q1b_helper(Tl, Acc+1);
count3s_q1b_helper([_ | Tl], Acc) -> count3s_q1b_helper(Tl, Acc).


% Q3
q3_reduce(W, Key) ->
  wtree:reduce(W,
    fun(ProcState) -> q3_leaf(ProcState, Key) end,
    fun(Left, Right) -> q3_combine(Left, Right) end).
      
% your Leaf function
q3_leaf(ProcState, Key) ->
  you_might_need_to_write_this(q3_leaf, [ProcState, Key]).

% your Combine function
q3_combine(Left, Right) ->
  you_might_need_to_write_this(q3_combine, [Left, Right]).



% The usual you_need_to_write this function
you_might_need_to_write_this(Fun, Args) ->
    io:format("Missing implementation for ~w~s.~n", [Fun, args_string(Args)]).

args_string([]) -> "()";
args_string([Arg1 | Args]) ->
  [ "(", io_lib:format("~p", [Arg1]),
    [ io_lib:format(", ~p", [Arg]) || Arg <- Args],
    ")"].
