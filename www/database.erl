-module(database).
-include("/usr/lib/erlang/lib/stdlib-2.2/include/qlc.hrl").
-include("$YAWS_INCLUDES/yaws_api.hrl").
%-export([]).
-compile(export_all).

-define(RECORD_TYPE, tine).
-define(RECORD_KEY_FIELD, id).

%-record(tine, {{testa, testb},test}).

-record(?RECORD_TYPE,
{?RECORD_KEY_FIELD, username, date, started, ended, lunch, total, comment=[]}).

-record(counters, {name,count}).

start() ->
    mnesia:start().

stop() ->
    mnesia:stop().

clear_all_tables() -> {error}.

make_tables() ->
    mnesia:create_table(tine, [ {disc_copies, [node()]},
                                {attributes, record_info(fields,tine)},
                                {index, [#?RECORD_TYPE.username]}]),
    mnesia:create_table(counters, [ {disc_copies, [node()]},
                                    {attributes, record_info(fields,counters)}]),
    mnesia:dirty_write(#counters{name="tineid", count=0}).
    

addTine(User, Date,Start,End,Lunch,Comment) ->
    F = fun() ->
        [Counter] = mnesia:read(counters, "tineid"),
        NewC = Counter#counters{count = (Counter#counters.count)+1},
        mnesia:write(NewC),
        mnesia:write(#tine{ id          = Counter#counters.count,
                            username    = User,
                            date        = Date,
                            started     = Start,
                            ended       = End,
                            lunch       = Lunch,
                            total       = times:remove_minutes(times:differ(Start,End),times:times_to_minutes(Lunch)),
                            comment     = Comment
                            }),
        Counter#counters.count
    end,
    {atomic, Rec} = mnesia:transaction(F),
    Rec.

updateTine(Id, Date, Start, End, Lunch, Comment) ->
    mnesia:transaction(fun() ->
        case mnesia:wread({tine, Id}) of
            [Rec] ->
                TineUp = Rec#?RECORD_TYPE{  date    = Date, 
                                        started     = Start, 
                                        ended       = End, 
                                        lunch       = Lunch, 
                                        total       = times:remove_minutes(times:differ(Start,End),
                                                      times:times_to_minutes(Lunch)), 
                                        comment     = Comment},
                mnesia:write(TineUp);
            _ ->
                mnesia:abort("No such record!")
        end
    end).

deleteTine(User, Id) ->
    F = fun() ->
        [Obj] = mnesia:read(tine, Id),
        if User =:= Obj#?RECORD_TYPE.username ->
                ok = mnesia:delete(tine, Id, write);
            true -> error
        end
    end,
    {atomic, Res} = mnesia:transaction(F),
    Res.

getTines(User, YearMonth)->
    F = fun() -> qlc:e(qlc:q(
        [ X || X <- mnesia:table(?RECORD_TYPE),
            X#?RECORD_TYPE.username =:= User
        ]))
    end,
    LF = fun(A,B) -> A#?RECORD_TYPE.date < B#?RECORD_TYPE.date end, 
    Rec = lists:sort(LF, mnesia:activity(transaction, F)),
    MatchedTines = [Tine || Tine <- Rec, date:in_month(YearMonth, Tine#?RECORD_TYPE.date)], 
    {tins, MatchedTines, sumTotalTime(MatchedTines), findnexts(Rec, YearMonth, {},{})}. 
        
findnexts([], _, B,S) -> {B,S};
findnexts([H|T], ActiveDate, Bigger, Smaller ) -> 
    {Y,M,_} = H#?RECORD_TYPE.date,
    YM = {Y,M},
    if  YM < ActiveDate andalso YM > Smaller ->
            findnexts(T, ActiveDate, Bigger, YM);
        YM > ActiveDate andalso (YM < Bigger orelse Bigger =:= {}) ->
            findnexts(T, ActiveDate, YM, Smaller);
        true -> findnexts(T, ActiveDate, Bigger, Smaller)
    end.

sumTotalTime(Rec) ->
    L = [ times:times_to_minutes(X#?RECORD_TYPE.total) || X <- Rec ],
    times:minutes_to_times(lists:foldl(fun(S, Sum) -> S + Sum end,0,L)).



