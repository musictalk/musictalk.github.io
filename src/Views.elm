module Views exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, id, attribute, href, type', src, width, height, alt)
import Model exposing (..)


navView : Model -> Html Msg
navView model =
    nav [ class "navbar navbar-default navbar-custom navbar-fixed-top", id "mainNav" ]
        [ div [ class "container" ]
            [ div [ class "navbar-header page-scroll" ]
                [ button [ class "navbar-toggle", attribute "data-target" "#bs-example-navbar-collapse-1", attribute "data-toggle" "collapse", type' "button" ]
                    [ span [ class "sr-only" ]
                        [ text "Toggle navigation" ]
                    , text "Menu "
                    , i [ class "fa fa-bars" ]
                        []
                    ]
                , a [ class "navbar-brand page-scroll", href "#page-top" ]
                    [ text "musictalk" ]
                ]
            , div [ class "collapse navbar-collapse", id "bs-example-navbar-collapse-1" ]
                [ ul [ class "nav navbar-nav navbar-right" ]
                    [ li [ class "hidden" ]
                        [ a [ href "#page-top" ] [] ]
                    , li []
                        [ a [ class "page-scroll", href "#portfolio" ] [ text "Playlists" ] ]
                    , userProfile model
                    ]
                ]
            ]
        ]


spotifyBigLoginView : Html Msg
spotifyBigLoginView =
    section [ class "bg-light-gray", id "team" ]
        -- [ div [ class "container" ]
        --       [
        --           div [ class "jumbotron"]
        --               [ h1 [] [ text "connect to spotify"]
        --               , p [] [ text "connect to spotify" ]
        --               , button
        --                     [ onClick StartSpotifyLogin
        --                     , class "btn btn-primary btn-lg btn-block"
        --                     ]
        --                     [ text "Log to spotify" ]
        --               ]
        --       ]
        [ div [ class "row" ]
            [ div [ class "col-lg-12 text-center" ]
                [ h2 [ class "section-heading" ]
                    [ text "Connect to Spotify" ]
                , p [] [ text "Link your account to display your playlists" ]
                , h3 [ class "section-subheading text-muted" ]
                    [ button
                        [ onClick StartSpotifyLogin
                        , class "btn btn-primary btn-lg"
                        ]
                        [ text "Login" ]
                    ]
                ]
            ]
          -- ]
        ]


spotifyLoginView : Html Msg
spotifyLoginView =
    button
        [ onClick StartSpotifyLogin
        , class "btn navbar-btn"
        ]
        [ text "Not connected" ]


userProfile : Model -> Html Msg
userProfile model =
    case model.state of
        LoggedIn token user ->
            let
                imgSrc =
                    List.head user.photo |> Maybe.withDefault ""
            in
                li []
                    [ p [ class "navbar-text" ]
                        [ Html.img [ src imgSrc, class "img-circle", width 30 ] []
                        , text user.name
                        ]
                      --   , div [] (List.map (\x -> Html.img [src x, class "img-circle img-responsive",  width 30] []) user.photo)
                    ]

        _ ->
            spotifyLoginView


viewSong : Int -> SpotifyPlaylist -> Song -> Maybe SongId -> List (Html Msg)
viewSong i p song selectedSong =
    let
        isCurrentSong =
            case selectedSong of
                Just selId ->
                    song.id == selId

                _ ->
                    False
    in
        tr
            (if isCurrentSong then
                [ class "info" ]
             else
                []
            )
            [ th [ id <| song.id, attribute "scope" "row" ] [ text (toString <| i + 1) ]
            , td [] [ text song.name ]
            , td [] [ text song.artist ]
            , td [] [ text song.album ]
              -- , td [] [ a [href (song.href ++ "#disqus_thread"), attribute "data-disqus-identifier" song.id] [text song.id] ]
            , td []
                [ {- span [ href (playlistSongUrl p s)
                            , attribute "data-disqus-identifier" (p.id ++ "/" ++ song.id)
                            ] [text song.id]
                     ,
                  -}
                  a [ class "commentsLink", onClick (LoadSongComments p song) ]
                    [ span [ class "glyphicon glyphicon-comment" ] []
                    , span
                        [ class "disqus-comment-count"
                        , attribute "data-disqus-identifier" (p.id ++ "/" ++ song.id)
                        ]
                        []
                    ]
                ]
            ]
            :: if isCurrentSong then
                [ tr []
                    [ td [ attribute "colspan" "5" ]
                        [ div [ id "disqus_thread" ] [] ]
                    ]
                ]
               else
                []


playlistUrl : SpotifyPlaylist -> String
playlistUrl playlist =
    "#!/user/" ++ playlist.owner ++ "/playlist/" ++ playlist.id


playlistSongUrl : SpotifyPlaylist -> SongId -> String
playlistSongUrl playlist songId =
    playlistUrl playlist ++ "/song/" ++ songId


viewPlaylist : SpotifyPlaylist -> Html Msg
viewPlaylist playlist =
    div [ class "col-md-4 col-sm-6 portfolio-item" ]
        [ a [ class "portfolio-link", href <| playlistUrl playlist ]
            [ div [ class "portfolio-hover" ]
                [ div [ class "portfolio-hover-content" ]
                    [ i [ class "fa fa-plus fa-3x" ]
                        []
                    ]
                ]
            , img [ alt "", class "img-responsive", src playlist.image ]
                --, width 360, height 360 ]
                []
            ]
        , div [ class "portfolio-caption" ]
            [ h4 []
                [ text playlist.name ]
            , p [ class "text-muted" ]
                [ text playlist.owner ]
            ]
        ]


viewPlayLists : List SpotifyPlaylist -> Html Msg
viewPlayLists playlists =
    let
        mapPlaylist =
            \i p ->
                List.concat
                    [ [ viewPlaylist p ]
                    , (if (i + 1) % 3 == 0 then
                        [ div [ class "clearfix visible-md-block visible-lg-block" ] [] ]
                       else
                        []
                      )
                    , (if (i + 1) % 2 == 0 then
                        [ div [ class "clearfix visible-sm-block" ] [] ]
                       else
                        []
                      )
                    ]
    in
        section [ class "bg-light-gray", id "portfolio" ]
            [ div [ class "container" ]
                [ div [ class "row" ]
                    [ div [ class "col-lg-12 text-center" ]
                        [ h2 [ class "section-heading" ]
                            [ text "Playlists" ]
                        , h3 [ class "section-subheading text-muted" ]
                            [ text "Public and private" ]
                        ]
                    ]
                , div [ class "row" ] ((List.concatMap identity << List.indexedMap mapPlaylist) playlists)
                ]
            ]


headerView : Model -> Html Msg
headerView model =
    header []
        [ div [ class "container" ]
            [ div [ class "intro-text" ]
                [ div [ class "intro-heading" ]
                    [ text "discuss playlists" ]
                , div [ class "intro-lead-in" ]
                    [ text "(and ask for more)" ]
                  -- , a [ class "page-scroll btn btn-xl", href "#services" ]
                  --     [ text "Tell Me More" ]
                ]
            ]
        ]


content : Model -> Html Msg
content model =
    case model.state of
        Unlogged ->
            spotifyBigLoginView

        LoggedIn token user ->
            case model.page of
                IndexData playlists ->
                    viewPlayLists playlists

                -- h1 [] [ text "playlists" ]
                PlaylistDetails playlist selectedSong ->
                    let
                        _ =
                            Debug.log "selected song" selectedSong
                    in
                        div [ class "bg-light-gray", id "playlist" ]
                            [ div [ class "container" ]
                                -- [ div [ class "row" ]
                                [ div [ class "jumbotron text-center" ]
                                    -- [ div [ class "col-lg-4 col-md-offset-4 text-center" ]
                                    [ img [ alt "", class "img-responsive center-block img-rounded", src playlist.image ] []
                                    , h2 [ class "section-heading" ]
                                        [ text playlist.name ]
                                    , h3 [ class "section-subheading text-muted" ]
                                        [ text playlist.owner ]
                                    ]
                                  -- ]
                                , div []
                                    -- , div [ class "row" ]
                                    --   [ div [class "col-lg-6 col-md-offset-3"]
                                    [ table [ class "table table-condensed table-striped" ]
                                        [ thead [] [ tr [] [ th [] [ text "#" ], th [] [ text "Title" ], th [] [ text "Artist" ], th [] [ text "Album" ], th [] [] ] ]
                                        , tbody [] (List.indexedMap (\i song -> viewSong i playlist song selectedSong) playlist.songs |> List.concat)
                                        ]
                                    , node "script" [ attribute "type" "text/javascript" ] [ text "setupTables();" ]
                                    ]
                                , node "script" [ attribute "type" "text/javascript" ] [ text "DISQUSWIDGETS.getCount({reset: true});" ]
                                  --   ]
                                ]
                            ]

                PlaylistReq _ _ _ ->
                    text "ERROR"

        _ ->
            div [] [ text (toString model) ]


view : Model -> Html Msg
view model =
    div []
        [ navView model
        , headerView model
        , content model
        , footerView
        ]


footerView : Html Msg
footerView =
    footer []
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "col-md-4" ]
                    [ span [ class "copyright" ]
                        [ text "Copyright © musictalk 2016" ]
                    ]
                , div [ class "col-md-4" ]
                    [ ul [ class "list-inline social-buttons" ]
                        [ li []
                            [ a [ href "https://github.com/theor" ]
                                [ i [ class "fa fa-github" ]
                                    []
                                ]
                            ]
                          -- , li []
                          --     [ a [ href "#" ]
                          --         [ i [ class "fa fa-facebook" ]
                          --             []
                          --         ]
                          --     ]
                          -- , li []
                          --     [ a [ href "#" ]
                          --         [ i [ class "fa fa-linkedin" ]
                          --             []
                          --         ]
                          --     ]
                        ]
                    ]
                  -- , div [ class "col-md-4" ]
                  --     [ ul [ class "list-inline quicklinks" ]
                  --         [ li []
                  --             [ a [ href "#" ]
                  --                 [ text "Privacy Policy" ]
                  --             ]
                  --         , li []
                  --             [ a [ href "#" ]
                  --                 [ text "Terms of Use" ]
                  --             ]
                  --         ]
                  --     ]
                ]
            ]
        ]



--   case model.state of
--     Unlogged -> spotifyLoginView
--     GotToken token -> div [] [ text (toString model), text token ]
--     LoggedIn (token, user, playlists) ->
--       div []
--         [ div [ Html.Attributes.id "disqussions_wrapper" ] []
--         , Html.ul []
--             [ Html.li [] [text token]
--             , Html.li [] [userProfile user]
--             ]
--         , Html.ul [] (List.map viewPlaylist playlists)
--         ]
