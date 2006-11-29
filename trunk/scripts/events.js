// This file contains all of the event handlers

// Chaneges the background of a programme TD on a mouseover
var prog_mouseOver = function(e) {
	updateNodeAttributes(e.src(),{'style':{'backgroundColor':'#408040'}});
};

// Reverts the background chage from a mouseover
var prog_mouseOut = function(e) {
	updateNodeAttributes(e.src(),{'style':{'backgroundColor':'green'}});
};

// Creates and displays extended info/record menu on a programme TD click
var prog_click = function(e) {
	makeInvisible('mnuAddStatus');
	
	var mousePos = e.mouse().page;
	
	// Create the close and record buttons
	var btnClose = INPUT({'id':'btnClose','class':'button', 'type':'button','value':'x'},null);
	var btnRecord = INPUT({'id':'btnRecord','class':'button', 'type':'submit','value':'record'}, null);
	
	var elProgramme = e.src(); // Clicked programme TD
	
	connect(btnClose,'onclick',btnClose_click);
	connect(btnRecord,'onclick',btnRecord_click);
	
	var prog_id = elProgramme.getAttribute('id'); 
	var start_time = prog_id.slice(prog_id.length-20);		// Start time is part of progID
	prog_id = prog_id.slice(0,prog_id.length-6);			// removes the timezone trailer
	var channel_id = prog_id.slice(0,prog_id.length-14);	// ChannelID is also part of progID
	
	var row = schedule.rows[channel_id];			// get the selected channel row and
	for (var i = 0; i < row.length; i++	) {			// search for selected show
		if(row[i].getAttribute('start') == start_time) {
			var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
			
			var desc_els = row[i].getElementsByTagName('desc');
			var prog_desc = (desc_els.length != 0)?desc_els[0].firstChild.nodeValue: "";
			
			var subtitle_els = row[i].getElementsByTagName('sub-title');
			var prog_subtitle = (subtitle_els.length != 0)?subtitle_els[0].firstChild.nodeValue:"";
		}
	}
	var progID = SPAN({'id':'prog_id','class':'invisible'},prog_id);
	var boxTitle = "Show name: " + prog_title;
	var boxMessage = (prog_desc != "")?"Details: " + prog_desc:"";
	var boxSubtitle = (prog_subtitle != "")?"Sub-title: " + prog_subtitle:"";
	
	var box = DIV({'id':'mnuRecord'},
		[btnClose, [boxTitle,BR(null,null),BR(null,null),boxMessage,BR(null,null),BR(null,null),boxSubtitle,progID], btnRecord]);
	
	// Positon box approx. box width to the right if at edge of screen
	var boxWidth = 250; 	// Hard coded because no easy way of finding dynamically
	if ( (boxWidth + mousePos.x) > elementDimensions('schedule').w) {
		mousePos.x -= boxWidth;
		setElementPosition(box,mousePos);
	}
	else {
		setElementPosition(box,mousePos);
	}
	swapDOM('mnuRecord',box);
	makeVisible($('mnuRecord'));
	
};

// Send a record request and display a wait box when record button is clicked
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

// Hide the record menu when the close button is clicked
var btnClose_click = function(e) {
	makeInvisible($('mnuRecord'));
};

// Requests a new listing table for the given time/date
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
	
    // send the request
    var d = doSimpleXMLHttpRequest('ruby/form_listing.rb',{'start_date_time':dateToZapTime(schedule.start),'end_date_time':dateToZapTime(schedule.stop)});
    d.addCallbacks(gotProgrammes,fetchFailed);
};

// Stub for displaying the recording table
var btnRecording_click = function(e) {
	//makeInvisible('listingContent');
	makeVisible('recordingContent');
	
	defRecording = doSimpleXMLHttpRequest('ruby/form_recording.rb');
	defRecording.addCallbacks(gotRecording,fetchFailed);
	
		
};

// Displays listing table
var btnListing_click = function(e) {
	makeInvisible('recordingContent');
	makeVisible('listingContent');
};

var btnRemoveRecording_click = function(e) {
	var chkBox = $('recording').getElementsByTagName('input');
	var recArray = [];
	var removeIDs = [];
	for(var i = 0; i < chkBox.length; i++) {
		if(chkBox[i].checked == true) {
			log(chkBox[i].value);
			recArray.push(doSimpleXMLHttpRequest('ruby/delete_recording.rb',{'prog_id':chkBox[i].value}));
			recArray[recArray.length - 1].addCallbacks(gotDelRecording,fetchFailed);
			removeIDs.push(chkBox[i].value);
		}
	}
	map(function(id) { removeElement(id);}, removeIDs);
};

var btnCloseRecording_click = function(e) {
	makeInvisible('recordingContent');
};
