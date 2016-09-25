var div = document.getElementById('elm-stamps');
  var app = Elm.Main.embed(div, {location:window.location.origin});
  app.ports.redirect.subscribe(function(urlStr){
      console.log("JS: ",urlStr);
    //   window.location.replace(urlStr);
      window.location.replace(urlStr);
  });
    app.ports.loadComments.subscribe(function(playlist){
        console.log("loadComments: ",playlist);
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

    app.ports.playlistsLoaded.subscribe(function(x){
        disqus_shortname = 'musictalk-1';
        
        console.log("ready",  performance.now(), jQuery(".playlist").length);
        window.requestAnimationFrame(function(time){
            console.log("callback",  performance.now(), jQuery(".playlist").length);
            jQuery(".playlist").inlineDisqussions({
                position: 'right',
                maxWidth: 300
            });
        });
        
    });