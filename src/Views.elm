module Views exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, id, attribute, href, type', src, width, height, alt)
import Model exposing (..)
import Spotify


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
        [ div [ class "container" ]
            [ div [ class "row" ]
                [ div [ class "col-lg-12 text-center" ]
                    [ h2 [ class "section-heading" ]
                        [ text "Our Amazing Team" ]
                    , h3 [ class "section-subheading text-muted" ]
                        [ button
                            [ onClick StartSpotifyLogin
                            , class "btn btn-primary btn-lg btn-block"
                            ]
                            [ text "Log to spotify" ]
                        ]
                    ]
                ]
            ]
        ]


spotifyLoginView : Html Msg
spotifyLoginView =
    button
        [ onClick StartSpotifyLogin
        , class "btn btn-primary navbar-btn"
        ]
        [ text "Log to spotify" ]


userProfile : Model -> Html Msg
userProfile model =
    case model.state of
        LoggedIn ( token, user, playlists ) ->
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


viewSong : Song -> Html Msg
viewSong s =
    Html.li []
        [ text s.name
        , text s.album
        , text s.artist
        ]


viewPlaylist : SpotifyPlaylist -> Html Msg
viewPlaylist playlist =
    div [ class "col-md-4 col-sm-6 portfolio-item" ]
        [ a [ class "portfolio-link", attribute "data-toggle" "modal", href "#portfolioModal1" ]
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



--   Html.li [class "playlist", Html.Attributes.attribute "data-disqus-identifier" (Spotify.playlistId p)]
--     [ text p.name
--     , text p.owner
--     , Html.ul [] (List.map viewSong p.songs)
--     , button [ onClick <| LoadPlaylist p] [ text "load" ]
--     , button [ onClick <| LoadPlaylistComments p] [ text "comments" ]
--     ]


viewPlayLists : List SpotifyPlaylist -> Html Msg
viewPlayLists playlists =
    let mapPlaylist = \i p ->
        List.concat [ [viewPlaylist p]
                    , (if (i+1) % 3 == 0 then [ div [ class "clearfix visible-md-block visible-lg-block"] []] else [])
                    , (if (i+1) % 2 == 0 then [ div [ class "clearfix visible-sm-block"] []] else [])
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
                [ div [ class "intro-lead-in" ]
                    [ text "Welcome To Our Studio!" ]
                , div [ class "intro-heading" ]
                    [ text "It's Nice To Meet You" ]
                , a [ class "page-scroll btn btn-xl", href "#services" ]
                    [ text "Tell Me More" ]
                ]
            ]
        ]


content : Model -> Html Msg
content model =
    case model.state of
        Unlogged ->
            spotifyBigLoginView

        GotToken token ->
            div [] [ text (toString model), text token ]

        LoggedIn ( token, user, playlists ) ->
            viewPlayLists playlists


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
                        [ text "Copyright © Your Website 2016" ]
                    ]
                , div [ class "col-md-4" ]
                    [ ul [ class "list-inline social-buttons" ]
                        [ li []
                            [ a [ href "#" ]
                                [ i [ class "fa fa-twitter" ]
                                    []
                                ]
                            ]
                        , li []
                            [ a [ href "#" ]
                                [ i [ class "fa fa-facebook" ]
                                    []
                                ]
                            ]
                        , li []
                            [ a [ href "#" ]
                                [ i [ class "fa fa-linkedin" ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , div [ class "col-md-4" ]
                    [ ul [ class "list-inline quicklinks" ]
                        [ li []
                            [ a [ href "#" ]
                                [ text "Privacy Policy" ]
                            ]
                        , li []
                            [ a [ href "#" ]
                                [ text "Terms of Use" ]
                            ]
                        ]
                    ]
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
