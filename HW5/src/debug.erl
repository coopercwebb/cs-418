-module(debug).
-export([start/0]).

start() ->
    X = hw5_lib:ed_seq("hello", "world", hw5_lib:default_op_costs()),
    Y = hw5:ed_par("hello", "world", 3, 3),
    io:format("Result: ~p~n", [Y]),
    X.
