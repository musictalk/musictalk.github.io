module Routing exposing (..)

import Navigation
import UrlParser exposing ((</>))
import Regex
import String
import Spotify

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

{-| The URL is turned into a result. If the URL is valid, we just update our
model to the new count. If it is not a valid URL, we modify the URL to make
sense.
-}
urlUpdate : Result String Page -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  case Debug.log "urlUpdate" result of
    -- Ok (Playlist uid pid) -> model ! [Spotify.getPlaylistTracks "" uid pid]
    Ok page ->
      ({model | page = page }, Cmd.none)

    Err _ ->
      (model, Navigation.modifyUrl "#")