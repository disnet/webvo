function App(dbg){
   this._dbg = dbg; 
   this.search_data = null;
   this.listing_data = null;
   this.scheduled_data = null;
   this.recorded_data = null;
}

App.prototype = {
    init: function() {
        Util.makeInvisible($('listingContent'));
        Util.makeVisible($('searchContent'));

        connect('btnSearchSubmit','onclick',search.submit);
    }
};

var search = {
    submit: function(e) {
        var d = loadJSONDoc('ruby/form_search.json');
        d.addCallbacks(search.gotSearch,search.fetchFailed);
    },
    gotSearch: function(req) {
        app.search_data = req;
        $('searched').innerHTML += req.search.programmes[0].html;
        $('searched').innerHTML += req.search.programmes[1].html;
    },
    fetchFailed: function(req) {
        console.log('error in search');
    }
};

var app;
window.onload = function() {
    app = new App(true);
    app.init();
}
