module Model exposing (..)

import Http

type alias Location = String


type alias Flags = { location: Location }


type alias QueryString =  { token : String, tokenType : String, expiration : String }
type Page = Index | LoginResult QueryString | Playlist String String
type PageData = IndexData (List SpotifyPlaylist)
              | PlaylistDetails (Result (String, String) SpotifyPlaylist)
              -- | LoginResultData QueryString 

type LoginState = Unlogged
                | GotToken SpotifyToken
                | LoggedIn SpotifyToken SpotifyUserData

-- type ModelState = Unlogged
--                 | GotToken SpotifyToken
--                 | LoggedIn (SpotifyToken, Maybe SpotifyUserData, List SpotifyPlaylist)


type alias Model =
  { flags : Flags
  , state : LoginState 
  , page : PageData
  }

-- Spotify

type alias SpotifyToken = String
type alias UserId = String
type alias PlaylistId = String

type alias SpotifyUserData = { name : String
                             , photo : List String }

type alias Song = { id : String
                  , name : String
                  , album : String
                  , artist : String
                  , href : String
                  }

type alias SpotifyPlaylist = { id : String
                             , name : String 
                             , owner : UserId
                             , songs : List Song
                             , image : String }

type SpotifyData = SpotifyUser SpotifyUserData
                 | SpotifyPlaylists (List SpotifyPlaylist) 
                 | SpotifyError Http.Error

-- Actions

type Msg
  = StartSpotifyLogin
  | QueryCachedToken SpotifyToken
  | SpotifyResponse (SpotifyToken, SpotifyData)
  | LoadPlaylist SpotifyPlaylist
  | ReceiveTracks (Result Http.Error SpotifyPlaylist)
  | LoadPlaylistComments SpotifyPlaylist