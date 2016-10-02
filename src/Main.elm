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
        , urlUpdate = urlUpdate
        , subscriptions = subscriptions
        }


port redirect : String -> Cmd msg


port loadComments : SpotifyPlaylist -> Cmd msg
port loadSongComments : (String,String,String) -> Cmd msg

port playlistsLoaded : String -> Cmd msg


port storeToken : String -> Cmd msg


port queryToken : () -> Cmd msg


port answerToken : (String -> msg) -> Sub msg



-- MODEL
-- Init Model


init : Flags -> Result String Page -> ( Model, Cmd Msg )
init flags page =
    case Debug.log "init" page of
        Ok (LoginResult r) ->
            { flags = flags, state = Unlogged, page = IndexData [] }
                ! [ storeToken r.token ]

        -- ! [ storeToken r.token, Spotify.getUserInfo r.token, Spotify.getPlaylists r.token ]
        Ok Index ->
            { flags = flags, state = Unlogged, page = IndexData [] } ! [ queryToken () ]

        Ok (Playlist uid pid song) ->
            { flags = flags, state = Unlogged, page = PlaylistDetails (Err (uid, pid, song)) } ! [ queryToken () ]

        -- Err e ->
        --     Routing.urlUpdate page { flags = flags, state = Unlogged, page = IndexData [] }

        _ ->
            Debug.crash ("init error " ++ toString page)



-- SUBS


subscriptions : Model -> Sub Msg
subscriptions model =
    answerToken QueryCachedToken



-- UPDATE


stateCmd : LoginState -> Cmd Msg
stateCmd s =
  case s of
    GotToken t -> Spotify.getUserInfo t
    LoggedIn _ _ -> Cmd.none
    Unlogged -> Debug.crash "Unlogged in state cmd"


pageCmd : SpotifyToken -> PageData -> List (Cmd Msg)
pageCmd token p =
    case p of
        IndexData _ -> [ Spotify.getPlaylists token ]
        PlaylistDetails (Err(uid, pid, song)) -> [ Spotify.getPlaylistTracks token uid pid ]
        PlaylistDetails (Ok _) -> []
        -- _ -> Debug.crash "pageCmd" p


{-| The URL is turned into a result. If the URL is valid, we just update our
model to the new count. If it is not a valid URL, we modify the URL to make
sense.
-}
urlUpdate : Result String Page -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  case Debug.log "urlUpdate" result of
    -- Ok (Playlist uid pid) -> model ! [Spotify.getPlaylistTracks "" uid pid]
    Ok page ->
      case model.state of
        Unlogged -> Debug.crash "unlogged" model
        LoggedIn token _ -> 
          let m = {model | page = Routing.pageToData page } in
          m ! (stateCmd m.state :: pageCmd token m.page)
        GotToken token ->
          let m = {model | page = Routing.pageToData page } in
          m ! (stateCmd m.state :: pageCmd token m.page)

    Err _ ->
      (model, Navigation.modifyUrl "#")

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- let _ = Debug.log "model" model in
        case msg {- Debug.log "update" msg -} of
            StartSpotifyLogin ->
                model ! [ redirect <| Spotify.loginUrl model.flags.location ]

            QueryCachedToken token ->
              let m = { model | state = GotToken token } in
              m ! (stateCmd m.state :: pageCmd token m.page)

            SpotifyResponse ( token, SpotifyUser userData ) ->
                { model | state = LoggedIn token userData } ! [ Cmd.none ]

            SpotifyResponse (token, SpotifyPlaylists data) ->
                { model | page = IndexData data } ! []
            --   case model.state of
            --     GotToken r -> { model | state = LoggedIn(r, Nothing, data) } ! []-- [ Spotify.getUserInfo token, Spotify.getPlaylists r ]
            --     LoggedIn(t,u,_) ->
            --       ( {model | state = LoggedIn (t, u, data) }
            --       , playlistsLoaded ""
            --       )
            --     _ -> Debug.crash (toString (model,msg))
            --   -- ((LoggedIn (t, u, data)), Cmd.none)
            --   -- (LoggedIn (t,u,[]), Cmd.none)
            SpotifyResponse (_, SpotifyError error) ->
              case error of
                Http.BadResponse 401 s ->
                  ( {model | state = Unlogged }
                  , redirect <| Spotify.loginUrl model.flags.location
                  )
                _ -> Debug.crash (toString msg)
            -- LoadPlaylist p ->
            --   case model.state of
            --     LoggedIn(t,u,d) ->
            --       ( {model | state = LoggedIn (t, u, d) }
            --       , Spotify.getPlaylistTracks t p.owner p.id
            --       )
            --     _ -> Debug.crash (toString (model,msg))
            ReceiveTracks (Ok pl) ->
              let _ = Debug.log "ReceiveTracks model" model in
              case model.page of
                PlaylistDetails (Err(_,_,songId)) -> { model | page = PlaylistDetails (Ok (pl, songId)) }
                 ! case songId of
                    Nothing -> []
                    Just jSongId -> [ loadSongComments <| (,,) (pl.id ++ "/" ++ jSongId) (Views.playlistSongUrl pl jSongId) jSongId]
                 
                _ -> Debug.crash "WTF"
            ReceiveTracks (Err _) ->
              model  ! []
            --   case (res, model.state) of
            --     (Ok playlist, LoggedIn(t,u,d)) ->
            --       let dd = List.map (\p -> if p.id == playlist.id then playlist else p) d in
            --       ( {model | state = LoggedIn (t, u, dd) }
            --       , Cmd.none
            --       )
            --     _ -> Debug.crash (toString (model,msg))
            LoadPlaylistComments p ->
                ( model, loadComments p )
            LoadSongComments pl song -> model ! [ Navigation.newUrl (Views.playlistSongUrl pl song.id) ]
                -- [ loadSongComments <| (,,) (pl.id ++ "/" ++ song.id) (Views.playlistSongUrl pl song) song.name]
            _ ->
                -- let
                --     x =
                --         Debug.log "model" model
                -- in
                    Debug.crash (toString msg)
