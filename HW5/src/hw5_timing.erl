-module(hw5_timing).

-export([ed_timing_suite_length/0, ed_timing_suite_tilesize/0]).

% Claude 4.5 generated timing suite (edited)
ed_timing_suite_length() ->
    io:format("~n=== Test 1: Short strings (5 chars) ===~n"),
    S1 = "hello",
    S2 = "world",
    ed_par_timing_measurements(S1, S2, 3, ed_seq_timing_measurements(S1, S2)),

    io:format("~n=== Test 2: Medium strings (100 chars) ===~n"),
    S100a = lists:duplicate(100, $a),
    S100b = lists:duplicate(100, $b),
    ed_par_timing_measurements(S100a, S100b, 10, ed_seq_timing_measurements(S100a, S100b)),

    io:format("~n=== Test 3: Longer strings (500 chars) ===~n"),
    S500a = lists:duplicate(500, $a),
    S500b = lists:duplicate(500, $b),
    ed_par_timing_measurements(S500a, S500b, 20, ed_seq_timing_measurements(S500a, S500b)),

    io:format("~n=== Test 4: Long strings (1000 chars) ===~n"),
    S1000a = lists:duplicate(1000, $a),
    S1000b = lists:duplicate(1000, $b),
    ed_par_timing_measurements(S1000a, S1000b, 50, ed_seq_timing_measurements(S1000a, S1000b)),

    io:format("~n=== Test 5: Very long strings (2000 chars) ===~n"),
    S2000a = lists:duplicate(2000, $a),
    S2000b = lists:duplicate(2000, $b),
    ed_par_timing_measurements(S2000a, S2000b, 100, ed_seq_timing_measurements(S2000a, S2000b)),

    io:format("~n=== Test 6: Ext long strings (5000 chars) ===~n"),
    S5000a = lists:duplicate(5000, $a),
    S5000b = lists:duplicate(5000, $b),
    ed_par_timing_measurements(S5000a, S5000b, 100, ed_seq_timing_measurements(S5000a, S5000b)),

    io:format("~n=== Timing suite complete ===~n"),
    ok.

ed_timing_suite_tilesize() ->
    S5000a = lists:duplicate(5000, $a),
    S5000b = lists:duplicate(5000, $b),

    io:format("~n=== Testing with 5000 char strings, varied tilewidth ===~n"),

    io:format("~n=== Test 0: BENCHMARK (SEQUENTIAL) ===~n"),
    SeqMean = ed_seq_timing_measurements(S5000a, S5000b),

    io:format("~n=== Test 1: Tile Width 2 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 2, SeqMean),

    io:format("~n=== Test 2: Tile Width 5 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 5, SeqMean),

    io:format("~n=== Test 3: Tile Width 10 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 10, SeqMean),

    io:format("~n=== Test 4: Tile Width 20 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 20, SeqMean),

    io:format("~n=== Test 5: Tile Width 40 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 40, SeqMean),

    io:format("~n=== Test 6: Tile Width 80 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 80, SeqMean),

    io:format("~n=== Test 7: Tile Width 160 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 160, SeqMean),

    io:format("~n=== Test 8: Tile Width 250 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 250, SeqMean),

    io:format("~n=== Test 9: Tile Width 500 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 500, SeqMean),

    io:format("~n=== Test 10: Tile Width 1000 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 1000, SeqMean),

    io:format("~n=== Test 11: Tile Width 2500 ===~n"),
    ed_par_timing_measurements(S5000a, S5000b, 2500, SeqMean),

    io:format("~n=== Timing suite complete ===~n"),

    ok.

% Returns SeqMean from sequential timing
% Runs exactly 10 times to get proper statistics
ed_seq_timing_measurements(S1, S2) ->
    NumRuns = 10,
    Seq = time_it:t(fun() -> hw5_lib:ed_seq(S1, S2, hw5_lib:default_op_costs()) end, NumRuns),
    SeqMean = proplists:get_value(mean, Seq),
    SeqStd = proplists:get_value(std, Seq),
    io:format("Sequential (n=~p): mean = ~.6f s", [NumRuns, SeqMean]),
    case SeqStd of
        undefined -> io:format(" (std = N/A)~n");
        _ -> io:format(", std = ~.6f s~n", [SeqStd])
    end,
    SeqMean.

% String 1, String 2, TileSize (Generates NW based on String1 length)
% Testing the most optimal case - square grid, square tiles
% Runs exactly 10 times to get proper statistics
ed_par_timing_measurements(S1, S2, TileSize, SeqMean) ->
    NumRuns = 10,
    NW = ceil(length(S1) / TileSize),
    io:format("Workers (NW): ~p~n", [NW]),
    Par = time_it:t(fun() -> hw5:ed_par(S1, S2, NW, TileSize) end, NumRuns),
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
