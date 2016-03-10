-module(date).
%-export([]).
-compile(export_all).


string_to_tuple(S) ->
    case string:tokens(S, "-") of
        [Y,M,D] -> 
            {list_to_integer(Y), list_to_integer(M), list_to_integer(D)};
        [Y,M] ->
            {list_to_integer(Y), list_to_integer(M)};
        _ ->
            bad_match
    end.

in_month(YM,{Y,M,_}) ->
    YM =:= {Y,M}.


to_string({})-> "";
to_string({Y,M}) ->
    to_string_(Y)++"-"++to_string_(M);
to_string({Y,M,D}) ->
    to_string_(Y)++"-"++to_string_(M)++"-"++to_string_(D).

to_string_(M) ->
    if  M > 9 ->
            integer_to_list(M);
        true ->
            "0" ++ integer_to_list(M)
    end.


to_link({})-> "";
to_link({Y,M}) ->
    integer_to_list(Y)++"-"++integer_to_list(M).
