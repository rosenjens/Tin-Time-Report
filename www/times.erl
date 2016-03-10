-module(times). 
-include("$YAWS_INCLUDES/yaws_api.hrl"). 
%-export([]). 
-compile(export_all). 

string_to_times([A,B,58,C,D]) ->
    string_to_times([A,B,C,D]);
string_to_times([A,B,C,D]) -> 
    {H,_Rest} = string:to_integer([A,B]),
    {M,_Rest} = string:to_integer([C,D]),
    {H,M}.


times_to_string({H,M}) ->
    times_to_string({H}) ++ ":" ++times_to_string({M});
times_to_string({T}) -> 
    case integer_to_list(T) of
        [X] -> [48,X];
        Y -> Y
    end.
    %[A,B] = case integer_to_list(H) of
    %        [Xa] -> [48,Xa];
    %        Ya -> Ya
    %    end,
    %[C,D] = case integer_to_list(M) of
    %        [Xb] -> [48,Xb];
    %        Yb -> Yb
    %    end,
    %[A,B,C,D].

times_to_minutes({H,M}) ->
    H*60+M.

minutes_to_times(M) ->
    {M div 60, M rem 60}.


differ(A,B)->
    minutes_to_times(times_to_minutes(B) - times_to_minutes(A)).
    

remove_minutes(A,M) ->
    minutes_to_times(times_to_minutes(A) - M). 
