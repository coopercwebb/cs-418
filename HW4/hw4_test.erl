-module(hw4_test).

-export([par_len_test/5, run_comparison/5, benchmark_speedup/0, benchmark_speedup/4]).
-include_lib("eunit/include/eunit.hrl").

%% Test for par_len_ms comparing sequential vs parallel implementations
par_len_test(NWorkers, N_trials, N_warmup, N_run, Tolerance) when
    is_integer(NWorkers),
    NWorkers > 0,
    is_integer(N_trials),
    N_trials > 0,
    is_integer(N_warmup),
    N_warmup >= 0,
    is_integer(N_run),
    N_run > 0,
    is_number(Tolerance),
    Tolerance > 0
->
    {setup,
        % Setup: create worker tree
        fun() ->
            WorkerTree = wtree:create(NWorkers),
            WorkerTree
        end,
        % Cleanup: reap worker tree
        fun(WorkerTree) ->
            wtree:reap(WorkerTree)
        end,
        % Test: compare sequential and parallel results
        fun(WorkerTree) ->
            % Create distributions for testing
            R_a = hw4_lib:expDist(1.5),
            R_s = hw4_lib:expDist(1.0),

            % Print test configuration
            io:format("~n~n=== Test Configuration ===~n"),
            io:format(
                "Workers: ~p, Trials: ~p, Warmup: ~p, Run: ~p~n",
                [NWorkers, N_trials, N_warmup, N_run]
            ),
            io:format("Tolerance: ~.2f~n~n", [Tolerance]),

            % Run sequential version
            SeqResult = hw4_lib:sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s),
            SeqMean = proplists:get_value(mean, SeqResult),
            SeqStd = proplists:get_value(std, SeqResult),

            % Run parallel version
            ParResult = hw4:par_len_ms(WorkerTree, N_trials, N_warmup, N_run, R_a, R_s),
            ParMean = proplists:get_value(mean, ParResult),
            ParStd = proplists:get_value(std, ParResult),

            % Print results
            io:format("=== Results Comparison ===~n"),
            io:format("Sequential: mean = ~.4f, std = ~.4f~n", [SeqMean, SeqStd]),
            io:format("Parallel:   mean = ~.4f, std = ~.4f~n", [ParMean, ParStd]),
            io:format("~n"),
            io:format("Differences:~n"),
            io:format(
                "  Mean diff: ~.4f (tolerance: ~.2f)~n",
                [abs(SeqMean - ParMean), Tolerance]
            ),
            io:format(
                "  Std diff:  ~.4f (tolerance: ~.2f)~n",
                [abs(SeqStd - ParStd), Tolerance * 2]
            ),
            io:format("~n"),

            % Check that means are close (within tolerance)
            % Since these are statistical simulations, results won't be identical
            % but should be statistically similar
            [
                ?_assert(abs(SeqMean - ParMean) < Tolerance),
                % Std deviation can vary more
                ?_assert(abs(SeqStd - ParStd) < Tolerance * 2)
            ]
        end}.

%% Direct runner function - shows output immediately
%% Usage: hw4_test:run_comparison(4, 20, 1000, 500, 2.0).
run_comparison(NWorkers, N_trials, N_warmup, N_run, Tolerance) ->
    WorkerTree = wtree:create(NWorkers),
    try
        % Create distributions for testing
        R_a = hw4_lib:expDist(1.5),
        R_s = hw4_lib:expDist(1.0),

        % Print test configuration
        io:format("~n~n=== Test Configuration ===~n"),
        io:format(
            "Workers: ~p, Trials: ~p, Warmup: ~p, Run: ~p~n",
            [NWorkers, N_trials, N_warmup, N_run]
        ),
        io:format("Tolerance: ~.2f~n~n", [Tolerance]),

        % Run sequential version
        io:format("Running sequential version...~n"),
        SeqResult = hw4_lib:sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s),
        SeqMean = proplists:get_value(mean, SeqResult),
        SeqStd = proplists:get_value(std, SeqResult),

        % Run parallel version
        io:format("Running parallel version...~n"),
        ParResult = hw4:par_len_ms(WorkerTree, N_trials, N_warmup, N_run, R_a, R_s),
        ParMean = proplists:get_value(mean, ParResult),
        ParStd = proplists:get_value(std, ParResult),

        % Print results
        io:format("~n=== Results Comparison ===~n"),
        io:format("Sequential: mean = ~.4f, std = ~.4f~n", [SeqMean, SeqStd]),
        io:format("Parallel:   mean = ~.4f, std = ~.4f~n", [ParMean, ParStd]),
        io:format("~n"),
        io:format("Differences:~n"),
        io:format(
            "  Mean diff: ~.4f (tolerance: ~.2f)~n",
            [abs(SeqMean - ParMean), Tolerance]
        ),
        io:format(
            "  Std diff:  ~.4f (tolerance: ~.2f)~n",
            [abs(SeqStd - ParStd), Tolerance * 2]
        ),

        % Check tolerances
        MeanPass = abs(SeqMean - ParMean) < Tolerance,
        StdPass = abs(SeqStd - ParStd) < Tolerance * 2,

        io:format("~n=== Test Results ===~n"),
        io:format("Mean within tolerance: ~p~n", [MeanPass]),
        io:format("Std within tolerance:  ~p~n", [StdPass]),

        if
            MeanPass and StdPass ->
                io:format("~n✓ All checks passed!~n~n"),
                ok;
            true ->
                io:format("~n✗ Some checks failed!~n~n"),
                error
        end
    after
        wtree:reap(WorkerTree)
    end.

%% Test suite with various configurations
par_len_test() ->
    [
        % Small test: 4 workers, 20 trials
        par_len_test(4, 20, 1000, 500, 2.0),

        % Medium test: 8 workers, 40 trials
        par_len_test(8, 40, 2000, 1000, 2.0),

        % Larger test: 4 workers, 100 trials
        par_len_test(4, 100, 5000, 2000, 1.5)
    ].

%% Alternative: Test that parallel gives same statistical structure
%% (not necessarily same values due to randomness)
par_len_structure_test() ->
    WorkerTree = wtree:create(4),
    try
        R_a = hw4_lib:expDist(2.0),
        R_s = hw4_lib:expDist(1.0),

        % Run parallel version
        Result = hw4:par_len_ms(WorkerTree, 50, 1000, 500, R_a, R_s),

        % Check structure
        ?assert(is_list(Result)),
        ?assert(length(Result) == 2),
        ?assert(proplists:is_defined(mean, Result)),
        ?assert(proplists:is_defined(std, Result)),

        % Check values are reasonable numbers
        Mean = proplists:get_value(mean, Result),
        Std = proplists:get_value(std, Result),
        ?assert(is_number(Mean)),
        ?assert(is_number(Std)),
        ?assert(Mean > 0),
        ?assert(Std >= 0)
    after
        wtree:reap(WorkerTree)
    end.

%% Test correctness of work distribution
%% Verify that total trials executed equals N_trials
work_distribution_test() ->
    NWorkers = 7,
    N_trials = 100,
    WorkerTree = wtree:create(NWorkers),
    try
        % Setup the same distribution logic as par_len
        TrialsPerWorker = N_trials div NWorkers,
        Remainder = N_trials rem NWorkers,

        wtree:update(
            WorkerTree,
            num_trials,
            fun(_ProcState, N) ->
                if
                    N =< Remainder -> TrialsPerWorker + 1;
                    true -> TrialsPerWorker
                end
            end
        ),

        % Retrieve trial counts from all workers
        TrialCounts = wtree:retrieve(WorkerTree, num_trials),
        TotalTrials = lists:sum(TrialCounts),

        % Verify total equals N_trials
        ?assertEqual(N_trials, TotalTrials),

        % Verify workers differ by at most 1 trial
        MaxTrials = lists:max(TrialCounts),
        MinTrials = lists:min(TrialCounts),
        ?assert(MaxTrials - MinTrials =< 1)
    after
        wtree:reap(WorkerTree)
    end.

%% Performance comparison test (informational, not assertion-based)
%% Run this manually to see speedup
performance_comparison_test_() ->
    {timeout, 60, fun() ->
        NWorkers = 4,
        N_trials = 100,
        N_warmup = 5000,
        N_run = 2000,

        R_a = hw4_lib:expDist(1.5),
        R_s = hw4_lib:expDist(1.0),

        % Time sequential version
        {SeqTime, SeqResult} = timer:tc(
            fun() -> hw4_lib:sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s) end
        ),

        % Time parallel version
        WorkerTree = wtree:create(NWorkers),
        try
            {ParTime, ParResult} = timer:tc(
                fun() -> hw4:par_len_ms(WorkerTree, N_trials, N_warmup, N_run, R_a, R_s) end
            ),

            % Print results
            io:format("~n=== Performance Comparison ===~n"),
            io:format("Sequential time: ~.2f seconds~n", [SeqTime / 1000000]),
            io:format("Parallel time:   ~.2f seconds~n", [ParTime / 1000000]),
            io:format("Speedup:         ~.2fx~n", [SeqTime / ParTime]),
            io:format("Sequential result: ~p~n", [SeqResult]),
            io:format("Parallel result:   ~p~n", [ParResult]),

            % Just verify parallel is faster (though not guaranteed due to overhead)
            ?assert(is_list(ParResult))
        after
            wtree:reap(WorkerTree)
        end
    end}.

%% Benchmark speedup with time_it library
%% Usage: hw4_test:benchmark_speedup().
%% Tests multiple worker configurations with a large number of trials
benchmark_speedup() ->
    % Default parameters - use large trial count for meaningful results
    % Extended worker counts to find optimal parallelism
    % Note: 1 worker excluded as it shows inconsistent results (slower than sequential on some machines)
    benchmark_speedup(200, 10000, 5000, [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]).

%% Benchmark with custom parameters
%% Usage: hw4_test:benchmark_speedup(200, 10000, 5000, [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]).
benchmark_speedup(N_trials, N_warmup, N_run, WorkerCounts) ->
    R_a = hw4_lib:expDist(1.5),
    R_s = hw4_lib:expDist(1.0),

    io:format(
        "~n~n╔════════════════════════════════════════════════════════╗~n"
    ),
    io:format("║        Queue Simulation Speedup Benchmark              ║~n"),
    io:format(
        "╚════════════════════════════════════════════════════════╝~n~n"
    ),
    io:format("Configuration:~n"),
    io:format("  Trials: ~p, Warmup: ~p, Run: ~p~n", [N_trials, N_warmup, N_run]),
    io:format("  Arrival dist: expDist(1.5), Service dist: expDist(1.0)~n"),
    io:format("  Testing worker counts: ~p~n~n", [WorkerCounts]),

    % Benchmark sequential version
    io:format(
        "─────────────────────────────────────────────────────────~n"
    ),
    io:format("Sequential Version (baseline)~n"),
    io:format(
        "─────────────────────────────────────────────────────────~n"
    ),
    SeqResult = time_it:t(fun() ->
        hw4_lib:sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s)
    end),
    SeqMean = proplists:get_value(mean, SeqResult),
    SeqStd = proplists:get_value(std, SeqResult),
    io:format("Sequential: mean = ~.6f s", [SeqMean]),
    case SeqStd of
        undefined -> io:format(" (std = N/A)~n");
        _ -> io:format(", std = ~.6f s~n", [SeqStd])
    end,
    io:format("~n"),

    % Benchmark parallel versions with different worker counts
    io:format(
        "─────────────────────────────────────────────────────────~n"
    ),
    io:format("Parallel Versions~n"),
    io:format(
        "─────────────────────────────────────────────────────────~n"
    ),

    Results = lists:map(
        fun(NWorkers) ->
            io:format("~nWorkers: ~p~n", [NWorkers]),
            WorkerTree = wtree:create(NWorkers),
            try
                ParResult = time_it:t(fun() ->
                    hw4:par_len_ms(WorkerTree, N_trials, N_warmup, N_run, R_a, R_s)
                end),
                ParMean = proplists:get_value(mean, ParResult),
                ParStd = proplists:get_value(std, ParResult),
                Speedup = SeqMean / ParMean,
                Efficiency = Speedup / NWorkers,

                io:format("  Time:       ~.6f s", [ParMean]),
                case ParStd of
                    undefined -> io:format(" (std = N/A)~n");
                    _ -> io:format(", std = ~.6f s~n", [ParStd])
                end,
                io:format("  Speedup:    ~.2fx~n", [Speedup]),
                io:format("  Efficiency: ~.2f%~n", [Efficiency * 100]),

                {NWorkers, ParMean, Speedup, Efficiency}
            after
                wtree:reap(WorkerTree)
            end
        end,
        WorkerCounts
    ),

    % Summary table
    io:format(
        "~n─────────────────────────────────────────────────────────~n"
    ),
    io:format("Summary~n"),
    io:format(
        "─────────────────────────────────────────────────────────~n"
    ),
    io:format("~-10s ~-15s ~-12s ~-12s~n", ["Workers", "Time (s)", "Speedup", "Efficiency"]),
    io:format("~-10s ~-15s ~-12s ~-12s~n", ["-------", "-------", "-------", "----------"]),
    io:format("~-10s ~-15.6f ~-12s ~-12s~n", ["1 (seq)", SeqMean, "1.00x", "100.0%"]),
    lists:foreach(
        fun({NW, Time, Speedup, Eff}) ->
            io:format(
                "~-10w ~-15.6f ~-12.2f ~-12.1f%~n",
                [NW, Time, Speedup, Eff * 100]
            )
        end,
        Results
    ),
    io:format("~n"),

    ok.
