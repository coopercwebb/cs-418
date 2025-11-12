-module(hw5_timing).

-export([ed_timing_suite_length/0, ed_timing_suite_tilesize/0]).
-export([ed_timing_measurements/3]).

% Claude 4.5 generated timing suite (edited)
ed_timing_suite_length() ->
    io:format("~n=== Test 1: Short strings (5 chars) ===~n"),
    ed_timing_measurements("hello", "world", 3),

    io:format("~n=== Test 2: Medium strings (100 chars) ===~n"),
    S100 = lists:duplicate(100, $a),
    ed_timing_measurements(S100, lists:duplicate(100, $b), 10),

    io:format("~n=== Test 3: Longer strings (500 chars) ===~n"),
    S500 = lists:duplicate(500, $a),
    ed_timing_measurements(S500, lists:duplicate(500, $b), 20),

    io:format("~n=== Test 4: Long strings (1000 chars) ===~n"),
    S1000 = lists:duplicate(1000, $a),
    ed_timing_measurements(S1000, lists:duplicate(1000, $b), 50),

    io:format("~n=== Test 5: Very long strings (2000 chars) ===~n"),
    S2000 = lists:duplicate(2000, $a),
    ed_timing_measurements(S2000, lists:duplicate(2000, $b), 100),

    io:format("~n=== Test 6: Ext long strings (5000 chars) ===~n"),
    S5000 = lists:duplicate(5000, $a),
    ed_timing_measurements(S5000, lists:duplicate(5000, $b), 100),

    io:format("~n=== Timing suite complete ===~n"),
    ok.

ed_timing_suite_tilesize() ->
    S5000a = lists:duplicate(5000, $a),
    S5000b = lists:duplicate(5000, $b),

    io:format("~n=== Testing with 5000 char strings, varied tilewidth ===~n"),
    io:format("~n=== Test 1: Tile Width 2 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 2),

    io:format("~n=== Test 2: Tile Width 5 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 5),

    io:format("~n=== Test 3: Tile Width 10 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 10),

    io:format("~n=== Test 4: Tile Width 20 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 20),

    io:format("~n=== Test 5: Tile Width 40 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 40),

    io:format("~n=== Test 6: Tile Width 80 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 80),

    io:format("~n=== Test 7: Tile Width 160 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 160),

    io:format("~n=== Test 8: Tile Width 250 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 250),

    io:format("~n=== Test 9: Tile Width 500 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 500),

    io:format("~n=== Test 10: Tile Width 1000 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 1000),

    io:format("~n=== Test 11: Tile Width 2500 ===~n"),
    ed_timing_measurements(S5000a, S5000b, 2500),

    io:format("~n=== Timing suite complete ===~n"),
    ok.

% String 1, String 2, TileSize (Generates NW based on String1 length)
% Testing the most optimal case - square grid, square tiles
ed_timing_measurements(S1, S2, TileSize) ->
    Seq = time_it:t(fun() -> hw5_lib:ed_seq(S1, S2, hw5_lib:default_op_costs()) end),
    NW = ceil(length(S1) / TileSize),
    Par = time_it:t(fun() -> hw5:ed_par(S1, S2, NW, TileSize) end),
    SeqMean = proplists:get_value(mean, Seq),
    SeqStd = proplists:get_value(std, Seq),
    io:format("Sequential: mean = ~.6f s", [SeqMean]),
    case SeqStd of
        undefined -> io:format(" (std = N/A)~n");
        _ -> io:format(", std = ~.6f s~n", [SeqStd])
    end,
    ParMean = proplists:get_value(mean, Par),
    ParStd = proplists:get_value(std, Par),
    io:format("Parallel: mean = ~.6f s", [ParMean]),
    case ParStd of
        undefined -> io:format(" (std = N/A)~n");
        _ -> io:format(", std = ~.6f s~n", [ParStd])
    end,
    Speedup = SeqMean / ParMean,
    io:format("Speedup: ~.2fx~n", [Speedup]),
    ok.
