-module(debug).
-export([start/0]).

start() ->
    X = hw5_lib:ed_seq("hello", "world", hw5_lib:default_op_costs()),
    io:format("Result: ~p~n", [X]),
    X.
