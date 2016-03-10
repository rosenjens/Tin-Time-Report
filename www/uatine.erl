-module(uatine).
-include("/usr/lib/erlang/lib/stdlib-2.2/include/qlc.hrl").
-include("$YAWS_INCLUDES/yaws_api.hrl").
-include("lm_session.hrl").
%-export([]).
-compile(export_all).

-define(RECORD_TYPE, tine). 
-define(RECORD_KEY_FIELD, id).

%-record(tine, {{testa, testb},test}).

-record(?RECORD_TYPE,
{?RECORD_KEY_FIELD, username, date, started, ended, lunch, total, comment=[]}).

handle(Arg) -> 
    Method = method(Arg),
    io:format("~p:~p ~p Request ~n", [?MODULE, ?LINE, Method]), 
    if Method == 'POST' -> 
        ArgNew = check_post(Method, Arg),
        M = method(ArgNew),
        handle(method(ArgNew), ArgNew); %Due to the problem with DELETE we post it.
    true -> handle(Method, Arg)
    end.

check_post(Method, Arg) ->
    L = yaws_api:parse_post(Arg),
    case lists:keysearch("method",1,L) of
        false -> 
            io:format("~p:~p ~p POST not DELETE ~n", [?MODULE, ?LINE, Method]), 
            Arg;
        
        {value, {K, V}} ->
            io:format("~p:~p ~p POST is DELETE, but ~p : ~p ~n", [?MODULE, ?LINE, Method, K,V]), 
            Rec = Arg#arg.req,
            Rec2 = Rec#http_request{method = 'DELETE'},
            io:format("~p:~p New Method: ~p ~n", [?MODULE, ?LINE, Rec2#http_request.method]), 
            Arg2 = Arg#arg{req = Rec2},
            Arg2;
        _WHAT -> 
            io:format("~p:~p ~p POST fail ~n", [?MODULE, ?LINE, Method]), 
            Arg
    end.

handle('GET', Arg) -> 
    io:format("~p:~p GET Request ~n", [?MODULE, ?LINE]),
    index(Arg);

handle('POST', Arg) ->
    L = yaws_api:parse_post(Arg),
{ok, Sess} = check_session(Arg),
    User = Sess#session.user,    
    io:format("~n~p:~p POST request ~p for ~p~n",[?MODULE, ?LINE, Arg#arg.clidata, User]),

    Id = database:addTine("test1",date:string_to_tuple(kv("date",L)),
                      times:string_to_times(kv("start",L)),
                      times:string_to_times(kv("ending",L)),
                      times:string_to_times(kv("lunch",L)),
                      ":)"),
    [{status, 201},{html, Arg#arg.clidata}];

handle('DELETE', Arg) ->
    io:format("~n~p:~p DELETE request ~n",[?MODULE, ?LINE]),
    IndexValue = string:tokens(Arg#arg.pathinfo, "/"), 
    io:format("~p:~p DELETE request ~p", [?MODULE, ?LINE, IndexValue]),
    {ok, Sess} = check_session(Arg),
    User = Sess#session.user,
    [A,B] = IndexValue,
    {ID, _} = string:to_integer(B), 
    database:deleteTine(User, ID),
    [{status, 200}];

handle(Method,_) ->
[{error, "Unknown method " ++ Method},
{status, 405},
{header, "Allow: GET, HEAD, POST, PUT, DELETE"} ].

method(Arg) ->
    Rec = Arg#arg.req, 
    Rec#http_request.method.

kv(K,L) ->
    { value, {K, V}} = lists:keysearch(K,1,L),
    V.

index(A) ->
    {ok, Sess} = check_session(A),
    io:format("Inside user: ~p~n", [Sess#session.user]),
    Head = html_head(Sess#session.user),

    io:format("q-data: ~p~n",[A#arg.querydata]),

    Body = case yaws_api:queryvar(A, "show") of
                {ok, Date} ->
                    body(Sess#session.user, date:string_to_tuple(Date));
                undefined ->
                    body(Sess#session.user, {})
            end,     

    [Head,Body].

check_session(A) -> 
    H = A#arg.headers,
    case yaws_api:find_cookie_val("lm_sid", H#headers.cookie) of
        [] -> 
            {error, nocookie};
        Cookie ->
            case yaws_api:cookieval_to_opaque(Cookie) of 
                {ok, Sess} ->
                    {ok, Sess};
                {error, {has_session, Sess}} ->
                    {ok, Sess};
                Else ->
                    Else
            end
    end.

html_head(User)->
    H =["<head>
            <title>Tin Time Report</title>
            <script src='http://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js'>
            </script>
            <script src='/tinscripts.js'></script>
        </head>"],
    {html,H}.

body(User, Date)->
    {ehtml,
        {body, [], [header(User), content(User, Date), footer()]}
    }.


header(User) ->
    {'div', [{class,"head"}], [
        {h1, [],User}
    ]}.

content(User, Date)->
    {Records, Tot, {GT, LT}} = tins(User, Date),
    {'div', [{class,"tintable"}], [
        {table, [],[
            {tr,[],[
                {td,[],"Datum"},
                {td,[],"Start"},
                {td,[],"Slut"},
                {td,[],"Lunch"},
                {td,[],"Jobbat"},
                {td,[],"Kommentar"}
            ]}]
            ++
            Records
            ++
            [{tr,[],[
                {td,[],[{input,[{type,"date"},{id,"indate"},{required,""}] }]},
                {td,[],[{input,[{type,"time"},{id,"instime"},{required,""}] }]},
                {td,[],[{input,[{type,"time"},{id,"inetime"},{required,""}] }]},
                {td,[],[{input,[{type,"time"},{id,"inlunch"},{required,""}] }]},
                {td,[],[]}
            ]}]
            ++
            [{tr,[],[
                     {td,[],[]},
                     {td,[],[]},
                     {td,[],[]},
                     {td,[],[]},
                     {td,[],[{'div',[],Tot}]}
            ]}
        ]},
        {'div',[{id,button1}],"Knapp?"},
        %{'div',[], "< " ++ date:to_string(LT) ++ " - " ++ date:to_string(GT)  ++ " >"},
        {'div',[], [{a, [{href, "?show=" ++ date:to_link(LT)}], case LT of 
                                                                    {} -> ""; 
                                                                    _ -> "< " end},
                    {a, [{href, "?show=" ++ date:to_link(GT)}], case GT of {} -> "";
                                                                        _ ->" >" end}]}
         
    ]}.

tins(User, {}) ->
    {Y,M, _} = date(),
    tins(User, {Y,M});
tins(User, Date) ->
    {tins, Tins, Tot , Next} = database:getTines(User, Date),
    Rec = [{tr,[{id, X#?RECORD_TYPE.id}],[
        {td, [{class,"date"}], date:to_string(X#?RECORD_TYPE.date)},
        {td, [{class,"start"}], times:times_to_string(X#?RECORD_TYPE.started)},
        {td, [{class,"end"}], times:times_to_string(X#?RECORD_TYPE.ended)},
        {td, [{class,"lunch"}], times:times_to_string(X#?RECORD_TYPE.lunch)},
        {td, [{class,"total"}], times:times_to_string(X#?RECORD_TYPE.total)},
        {td, [{class,"comment"}], X#?RECORD_TYPE.comment},
        {td, [], {'div',[{class,"delTine"}],"X"}}
    ]} || X <- Tins],
    {Rec, times:times_to_string(Tot),Next}. 


footer() ->
    {'div',[],"footer"}.
