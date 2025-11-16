-module(hw5).

% for Q2, dynamic programming
-export([ed_par/4, ed_par/5]).

% exports below are for Q3, Sorting on a Linear Array
-export([bubble/1, odd_even/1, sort/2]).
-export([bubble_test/1, odd_even_test/1, sort_test/2]).
-export([sortv/1, sortv/2, ik/1, ijk/1]).

-include_lib("eunit/include/eunit.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
% Functions for Q2, Dynamic Programming                                    %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% My solution uses the commented-out imports from hw5_lib.
% You are likely to want them as well.
% As usual, you do not need to write the you_need_to_write_this/3 function.
%   In fact, you should not modify hw5_lib.erl.  We will test your code using
%   the supplied version.  You should find calls to you_need_to_write_this
%   in this template file and replace them with your solution.
-import(
    hw5_lib,
    [
        you_need_to_write_this/2,
        string_to_strcost/2,
        ed_tile/3,
        default_op_costs/0,
        chain_create/2,
        chain_exit/1,
        chain_send/2,
        chain_receive/1
    ]
).

ed_par(S1, S2, NW, TileWidth) ->
    ed_par(S1, S2, default_op_costs(), NW, TileWidth).

% ed_par(S1, S2, OpCosts, NW, TileWidth) -> EditDistance
ed_par(S1, S2, OpCosts, NW, TileWidth) when
    is_list(S1),
    is_list(S2),
    is_integer(NW),
    NW >= 1,
    is_integer(TileWidth),
    TileWidth >= 1
->
    % Ensure the chain is not longer than length(S1)
    % As this implementation is dependent on breaking the grid into rows for workers
    TileHeight = min(ceil(length(S1) / NW), length(S1)),
    LeftCol = segment_list(string_to_strcost(S1, OpCosts), TileHeight + 1),
    TopRow = segment_list(string_to_strcost(S2, OpCosts), TileWidth + 1),
    % Initialize Chain to size length(LefCol) in case
    % there were more workers specified than potential tile rows
    Chain = chain_create(length(LeftCol), fun chain_worker_init/1),
    % initialize the chain with opcosts and there respective LeftCol
    chain_send(Chain, {OpCosts, LeftCol}),
    chain_send_master(Chain, TopRow),
    chain_exit(Chain),
    chain_receive_master(Chain, length(TopRow)).

% Sends the top row of the grid to the first worker (in tiled chunks)
chain_send_master(_Chain, []) ->
    ok;
chain_send_master(Chain, [TopRow_Hd | TopRow_Tl]) ->
    chain_send(Chain, TopRow_Hd),
    chain_send_master(Chain, TopRow_Tl).

% Receive length of TopRow (# of tile cols) messages from last worker
% Only the final message contains the ed_tile bottom row result
% from the bottom right of the grid...
% This contains final value (last element of list - tuple element 2).
chain_receive_master(Chain, 1) ->
    % return last element of list, second element of tuple
    element(2, lists:last(chain_receive(Chain)));
chain_receive_master(Chain, X) ->
    chain_receive(Chain),
    chain_receive_master(Chain, X - 1).

% Claude 4.5 generated helper
% creates overlapping segments (size 1 overlap)
segment_list(List, Size) when length(List) =< Size ->
    [List];
segment_list([_ | _] = List, Size) ->
    Segment = lists:sublist(List, Size),
    Rest = lists:nthtail(Size - 1, List),
    [Segment | segment_list(Rest, Size)].

% Receive OpCosts and LeftCol from Chain prev
chain_worker_init(Chain) ->
    {OpCosts, LeftCol} = chain_receive(Chain),
    chain_worker_init_helper(Chain, OpCosts, LeftCol).

% Last worker in chain, do not send info back to master
% Stops the master from blocking
chain_worker_init_helper(Chain, OpCosts, [LeftCol_Hd]) ->
    chain_worker_stable(Chain, OpCosts, LeftCol_Hd);
% More workers in the chain, pass along LeftCol_Tl
chain_worker_init_helper(Chain, OpCosts, [LeftCol_Hd | LeftCol_Tl]) ->
    chain_send(Chain, {OpCosts, LeftCol_Tl}),
    chain_worker_stable(Chain, OpCosts, LeftCol_Hd).

% Worker awaits Chain prev's bottom row (the workers TopRow...)
% Once it receives it it calcs {RightCol, BottomRow},
% communicates with chain next, then finally recurses along its row
chain_worker_stable(Chain, OpCosts, LeftCol) ->
    TopRow = chain_receive(Chain),
    {RightCol, BottomRow} = ed_tile(LeftCol, TopRow, OpCosts),
    chain_send(Chain, BottomRow),
    chain_worker_stable(Chain, OpCosts, RightCol).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
% EUnit Tests for Q2 - Edit Distance Parallel vs Sequential               %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Partially generated Claude4.5 Eunit test cases
% Test that parallel and sequential versions produce the same result
ed_par_test_() ->
    [
        {"Short strings - hello/world",
            ?_test(begin
                Seq = hw5_lib:ed_seq("hello", "world", default_op_costs()),
                Par = ed_par("hello", "world", 2, 3),
                ?assertEqual(Seq, Par)
            end)},

        {"Short strings - hello/world - TileWidth 1, NW 1",
            ?_test(begin
                Seq = hw5_lib:ed_seq("hello", "world", default_op_costs()),
                Par = ed_par("hello", "world", 1, 1),
                ?assertEqual(Seq, Par)
            end)},

        {"Short strings - hello/world - TileWidth greater than S2 length",
            ?_test(begin
                Seq = hw5_lib:ed_seq("hello", "world", default_op_costs()),
                Par = ed_par("hello", "world", 1, 10),
                ?assertEqual(Seq, Par)
            end)},

        {"Short strings - hello/world - NW greater than S1 length",
            ?_test(begin
                Seq = hw5_lib:ed_seq("hello", "world", default_op_costs()),
                Par = ed_par("hello", "world", 10, 1),
                ?assertEqual(Seq, Par)
            end)},

        {"Short strings - hello/world - NW greater than S1 length and TileWidth greater than S2 length",
            ?_test(begin
                Seq = hw5_lib:ed_seq("hello", "world", default_op_costs()),
                Par = ed_par("hello", "world", 10, 10),
                ?assertEqual(Seq, Par)
            end)},

        {"Medium strings - 100 chars",
            ?_test(begin
                S1 = lists:duplicate(100, $a),
                S2 = lists:duplicate(100, $b),
                Seq = hw5_lib:ed_seq(S1, S2, default_op_costs()),
                Par = ed_par(S1, S2, 10, 10),
                ?assertEqual(Seq, Par)
            end)},

        {"Longer strings - 500 chars",
            ?_test(begin
                S1 = lists:duplicate(500, $a),
                S2 = lists:duplicate(500, $b),
                Seq = hw5_lib:ed_seq(S1, S2, default_op_costs()),
                Par = ed_par(S1, S2, 25, 20),
                ?assertEqual(Seq, Par)
            end)},

        {"Different tile sizes - 100 chars, tile 5",
            ?_test(begin
                S1 = lists:duplicate(100, $a),
                S2 = lists:duplicate(100, $b),
                Seq = hw5_lib:ed_seq(S1, S2, default_op_costs()),
                Par = ed_par(S1, S2, 20, 5),
                ?assertEqual(Seq, Par)
            end)},

        {"Different tile sizes - 100 chars, tile 20",
            ?_test(begin
                S1 = lists:duplicate(100, $a),
                S2 = lists:duplicate(100, $b),
                Seq = hw5_lib:ed_seq(S1, S2, default_op_costs()),
                Par = ed_par(S1, S2, 5, 20),
                ?assertEqual(Seq, Par)
            end)},

        {"Different worker counts - 200 chars, 4 workers",
            ?_test(begin
                S1 = lists:duplicate(200, $a),
                S2 = lists:duplicate(200, $b),
                Seq = hw5_lib:ed_seq(S1, S2, default_op_costs()),
                Par = ed_par(S1, S2, 4, 50),
                ?assertEqual(Seq, Par)
            end)},

        {"Different worker counts - 200 chars, 10 workers",
            ?_test(begin
                S1 = lists:duplicate(200, $a),
                S2 = lists:duplicate(200, $b),
                Seq = hw5_lib:ed_seq(S1, S2, default_op_costs()),
                Par = ed_par(S1, S2, 10, 20),
                ?assertEqual(Seq, Par)
            end)}
    ].

% My code also has:
% ed_worker(Chain, LeftCol, OpCosts) -> ...
%   It's four lines of code.

% I wrote one more helper function.  Five lines of code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                          %
% Functions for Q3, Sorting on a Linear Array                              %
%   bubble(N): generate a sorting network for bubble-sort with N inputs    %
%                                                                          %
%   odd_even(N): generate a sorting network for odd-even exchange sort     %
%     with N inputs.                                                       %
%                                                                          %
%   sort(SortNet, Data): sort Data using the SortNet sorting network.      %
%                                                                          %
%   sort_test(SortNetFun, N): test the sorting network generated by        %
%       SortNetFun(N).                                                     %
%     Functions related to testing:                                        %
%        try_these() -> [0, 1, 2, 3, 5, 6, 100, 101],                      %
%          values for N for testing sorting networks.                      %
%        bubble_test(): test the bubble-sort network for each of the       %
%          values for N from try_these().                                  %
%        odd-even(): test the odd-even exchange  network for each of the   %
%          values for N from try_these().                                  %
%                                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% bubble(N) -> SortingNetwork
% Generate a sorting network for bubble-sort with N inputs.
%   SortingNetwork is a nested-list of tuples.
%   This represents the sorting network that is obtained by starting with the identity network
%     (i.e. with no compare-and-swap element), and then appending compare-and-swap elements in
%     the order they appear in lists:flatten(bubble(N)).
%   Each compare and swap element is represented by a tuple, {I,J}.
%     This inputs values from the I^th and J^th "line" of the sorting network and
%     The min of these two elements is output on line I, and the max is output on line J.
%     Note that you can flip the orientation of a compare-and-swap module by flipping I and J in the tuple.
%   Example:
%    hw5:bubble(5) -> % Bubble-sort network from the figure in the hw5.pdf
%       [[{0,1}],
%        [{1,2}],
%        [{0,1},{2,3}],
%        [{1,2},{3,4}],
%        [{0,1},{2,3}],
%        [{1,2}],
%        [{0,1}]]
%
%   Why did I use a nested-list (aka. a "deep list")?
%     Because I want to make the homework easy.
%     Each sublist corresponds to a set of compare-and-swap elements of the same "color" in
%     the figures in hw5.pdf.
bubble(N) when is_integer(N), 2 =< N ->
    [
        [{J, J + 1} || J <- lists:seq(I rem 2, I, 2)]
     || I <- lists:seq(0, N - 2) ++ lists:seq(N - 3, 0, -1)
    ];
bubble(N) when is_integer(N), 0 =< N -> [].

% odd_even(N) -> SortingNetwork
% Generate a sorting network for odd-even transposition sort with N inputs.
%   See the comment for bubble(N) for a description of SortingNetwork.
%   Example:
%     hw5:odd_even(5) -> % Network 2 from the figure in the hw5.pdf
%     [[{0,1},{2,3}],
%      [{1,2},{3,4}],
%      [{0,1},{2,3}],
%      [{1,2},{3,4}],
%      [{0,1},{2,3}]]
odd_even(N) when is_integer(N), 2 =< N ->
    [
        [{J, J + 1} || J <- lists:seq(I rem 2, N - 2, 2)]
     || I <- lists:seq(0, N - 1)
    ];
odd_even(N) when is_integer(N), 0 =< N -> [].

% sort(SortNet, Data) -> SortedData
%   Parameters:
%     SortNet is a sorting network represented as a nested list of tuples.
%       See the comments for bubble(N) to get a description of this representation.
%     Data is a list of data values to be sorted.
%       The length of Data must match the number of inputs to SortNet.
%       We don't check this.  You'll get an exception or garbage if your data
%       doesn't match the size of SortNet.
%
%   Result:
%     SortedData: the same values as Data but sorted into ascending order.
sort(SortNet, []) when is_list(SortNet) -> [];
sort(SortNet, Data) when is_list(SortNet), is_list(Data) ->
    N = length(Data),
    {_, Sorted} =
        lists:unzip(
            % sorting by index in the Map
            lists:sort(
                maps:to_list(
                    lists:foldl(
                        fun({I, J}, M) ->
                            A = maps:get(I, M),
                            B = maps:get(J, M),
                            maps:put(I, min(A, B), maps:put(J, max(A, B), M))
                        end,
                        maps:from_list([{I, D} || {I, D} <- lists:zip(lists:seq(0, N - 1), Data)]),
                        lists:flatten(SortNet)
                    )
                )
            )
        ),
    Sorted.

% A few simple tests for bubble, odd_even, and sort.
try_these() -> [0, 1, 2, 3, 5, 6, 100, 101].
bubble_test() -> [bubble_test(N) || N <- try_these()].
bubble_test(N) -> sort_test(fun ?MODULE:bubble/1, N).
odd_even_test() -> [odd_even_test(N) || N <- try_these()].
odd_even_test(N) -> sort_test(fun ?MODULE:odd_even/1, N).

sort_test(SortNetFun, N) ->
    SortNet = SortNetFun(N),
    Random = misc:rlist(N, round(math:pow(10, ceil(1.5 * math:log10(max(N, 2)))))),
    Sorted = sort(SortNet, Random),
    ?assertEqual(lists:sort(Random), Sorted).

% A version of sort that prints the output after each batch of compare-and-swap operations.
sortv(SortNet, Data) -> sortv(SortNet, Data, 0).

% sortv(Data): use odd-even transposition sort as the default sorting algorithm
sortv(Data) -> sortv(odd_even(length(Data)), Data).

% sortv(SortNet, Data, J) -> SortedData
%   Print data for the output of column 0 of compare and swaps.
%   If there are more columns, compute the output of the next column and recurse.
%   Return the output of the final column.
sortv([], Data, J) ->
    io:format("J =~2b:  ~s~n", [J, show_data(Data, J)]),
    Data;
sortv([SortHd | SortTl], Data, J) ->
    io:format("J =~2b:  ~s~n", [J, show_data(Data, J)]),
    sortv(SortTl, sort(SortHd, Data), J + 1).

show_data([], _) ->
    "[]";
show_data(Data = [_], _) ->
    io_lib:format("~p", [Data]);
show_data(Data = [_ | _], J) ->
    % $[,
    [
        [
            io_lib:format(
                "~s~w",
                [
                    if
                        (I rem 2) == (J rem 2) -> "|";
                        I == 0 -> " ";
                        true -> ","
                    end,
                    D
                ]
            )
         || {I, D} <- lists:zip(lists:seq(0, length(Data) - 1), Data)
        ],
        if
            (J rem 2) == 0 -> "|";
            (J rem 2) == 1 -> " "
        end
        % , $]
    ].

ik(Data) ->
    [I || {I, D} <- lists:zip(lists:seq(0, length(Data) - 1), Data), D == 0].

ijk(Data) -> ijk(odd_even(length(Data)), Data, 0).

ijk([], Data, J) ->
    io:format("J =~2b: i_{j,k} = ~w~n", [J, ik(Data)]),
    Data;
ijk([SortHd | SortTl], Data, J) ->
    io:format("J =~2b: i_{j,k} = ~w~n", [J, ik(Data)]),
    ijk(SortTl, sort(SortHd, Data), J + 1).
