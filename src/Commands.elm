module Commands exposing (..)
import Model exposing (..)
import Http
import Json.Decode exposing (Decoder, string, (:=))
import Task

tokenDecoder : Decoder String
tokenDecoder = "token" := string

-- CMDS
-- loginRequest : Cmd Msg
-- loginRequest = 
--   let url =
--     Http.url "https://accounts.spotify.com/authorize" [
--         ("client_id","0775af0cec204cbf96932239352abd17"),
--         ("response_type","token"),
--         ("redirect_uri","http://localhost:8000")
--     ]
--   in
--   Http.get tokenDecoder url
--   |> Task.perform LoginError Login
--   |> Debug.log "loginRequest"
