module Routing exposing (..)

import Navigation
import UrlParser exposing ((</>))
import Regex

import Model exposing (..)

toUrl : Model -> String
toUrl count =
  "#/" ++ toString count

-- http://localhost:8000/index.html#!/user/123/playlist/456
playlistParser : UrlParser.Parser (String -> String -> a) a
playlistParser =
  UrlParser.s "#!" </> UrlParser.s "user" </> UrlParser.string </> UrlParser.s "playlist" </> UrlParser.string
  


-- pageParser : UrlParser.Parser (Page -> a) a
pageParser =
  let r = Regex.regex "#access_token=(.*)&token_type=(.*)&expires_in=(\\d+)"
      match = (\x ->
        let l = Regex.find Regex.All r x in
          if List.isEmpty l then Err "no match"
          else
            -- let lh = List.head l
            --     fm = Result.fromMaybe "" lh
            l |> List.head
              |> Result.fromMaybe ""
              |> Result.map (.submatches >> List.filterMap identity)
              |> flip Result.andThen (\l ->
                  case l of
                    [a,b,c] -> Ok { token = a, tokenType = b, expiration = c }
                    _ -> Err "Struct")
            -- (Result.map .submatches) << Result.fromMaybe "" << List.head <| l
          ) 
  in
    UrlParser.custom "FAIL" match

fromUrl : String -> Result String Page
fromUrl url =
    UrlParser.parse identity (UrlParser.oneOf
      [ --UrlParser.format Playlists (UrlParser.s "playlists")
        UrlParser.format Playlist playlistParser
      , UrlParser.format LoginResult pageParser
      , UrlParser.custom "" (\_ -> Ok Index)
      ]) url


urlParser : Navigation.Parser (Result String Page)
urlParser =
  Navigation.makeParser (fromUrl << .hash)


pageToData : Page -> PageData
pageToData p = case p of
  Index -> IndexData []
  Playlist u p -> PlaylistDetails (Err(u, p))
  _ -> Debug.crash "pageToData" p
