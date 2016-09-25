module Model exposing (..)

import Http

type Model = Unlogged
           | GotToken SpotifyToken
           | LoggedIn (SpotifyToken, SpotifyUserData, List SpotifyPlaylist)

type alias SpotifyToken = String
type alias UserId = String
type alias PlaylistId = String

type alias SpotifyUserData = { name : String
                             , photo : List String }

type alias Song = { name : String }

type alias SpotifyPlaylist = { name : String 
                             , owner : String
                             , songs : List Song }

type SpotifyData = SpotifyUser SpotifyUserData
                 | SpotifyPlaylists (List SpotifyPlaylist) 
                 | SpotifyError Http.Error

type Msg
  = StartSpotifyLogin
  | SpotifyResponse (SpotifyToken, SpotifyData)