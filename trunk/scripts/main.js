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
        var searchText = $('txtSearchTitle').value;
        var d = loadJSONDoc('ruby/form_search.rb',{'title':searchText,'format':'new'});
        d.addCallbacks(search.gotSearch,search.fetchFailed);
    },
    gotSearch: function(req) {
        app.search_data = req;
        var searchTable = $('searched');
        console.log(req);
        searchTable.innerHTML = req.search.header;
        for(var i = 0; i < req.search.programmes.length; i++) {
            searchTable.innerHTML += req.search.programmes[i].html;
        }
    },
    fetchFailed: function(req) {
        console.error("Problem retrieving search results:");
        console.error(req);
    }
};

var app;
window.onload = function() {
    app = new App(true);
    app.init();
}