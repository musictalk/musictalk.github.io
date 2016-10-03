module Routing exposing (..)

import Navigation
import UrlParser exposing (..)
import Regex

import Model exposing (..)

toUrl : Model -> String
toUrl count =
  "#/" ++ toString count

-- http://localhost:8000/index.html#!/user/123/playlist/456
playlistParser : Parser (String -> String -> a) a
playlistParser =
  s "#!" </> s "user" </> string </> s "playlist" </> string
  
playlistSongParser : Parser (String -> String -> String -> a) a
playlistSongParser =
  s "#!" </> s "user" </> string </> s "playlist" </> string </> s "song" </> string


pageParser : Parser (QueryString -> a) a
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
    custom "FAIL" match

fromUrl : String -> Result String Page
fromUrl url =
    parse identity (oneOf
      [ --format Playlists (s "playlists")
        format (\x y song -> Playlist x y (Just song)) playlistSongParser
      , format (\x y -> Playlist x y Nothing) playlistParser
      , format LoginResult pageParser
      , custom "" (\_ -> Ok Index)
      ]) url


urlParser : Navigation.Parser (Result String Page)
urlParser =
  Navigation.makeParser (fromUrl << .hash)


pageToData : Model -> Page -> PageData
pageToData model p =
  let _ = Debug.log "pageToData" (dumpModel model, p) in
  case p of
    Index -> IndexData []
    Playlist u p s ->
      case model.page of
        PlaylistDetails pl so -> if pl.id == p then PlaylistDetails pl s else PlaylistReq u p s 
        _ -> PlaylistReq u p s
    _ -> Debug.crash "pageToData" p
