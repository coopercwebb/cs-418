-module(hw4_lib).

% functions for Q2: Hypercube Congestion
-export([congestion_0/1, congestion/1, route1/3, msg_count/3, all_nodes/1, transpose/1, traffic/1]).

% functions for Q3: Queues
-export([create/4, create/2, m_get/2, m_put/3, step/1, run/2]).
-export([arrive/1, service/1]).
-export([sim/5, sim_len/4, sim_len/5, sim_len_ms/5]).
-export([expDist/1, expDist/0, constDist/1, uniformDist/2, erlangDist/2]).

% The usual function to report that you are not done yet.
-export([you_need_to_write_this/4]).

-import(hw4, [link_counts/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                              %
%  Functions for Q2: Hypercube Congestion                                      %
%                                                                              %
%  See the description in hw4.erl of how we represent hypercube routing.       %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% route1(Src, Dst, K) -> {Before, After}
%   Perform a single step in dimenstion routing on a hypercube.
%   Parameters:
%     Src, Dst, Before, and After are node addresses for a D-dimensional hypercube.
%       Node addresses are represented by lists of D elements where each element is a 0 or 1.
%       D is implicit in our parameters:  D = length(Src), and we require length(Dst) = length(Src).
%     K specifies which step of dimension routing to model.
%       When K=0, we route according to the least significant bit of Dst,
%       i.e. the first element of the list.
%       More generally, We route according to the K^th bit of Dst (zero based indexing).
%   Return value: {Before, After}
%     Before is the node that the message being sent from Src to Dst is at
%       before routing along dimension K.
%     After is the node that the message being sent from Src to Dst is at
%       after routing along dimension K.
route1(Src, Dst, K) when
    is_list(Src),
    is_list(Dst),
    length(Src) == length(Dst),
    is_integer(K),
    0 =< K,
    K < length(Src)
->
    D = length(Src),
    Before = lists:sublist(Dst, K) ++ lists:sublist(Src, K + 1, D - K),
    After = lists:sublist(Dst, K + 1) ++ lists:sublist(Src, K + 2, D - (K + 1)),
    {Before, After}.

% msg_count(Node, Link, SrcDstList) -> Count
%   Parameters:
%     Node: address of a router node, a list.  Let D = length(Node)
%     Link: one of the D links out of Node.
%     SrcDstList: a list of {Src, Dst} pairs,
%       where Src and Dst are node addresses, i.e. lists of length D of 0s and 1s.
%   Return value: Count
%     How many messages are sent from Node along Link when
%     sending messages from each Src to the corresponding Dst.
msg_count(Node, Link, [{Src, Dst} | Tl]) ->
    {Before, After} = route1(Src, Dst, Link),
    case (Before == Node) andalso (Before /= After) of
        true -> 1;
        false -> 0
    end + msg_count(Node, Link, Tl);
msg_count(_, _, []) ->
    0.

% all_nodes(D) -> ListOfNodeAddresses
%   Return a list the node addresses for all nodes of a D-dimensional hypercube.
all_nodes(D) when is_integer(D), D > 0 ->
    A = all_nodes(D - 1),
    [[0 | X] || X <- A] ++ [[1 | X] || X <- A];
all_nodes(0) ->
    [[]].

% transpose(Addr)
%   Swap the left and right halves of an address.
%   Let Addr be a node address for a D-dimensional hypercube.
%   For simplicity, assume D is even, and let Left and Right be lists of length
%   D div 2 such that Left ++ Right == Addr.
%   Return the node address Right ++ Left.
transpose(Addr) when is_list(Addr) ->
    {A, B} = lists:split(length(Addr) div 2, Addr),
    B ++ A.

% traffic(D) -> SrcDstList
%   Return the SrcDstList for a D-dimensional hypercube where each node sends
%   a message to its transpose.
traffic(D) when is_integer(D), 0 =< D ->
    Nodes = all_nodes(D),
    lists:zip(Nodes, [transpose(Node) || Node <- Nodes]).

% congestion_0(D) -> {MaxCongestion, MaxCongestedLinks}.
%   Let SrcDstList be the traffic pattern consisting of all pairs {Src, Dst},  %
%     where Src is the address of a D-dimensional hypercube and Dst is the     %
%     transpose of Src.                                                        %
%   Return {MaxCongestion, MaxCongestedLinks} where                            %
%     MaxCongestion is the maximum congestion of a link, i.e. the maximum      %
%       number of messages sent over a particular link when routing            %
%       SrcDstList.                                                            %
%     MaxCongestedLinks is the number of links over which MaxCongestion        %
%       messages are sent when routing SrcDstList.                             %
%                                                                              %
% Remarks on runtime for congestion_0:                                         %
%   Let N = 2^D be the number of nodes in a D-dimensional hypercube.  The      %
%   router for each node has D links to other nodes.  Thus there are N*D       %
%   links.  The transpose traffic pattern has one {Src, Dst} pair for each     %
%   of the N nodes.  congestion_0 checks for each link, whether or not each    %
%   message in the traffic pattern uses this link.  Thus it makes (N*D)*N      %
%   calls to route1 -- route1 simulates one step of dimension routing.         %
%   route1 runs in Theta(D) time.  Thus the total time is D^2 N^2.             %
congestion_0(D) ->
    Nodes = all_nodes(D),
    SrcDstList = traffic(D),
    V = [
        msg_count(Node, Link, SrcDstList)
     || Node <- Nodes, Link <- lists:seq(0, D - 1)
    ],
    MaxCount = lists:max(V),
    {MaxCount, length([ok || Count <- V, Count == MaxCount])}.

% congestion(D) -> {MaxCongestion, MaxCongestedLinks}.
%   congestion(D) computes the same result as congestion_0(D) as described     %
%   above, but it is faster.  congestion(D) calls link_counts(SrcDstList)      %
%   which you need to write.  If link_counts(SrcDstList) is implemented as     %
%   intended, then congestion should run in time O(D^2 N).  As noted in the    %
%   comments for this module, we could get time O(D N) if we used Erlang       %
%   integers to represent node addresses and replaced the list operations      %
%   in route1/3 with bit-wise logical operations and shifts.  But, this        %
%   is "fast enough" and we won't add the extra design issue of doing bit      %
%   fiddling.                                                                  %
congestion(D) ->
    SrcDstList = traffic(D),
    V = maps:values(link_counts(SrcDstList)),
    MaxCount = lists:max(V),
    {MaxCount, length([ok || Count <- V, Count == MaxCount])}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                      %
%  Functions for Q3: Queues                                            %
%                                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% I represent a Queue with an Erlang map with entries:
%   len => number of "customers" in the queue
%   t_a => time of next arrival
%   t_s => time that next service completes, 'undefined' if the Queue is empty
%   r_a => a function, R_a(), such that R_a() returns samples of the time between
%            customer arrivals.
%   r_s => a function, R_s(), such that R_s() returns samples of the time it takes
%            to service a customer (e.g. cashier check-out times).
%   callback_fun => a user-provided function to call on each arrival or service event
%            f(Q, What, D_old) -> D_new, where:
%              Q is this Queue;
%              What is 'a' if the current event is an arrival, and 's' if it's a service; and
%              D_old and D_new are data values defined by the user.
%            If f is the atom 'none', then no callback is performed.
%   callback_data => data for f.
%
%   Note: I spent too long trying to make this both efficient and general.
%     For generality, I would like to have an actual queue that recorded the arrival
%       times of waiting customers.  In Erlang, it would be natural to use a list,
%       but this leads to efficiency issues.
%     For efficiency, a list is awful.  The list could be kept in increasing order
%       of arrival times.  Then, the next customer to service is the first element
%       of the list -- nice!  But arriving customers have to be appeneded to the
%       end of the list which takes time O(length(Queue)).  Ouch.  Conversely,
%       if the list were ordered in decreasing arrival time, i.e. most recent
%       arrival first, arrivals can be handled quickly, but service operations
%       take O(length(Queue)).
%         I could use a map where the keys are integer indices that are incremented
%       with each arrival.  That's worth trying, but it makes this HW problem more
%       of a plunge into maps than I intended.  Or, I could make a tree structure
%       that ensures O(log(length(Q))) time for arrivals and service, but that
%       also seemed like a distraction from the goals of this question.
%     Compromise: I just track the number of waiting customers.  It's initially 0,
%       incremented on an arrival event, and decremented on a departure event.
%       This is simple.  It loses the information of the arrival times of waiting
%       customers, which means we can't demonstrate some fun properties of Queues,
%       but that will have to wait for another term.

%   create(R_a, R_s, F, D): create an empty queue.
create(R_a, R_s, CallBackFun, CallBackData) ->
    FirstArrival = R_a(),
    FirstService = FirstArrival + R_s(),
    % the queue is initially empty
    #{
        len => 0,
        t_a => FirstArrival,
        t_s => FirstService,
        % (random) time between arrivals
        r_a => R_a,
        % (random) time to service a customer
        r_s => R_s,
        % customization: call-back function for each arrival and departure
        callback_fun => CallBackFun,
        % data maintained by F.
        callback_data => CallBackData
    }.

% default: no call-back customizations
create(R_a, R_s) -> create(R_a, R_s, none, none).

% simulate N steps of the Q where each step corresponds to an arrival
% or service event.
run(0, Q) ->
    Q;
run(N, Q) when is_integer(N), 0 < N ->
    run(N - 1, step(Q)).

% Process an arrival or service event -- whichever is next in time-order.
step(Q) ->
    [T_a, T_s] = m_get([t_a, t_s], Q),
    if
        T_a =< T_s -> arrive(Q);
        T_a > T_s -> service(Q)
    end.

% Process an arrival event
arrive(Q) when is_map(Q) ->
    [T_a, T_s, R_a, R_s, Len, CBfun, CBdata] =
        m_get([t_a, t_s, r_a, r_s, len, callback_fun, callback_data], Q),
    Next_T_a = T_a + R_a(),
    Next_T_s =
        case Len of
            0 -> T_a + R_s();
            _ -> T_s
        end,
    Q#{
        t_a => Next_T_a,
        t_s => Next_T_s,
        len => Len + 1,
        callback_data =>
            if
                is_function(CBfun, 2) ->
                    CBfun(Q, a);
                CBfun == none ->
                    CBdata;
                true ->
                    error(
                        {bad_fun,
                            lists:flatten(
                                io_lib:format(
                                    "~w:arrive(...): bad call-back function, ~p~n",
                                    [?MODULE, CBfun]
                                )
                            )}
                    )
            end
    }.

% Process a service event
service(Q) when is_map(Q) ->
    [T_s, R_s, Len, CBfun, CBdata] =
        m_get([t_s, r_s, len, callback_fun, callback_data], Q),
    Next_T_s =
        case Len of
            1 -> undefined;
            _ -> T_s + R_s()
        end,
    Q#{
        t_s => Next_T_s,
        len => Len - 1,
        callback_data =>
            if
                is_function(CBfun, 2) ->
                    CBfun(Q, s);
                CBfun == none ->
                    CBdata;
                true ->
                    error(
                        {bad_fun,
                            lists:flatten(
                                io_lib:format(
                                    "~w:service(...): bad call-back function, ~p~n",
                                    [?MODULE, CBfun]
                                )
                            )}
                    )
            end
    }.

% sim(N_warmup, N_run, R_a, R_s, F)
%   Simulate a queue.
%   Parameters:
%     N_warmup: warm-up the queue for this many steps before
%       gathering simulation data.  A step is a single arrive or service
%       event.
%     N_run: number of steps to simulate while gathering data.
%     R_a: R_a() returns samples of the inter-arrival time distribution.
%     R_s: R_s() returns samples of the service time distribution.
%     F: if F == none, we don't do anything special in the N_run phase.
%        otherise, F(Q) returns {Callback_fun, Callback_data} as describe
%        in the description of the Q-map above.
%   Return value:
%     The Q-map reached at the end of the simulation.
sim(N_warmup, N_run, R_a, R_s, F) ->
    Q0 = create(R_a, R_s),
    Q1 = run(N_warmup, Q0),
    Q2 =
        if
            F == none -> Q1;
            is_function(F, 1) -> F(Q1)
        end,
    run(N_run, Q2).

% Some random distributions to use for experimenting with queues.
%   Every distribution should return samples that are positive numbers --
%     we want our models to be causal (can't go backwards in time).
%
% For many of the distributions below, we get samples by using rand:uniform()
% to get a uniformly distributed sample, S, in [0,1).  Let cdf be the cummulative
% distribution function; i.e. cdf(X) = Prob{Sample_from_distribution =< X}.
% Let icdf(S) be the inverse of the cdf, i.e.  cdf(icdf(S)) = S.  Then icdf(S)
% is a sample of the distribution we want.  This works for any distribution as
% long as we can compute icdf.

% expDist(Mean):
%   An exponential distribution with Mean.
%   probability density function:
%     pdf(x) = 0, x < 0
%     pdf(x) = (1/Mean)*exp(-x/Mean), x >= 0
%   cummulative density function:
%     cdf(x) = 0, x < 0
%     cdf(x) = 1 - exp(-x/Mean), x >= 0
expDist(Mean) when is_number(Mean), 0 < Mean ->
    fun() -> -Mean * math:log(1 - rand:uniform()) end.

expDist() -> expDist(1).

% constDist(Mean):
%   A constant distribution.  Every sample is Mean.
constDist(Mean) -> fun() when is_number(Mean), 0 < Mean -> Mean end.

% uniformDist(Mean, Width):
%   uniform distribution in [Mean-(Width/2), Mean+Width/2]
uniformDist(Mean, Width) when
    is_number(Mean), 0 < Mean, is_number(Width), 0 =< Width, Width =< 2 * Mean
->
    Mean + Width * (0.5 - rand:uniform()).

% erlangDist(Mean, K):
%   The Erlang-K distribution with mean=Mean.
%   Of course, we need an Erlang distribution in this class!
erlangDist(Mean, K) when is_number(Mean), 0 < Mean, is_integer(K), 0 < K ->
    ExpDist = expDist(Mean / K),
    fun() ->
        lists:sum([ExpDist() || _ <- lists:seq(1, K)])
    end.

% simulate a queue and gather statistics on the queue length
qlen(Q) ->
    m_put(
        [callback_fun, callback_data],
        [
            fun qlen_update/2,
            #{
                t0 => m_get(t_now, Q),
                t_last => m_get(t_now, Q),
                sum_len => 0
            }
        ],
        Q
    ).

qlen_update(Q, _) ->
    [T_now, Len, D] = m_get([t_now, len, callback_data], Q),
    [SumLen, T_last] = m_get([sum_len, t_last], D),
    D#{
        t_last => T_now,
        sum_len => SumLen + Len * (T_now - T_last)
    }.

qlen_mean(Q) ->
    D = m_get(callback_data, Q),
    [SumLen, T_0, T_last] = m_get([sum_len, t0, t_last], D),
    m_get([sum_len, t0, t_last], D),
    SumLen / (T_last - T_0).

% sim_len:
%   Use sim to estimate the average length of a queue.
%   Parameters:
%     N_warmup: warm-up the queue for this many steps before
%       gathering simulation data.
%     N_run: number of steps to simulate while gathering data.
%     R_a: R_a() returns samples of the inter-arrival time distribution.
%     R_s: R_s() returns samples of the service time distribution.
%   Result:
%     The average queue-length during the N_run steps.
sim_len(N_warmup, N_run, R_a, R_s) ->
    qlen_mean(sim(N_warmup, N_run, R_a, R_s, fun qlen/1)).

% sim_len(N_trials, N_warmup, N_run, R_a, R_s)
%   Like sim_len(N_warmup, N_run, R_a, R_s,
%     but we run N_trials trials and report a stat structure.
%     See stat:create/0, stat:accum/1, stat:accum/2, and stat:combine/2,
%     https://www.students.cs.ubc.ca/~cs-418/resources/erl/doc/index.html.
%   To get the mean and standard-deviation, see sim_len_ms/5 below.
sim_len(N_trials, N_warmup, N_run, R_a, R_s) ->
    stat:accum(
        [
            sim_len(N_warmup, N_run, R_a, R_s)
         || _ <- lists:seq(1, N_trials)
        ]
    ).

% sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s)
%   sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s), but we return a keylist
%   with our estimates (based on the simulations) of the mean and standard
%   deviation of the queue length.
sim_len_ms(N_trials, N_warmup, N_run, R_a, R_s) ->
    S = sim_len(N_trials, N_warmup, N_run, R_a, R_s),
    [{mean, stat:mean(S)}, {std, stat:std(S)}].

% map utilities

% I'd like to use maps in patterns, here's a way to do it.
%   Let M be a map, where every key is an atom.
%   Let KeyList be a (deep) list of keys.
%   Then m_get(KeyList, M) returns the values for those keys in a
%     (deep) list with the same shape as KeyList.
% m_get(DeepListOfKeys, Map) -> DeepListOfValues
m_get(t_now, M) when is_map(M) -> lists:min(m_get([t_a, t_s], M));
m_get(Key, M) when is_atom(Key), is_map(M) -> maps:get(Key, M);
m_get(KeyList, M) when is_list(KeyList), is_map(M) ->
    [m_get(X, M) || X <- KeyList].

% m_put(KeyList, ValList, Map) -> UpdatedMap
%   The counterpart of m_get for updating a map.
%   KeyList must be a (deep) list of atoms.
%   ValList is a (deep) list of values.  ValList must have the same shape as KeyList
m_put(Key, Val, M) when is_atom(Key), is_map(M) ->
    maps:put(Key, Val, M);
m_put(KeyList, ValList, M) when is_list(KeyList), is_list(ValList), is_map(M) ->
    lists:foldl(fun({K, V}, X) -> m_put(K, V, X) end, M, lists:zip(KeyList, ValList)).

% you_need_to_write_this(Fun, Args)
%   The usual place holder that will print an error message and then throw an
%   error if you haven't implemented something requested in the homework.
you_need_to_write_this(Fun, Args, FileName, LineNumber) ->
    io:format(
        "~s (line ~b): missing implementation for ~w~s.~n",
        [FileName, LineNumber, Fun, args_string(Args)]
    ),
    % The Erlang shell will report the exception as being thrown on the next line.
    % It won't show the call to you_need_to_write_this in the stack trace because
    % calling you_need_to_write_this(...) is usually a tail-call.  Do not fear.
    % The error message printed on the previous line tells you where the call
    % to you_need_to_write_this(...) was made.  You need to fix your code there.
    % You don't need to change this function.

    % See the comment on the previous six lines.
    error(missing_implementation).

args_string([]) ->
    "()";
args_string([Arg1 | Args]) ->
    [
        "(",
        io_lib:format("~p", [Arg1]),
        [io_lib:format(", ~p", [Arg]) || Arg <- Args],
        ")"
    ].
