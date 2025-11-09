-module(hw5_lib).

-export([ed_seq/2, ed_seq/3]).
-export([ed_tab0/2, ed_tab0/3, ed_tab/3, ed_row/3]).
-export([ed_tile/3, ed_tile/4]).
-export([string_to_strcost/1, string_to_strcost/2, strcost_to_costs/1]).
-export([default_op_costs/0]).

-export([chain_create/2, chain_create/3, chain_exit/1]).
-export([chain_send/2, chain_send/3, chain_receive/1, chain_receive/2]).
-export([chain_worker_demo/2, chain_demo/1, chain_demo/0]).
-export([chain_demo2/0, chain_demo2/1]).

-export([you_need_to_write_this/2]).

% ed_seq(S1, S2, OpCosts) -> EditCost
%   Parameters:
%     S1:  The first "string" -- any list is acceptable.
%     S2:  The second "string" -- again, any list is acceptable.
%     OpCosts = {CostInsDel, CostReplace}
%       CostInsDel is the editing cost for inserting or deleting an element from S1.
%       CostReplace is the cost for replacing an element of S1 with a different value.
%       By assuming that the insert and delete costs are the same, we have the nice
%       property that the cost for editing S1 to produce S2 is the same as the cost
%       for editing S2 to produce S1.
%
%   Return value:  EditingCost, a number
%     The cost of editing S1 into S2.
%
%   Example: hw5_lib:ed_seq("hello", "world", hw5_lib:default_op_costs()).
%     Should return 6.
ed_seq(S1, S2, OpCosts) ->
  {RightCol,_} = ed_tile(string_to_strcost(S1, OpCosts),
			 string_to_strcost(S2, OpCosts),
			 OpCosts),
  element(2, lists:last(RightCol)).

% ed_seq(S1, S2) -> EditCost
%   Compute the editing cost for transforming S1 to S2 using the defaults
%     costs for insertions, deletions, and replacements.
ed_seq(S1, S2) -> ed_seq(S1, S2, default_op_costs()).


% ed_tab0(LeftString, TopString, OpCosts) -> Tableau
%   Return the dynamic programming tableau for computing the editing distance
%   from LeftString to TopString.
%   This is provided as a demonstration of the dynamic-programming algorithm
%   -- it %   returns the entire tableau.  That can be helpful when trying
%   cases with short string.  The disadvantage is that this requires enough
%   memory to store the entire tableau.  Given the memory limits for student
%   accounts when running Erlang on CS department machines, this is likely
%   to be a severe constraint for larger examples.
%   
%   Note: ed_seq uses ed_tile (below) which uses O(length(S2)) space.
%
%   Parameters:
%     LeftString:  The first "string" -- any list is acceptable.
%       It is called the LeftString because each element of LeftString
%       corresponds to a row of the tableau.  We can think of LeftString
%       as going from top-to-bottom along the left side of the tableau.
%     TopString:  The second "string" -- again, any list is acceptable.
%       It is called the TopString because each element of TopString
%       corresponds to a column of the tableau.  We can think of TopString
%       as going from left-to-right along the top side of the tableau.
%     OpCosts = {CostInsDel, CostReplace}
%       CostInsDel is the editing cost for inserting or deleting an element
%         from LeftString.
%       CostReplace is the cost for replacing an element of LeftString with
%         a different value.
%       By assuming that the insert and delete costs are the same, we have the nice
%       property that the cost for editing LeftString to produce TopString is
%       the same as the cost for editing TopString to produce LeftString.
%
%   Return value:  Tableau, a list of lists.
%     Let T[I,J] be shorthand for lists:nth(J, lists:nth(I, Tableau)).
%     For 0 =< I =< length(LeftString) and 0 =< J =< length(TopString),
%       T[I,J] is the cost for editing lists:sublist(LeftString, I) to
%     lists:sublist(TopString, J).
%       Note that the number of rows in T is one greater than the number
%     of elements in LeftString, and the number of columns in T is one
%     greater than the number of elements in TopString.  That is because
%     the tableau includes the cases for lists:sublist(LeftString, 0) and
%     lists:sublist(TopString, 0).  The top row of the tableau gives the
%     costs for editing the empty string, [], to prefixes of TopString --
%     a sequence of inserts operations.  Likewise, the left column of the
%     tableau corresponds to editing prefixes of LeftString to the empty
%     string.
%       One can construct the optimal sequence of edits for editing
%     LeftString to TopString from the tableau.  Simply start at the final value:
%       lists:nth(length(TopString)+1, lists:nth(length(LeftString)+1, Tableau)).
%     Initially, let I=length(LeftString)+1, and J = length(TopString)+1.
%     If T[I,J] == T[I-1,J] + CostInsDel,
%       then an optimal sequence of edits goes through T[I-1,J] and deletes
%       lists:nth(I-1, LeftString) to the edited string at I-1,J to obtain the
%       edited string at I,J.
%     If T[I,J] == T[I,J-1] + CostInsDel,
%       then an optimal sequence of edits goes through T[I,J-1] and inserts
%       lists:nth(J-1, TopString) to the edited string at I,J-1 to obtain
%       the edited string at I,J.
%     If T[I,J] == T[I-1,J-1] + CostReplace
%       then an optimal sequence of edits goes through T[I-1,J-1] and
%       replaces lists:nth(I-1, LeftString) with lists:nth(J-1, TopString)
%       to obtain the edited string at I,J.
%
%  Examples: try hw5_lib:ed_tab0("hello", "world"), and
%    hw5_lib:ed_tab0("say hello", "to Othello.").
%   If you need more examplse, try more combinations of short strings.
ed_tab0(LeftString, RightString, OpCosts)
    when is_list(LeftString), is_list(RightString), is_tuple(OpCosts) ->
  % See the comments for ed_tab/3 below for a description of why we use
  %   string_to_strcost.
  T = ed_tab(tl(string_to_strcost(LeftString, OpCosts)),
	     string_to_strcost(RightString, OpCosts),
	     OpCosts),
  [strcost_to_costs(Row) || Row <- T].
strcost_to_costs(SC) -> [Cost || {_Char, Cost} <- SC].

ed_tab0(LeftString, RightString) -> ed_tab0(LeftString, RightString, default_op_costs()).


% ed_tab: see the comments above for ed_tab0
%   Parameters:
%     LeftCol = [Left_Hd | Left_Tl] or []:
%       The column of initial values for this tableau.  LeftCol is a list
%       of {Element, Cost} tuples.  These are the elements of LeftString
%       (from ed_tab0) and the initial costs for matching the prefixes of
%       LeftString to the empty prefix of RightString.
%     PrevRow:  The row above this one.  This is a list of {Element, Cost}
%       pairs as described below.
%     OpCosts:  The costs for insert/delete and for replace.
%   Return value: The tableau from (and including) PrevRow through the last row.
%
%  The difference between ed_tab(Left, Right, OpCosts) and ed_tab0(Left, Right, OpCosts)
%  is that ed_tab uses a representation for left and right that zips
%  the elements of the strings with the values of their tableau entries.
%  This is in anticipation of ed_tile below where we divide the tableau
%  into tiles.  The tableau elements for the right column of a tile are the
%  initial values (i.e. the left column) of the adjacent tile to the right.
%  Likewise, the tableau elements for the bottom of a tile are the initial
%  values of the adjacent tile below this one.  Each tile element is of
%  the form {Element, Cost}.  That way, communication between tiles conveys
%  the cost *and* the string element associated with that row or column.
%
%  Example:
%    hw5_lib:ed_tab(
%      hw5_lib:string_to_strcost("hello"),
%      hw5_lib:string_to_strcost("world"),
%      hw5_lib:default_op_costs()).
%    The numbers in the range 100 to 119 in the {Element, Cost} tuples
%    are the ascii values of the characters in the string:
%      $h==108, $e=101, $l=106, $o=111, $r=114, $w=$119.
%    An element of '_' is a marker for the "character" at the beginning of
%    an empty string, e.g. lists:sublist("hello", 0).
%    Compare with hw5_lib:ed_tab0("hello", "world").
ed_tab([Left_Hd | Left_Tl], PrevRow, OpCosts) ->
  ThisRow = ed_row(Left_Hd, PrevRow, OpCosts),
  [ThisRow | ed_tab(Left_Tl, ThisRow, OpCosts)];
ed_tab([], _, _) -> [].


% ed_row({RowChar, LeftCost}, PrevRow, OpCosts)
%   Compute one row of the dynamic programming tableau for editing distance
%   Parameters:
%     RowChar:  The Element of LeftString for this row.
%     LeftCost: The editing cost for the tableau element immediately to the
%                 left of the current one
%     PrevRow:  The previous row.  These are {Element, Cost} tableau entries.
%                 We are sweeping across the rows.  PrevRow "starts" at the
%                 position one above and one to the left of the current
%                 position.  This is needed when computing the cost for a
%                 match (no added cost) or a replacement.
%     OpCosts:  The costs for insert/delete and for replace.
%   Return value: The row from the current position to the end.
ed_row({RowChar, LeftCost},
       [{UpLeftChar, UpLeftCost} | Up_Tl = [{UpChar, UpCost} | _]],
       OpCosts={CostInsDel,CostReplace}) ->
  MyCost = lists:min(
    [ if UpChar == RowChar -> UpLeftCost;
	 true -> UpLeftCost + CostReplace
      end,
      UpCost + CostInsDel,
      LeftCost + CostInsDel ]),
  [   {UpLeftChar, LeftCost}
    | ed_row({RowChar, MyCost}, Up_Tl, OpCosts) ];
ed_row({_, RightCost}, [{RightMostChar,_}], _UpCost) ->
  [{RightMostChar, RightCost}].


% ed_tile(LeftCol, TopRow, OpCost) -> {RightCol, BottomRow}
%   Overview:
%     ed_tile computes a "tile" of the dynamic programming tableau for
%       computing the editing distance between the string represented by
%       LeftCol and the string represented by TopRow.  Both LeftCol and
%       TopRow are lists of tuples of the form {Element, Cost} as described
%       in the comments for ed_row.
%       are segments of longer strings.  Let's call them In1 and In2.
%       We could define strings Prefix1, Suffix1, Prefix2, and Suffix2 such that
%         In1 = Prefix1 ++ LeftString ++ Suffix1, and
%         In2 = Prefix2 ++ S2 ++ Suffix2.
%       Tableau entry T[I,J] is the editing distance from lists:sublist(I, In1) to
%       lists:sublist(J, In2).
%   Parameters:
%     LeftCol:  A list of {Element, Cost} tuples describing the left column of this tile.
%     TopRow:  A list of {Element, Cost} tuples describing the top row of this tile.
%     OpCost: the "costs" for editing operations.
%
%   Result: {RightCol, BottomRow}
%     RightCol and BottomRow are lists of {Element, Cost} tuples.
%
%   Example:
%     hw5_lib:ed_tile(
%       hw5_lib:string_to_strcost("hello"),
%       hw5_lib:string_to_strcost("world"),
%       hw5_lib:default_op_costs()).
%   The numbers in the range 100 to 119 in the {Element, Cost} tuples
%   are the ascii values of the characters in the string:
%     $d==100, $e=101, $h=104, $l=108, $o=111, $r=114, $w=119.
%   An element of '_' is a marker for the "character" at the beginning of
%   an empty string, e.g. lists:sublist("hello", 0).
%   Compare with
%     hw5_lib:ed_tab(
%       hw5_lib:string_to_strcost("hello"),
%       hw5_lib:string_to_strcost("world"),
%       hw5_lib:default_op_costs()).
ed_tile([_LeftCol0 | LeftCol_Tl], TopRow, OpCosts) ->
  ed_tile(LeftCol_Tl, TopRow, OpCosts, [{'_', element(2, lists:last(TopRow))}]).

ed_tile([Left_Hd={LeftChar,_}| Left_Tl], PrevRow, OpCosts, RightColAcc) ->
  ThisRow = ed_row(Left_Hd, PrevRow, OpCosts),
  {_, RightCol} = lists:last(ThisRow),
  ed_tile(Left_Tl, ThisRow, OpCosts, [{LeftChar, RightCol} | RightColAcc]);
ed_tile([], BottomRow, _OpCosts, RightColAcc) ->
  {lists:reverse(RightColAcc), BottomRow}.


string_to_strcost(S, {CostInsDel, _}) ->
  [ {'_', 0} |
    [    {C, I*CostInsDel}
      || {C, I} <- lists:zip(S, lists:seq(1, length(S)))] ].

string_to_strcost(S) -> string_to_strcost(S, default_op_costs()).

default_op_costs() -> {1, 1.5}.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                      %
%  Functions for creating, working with, and destroying chains of      %
%  processes.                                                          %
%                                                                      %
%  Example:                                                            %
%    See chain_demo below.                                             %
%                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% chain_create(NW, Fun) when is_integer(NW), is_function(Fun, 1) -> Chain.
%   Create a chain of NW processes.
%   Each process executes Fun(Chain).
%
% chain_create(Fun, ArgLists) when is_function(Fun), is_list(ArgLists) -> Chain.
%   Create a chain of length(ArgLists) processes.
%   Each element of ArgLists is a list of arguments to Fun.
%   In more detail, process P executes Fun with [Chain | lists:nth(P, ArgLists)]
%   as its argument list.
%
% Return Value:
%   Chain -- an Erlang map used by the other chain_* functions.
% 
% Note: chain_create/2 calls chain_create/3 setting the DebugTimeOut
%   parameter to 5.0 (i.e. seconds)
chain_create(NW, Fun) -> chain_create(NW, Fun, 5.0).

% chain_create(NW, Fun, DebugTimeOut) when is_integer(NW), ... -> Chain.
% chain_create(Fun, ArgLists, DebugTimeOut) when is_function(Fun), ... -> Chain.
%   Like chain_create/2 described above.
%   The DebugTimeOut parameter gives an upper bound on waiting for receive.
%     if is_float(DebugTimeOut) -> DebugTimeOut is in seconds;
%        is_integer(DebugTimeOut) -> DebugTimeOut is in milliseconds.
%     end
%
% Return Value:
%   Chain -- an Erlang map used by the other chain_* functions.
chain_create(NW, Fun, DebugTimeOut)
    when is_integer(NW), NW >= 1, is_function(Fun, 1),
	 is_number(DebugTimeOut), DebugTimeOut >= 0 ->
  chain_create(NW, Fun, undef, DebugTimeOut);
chain_create(Fun, ArgLists, DebugTimeOut)
    when is_function(Fun), is_list(ArgLists), length(ArgLists) >= 1,
	 is_number(DebugTimeOut), DebugTimeOut >= 0 ->
  chain_create(length(ArgLists), Fun, ArgLists, DebugTimeOut).

% chain_create(NW, Fun, ArgLists, DebugTimeOut)  ## not exported
%   Merge the two cases from chain_create/3 into a single function.
%   Spawn the worker processes.
%   Return a Chain object where our next process is the first
%     process of the chain, and our prev process is the last
%     process of the chain.
chain_create(NW, Fun, ArgLists, DebugTimeOut)
    when is_integer(NW), NW >= 1, is_number(DebugTimeOut), DebugTimeOut >= 0,
	 (is_list(ArgLists) andalso length(ArgLists) == NW) orelse ArgLists == undef ->
  % TimeOut is the integer-milliseconds version of DebugTimeOut
  %   because an after clause for receive works on integer milliseconds.
  TimeOut = if is_integer(DebugTimeOut) -> DebugTimeOut;
	       is_float(DebugTimeOut) -> round(1000.0 * DebugTimeOut)
	    end,

  % spawn the chain of processes
  LastPid = chain_create(NW, self(), Fun, ArgLists, TimeOut),

  % connect ourselves to the chain, and return Chain.
  chain_worker(LastPid, TimeOut, fun(Chain) -> Chain end, []).
 

% chain_create(NW, PrevPid, Fun, Args, TimeOut)  ## not exported
%   spawn the worker processes.  Set up their Chain objects.
chain_create(0, LastPid, _, _, _) -> LastPid;
chain_create(NW, PrevPid, Fun, Args, TimeOut) ->
  {Arg_Hd, Arg_Tl} = case Args of
		       [Hd | Tl] -> {Hd, Tl};
		       undef -> {[], undef}
		     end,
  NewPid = spawn(fun() -> chain_worker(PrevPid, TimeOut, Fun, Arg_Hd) end),
  chain_create(NW-1,NewPid, Fun, Arg_Tl, TimeOut).

% chain_exit(Chain)
%   Terminate the processes in a chain.
%   Parameter:
%     Chain:  a chain object.  See chain_create/2 or chain_create/3.
%
%   The worker processes terminate in chain order when each process attempts
%   to receive a message.  I could make a version that kills the processes
%   immediately, but that uses Erlang process management features we haven't
%   described in class or assigned in the readings.
chain_exit(Chain) ->
  FirstProc = maps:get(next, Chain),
  FirstProc ! {self(), exit},
  LastProc = maps:get(prev, Chain),
  TimeOut = maps:get(timeout, Chain),
  receive
    {LastProc, exit} -> ok
  after TimeOut -> timeout
  end.


% chain_worker(PrevPid, TimeOut, Fun, Args)   ## not exported
%   Tell PrevPid who we are -- PrevPid was spawned before we were and they
%     will be delighted to find out that we are their neighbour.
%   Receive a message from our 'next' processes.
%   Now we know all of our neighbours; we can create a Chain map.
%   Call Fun with [Chain | Args] as its argument list.
%   We return the value returned by calling Fun.
%     For most worker processes, this value is silently discarded.
%     But, the master process uses it to get its Chain map.
chain_worker(PrevPid, TimeOut, Fun, Args) ->
  PrevPid ! {self(), chain_next},
  NextPid = receive
    {NPid, chain_next} -> NPid
  after TimeOut ->
    io:format("~w: timeout waiting to receive a message telling me who the next chain-process is." ++
	      "  Good bye.~n",
	      [self()]),
    exit(ok)
  end,
  Chain = #{prev => PrevPid, next => NextPid, timeout => TimeOut},
  apply(Fun, [Chain | Args]).


% chain_send(Chain, Who, What) -> What
%   Send a message to Who.
%   Parameters:
%     Chain:  a Chain object.  See chain_create/2 or chain_create/3
%     Who:    the destination, prev or next.
%     What:   the message to send.
%   Return value:
%     What:   just because that mimics Erlang's ! operator
chain_send(Chain, Who, What)
    when Who==prev; Who==next ->
  Dst = maps:get(Who, Chain),
  Dst ! {self(), chain_msg, What},
  What.

% chain_send(Chain, What) -> What
%   Send a message to the next processor in the chain.
%   Equivalent to chain_send(Chain, next, What).
chain_send(Chain, What) -> chain_send(Chain, next, What).


% chain_receive(Chain, Who) -> ReceivedValue
%   Receive a message from Who.
%   Parameters:
%     Chain:  a Chain object.  See chain_create/2 or chain_create/3.
%     Who:    'prev' or 'next'
%   Return value:
%     The value sent to this process by the specified sender having
%     called chain_send/2 or chain_send/3.
chain_receive(Chain, Who) when Who==prev; Who==next ->
  Src = maps:get(Who, Chain),
  Prev = maps:get(prev, Chain),
  TimeOut = maps:get(timeout, Chain),
  receive
    {Prev, exit} ->
      maps:get(next, Chain) ! {self(), exit},
      exit(ok);
    {Src, chain_msg, What} -> What
  after TimeOut ->
    io:format("~w: timeout while waiting to receive a message from Chain.~w = ~w.~n",
	      [self(), Who, Src]),
    exit(timeout)
  end.

% chain_receive(Chain) -> ReceivedValue
%   Equivalent to chain_receive(Chain, prev).
chain_receive(Chain) -> chain_receive(Chain, prev).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The next four function give a simple demo of working with process chains.
%   chain_worker_demo: operations performed by each process in the chain.
%   chain_demo_do: a utility function for the master process.
%   chain_demo(NW): create a chain of NW processes and perform some simple operations.
%   chain_demo():  shorthand for chain_demo(10).

% chain_demo(NW)
%   Create a Chain on NW processes.  Each worker calls
%     chain_worker_demo(Ch, I) where Ch is the Chain object for the worker
%       and I is a positive integer, that just happens to be the position of
%       the worker in the chain, but I would be happy to change that.
%     Perform three operations with the Chain and print the results:
%       chain_demo_do(Chain, '+', 0): the sum of the worker indices;
%       chain_demo_do(Chain, '*', 0): the product of the worker indices;
%       chain_demo_do(Chain, 'max', 0): the maximum of the worker indices.
chain_demo(NW) when is_integer(NW), NW >= 0 ->
  % Note the [I] -- this is an argument list for chain_worker_demo.
  Chain = chain_create(fun chain_worker_demo/2, [[I] || I <- lists:seq(1, NW)]),

  io:format("sum of first ~b positive integers = ~b~n",
	    [NW, chain_demo_do(Chain, '+', 0)]),
  io:format("~b! = ~b~n",
	    [NW, chain_demo_do(Chain, '*', 1)]),
  io:format("max of first ~b positive integers = ~b~n",
	    [NW, chain_demo_do(Chain, 'max', -1)]),
  chain_exit(Chain).

chain_demo() -> chain_demo(10).


% chain_worker_demo(Chain, I)
%   Each worker in the chain starts with an integer, I.
%   Each worker repeatedly waits to receive an tuple of the form
%   {Op, X} from its predecessor.  It then sends {Op, Op(X, I)}
%   to the next process in the chain.
chain_worker_demo(Chain, I) ->
  {Op, X} = chain_receive(Chain),
  Y = case Op of
	'+' -> X+I;
	'*' -> X*I;
	'max' -> max(X, I)
      end,
  chain_send(Chain, {Op, Y}),
  chain_worker_demo(Chain, I).

% chain_demo_do(Chain, Op, X)
%   Called by the paster process.
%   send {Op, X} to the first worker of the chain,
%   and then receive {Op, Result} from the last worker.
%   Return Result.
chain_demo_do(Chain, Op, X) ->
  chain_send(Chain, {Op, X}),
  element(2, chain_receive(Chain)).

chain_demo2(NW) when is_integer(NW), NW >= 0 ->
  Chain = chain_create(NW, fun chain_worker_demo2/1),

  chain_send(Chain, 0),
  io:format("~w = ~w~n", [chain_receive(Chain), NW]),
  io:format("sum of first ~b positive integers = ~b~n",
	    [NW, chain_demo_do(Chain, '+', 0)]),
  io:format("~b! = ~b~n",
	    [NW, chain_demo_do(Chain, '*', 1)]),
  io:format("max of first ~b positive integers = ~b~n",
	    [NW, chain_demo_do(Chain, 'max', -1)]),
  chain_exit(Chain).

chain_demo2() -> chain_demo2(7).

chain_worker_demo2(Chain) ->
  chain_worker_demo(Chain, chain_send(Chain, 1+chain_receive(Chain))).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

you_need_to_write_this(FunAtom, Args) ->
  io:format("missing implementation for~n" ++
	    "  ~w(~s)~n",
	    [FunAtom, argString(Args)]),
  error(missing_implementation).

argString([]) -> [];
argString([Arg1 | ArgTl]) ->
  [   io_lib:format("~p", [Arg1])
    | [ io_lib:format(", ~p", [Arg]) || Arg <- ArgTl]].
