port module Main exposing (..)

import Navigation
import UrlParser exposing ((</>))
import Regex
import String
import Http

-- import Commands
import Model exposing (..)
import Spotify
import Views


main : Program Flags
main =
  Navigation.programWithFlags urlParser
    { init = init
    , view = Views.view
    , update = update
    , urlUpdate = urlUpdate
    , subscriptions = subscriptions 
    }

port redirect : String -> Cmd msg
port loadComments : SpotifyPlaylist -> Cmd msg
port playlistsLoaded : String -> Cmd msg

type alias QueryString =  { token : String, tokenType : String, expiration : String }
type Page = Index | LoginResult QueryString | Playlist String String
toUrl : Model -> String
toUrl count =
  "#/" ++ toString count

-- http://localhost:8000/index.html#!/user/123/playlist/456
playlistParser : UrlParser.Parser (Page -> a) a
playlistParser =
  UrlParser.s "#!" </> UrlParser.s "user" </> UrlParser.string </> UrlParser.s "playlist" </> UrlParser.string
  |> UrlParser.format Playlist


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
      playlistParser,
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
init : Flags -> Result String Page -> (Model, Cmd Msg)
init flags r =
  case Debug.log "init" r of
    Ok (LoginResult r) ->
      ( {flags = flags, state = GotToken r.token }
      , Cmd.batch[ Spotify.getUserInfo r.token, Spotify.getPlaylists r.token ]
      )
    _ -> urlUpdate r  {flags = flags, state = Unlogged }

-- SUBS

subscriptions: Model -> Sub Msg
subscriptions model = Sub.none


-- UPDATE



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  
  case Debug.log "update" msg of
    StartSpotifyLogin -> (model, redirect <| Spotify.loginUrl model.flags.location)
  
    SpotifyResponse (token, SpotifyUser data) ->
      ( {model | state = LoggedIn (token, data, []) }
      , Cmd.none
      )

    SpotifyResponse (token, SpotifyPlaylists data) ->
      case model.state of
        LoggedIn(t,u,_) ->
          ( {model | state = LoggedIn (t, u, data) }
          , playlistsLoaded ""
          )
        _ -> Debug.crash (toString (model,msg))
      -- ((LoggedIn (t, u, data)), Cmd.none)
      -- (LoggedIn (t,u,[]), Cmd.none)
    SpotifyResponse (_, SpotifyError error) ->
      case error of
        Http.BadResponse 401 s ->
          ( {model | state = Unlogged }
          , redirect <| Spotify.loginUrl model.flags.location
          )
        _ -> Debug.crash (toString msg)  

    LoadPlaylist p ->
      case model.state of
        LoggedIn(t,u,d) ->
          ( {model | state = LoggedIn (t, u, d) }
          , Spotify.getPlaylistTracks t p
          )
        _ -> Debug.crash (toString (model,msg))

    ReceiveTracks res ->
      case (res, model.state) of
        (Ok playlist, LoggedIn(t,u,d)) ->
          let dd = List.map (\p -> if p.id == playlist.id then playlist else p) d in
          ( {model | state = LoggedIn (t, u, dd) }
          , Cmd.none
          )
        _ -> Debug.crash (toString (model,msg))

    LoadPlaylistComments p ->
      (model, loadComments p)
      
    -- _ -> Debug.crash (toString msg)

