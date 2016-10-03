module Model exposing (..)

import Http

type alias Location = String


type alias Flags = { location: Location }


type alias QueryString =  { token : String, tokenType : String, expiration : String }

type Page = Index
          | LoginResult QueryString
          | Playlist UserId PlaylistId (Maybe SongId)

type PageData = IndexData (List SpotifyPlaylist)
              | PlaylistReq UserId PlaylistId (Maybe SongId)
              | PlaylistDetails SpotifyPlaylist (Maybe SongId)
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
type alias SongId = String

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
  | LoadSongComments SpotifyPlaylist Song
  | Logout

dumpUpdate : Msg -> String
dumpUpdate update = case update of
    StartSpotifyLogin -> "StartSpotifyLogin"
    QueryCachedToken _ -> "QueryCachedToken"
    SpotifyResponse (_,x) -> "SpotifyResponse " ++
      (case x of
        SpotifyUser _ -> "SpotifyUser"
        SpotifyPlaylists _ -> "SpotifyPlaylists"
        SpotifyError _ -> "SpotifyError")
    LoadPlaylist _ -> "LoadPlaylist"
    ReceiveTracks _ -> "ReceiveTracks"
    LoadPlaylistComments _ -> "LoadPlaylistComments"
    LoadSongComments _ _ -> "LoadSongComments"
    Logout -> "Logout"

dumpModel : Model -> ( String, String )
dumpModel model = 
  let l = case model.state of
            Unlogged -> "Unlogged"
            GotToken _ -> "GotToken" 
            LoggedIn _ _ -> "LoggedIn" 
      pd = case model.page of
             IndexData _ -> "IndexData"
             PlaylistReq _ _ _ -> "PlaylistReq"
             PlaylistDetails _ _ -> "PlaylistDetails"
  in
    (l,pd)

dump : Msg -> Model -> ( String, ( String, String ) )
dump update model = (dumpUpdate update, dumpModel model) 