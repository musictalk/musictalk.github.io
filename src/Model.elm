module Model exposing (..)

import Http

type alias Location = String
type alias Flags = { location: Location }

type ModelState = Unlogged
                | GotToken SpotifyToken
                | LoggedIn (SpotifyToken, Maybe SpotifyUserData, List SpotifyPlaylist)


type alias Model =
  { flags : Flags
  , state : ModelState 
  }
type alias SpotifyToken = String
type alias UserId = String
type alias PlaylistId = String

type alias SpotifyUserData = { name : String
                             , photo : List String }

type alias Song = { name : String
                  , album : String
                  , artist : String
                  }

type alias SpotifyPlaylist = { id : String
                             , name : String 
                             , owner : UserId
                             , songs : List Song
                             , image : String }

type SpotifyData = SpotifyUser SpotifyUserData
                 | SpotifyPlaylists (List SpotifyPlaylist) 
                 | SpotifyError Http.Error

type Msg
  = StartSpotifyLogin
  | QueryCachedToken SpotifyToken
  | SpotifyResponse (SpotifyToken, SpotifyData)
  | LoadPlaylist SpotifyPlaylist
  | ReceiveTracks (Result Http.Error SpotifyPlaylist)
  | LoadPlaylistComments SpotifyPlaylist