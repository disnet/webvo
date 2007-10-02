function App(dbg){
   this._dbg = dbg; 
   this.search_data = null;
   this.listing_data = null;
   this.scheduled_data = null;
   this.recorded_data = null;

   this.search_data = new SearchData();
   this.scheduled_data = new ScheduledData();
   this.recorded_data = new RecordedData();
   this.listing_data = new ListingData();

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
        this.listing_data.update();
    },
    showScheduled: function() {
        this._displayPage($('scheduledContent')); 
        this.scheduled_data.update();
    },
    showRecorded: function() {
        this._displayPage($('recordedContent')); 
        this.recorded_data.update();
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

var app;
window.onload = function() {
    app = new App(true);
    app.init();
}
