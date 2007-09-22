function App(dbg){
   this._dbg = dbg; 
   this.search_data = null;
   this.listing_data = null;
   this.scheduled_data = null;
   this.recorded_data = null;

   this.search_data = new SearchData();

   this.pages = [$('listingContent'), $('scheduledContent'), $('recordedContent'), $('searchContent')];
}

App.prototype = {
    init: function() {
        this.showSearch();
        connect('btnSearchSubmit','onclick',this,'searchSubmit');

        connect('btnListing','onclick',this,'showListing');
        connect('btnScheduled','onclick',this,'showScheduled');
        connect('btnRecorded','onclick',this,'showRecorded');
        connect('btnSearch','onclick',this,'showSearch');
    },
    
    searchSubmit: function(e) {
        this.search_data.setQuery('title',$('txtSearchTitle').value);
        this.search_data.update();
    },

    /* Display/hide pages */
    showListing: function() {
        this._displayPage($('listingContent')); 
    },
    showScheduled: function() {
        this._displayPage($('scheduledContent')); 
    },
    showRecorded: function() {
        this._displayPage($('recordedContent')); 
    },
    showSearch: function() {
        this._displayPage($('searchContent')); 
    },

    _displayPage: function(elDisplay) {
        for(var i = 0; i < this.pages.length; i++) {
            if(this.pages[i] != elDisplay) {
                Util.makeInvisible(this.pages[i]);
            }
        }
        Util.makeVisible(elDisplay);
    }
};

function SearchData() {
    bindMethods(this); /* preserve `this` for callbacks */
}
SearchData.prototype = new JSONRequest('ruby/form_search.rb');

SearchData.prototype.setQuery = function(term,val) {
    this._query[term] = val;
}

SearchData.prototype.reqHandler = function() {
    var searchTable = $('searched');
    var temp_html = this.data.search.header;
    for(var i = 0; i < this.data.search.programmes.length; i++) {
        temp_html += this.data.search.programmes[i].html;
    }
    searchTable.innerHTML = temp_html
}
SearchData.prototype.searchFailed = function(req) { 
    console.error("Problem retrieving search results:");
    console.error(req);
}

function JSONRequest(url) {
    this._url = url;
    this._query = {'json':'true'};
}
JSONRequest.prototype.update = function() {
    var d = loadJSONDoc(this._url,this._query);
    d.addCallbacks(this._gotRequest,this._fetchFailed);
}
JSONRequest.prototype._gotRequest = function(req) {
    this.data = req;
    this.reqHandler();
}
JSONRequest.prototype._fetchFailed = function(req) {
    console.log('Abstract method...should have been implemented in child');
}


var app;
window.onload = function() {
    app = new App(true);
    app.init();
}
