-module('access_control').
-include("$YAWS_INCLUDES/yaws_api.hrl").
%%-export([validate/2]).
-compile(export_all).

-record(user,{username, passwdMD5, uuid}).

validate_username_password(Username, PasswordMD5)->
    Query = fun () ->
            mnesia:read({user, string:to_lower(Username)})
    end,
    Value = mnesia:transaction(Query),
    case Value of
        {atomic,[]} ->
            {false, no_user};
        {atomic, [UserRecord]} when UserRecord#user.passwdMD5 =:= PasswordMD5 ->
            {true, UserRecord#user.username};
        _false -> {false, bad_password}
    end.

validate({false,Reason}) -> {false};
validate({true, Data}) -> {true, Data}.

validate(U, P) ->
    validate(validate_username_password(U,P)).



insert(Username, PasswdMD5) ->
    LowerCaseUsername = string:to_lower(Username),
    Record = #user{username=LowerCaseUsername, passwdMD5 = PasswdMD5},
    F = fun() ->
    mnesia:write(Record)
    end,
    mnesia:transaction(F).

retrieve(Username) ->
    F = fun() ->
    mnesia:read({user, string:to_lower(Username)})
    end,
    {atomic, Data} = mnesia:transaction(F),
    Data.

traverse_table_and_show(Table_name)->
    Iterator =  fun(Rec,_)->
                    io:format("~p~n",[Rec]),
                    []
                end,
    case mnesia:is_transaction() of
        true -> mnesia:foldl(Iterator,[],Table_name);
        false -> 
            Exec = fun({Fun,Tab}) -> mnesia:foldl(Fun, [],Tab) end,
            mnesia:activity(transaction,Exec,[{Iterator,Table_name}],mnesia_frag)
    end.
