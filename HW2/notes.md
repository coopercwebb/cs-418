
% Get the test fixtures
Tests = hw2_tests:moose_par_test_().

% Run the first test fixture
[FirstTest|_] = Tests.
eunit:test(FirstTest).

Run EUnit with verbose output:

All tests (with output):
eunit:test(hw2_tests, [verbose]).

Individual Suite (with output):
eunit:test(hw2_tests:moose_par_test_(), [verbose]).
eunit:test(hw2_tests:moose_combine_test(), [verbose]).
eunit:test(hw2_tests:moose_leaf_test(), [verbose]).