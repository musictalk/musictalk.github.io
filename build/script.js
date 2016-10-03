var div = document.getElementById('page-top');
var app = Elm.Main.embed(div, { location: window.location.origin });

app.ports.redirect.subscribe(function (urlStr) {
    console.log("JS: ", urlStr);
    window.location.replace(urlStr);
});
app.ports.loadComments.subscribe(function (playlist) {
    console.log("loadComments: ", playlist);
    var threadId = playlist.owner + "/" + playlist.id;
    console.log("loadComments threadId: ", threadId);
    DISQUS.reset({
        reload: true,
        config: function () {
            this.page.identifier = threadId;
            this.page.url = "http://musictalk.github.io/#!/user/" + playlist.owner + "/playlist/" + playlist.id;
        }
    });

});

app.ports.loadSongComments.subscribe(function (idUrlTitleIndex) {
    console.log("loadSongComments", idUrlTitleIndex);
    window.requestAnimationFrame(function (t) {
        console.log("loadSongComments CALLBACK", idUrlTitleIndex);
        var fullUrl = location.origin + location.pathname + idUrlTitleIndex[1];
        DISQUS.reset({
            reload: true,
            config: function () {
                this.page.identifier = idUrlTitleIndex[0];
                this.page.url = fullUrl;
                this.page.title = idUrlTitleIndex[2];
                // this.language = newLanguage;
            }
        });
        $('html,body').animate({
            scrollTop: $("#disqus_thread").offset().top - 50
        });
    });
})

// app.ports.playlistsLoaded.subscribe(function (x) {
//     disqus_shortname = 'musictalk-1';

//     console.log("ready", performance.now(), jQuery(".playlist").length);
//     window.requestAnimationFrame(function (time) {
//         console.log("callback", performance.now(), jQuery(".playlist").length);
//         jQuery(".playlist").inlineDisqussions({
//             position: 'right',
//             maxWidth: 300
//         });
//     });

// });


app.ports.storeToken.subscribe(function (token) {
    // console.log("token", token);
    window.localStorage.setItem("token", token);
    app.ports.answerToken.send(token);
})

app.ports.queryToken.subscribe(function () {
    console.log("query token");
    var t = window.localStorage.getItem("token");
    if (t != null)
        app.ports.answerToken.send(t);
});

var setup = function (_) {
    if ($('#mainNav').length == 0) {
        window.requestAnimationFrame(setup);
        return;
    }
    $('#mainNav').affix({
        offset: {
            top: 100
        }
    });
};
setup();

function setupTables() {
    // console.log ("setupTables", $('.table'));
    // $('.table').DataTable({"paging":   false, "info": false});
}