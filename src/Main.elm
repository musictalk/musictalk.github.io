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


-- MODEL


-- Init Model
init : Flags -> Result String Routing.Page -> (Model, Cmd Msg)
init flags r =
  case Debug.log "init" r of
    Ok (Routing.LoginResult r) ->
      ( {flags = flags, state = GotToken r.token }
      , Cmd.batch[ Spotify.getUserInfo r.token, Spotify.getPlaylists r.token ]
      )
    _ -> Routing.urlUpdate r  {flags = flags, state = Unlogged }

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
        GotToken r -> Debug.crash "got token"
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

