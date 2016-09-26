module Spotify exposing
    ( loginUrl
    , getUserInfo
    , getPlaylists
    , getPlaylistTracks
    , playlistId
    )

import Http exposing (Error)
import Json.Decode exposing (..)
import Task exposing (Task)
import Platform.Cmd

import Model exposing (..)

import Navigation

playlistId : SpotifyPlaylist -> String
playlistId playlist = playlist.owner ++ "/" ++ playlist.id

loginUrl : String -> String
loginUrl returnUri =
    let asd = Debug.log "loc" Navigation.Location in
    Http.url "https://accounts.spotify.com/authorize"
        [ ("client_id","0775af0cec204cbf96932239352abd17")
        , ("response_type","token")
        , ("redirect_uri", returnUri ++ "/index.html")
        , ("scope", "playlist-read-private")
        ]

get : SpotifyToken -> Decoder value -> String -> Task Error value
get token decoder url =
    let request =
        { verb = "GET"
        , headers = [("Authorization","Bearer " ++ token)]
        , url = url
        , body = Http.empty
        }
        d = decoder
        -- d = (map (Debug.log "json") decoder)
    in
      Http.fromJson d (Http.send Http.defaultSettings request)

performTask token = Task.perform (\x -> SpotifyResponse(token, SpotifyError x)) (\x -> SpotifyResponse(token, x))

getSpotify : SpotifyToken -> Decoder a -> String -> Task Error a
getSpotify token decoder url =
    get token decoder url

decodeUser : Decoder SpotifyData
decodeUser =
    object2 (SpotifyUserData) ("display_name" := string) ("images" := list ("url" := string))
    |> map SpotifyUser

getUserInfo : SpotifyToken -> Cmd Msg
getUserInfo token =
    getSpotify token decodeUser "https://api.spotify.com/v1/me" 
    |> performTask token
        

decodePlaylist : Decoder SpotifyPlaylist
decodePlaylist =
    object5 SpotifyPlaylist
        ("id" := string)
        ("name" := string)
        (at ["owner", "id"] string)
        (succeed [])
        ("images" := list ("url" := string) |> map (List.head >> Maybe.withDefault ""))
    -- ("" := string)
    --|> map (\(id, name, owner) -> { id = id, name = name, owner = owner, songs = []})

decodePlaylists : Decoder SpotifyData
decodePlaylists =
    "items" := list decodePlaylist
    |> map SpotifyPlaylists


decodeTrack : Decoder Song
decodeTrack =
    object3 Song
        (at ["track","name"] string)
        (at ["track", "album","name"] string)
        (at ["track", "artists" ] (list ("name" := string)) |> map (List.head >> Maybe.withDefault "<Unknown>"))
        --  |> map (\x -> {name = x})

decodePlaylistTracks : SpotifyPlaylist -> Decoder SpotifyPlaylist
decodePlaylistTracks l =
    -- Json.Decode.succeed l
    "items" := list decodeTrack |> map (\songs -> {l | songs = songs})

fetchListDetails : SpotifyToken -> SpotifyPlaylist -> Task Error SpotifyPlaylist
fetchListDetails token l =
    getSpotify token (decodePlaylistTracks l) ("https://api.spotify.com/v1/users/"++ l.owner ++"/playlists/" ++ l.id ++ "/tracks")
    -- Task.succeed l

fetchListsDetails : SpotifyToken -> SpotifyData -> Task Error SpotifyData
fetchListsDetails token data =
    case data of
        SpotifyPlaylists lists -> Task.map SpotifyPlaylists <| Task.sequence (List.map (fetchListDetails token) lists)
        _ -> Debug.crash "no lists"

getPlaylists : SpotifyToken -> Cmd Msg
getPlaylists token =
    getSpotify token decodePlaylists "https://api.spotify.com/v1/me/playlists"
    -- `Task.andThen` fetchListsDetails token
    |> performTask token

getPlaylistTracks : SpotifyToken -> SpotifyPlaylist -> Cmd Msg
getPlaylistTracks token l =
    fetchListDetails token l
    |> Task.perform (ReceiveTracks << Err) (ReceiveTracks << Ok)
