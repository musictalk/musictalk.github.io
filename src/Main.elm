port module Main exposing (..)

import Html exposing (Html, button, div, text)
import Navigation
import UrlParser exposing ((</>))
import Regex
import String
import Html.Events exposing (onClick)
import Html.Attributes

-- import Commands
import Model exposing (..)
import Spotify

main : Program Never
main =
  Navigation.program urlParser
    { init = init
    , view = view
    , update = update
    , urlUpdate = urlUpdate
    , subscriptions = subscriptions 
    }

port redirect : String -> Cmd msg


type alias QueryString =  { token : String, tokenType : String, expiration : String }
type Page = Index | LoginResult QueryString
toUrl : Model -> String
toUrl count =
  "#/" ++ toString count

pageParser : UrlParser.Parser (Page -> a) a
pageParser =
  let r = Regex.regex "#access_token=(.*)&token_type=(.*)&expires_in=(\\d+)"
      match = (\x ->
        let l = Regex.find Regex.All r x in
          if List.isEmpty l then Err "no match"
          else
            -- let lh = List.head l
            --     fm = Result.fromMaybe "" lh
            l |> List.head
              |> Result.fromMaybe ""
              |> Result.map (.submatches >> List.filterMap identity)
              |> flip Result.andThen (\l ->
                  case l of
                    [a,b,c] -> Ok <| LoginResult { token = a, tokenType = b, expiration = c }
                    _ -> Err "Struct")
            -- (Result.map .submatches) << Result.fromMaybe "" << List.head <| l
          ) 
  in
    UrlParser.custom "FAIL" match

fromUrl : String -> Result String Page
fromUrl url =
    UrlParser.parse identity (UrlParser.oneOf [
      pageParser,
      UrlParser.custom "" (\s -> if String.isEmpty s then Ok Index else Err "NotEmpty")
    ]) url


urlParser : Navigation.Parser (Result String Page)
urlParser =
  Navigation.makeParser (fromUrl << .hash)

{-| The URL is turned into a result. If the URL is valid, we just update our
model to the new count. If it is not a valid URL, we modify the URL to make
sense.
-}
urlUpdate : Result String Page -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  case Debug.log "urlUpdate" result of
    -- Ok Index -> (model, redirect Spotify.loginUrl)
    Ok newCount ->
      (model, Cmd.none)

    Err _ ->
      (model, Navigation.modifyUrl "#")
-- MODEL


-- Init Model
init : Result String Page -> (Model, Cmd Msg)
init r =
  case Debug.log "init" r of
    Ok (LoginResult r) -> (GotToken r.token, Cmd.batch[ Spotify.getUserInfo r.token, Spotify.getPlaylists r.token ])
    _ -> urlUpdate r Unlogged

-- SUBS

subscriptions: Model -> Sub Msg
subscriptions model = Sub.none


-- UPDATE



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  
  case Debug.log "update" msg of
    StartSpotifyLogin -> (model, redirect Spotify.loginUrl)
  
    SpotifyResponse (token, SpotifyUser data) ->
      (LoggedIn (token, data, []), Cmd.none)

    SpotifyResponse (token, SpotifyPlaylists data) ->
      case model of
        LoggedIn(t,u,_) -> (LoggedIn (t, u, data), Cmd.none)
        _ -> Debug.crash (toString (model,msg))
      -- ((LoggedIn (t, u, data)), Cmd.none)
      -- (LoggedIn (t,u,[]), Cmd.none)

    _ -> Debug.crash (toString msg)


-- VIEW

spotifyLoginView : Html Msg
spotifyLoginView = button [onClick StartSpotifyLogin] [ text "Log to spotify" ]

userProfile : SpotifyUserData -> Html Msg
userProfile user =
  div []
    [ text user.name
    , div [] (List.map (\x -> Html.img [Html.Attributes.src x] []) user.photo) 
    ]

viewPlaylist : SpotifyPlaylist -> Html Msg
viewPlaylist p = Html.li [] [ text p.name, text p.owner ]

view : Model -> Html Msg
view model =
  case model of
    Unlogged -> spotifyLoginView
    GotToken token -> div [] [ text (toString model), text token ]
    LoggedIn (token, user, playlists) ->
      div []
        [ Html.ul []
            [ Html.li [] [text token]
            , Html.li [] [userProfile user]
            ]
        , Html.ul [] (List.map viewPlaylist playlists)
          
        ]
        -- div []
      --   [ div [] [ text (toString model) ]
      --   , button [] [ text "+" ]
      --   ]