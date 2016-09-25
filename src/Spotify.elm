module Spotify exposing
    ( loginUrl
    , getUserInfo
    , getPlaylists
    )

import Http exposing (Error)
import Json.Decode exposing (..)
import Task exposing (Task)
import Platform.Cmd

import Model exposing (..)

loginUrl : String
loginUrl =
    Http.url "https://accounts.spotify.com/authorize"
        [ ("client_id","0775af0cec204cbf96932239352abd17")
        , ("response_type","token")
        , ("redirect_uri","http://localhost:8000/index.html")
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

getSpotify : SpotifyToken -> Decoder SpotifyData -> String -> Task Error SpotifyData
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
    object2 (,) ("name" := string) (at ["owner", "id"] string)
    -- ("" := string)
    |> map (\(x,y) -> {name = x, owner = y, songs = []})

decodePlaylists : Decoder SpotifyData
decodePlaylists =
    "items" := list decodePlaylist
    |> map SpotifyPlaylists

fetchListDetails : SpotifyPlaylist -> Task Error SpotifyPlaylist
fetchListDetails l = Task.succeed l


fetchListsDetails : SpotifyData -> Task Error SpotifyData
fetchListsDetails data =
    case data of
        SpotifyPlaylists lists -> Task.map SpotifyPlaylists <| Task.sequence (List.map fetchListDetails lists)
        _ -> Debug.crash "no lists"

getPlaylists : SpotifyToken -> Cmd Msg
getPlaylists token =
    
    getSpotify token decodePlaylists "https://api.spotify.com/v1/me/playlists"
    `Task.andThen` (\asd -> getSpotify token decodePlaylists "https://api.spotify.com/v1/me/playlists")
    |> performTask token

getPlaylistTracks : SpotifyToken -> UserId -> PlaylistId -> List Song
getPlaylistTracks token userId playlistId = []
