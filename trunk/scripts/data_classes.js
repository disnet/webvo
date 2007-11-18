/****************************************************/
function ListingData(url) {
    this._url = url;
    this._query = {'json':'true'};
    this._stats = new Stats();
    this.numHours = 3;

    connect('btnLoad','onclick',this,'btnChangeDate');
    bindMethods(this);
}

/*  function will refresh data */
ListingData.prototype = {
    update : function(start,stop) {
        if (undefined == start || undefined == stop) {
            var d = loadJSONDoc(this._url,this._query);
            d.addCallbacks(this._gotRequest,this._fetchFailed);

            this._stats.update(this._statsReady);
        }
        else {
            console.log(start);
            console.log(stop);
            this._query.start_date_time = start;
            //this._query.stop_date_time = stop;
            var d = loadJSONDoc(this._url,this._query);
            d.addCallbacks(this._gotRequest,this._fetchFailed);
        }
    },

    btnChangeDate: function(e) {
        // Fill a Date object with the date stored in the select box
        var date = new Date($('selDate').value);
        date.setHours($('selTime').value);
        date.setMinutes(0);
        date.setSeconds(0);

        // Check to see if we are at the end of our schedule
        var lastDay = new Date($('selDate').options[$('selDate').options.length - 1].value); // grabs the very last day
        lastDay.setHours(23 - (this.numHours - 1));   // move the end time back the length of the display schedule

        if (date > lastDay) { // if selected date is after the last <numHours> of the schedule
            date = lastDay;
        }
        
        // initialize the time header
        this.timesHeader = [];
        headDate = new Date(date);
        for (var i = 0; i < this.numHours; i++) {
            this.timesHeader.push( mil2std(headDate.getHours().toString() + ":00"));
            this.timesHeader.push( mil2std(headDate.getHours().toString() + ":30"));
            headDate.setHours(headDate.getHours() + 1);       
        }
       
        
        
        // find what date/time we want
        this.start = date;
        this.stop = new Date(date);
        this.stop.setHours(date.getHours() + this.numHours);
        
        // send the request
        this.update(Util.dateToZapTime(this.start),Util.dateToZapTime(this.stop));
        /*
         var d = doSimpleXMLHttpRequest('ruby/form_listing.rb',
            {'start_date_time':dateToZapTime(this.start),'end_date_time':dateToZapTime(this.stop)});
        d.addCallbacks(gotProgrammes,fetchFailed);
        */
    },

    _gotRequest : function(req) {
        this.data = req;
        var boxDate = $('boxDate');
        $('schedule').innerHTML = this.data.header;
        
    },

    _statsReady : function() {
        var date_range = this._stats.data.programme_date_range;

        var boxDate = $('boxDate');
        var selDate = $('selDate');
        
        var time = new Date();
        boxDate.firstChild.nodeValue = time.toLocaleDateString();
        this._fillSelTime();
        this._fillSelDate(date_range.start,date_range.stop);
    },

    _fillSelDate: function(start,stop) {
        var dayOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
        var dStart= isoDate(start);
        var dStop= isoDate(stop);
        //return;
        while(dStart <= dStop) { 
            var opDate = OPTION({'value':dStart}, 
                [dayOfWeek[dStart.getDay()] + " " + dStart.getDate()]);
            $('selDate').appendChild(opDate);
            dStart.setDate(dStart.getDate() + 1);
        }
        today = time;
        today.setHours(0);
        today.setMinutes(0);
        today.setSeconds(0);
        selDay = new Date( $('selDate').value );
        if (today > selDay) {
            $('selDate').value = today;
        }
    },

    _fillSelTime: function() {
        var selTime = $('selTime');
        var time = new Date; 
        time.setHours(0);

        for(var i = 0; i < 24; i++) {
            var tmpTime = Util.mil2std(time.getHours() + ':00');
            selTime.appendChild( OPTION({'value':time.getHours()},tmpTime) );
            time.setHours(time.getHours() + 1);
        }
    }
};

/****************************************************/
function Stats() {
    this.data = null;
    bindMethods(this);
}

Stats.prototype = {
    update: function(callback) {
        var d = loadJSONDoc('ruby/form_stats.rb?json=true');
        d.addCallbacks(this._gotRequest,this._fetchFailed);
        d.addCallback(callback);
    },
    
    _gotRequest: function(req) {
        this.data = req;
    },

    _fetchFailed: function(req) {
        //pass
    }
};

/****************************************************/
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
