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

    showClick: function(e) {
        /* funciton to handle clicking */
        function createActionHandler(server_file,message) {
            return function() {
                makeVisible('boxLoading');

                // Setup loading box
                var prog_id = $('prog_id').firstChild.nodeValue;
                
                setElementPosition('mnuRecord',elementPosition('mnuRecord'));
                setElementDimensions('mnuRecord',elementDimensions('mnuRecord'));
                $('boxContent').innerHTML = message;
                
                // Initiate request
                var d = loadJSONDoc(server_file,{'json':'true','prog_id':prog_id});
                d.addCallbacks(gotResult,fetchFailed);

                function gotResult(doc) {
                    if (doc.status == "success") {
                        if(doc.type == "add") {
                            updateNodeAttributes("listing" + doc.programmes[0].id,{'class':'recordingProgramme'});
                        }
                        else {
                            /* slight bug here, will over write any prvious classes */
                            updateNodeAttributes("listing" + doc.programmes[0].id,{'class':'programme'});
                        }
                        makeInvisible('mnuRecord');
                    }
                    else {
                        $('boxContent').innerHTML = doc.error;
                        console.log("Error response from the server");
                    }
                    makeInvisible('boxLoading');
                }
                function fetchFailed(doc) {
                    $('boxContent').innerHTML = "Somthing happend when trying to contact the server";
                    console.log("Problem contacting the server");
                    makeInvisible('boxLoading');
                }
            }
        }
        var elProgramme = e.src(); // Clicked programme TD
        var prog_id = elProgramme.getAttribute('id'); 

        /* hide the detail box if it already is visible */
        if($('mnuRecord').getAttribute('class') != 'invisible') {
            /* hack alert */
            var pid = $('prog_id').firstChild.nodeValue;
            if (prog_id == "listing" + pid) {
                makeInvisible($('mnuRecord'));
                return;
            }
        }
        /* create and show detail box */
        var mousePos = e.mouse().page;
        var mousePosClient = e.mouse().client;
        

        /* is this show going to be scheduled...somewhat of a hack...better not change these classes */
        var isScheduled = false;
        if (elProgramme.getAttribute('class') == 'recordingProgramme' || elProgramme.getAttribute('class') == 'programme scheduledSearched') {
            isScheduled = true;     
        }

        // Create the close and record buttons
        var btnClose = INPUT({'id':'btnClose','class':'button', 'type':'button','value':'x'},null);
        connect(btnClose,'onclick',function(e) { makeInvisible($('mnuRecord')); });
        if(isScheduled) {
            var btnAction = INPUT({'id':'btnAction','class':'button', 'type':'submit','value':'Del'}, null);
            connect(btnAction,'onclick',createActionHandler('ruby/delete_recording.rb','Removing Show...'));
        }
        else {
            var btnAction = INPUT({'id':'btnAction','class':'button', 'type':'submit', 'value':'Add'}, null);
            connect(btnAction,'onclick',createActionHandler('ruby/add_recording.rb','Adding Show...'));
        }


        
        console.log(app.scheduled_table.findProgramme(prog_id));
        var pdetail = filter(function(el) {return ("listing" + el.id) == prog_id;}, this.data.programmes)[0];

        var progID = SPAN({'id':'prog_id','class':'invisible'},pdetail.id);
        var boxTitle = (pdetail.sub_title != "&nbsp;") ?  // Add subtitle if it exists
            ("Show: " + pdetail.title + " -- " + pdetail.sub_title) : ("Show: " + pdetail.title); 
        

        var offset = Util.getOffset(this._stats.data.datetime);

        var boxStart = "Start: " + isoTimestamp(Util.utcToLocal(pdetail.start,offset));
        var boxStop = "Stop: " + isoTimestamp(Util.utcToLocal(pdetail.stop,offset));
        
        var boxMessage = (pdetail.desc != "&nbsp;") ? ("Description: " + pdetail.desc) : ("");

        //todo: deal with removal of programmes
        var boxContent = DIV({'id':'boxContent'},
            [[boxTitle,BR(null,null),boxStart,BR(null,null),boxStop,BR(null,null),BR(null,null),boxMessage,progID]]);

        var box = DIV({'id':'mnuRecord'},
            [btnClose, boxContent, btnAction]);
        
        // Positon box box width to the right if at edge of screen and box height up if at bottom of screen
        // This will also display as much of the box on screen if the sceen is very small
        swapDOM('mnuRecord',box);
        var boxWidth = elementDimensions('mnuRecord').w;
        var boxHeight = elementDimensions('mnuRecord').h;
        var viewport = getViewportDimensions();
        if ( boxWidth + mousePosClient.x > elementDimensions('schedule').w + elementPosition('schedule').x ) {
            if (mousePosClient.x - boxWidth < 0){
                mousePos.x -= mousePosClient.x;
                }
            else {
                mousePos.x -= boxWidth;
            }
        }
        if ( (boxHeight + mousePosClient.y) > viewport.h ) {
            if (mousePosClient.y - boxHeight < 0){
                mousePos.y -= mousePosClient.y;
                }
            else {
                mousePos.y -= boxHeight;
            }
        }
        setElementPosition(box,mousePos);
        //swapDOM('mnuRecord',box);
    },

    _gotRequest : function(req) {
        this.data = req;
        var boxDate = $('boxDate');
        $('schedule').innerHTML = this.data.header;
        this._connectClickBox();    
    },

    _connectClickBox: function(){
        var programmes = getElementsByTagAndClassName("td","programme");

        for (var i = 0; i < programmes.length; i++) {
            connect(programmes[i],"onclick",this,"showClick");
        }
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
        var dStart= isoTimestamp(start);
        var dStop= isoTimestamp(stop);
        //return;
        while(dStart <= dStop) { 
            dStart.setHours(0);
            dStart.setMinutes(0);
            dStart.setSeconds(0);
            var opDate = OPTION({'value':dStart}, 
                [dayOfWeek[dStart.getDay()] + " " + (dStart.getMonth() + 1) + "/" + dStart.getDate()]);
            $('selDate').appendChild(opDate);
            dStart.setDate(dStart.getDate() + 1);
        }
        today = new Date();
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
