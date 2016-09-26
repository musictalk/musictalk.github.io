module Routing exposing (..)

import Navigation
import UrlParser exposing ((</>))
import Regex
import String
import Spotify

import Model exposing (..)

type alias QueryString =  { token : String, tokenType : String, expiration : String }
type Page = Index | LoginResult QueryString | Playlist String String
toUrl : Model -> String
toUrl count =
  "#/" ++ toString count

-- http://localhost:8000/index.html#!/user/123/playlist/456
playlistParser : UrlParser.Parser (Page -> a) a
playlistParser =
  UrlParser.s "#!" </> UrlParser.s "user" </> UrlParser.string </> UrlParser.s "playlist" </> UrlParser.string
  |> UrlParser.format Playlist


pageParser : UrlParser.Parser (Page -> a) a
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
                    [a,b,c] -> Ok <| LoginResult { token = a, tokenType = b, expiration = c }
                    _ -> Err "Struct")
            -- (Result.map .submatches) << Result.fromMaybe "" << List.head <| l
          ) 
  in
    UrlParser.custom "FAIL" match

fromUrl : String -> Result String Page
fromUrl url =
    UrlParser.parse identity (UrlParser.oneOf [
      playlistParser,
      pageParser,
      UrlParser.custom "" (\s -> if String.isEmpty s then Ok Index else Err "NotEmpty")
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
    -- Ok Index -> (model, redirect Spotify.loginUrl)
    Ok (Playlist uid pid) -> model ! [Spotify.getPlaylistTracks "" uid pid]
    Ok newCount ->
      (model, Cmd.none)

    Err _ ->
      (model, Navigation.modifyUrl "#")