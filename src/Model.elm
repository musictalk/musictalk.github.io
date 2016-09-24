module Model exposing (..)

import Http

type Model = Unlogged

type alias SpotifyToken = String


type Msg
  = Login SpotifyToken
  | LoginError Http.Error