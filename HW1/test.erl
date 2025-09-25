-module(test).

-compile(export_all).

q1_test() ->
    Cases = [ [], 0, [cat], [cat, fish], [potoroo, bettong, wombat],
                    lists:seq(10,0,-2), {bat, wombat},
                    [{panda, 3}, {penguin, 2}, {potoroo, 137}],
                    [{dog, 2}, {potoroo, 137}, {cat, 3}],
                    {[cat, dog, potoroo], [3, 2, 137]}
    ],
    io:format("Testing pattern i ~n"),
    _ = [ pattern_i(X)
            || X <- Cases
        ],
    io:format("Testing pattern ii ~n"),
    _ = [ pattern_ii(X)
            || X <- Cases
        ],
    io:format("Testing pattern iii ~n"),
    _ = [ pattern_iii(X)
            || X <- Cases
        ],
    io:format("Testing pattern iv ~n"),
    _ = [ pattern_iv(X)
            || X <- Cases
        ],
    io:format("Testing pattern v ~n"),
    _ = [ pattern_v(X)
            || X <- Cases
        ],
    io:format("Testing pattern vi ~n"),
    _ = [ pattern_vi(X)
            || X <- Cases
        ],
    io:format("Testing pattern vii ~n"),
    _ = [ pattern_vii(X)
            || X <- Cases
        ],
    io:format("Testing pattern viii ~n"),
    _ = [ pattern_viii(X)
            || X <- Cases
        ],
    io:format("Testing pattern ix ~n"),
    _ = [ pattern_ix(X)
            || X <- Cases
        ],
    io:format("Testing pattern x ~n"),
    _ = [ pattern_x(X)
            || X <- Cases
        ],
    true.

% io printout of result if it matches
pattern_i(X) ->
    io:format("Match, X=~p ~n", [X]).

% io printout of result if it matches
pattern_ii(_) ->
    io:format("Match~n").

% io printout of result if it matches
pattern_iii([X, Y]) ->
    io:format("Match, X=~p ~n", [X]);
% otherwise io printout "does not match"
pattern_iii(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_iv([X|Y]) ->
    io:format("Match, X=~p ~n", [X]);
% otherwise io printout "does not match"
pattern_iv(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_v([X, Y|Z]) ->
    io:format("Match, X=~p ~n", [X]);
% otherwise io printout "does not match"
pattern_v(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_vi(0) ->
    io:format("Match~n");
% otherwise io printout "does not match"
pattern_vi(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_vii({X}) ->
    io:format("Match, X=~p ~n", [X]);
% otherwise io printout "does not match"
pattern_vii(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_viii({X, _}) ->
    io:format("Match, X=~p ~n", [X]);
% otherwise io printout "does not match"
pattern_viii(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_ix([_, {_,X}|_]) ->
    io:format("Match, X=~p ~n", [X]);
% otherwise io printout "does not match"
pattern_ix(_) ->
    io:format("Does not match ~n").

% io printout of result if it matches
pattern_x([_|_]) ->
    io:format("Match~n");
% otherwise io printout "does not match"
pattern_x(_) ->
    io:format("Does not match ~n").