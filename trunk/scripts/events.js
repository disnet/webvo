var prog_mouseOver = function(e) {
	updateNodeAttributes(e.src(),{'style':{'border':'1px solid red'}});
};

var prog_mouseOut = function(e) {
	updateNodeAttributes(e.src(),{'style':{'border':'1px solid black'}});
};
// Event handler for clicking a programme in the table
var prog_click = function(e) {
	makeInvisible('mnuAddStatus');
	
	var mousePos = e.mouse().page;
	var btnClose = INPUT({'id':'btnClose','type':'button','value':'x'},null);
	var btnRecord = INPUT({'id':'btnRecord','type':'submit','value':'record'}, null);
	
	var elProgramme = e.src();
	
	connect(btnClose,'onclick',btnClose_click);
	connect(btnRecord,'onclick',btnRecord_click);
	
	var prog_id = elProgramme.getAttribute('id'); // get the programme id
	var start_time = prog_id.slice(prog_id.length-20);
	prog_id = prog_id.slice(0,prog_id.length-6);	// removes the timezone trailer
	var channel_id = prog_id.slice(0,prog_id.length-14);
	
	var row = schedule.rows[channel_id];
	
	for (var i = 0; i < row.length; i++	) {	// search for selected show
		if(row[i].getAttribute('start') == start_time) {
			var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
			var desc_els = row[i].getElementsByTagName('desc');
			var prog_desc = "";
			if (desc_els.length != 0) {
				var prog_desc = desc_els[0].firstChild.nodeValue;
			}
			
			var subtitle_els = row[i].getElementsByTagName('sub-title');
			var prog_subtitle = "";
			if(subtitle_els.length != 0) {
				prog_subtitle = subtitle_els[0].firstChild.nodeValue;
			}
		}
	}
	var progID = SPAN({'id':'prog_id','class':'invisible'},prog_id);
	var boxTitle = "Show name: " + prog_title;
	var boxMessage = "Details: " + prog_desc;
	var boxSubtitle = "Sub-title: " + prog_subtitle;
	
	var box = DIV({'id':'mnuRecord'},
		[btnClose, [boxTitle,BR(null,null),BR(null,null),boxMessage,BR(null,null),BR(null,null),boxSubtitle,progID], btnRecord]);
		
	setElementPosition(box,mousePos);
	swapDOM('mnuRecord',box);
	makeVisible($('mnuRecord'));
	
};
var btnRecord_click = function(e) {	
	makeVisible('boxLoading');
	
	var prog_id = $('prog_id').firstChild.nodeValue;
	
	setElementPosition('mnuAddStatus',elementPosition('mnuRecord'));
	setElementDimensions('mnuAddStatus',elementDimensions('mnuRecord'));
	$('mnuAddStatus').innerHTML = "Adding Show...";
	
	makeInvisible('mnuRecord');
	makeVisible('mnuAddStatus');
	var ad = doSimpleXMLHttpRequest('ruby/add_recording.rb', {'prog_id':prog_id});
    ad.addCallbacks(gotAdd,fetchFailed);
}

var btnClose_click = function(e) {
	makeInvisible($('mnuRecord'));
};

// Sets up the async request for the schedule
// Currently a btnLoad click event -- will eventually 
// be an `onload` event along with a form for changing
// the begin and end times.
var btnLoad_click = function(e) {  
	makeVisible('boxLoading');
    // Fill a Date object with the date stored in the select box
	var date = new Date($('selDate').value);
	date.setHours($('selTime').value);
	date.setMinutes(0);
	date.setSeconds(0);

    // initialize the time header
    schedule.timesHeader = [];
	headDate = new Date(date);
    for (var i = 0; i < schedule.numHours; i++) {
        schedule.timesHeader.push( mil2std(headDate.getHours().toString() + ":00"));
        schedule.timesHeader.push( mil2std(headDate.getHours().toString() + ":30"));
		headDate.setHours(headDate.getHours() + 1);       
    }
	
    // find what date/time we want
	schedule.start = date;
	schedule.stop = new Date(date);
	schedule.stop.setHours(date.getHours() + schedule.numHours);
	
    // init the request
    var d = doSimpleXMLHttpRequest('ruby/form_listing.rb',{'start_date_time':dateToZapTime(schedule.start),'end_date_time':dateToZapTime(schedule.stop)});
    d.addCallbacks(gotProgrammes,fetchFailed);
};

var btnRecording_click = function(e) {
	makeInvisible('listingContent');
	makeVisible('recordingContent');
		
};
var btnListing_click = function(e) {
	makeInvisible('recordingContent');
	makeVisible('listingContent');
};
