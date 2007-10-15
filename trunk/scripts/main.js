function App(dbg){
    this._dbg = dbg; 

    this.listing_data = new ListingData();

    this.scheduled_table = new InfoTable('scheduled','ruby/form_scheduled.rb','ruby/add_recording.rb');
    this.scheduled_table.addUpdateCallback(this._markScheduledAdjacent);

    this.recorded_table = new InfoTable('recorded','ruby/form_recorded.rb','ruby/add_recording.rb');
    this.search_table = new InfoTable('searched','ruby/form_search.rb','ruby/add_recording.rb'); 

    this.pages = [$('listingContent'), $('scheduledContent'), $('recordedContent'), $('searchContent')];
}

function foo() {
    console.log('foo');
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
        this.search_table.update('json=true&title=' + $('txtSearchTitle').value);
    },

    /* Display/hide pages */
    showListing: function() {
        this._displayPage($('listingContent')); 
        this.listing_data.update();
    },
    showScheduled: function() {
        this._displayPage($('scheduledContent')); 
        this.scheduled_table.update('json=true');
    },
    showRecorded: function() {
        this._displayPage($('recordedContent')); 
        this.recorded_table.update('json=true');
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
    },
    
    _markScheduledAdjacent: function() {
        var previousEnd = "";
        for(var i = 0; i < this.scheduled_table.data.programmes.length; i++) {
            if (this.scheduled_table.data.programmes[i].start == previousEnd) {
                addElementClass(this.scheduled_table.data.programmes[i].html_id, "adjacentBefore");
            }
            else {
                removeElementClass(this.scheduled_table.data.programmes[i].html_id, "adjacentBefore");
            }
            previousEnd = this.scheduled_table.data.programmes[i].stop;
        }
    }

};

var app;
window.onload = function() {
    app = new App(true);
    app.init();
}
