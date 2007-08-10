function ScheduledFrame() {
    this.title = "Show which have been scheduled";   
    this.def = new Deferred();
}

ScheduledFrame.prototype = {
    init: function() {
        connect('btnRemoveScheduled','onclick',this.btnRemoveScheduled_click);
    },

    load: function() {
    },

    
    /* Event handlers */
    gotScheduled: function(req) {
        console.log(req);
    },

    fetchFailed: function(req) {
        console.error("Error fetching scheduled data",req);
    },

    btnRemoveScheduled_click: function(e) {
        console.log("The button has been clicked");
    }
};

function ListingFrame() {
    this.title = "Listing";
    this.def = new Deferred();
}

ListingFrame.prototype = {
    init: function() {
    },

    load: function() {
        this.def = doSimpleXMLHttpRequest("ruby/form_listing.rb",
            {'start_date_time': '20070809190000', 'end_date_time': '20070809220000'}
        );
        this.def.addCallbacks(this.gotListing, this.fetchFailed);
    },

    gotListing: function(req) {
        console.log(req); 
    },

    fetchFailed: function(req) {
        console.error("Fetch Failed");
    }
};
