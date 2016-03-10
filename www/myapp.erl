%% myapp.erl

-module(myapp).
-include("$YAWS_INCLUDES/yaws_api.hrl").
-export([arg_rewrite/1, authenticate/2, check_cookie/2, get_cookie_val/2]).

%% List of pages that can be visited without logging in.
login_pages() -> 
    [ "/index.yaws", "/login_post.yaws","/style.css","/register.yaws" ].

get_cookie_val(CookieName, Arg) ->
    H = Arg#arg.headers,
    yaws_api:find_cookie_val(CookieName, H#headers.cookie).


check_cookie(A, CookieName) ->
    case get_cookie_val(CookieName, A) of
        [] -> {error, "Not Logged In" };
        Cookie -> yaws_api:cookieval_to_opaque(Cookie)
    end.

do_rewrite(Arg) ->
    Req = Arg#arg.req,
    { abs_path, Path } = Req#http_request.path,
    case lists:member(Path, login_pages()) of
        true -> Arg;
        false -> 
            Arg#arg{
                req = Req#http_request{
                    path = { abs_path, "/index.yaws" }
                },
                state = { abs_path, Path }
            }
    end. 

do_rewrite(in, Arg) ->
    Req = Arg#arg.req,
    { abs_path, Path } = Req#http_request.path,
    if "/index.yaws" =:= Path orelse Path =:= "/"-> 
            Arg#arg{
                req = Req#http_request{
                    path = { abs_path, "/inside.yaws" }
                },
                state = { abs_path, Path }
            };
        true -> Arg
    end.

arg_rewrite(Arg) ->
    OurCookie = "lm_sid",
    case check_cookie(Arg, OurCookie) of
        {error, _} -> do_rewrite(Arg);
        {ok, _Session} -> do_rewrite(in,Arg)
    end.

authenticate(User, Password) ->
    U = access_control:validate(User, crypto:md5(Password)),
    case U of
        {true, LUser} -> {ok, LUser};
        {false} -> false
    end.

