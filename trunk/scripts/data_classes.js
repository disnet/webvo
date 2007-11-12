/****************************************************/
function ListingData(url) {
    this._url = url;
    this._query = {'json':'true'};
    bindMethods(this);
}

/*  function will refresh data */
// TODO: add callback capability, code outside of data class to be
//  notified when data has been refreshed
ListingData.prototype.update = function() {
    var d = loadJSONDoc(this._url,this._query);
    d.addCallbacks(this._gotRequest,this._fetchFailed);
}

ListingData.prototype._gotRequest = function(req) {
    this.data = req;
    var boxDate = $('boxDate');
    $('schedule').innerHTML = this.data.header;
    
}

/****************************************************/
function Stats() {
    bindMethods(this);
}

Stats.prototype = {
    update: function() {
        var d = loadJSONDoc('ruby/form_stats.rb?json=true');
        d.addCallbacks(this._gotRequest,this._fetchFailed);
    },
    
    _gotRequest: function(req) {
        this._data = req;
        var boxDate = $('boxDate');
        var selDate = $('selDate');
        
        var time = new Date();
        boxDate.firstChild.nodeValue = time.toLocaleDateString();
        this._fillSelTime();
        this._fillSelDate();
    },

    _fillSelDate: function() {
        var start = this._data.programme_date_range.start;
        var end = this._data.programme_date_range.end;
        var d = isoDate(start);
        console.log(d);
        return;
        while(day <= end) { 
            var opDate = OPTION({'value':day}, 
                [dayOfWeek[day.getDay()] + " " + day.getDate()]);
            $('selDate').appendChild(opDate);
            day.setDate(day.getDate() + 1);
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
