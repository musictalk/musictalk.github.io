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
    init();
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
        init();
        DISQUS.reset({
            reload: true,
            config: function () {
                this.page.identifier = idUrlTitleIndex[0];
                this.page.url = fullUrl;
                this.page.title = idUrlTitleIndex[2];
                // this.language = newLanguage;
            }
        });
        // $('html,body').animate({
        //     scrollTop: $("#disqus_thread").offset().top - 150
        // });
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

/* * * DON'T EDIT BELOW THIS LINE * * */
var init = function() {
    var element = document.getElementById("element-id");
    if(element)
        element.parentNode.removeChild(element);
    if(window.disqusInitialized || !document.getElementById("disqus_thread"))
        return;
    window.disqusInitialized = true;
    var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
    dsq.src = 'https://' + disqus_shortname + '.disqus.com/embed.js';
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
};
/* * * Disqus Reset Function * * */
var reset = function (newIdentifier, newUrl, newTitle, newLanguage) {
    init();
    DISQUS.reset({
        reload: true,
        config: function () {
            this.page.identifier = newIdentifier;
            this.page.url = "http://localhost:8000/index.html" + newUrl;
            this.page.title = newTitle;
            this.language = newLanguage;
        }
    });
};

init();