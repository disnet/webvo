function ScheduledFrame() {
    this.title = "Show which have been scheduled";   
    this.def = new Deferred();
}

ScheduledFrame.prototype = {
    init: function() {
        makeInvisible('listingContent');
        makeVisible('scheduledContent');
        connect('btnRemoveScheduled','onclick',this.btnRemoveScheduled_click);
        this.load();
    },

    load: function() {
        this.def = doSimpleXMLHttpRequest("ruby/form_scheduled.rb"); 
        this.def.addCallbacks(this.gotScheduled, this.fetchFailed);
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
