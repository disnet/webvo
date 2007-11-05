function App(dbg){
    this._dbg = dbg; 
    this.adder = new Adder();
    this.stats = new Stats();
    this.listing_data = new ListingData('ruby/form_listing.rb');

    this.scheduled_table = new InfoTable('scheduled','ruby/form_scheduled.rb','ruby/add_recording.rb');
    this.scheduled_table.setMarkAdjacent(true);

    this.recorded_table = new InfoTable('recorded','ruby/form_recorded.rb','ruby/add_recording.rb');
    this.search_table = new InfoTable('searched','ruby/form_search.rb','ruby/add_recording.rb'); 

    this.pages = [$('listingContent'), $('scheduledContent'), $('recordedContent'), $('searchContent')];
}

App.prototype = {
    init: function() {
        this.showSearch();
        connect('btnSearchSubmit','onclick',this,'searchSubmit');
        connect('btnSearchRecord','onclick',this,'searchAddRecording');
        connect('btnRemoveScheduled','onclick',this,'scheduledRemoveRecording');
        connect('btnDeleteRecorded','onclick',this,'recordedRemoveRecorded');

        connect('btnListing','onclick',this,'showListing');
        connect('btnScheduled','onclick',this,'showScheduled');
        connect('btnRecorded','onclick',this,'showRecorded');
        connect('btnSearch','onclick',this,'showSearch');
    },
    
    searchSubmit: function(e) {
        this.search_table.update('json=true&title=' + $('txtSearchTitle').value);
    },

    searchAddRecording: function(e) {
        var sel = filter(function(el){ return el.checked; }, document.getElementsByName('searchCheck'));
        for(var i = 0; i < sel.length; i++) {
            this.adder.add(sel[i].value);
        }
    },

    scheduledRemoveRecording: function(e) {
        var sel = filter(function(el) {return el.checked; }, document.getElementsByName('scheduledCheck'));
        for(var i = 0; i < sel.length; i++) {
            this.adder.removeRecording(sel[i].value);
        }
    },

    recordedRemoveRecorded: function(e) {
        var sel = filter(function(el) {return el.checked; }, document.getElementsByName('recordedCheck'));
        for(var i = 0; i < sel.length; i++) {
            this.adder.deleteRecorded(sel[i].value);
        }
    },

    /* Display/hide pages */
    showListing: function() {
        this._displayPage($('listingContent')); 
        this.listing_data.update();
        this.stats.update();
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
    }
};

function Stats() {
    bindMethods(this);
}

Stats.prototype = {
    update: function() {
        var d = loadJSONDoc('ruby/form_stats.rb?json=true');
        d.addCallbacks(this._gotReqeust,this._fetchFailed);
    },
    
    _gotRequest: function(req) {
        //pass
    },

    _fetchFailed: function(req) {
        //pass
    }
};

function Adder() {
   bindMethods(this); 
}

Adder.prototype = {
    add: function(id) {
        var d = loadJSONDoc('ruby/add_recording.rb?json=true&prog_id=' + id);
        d.addCallbacks(this._gotAddRequest,this._fetchFailed);
    },
    removeRecording: function(id) {
        var d = loadJSONDoc('ruby/delete_recording.rb?json=true&prog_id=' + id);
        d.addCallbacks(this._gotDelRequest,this._fetchFailed);
    },

    deleteRecorded: function(id) {
        var d = loadJSONDoc('ruby/delete_recorded.rb?json=true?prog_id=' + id);
        d.addCallbacks(this._gotDelRequest,this._fetchFailed);
    },
    _gotAddRequest: function(req) {
//        console.log(req);
    },
    _gotDelRequest: function(req) {
        //pass
    },
    _fetchFailed: function(req) {
        console.log(req);
    }
};
var app;
window.onload = function() {
    app = new App(true);
    app.init();
}
