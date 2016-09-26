port module Main exposing (..)

import Navigation
import Http

-- import Commands
import Model exposing (..)
import Spotify
import Views
import Routing


main : Program Flags
main =
  Navigation.programWithFlags Routing.urlParser
    { init = init
    , view = Views.view
    , update = update
    , urlUpdate = Routing.urlUpdate
    , subscriptions = subscriptions 
    }

port redirect : String -> Cmd msg
port loadComments : SpotifyPlaylist -> Cmd msg
port playlistsLoaded : String -> Cmd msg
port storeToken : String -> Cmd msg
port queryToken : () -> Cmd msg
port answerToken : (String -> msg) -> Sub msg

-- MODEL


-- Init Model
init : Flags -> Result String Routing.Page -> (Model, Cmd Msg)
init flags r =
  case Debug.log "init" r of
    Ok (Routing.LoginResult r) ->
      {flags = flags, state = GotToken r.token }
        ! [ storeToken r.token, Spotify.getUserInfo r.token, Spotify.getPlaylists r.token ]
    Ok (Routing.Index) -> { flags = flags, state = Unlogged} ! [ queryToken () ]
    _ -> Routing.urlUpdate r  {flags = flags, state = Unlogged }

-- SUBS

subscriptions: Model -> Sub Msg
subscriptions model = answerToken QueryCachedToken


-- UPDATE



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let _ = Debug.log "model" model in
  case Debug.log "update" msg of
    StartSpotifyLogin -> (model, redirect <| Spotify.loginUrl model.flags.location)
  
    QueryCachedToken token -> {flags = model.flags, state = GotToken token } ! [ Spotify.getUserInfo token, Spotify.getPlaylists token ]

    SpotifyResponse (token, SpotifyUser userData) ->
      ( {model | state = LoggedIn (token, Just userData, []) }
      , Cmd.none
      )

    SpotifyResponse (token, SpotifyPlaylists data) ->
      case model.state of
        GotToken r -> { model | state = LoggedIn(r, Nothing, data) } ! []-- [ Spotify.getUserInfo token, Spotify.getPlaylists r ]
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
          , Spotify.getPlaylistTracks t p.owner p.id
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

