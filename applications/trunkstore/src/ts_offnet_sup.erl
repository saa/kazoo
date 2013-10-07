%%%-------------------------------------------------------------------
%%% @copyright (C) 2011-2013, 2600Hz INC
%%% @doc
%%% Manage offnet calls
%%% @end
%%% @contributors
%%%   James Aimonetti
%%%-------------------------------------------------------------------
-module(ts_offnet_sup).

-behaviour(supervisor).

%% API
-export([start_link/1
         ,listener/1
         ,fsm/1
         ,stop/1
        ]).

%% Supervisor callbacks
-export([init/1]).

-include("ts.hrl").

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
-spec start_link(whapps_call:call()) -> startlink_ret().
start_link(Call) -> supervisor:start_link(?MODULE, [Call]).

-spec listener(pid()) -> api_pid().
listener(Supervisor) ->
    case child_of_type(Supervisor, 'ts_offnet_listener') of
        [] -> 'undefined';
        [Pid] -> Pid
    end.

-spec fsm(pid()) -> api_pid().
fsm(Supervisor) ->
    case child_of_type(Supervisor, 'ts_offnet_fsm') of
        [] -> 'undefined';
        [Pid] -> Pid
    end.

-spec stop(pid()) -> 'ok' | {'error', 'not_found'}.
stop(Supervisor) ->
    supervisor:terminate_child('ts_offnet_calls_sup', Supervisor).

-spec child_of_type(pid(), atom()) -> pids().
child_of_type(S, T) ->
    [P || {Ty, P, 'worker', _} <- supervisor:which_children(S), T =:= Ty].

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @spec init(Args) -> {ok, {SupFlags, [ChildSpec]}} |
%%                     ignore |
%%                     {error, Reason}
%% @end
%%--------------------------------------------------------------------
init(Args) ->
    RestartStrategy = 'one_for_all',
    MaxRestarts = 0,
    MaxSecondsBetweenRestarts = 1,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    {'ok', {SupFlags, [?WORKER_ARGS_TYPE('ts_offnet_listener', [self() | Args], 'temporary')
                       ,?WORKER_ARGS_TYPE('ts_offnet_fsm', [self() | Args], 'temporary')
                      ]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
