-module(hw4).

-export([link_counts/1]).  % the function you need to for Q2: Hypercube conjestion.
-export([par_len/6, par_len_ms/6]).  % the functions you need to write for Q3: queues.

% I added various
-import(hw4_lib,
  [ sim_len/4,    % simulate a queue and return summary as an accumulator from the stat module.
    sim_len_ms/4, % same as sim_len/4 but return a keylist with the mean and std (standard deviation).
    you_need_to_write_this/4 % The usual error function that gets called if
                             % you haven't written something required for the
			     % assignment.
  ]).

-define(you_need_to_write_this(Func, Args),
	you_need_to_write_this(Func, Args, ?FILE, ?LINE)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                              %
% Code for Q2                                                                  %
%                                                                              %
% The functions in this module demonstrate a traffic pattern that creates      %
% congestion on a hypercube when using dimension routing.  First, some         %
% definitions:                                                                 %
%   Dimension: the dimension of the hypercube.  We will use D to denote the    %
%     dimension of the hypercube.                                              %
%   Node address: a list of length Dim where every element is a 0 or 1.        %
%     We use little-endian order.  The first element of a node address         %
%     is the least-significant bit of the address.  Say that the least         %
%     significant bit of an address is bit 0.  Sadly, Erlang uses 1-based      %
%     indexing; so, bit-K of an address is list:nth(K+1, Address).             % 
%   Traffic Pattern: a list of {Src, Dst} pairs where Src and Dst are          %
%     node addresses.  This means a message is sent from node Src to           %
%     node Dst.                                                                %
%                                                                              %
% Congestion:                                                                  %
%   We are interested in traffic patterns where every Src is distinct, i.e.    %
%   each node sends at most one message, and there are no two source nodes     %
%   that send messages to the same destination.  Note that such a traffic      %
%   pattern could be routed in a single step using a cross-bar network.        %
%     Congestion occurs if two messages need to traverse the same link.        %
%   This means that if each node tries to send a new message to its            %
%   destination on each time step, then, the throughput of the network         %
%   will be constrained by the most congested link.  For example, if           %
%   there is a link that conveys C messages each time the traffic pattern      %
%   is sent, then we can send the traffic pattern at most once every           %
%   time steps.                                                                %
%                                                                              %
% The homework asks you to show that the 'transpose' pattern for a hypercube   %
% with 2^D nodes has some links that convey (1/2)*2^(D/2) messages each        %
% time the traffic pattern is sent.  The code in this module lets you          % 
% experimentally test this claim.  In particular, the function                 %
%   congestion_0(D) -> {MaxCongestion, CongestedLinks}                         %
% where MaxCongestion is the maximum number of messages conveyed by any link   %
% when routing the transpose pattern, and CongestedLinks is the number of      %
% links with this level of congestion.                                         % 
%                                                                              %
%   As implemented, congestion_0(Dim) is embarrassingly slow.  Let N = 2^D be  %
% the number of nodes in a D-dimensional hypercube.  congestion_0 runs in time %
% D^2*N^2, which is embarrassingly slow -- but it kept the code simple.        %
% I've also provided the code for congestion(Dim) which should run in time     %
% D^2*N.  For congestion(Dim) to run, you need to implement link_counts/1.     %
% A template is provided.                                                      %
%                                                                              %
% A runtime of D*N should be achievable, but we would need to represent node   %
% addresses as Erlang integers and use bit-fiddling operations such as band,   %
% bor, bnot, bsl, etc.  The list version is simpler to explain, and D^2*N      %
% is fast enough for the kinds of experiments I can imagine you wanting to     %
% try.                                                                         %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% link_counts(SrcDstList) -> CountMap                                          %
%   Count the number of messages sent over each link of a hypercube when       %
%   routing the messages of SrcDstList.                                        %
%   Parameters:                                                                %
%     SrcDstList: a list of {Src, Dst} pairs where Src and Dst are node        %
%       addresses.  The dimension of the hypercube, D, is length(Src)          %
%       and we assume length(Dst) = length(Src).                               %
%   Return value:                                                              %
%     CountMap: an Erlang map.                                                 %
%       See https://www.erlang.org/doc/apps/stdlib/maps.html                   %
%       Keys for the map are {NodeAddress, K} tuples where                     %
%         NodeAddress is the address of the node for the router.               %
%         K is which dimension this is routing.  0 =< Link < D.                %
%     For each link {NodeAddress, K} used in routing the messages of           %
%     SrcDstList, maps:get({NodeAddress, K}, CountMap) returns the number      %
%     of messages that were sent over this link when routing the messages      %
%     of SrcDstList.  If no messages were sent, then CountMap may either       %
%     have no entry for that link, or the entry can be 0.                      %
%                                                                              %
% Hints:                                                                       %
%   To get the requested run-time it is *very* helpful to have a map data      %
%   structure with O(1) time operations for put and get.  Erlang maps          %
%   provide this.  Helpful functions include:                                  %
%     maps:new() -- create an empty map.                                       %
%     maps:put(Key, Value, Map) -- create or update the entry in Map for       %
%       Key to map to Value.  Because Erlang is functional, this returns a new %
%       map.  Because the Erlang implementers are clever, the run-time for     %
%       get and put operations is very close to O(1) in practice.  You can     %
%       make it worse by a log'ish factor if you do pathological stuff with    %
%       maps, but there  is no need to do so for this problem.                 %
%     maps:get(Key, Map) -- return the value associated with Key in Map.       %
%       Throw an error if there is no such entry.                              %
%     maps:get(Key, Map, DefaultValue) -- return the value associated with Key %
%       in Map.  Return DefaultValue if there is no such entry.                %
%                                                                              %
%   My solution uses two helper functions to keep everything tail-recursive    %
%     and thereby minimize the memory requirements of the function.            %
%     For the main use case, the call by contention/1, CountMap will have one  %
%     entry for each link of the hypercube.  There are D*2^D such links.       %
%     Each CountMap entry has a key of size O(D), and a value of O(1).         %
%     The total space is O(D^2 2^D).  I guess that CountMap dominates the      %
%     memory footprint; so reasonable implementations that are body-recursive  %
%     or use foldl are also acceptable.
link_counts(SrcDstList) ->
  ?you_need_to_write_this(link_counts, [SrcDstList]).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                              %
% Code for Q3: queues.                                                         %
%                                                                              %
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% par_len(W, N_trials, N_run, N_warmup, R_a, R_s) %   simulate a queue
%   Parameters: %     W:  a worker tree from wtree:create/1
%     N_trials:  How many simulation runs to make for gathering queue length statistics
%                  This is the *total* number of runs (i.e. the sum over all workers)
%     N_warmup:  Process N_warmup events (arrival or service events) before gathering statistics.
%     N_run:     Gather statistics for N_run events (arrival or service events)
%     R_a:       A function.  R_a() returns samples of the inter-arrival time distribution
%     R_s:       A function.  R_s() returns samples of the service time distribution
%   Return value:
%     S: an accumulator created and used by functions in the stat module (from the course library).
%
%   See also: hw4_lib:sim_len.
%
%   This should be a parallel implementation using wtree:reduce to obtain better
%   performance than hw4_lib:sim_len.
par_len(W, N_trials, N_warmup, N_run, R_a, R_s) ->
  ?you_need_to_write_this(par_len, [W, N_trials, N_run, N_warmup, R_a, R_s]).


% par_len_ms(W, N_trials, N_run, N_warmup, R_a, R_s)
%   simulate a queue
%   Paramaters:
%     same as for par_len/5
%   Return value:
%     A keylist of the form [{mean, Mean}, {std, Std}] where Mean is the
%     estimate of the average queue length from the simulation, and Std is
%     the standard deviation.
%
%   This should be parallel implementation.  You can make it parallel by calling par_len/5.
par_len_ms(W, N_trials, N_warmup, N_run, R_a, R_s) ->
  ?you_need_to_write_this(par_len_ms, [W, N_trials, N_run, N_warmup, R_a, R_s]).
