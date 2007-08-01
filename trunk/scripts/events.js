// This file contains all of the event handlers

// Chaneges the background of a programme TD on a mouseover
var prog_mouseOver = function(e) {
	var progClass = getNodeAttribute(e.src(),'class');
	if( progClass == 'programme' ) {
		updateNodeAttributes(e.src(),{'class':'programmeOver'});
	}
	else if (progClass == 'programmePast') { // don't do any backgound change if it is in the past 
		return;
	}
	else {
		updateNodeAttributes(e.src(),{'class':'recordingProgrammeOver'});
	}
};

// Reverts the background chage from a mouseover
var prog_mouseOut = function(e) {
	var progClass = getNodeAttribute(e.src(),'class');
	if( progClass == 'programmeOver') {
		updateNodeAttributes(e.src(),{'class':'programme'});
	}
	else if (progClass == 'programmePast') {
		return;
	}
	else {
		updateNodeAttributes(e.src(),{'class':'recordingProgramme'});
	}
};

// Creates and displays extended info/record menu on a programme TD click
var prog_click = function(e) {
	makeInvisible('mnuAddStatus');
	
	var mousePos = e.mouse().page;
    var mousePosClient = e.mouse().client;
	
	// Create the close and record buttons
	var btnClose = INPUT({'id':'btnClose','class':'button', 'type':'button','value':'x'},null);
	var btnRecord = INPUT({'id':'btnRecord','class':'button', 'type':'submit','value':'Record'}, null);
	
	var elProgramme = e.src(); // Clicked programme TD
	
	connect(btnClose,'onclick',btnClose_click);
	connect(btnRecord,'onclick',btnRecord_click);
	
	var prog_id = elProgramme.getAttribute('id'); 
	var start_time = prog_id.slice(prog_id.length-14);		// Start time is part of progID
	var channel_id = prog_id.slice(0,prog_id.length-14);	// ChannelID is also part of progID
	
	var row = schedule.rows[channel_id];			// get the selected channel row and
	for (var i = 1; i < row.length; i++	) {			// search for selected show by start time
		var rowStart = row[i].getAttribute('start');
		rowStart = rowStart.slice(0,rowStart.length - 6);   // drop timezone
		if(rowStart == start_time) {
			var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
		
			var prog_start = zapTimeToDate( row[i].getAttribute('start') );
			var prog_stop = zapTimeToDate( row[i].getAttribute('stop') );
			
			var desc_els = row[i].getElementsByTagName('desc');
			var prog_desc = (desc_els.length != 0) ? (desc_els[0].firstChild.nodeValue) : ("");
			
			var subtitle_els = row[i].getElementsByTagName('sub-title');
			var prog_subtitle = (subtitle_els.length != 0) ? (subtitle_els[0].firstChild.nodeValue) : ("");
		}
	}
	var progID = SPAN({'id':'prog_id','class':'invisible'},prog_id);
	var boxTitle = (prog_subtitle != "") ?  // Add subtitle if it exists
		("Show: " + prog_title + " -- " + prog_subtitle) : ("Show: " + prog_title); 
	
	var startMin = (prog_start.getMinutes() < 10) ?  // Pad time with 0 if needed
		("0" + prog_start.getMinutes().toString()) : (prog_start.getMinutes().toString());
	var stopMin = (prog_stop.getMinutes() < 10) ? 
		("0" + prog_stop.getMinutes().toString()) : (prog_stop.getMinutes().toString());

	var boxStart = "Start: " + mil2std(prog_start.getHours() + ":" + startMin);
	var boxStop = "Stop: " + mil2std(prog_stop.getHours() + ":" + stopMin);
	
	var boxMessage = (prog_desc != "") ? ("Description: " + prog_desc) : ("");

    if(recording.find(prog_id) != -1) {
        var btnRemove = INPUT({'id':'btnRemove','class':'button', 'type':'button','value':'Remove','name':prog_id},null);
        connect(btnRemove,'onclick',btnRemove_click);
        var boxContent = DIV({'id':'boxContent'},
            [[boxTitle,BR(null,null),boxStart,BR(null,null),boxStop,BR(null,null),BR(null,null),boxMessage,progID],btnRemove]);
    }
    else {
        var boxContent = DIV({'id':'boxContent'},
            [[boxTitle,BR(null,null),boxStart,BR(null,null),boxStop,BR(null,null),BR(null,null),boxMessage,progID],btnRecord]);
    }
	var box = DIV({'id':'mnuRecord'},
		[btnClose, boxContent]);
	
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
};

// Send a record request and display a wait box when record button is clicked
var btnRecord_click = function(e) {	
	makeVisible('boxLoading');

    // don't allow the user to click anywhere else
    //forEach(schedule.progTDs, function(el) { 
     //   disconnectAll(el,'onclick');
    //});
	
    // Setup loading box
	var prog_id = $('prog_id').firstChild.nodeValue;
	
	setElementPosition('mnuRecord',elementPosition('mnuRecord'));
	setElementDimensions('mnuRecord',elementDimensions('mnuRecord'));
	$('boxContent').innerHTML = "Adding Show...";
	
    // Initiate request
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

    // Check to see if we are at the end of our schedule
    var lastDay = new Date($('selDate').options[$('selDate').options.length - 1].value); // grabs the very last day
    lastDay.setHours(23 - (schedule.numHours - 1));   // move the end time back the length of the display schedule

    if (date > lastDay) { // if selected date is after the last <numHours> of the schedule
        date = lastDay;
    }
    
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
    var d = doSimpleXMLHttpRequest('ruby/form_listing.rb',
        {'start_date_time':dateToZapTime(schedule.start),'end_date_time':dateToZapTime(schedule.stop)});
    d.addCallbacks(gotProgrammes,fetchFailed);
};

// Stub for displaying the recording table
var btnRecording_click = function(e) {
	makeInvisible('listingContent');
    makeInvisible('searchContent');
	makeInvisible('recordedContent');
	makeVisible('recordingContent');

	defRecording = doSimpleXMLHttpRequest('ruby/form_scheduled.rb');
	defRecording.addCallbacks(gotRecordingFromScheduled,fetchFailed);		
};

var btnSearch_click = function(e) {
    makeInvisible('listingContent');
    makeInvisible('recordedContent');
    makeInvisible('recordingContent');
    makeVisible('searchContent');
};

// Stub for displaying the recording table
var btnRecorded_click = function(e) {
	makeInvisible('listingContent');
	makeInvisible('recordingContent');
    makeInvisible('searchContent');
	makeVisible('recordedContent');
	
	defRecording = doSimpleXMLHttpRequest('ruby/form_recorded.rb');
	defRecording.addCallbacks(gotRecorded,fetchFailed);		
};

// Displays listing table
var btnListing_click = function(e) {
	makeInvisible('recordingContent');
    makeInvisible('searchContent');
	makeVisible('listingContent');
    makeInvisible('recordedContent');
    place_quick_nav(null);
};

var btnRemoveRecording_click = function(e) {
	var chkBox = $('recording').getElementsByTagName('input');
	var recArray = [];
	var removeIDs = [];
	for(var i = 0; i < chkBox.length; i++) {
		if(chkBox[i].checked == true) {
			recArray.push(doSimpleXMLHttpRequest('ruby/delete_recording.rb',{'prog_id':chkBox[i].value}));
			recArray[recArray.length - 1].addCallbacks(gotDelRecording,fetchFailed);
			removeIDs.push(chkBox[i].value);
		}
	}
	map(function(id) { removeElement("recording:" + id);}, removeIDs);
};

var btnDeleteRecorded_click = function(e) {
    if(confirm("Are you sure you want to delete this show from the hard drive?")) {
        var chkBox = $('recorded').getElementsByTagName('input');
        var recArray = [];
        var removeIDs = [];
        for(var i = 0; i < chkBox.length; i++) {
            if(chkBox[i].checked == true) {
                recArray.push(doSimpleXMLHttpRequest('ruby/delete_recorded.rb',{'prog_id':chkBox[i].value}));
                recArray[recArray.length - 1].addCallbacks(gotDelRecorded,fetchFailed);
                removeIDs.push(chkBox[i].value);
            }
        }
        map(function(id) { removeElement("recorded:" + id);}, removeIDs);
    }
};

// Delete button on the listing table
// Removes a recording show
var btnRemove_click = function(e) {
    var show = e.src().getAttribute('name');    
    makeVisible('boxLoading');

    //forEach(schedule.progTDs, function(el) {
     //   disconnectAll(el,'onclick'); 
   // });
    var del = doSimpleXMLHttpRequest('ruby/delete_recording.rb',{'prog_id':show});
    del.addCallbacks(gotDelRecording,fetchFailed);
    makeInvisible('mnuRecord');
};

var next_day = function(e) {
    var selDate = $('selDate');
    if (selDate.selectedIndex < selDate.length - 1) {
        selDate.selectedIndex++;
        btnLoad_click(e);
    }
};

var next_hours = function(e) {
    var selTime = $('selTime');
    var newTimeIndex = (selTime.selectedIndex + 3) % selTime.length;
    if (newTimeIndex < 3) {
        var selDate = $('selDate');
        if (selDate.selectedIndex < selDate.length - 1) {
            selDate.selectedIndex++;
        }
        else {
            return;
        }
    }
    selTime.selectedIndex = newTimeIndex;
    btnLoad_click(e);
};

var previous_day = function(e) {
    var selDate = $('selDate');
    if (selDate.selectedIndex > 0) {
        selDate.selectedIndex--;
        btnLoad_click(e);
    }
};

var previous_hours = function(e) {
    var selTime = $('selTime');
    var newTimeIndex = (selTime.selectedIndex - 3);
    if (newTimeIndex < 0) {
        newTimeIndex += selTime.length;
        var selDate = $('selDate');
        if (selDate.selectedIndex > 0) {
            selDate.selectedIndex--;
        }
        else {
            newTimeIndex = selTime.selectedIndex;
        }
    }
    selTime.selectedIndex = newTimeIndex;
    btnLoad_click(e);
};

var place_quick_nav= function(e) {
    var btnNextHours = INPUT({'id':'btnNext','class':'button', 'type':'button','value':'>'},null);
    var btnPreviousHours = INPUT({'id':'btnPrevious','class':'button', 'type':'button','value':'<'},null);
    var btnHours = INPUT({'id':'btnHours','class':'button', 'type':'button','value':'H'},null);
    connect(btnNextHours, "onclick", next_hours); 
    connect(btnPreviousHours, "onclick", previous_hours);
    var hourButtons = DIV({'id':'hourButtons'},[btnPreviousHours, btnHours, btnNextHours]);
    var btnNextDay = INPUT({'id':'btnNext','class':'button', 'type':'button','value':'>'},null);
    var btnPreviousDay = INPUT({'id':'btnPrevious','class':'button', 'type':'button','value':'<'},null);
    var btnDay= INPUT({'id':'btnHours','class':'button', 'type':'button','value':'D'},null);
    connect(btnNextDay, "onclick", next_day); 
    connect(btnPreviousDay, "onclick", previous_day);
    var dayButtons = DIV({'id':'dayButtons'},[btnPreviousDay, btnDay, btnNextDay]);
    var viewportPos = getViewportPosition();
    // this is a semi-hack to deal with the edges, currently "ch" and the first channel number are covered with the boxes
    var schedPos = elementPosition('schedule');
	if ( viewportPos.y - schedPos.y - 6 < 0 ) {
        viewportPos.y = schedPos.y + 6;
    }
    viewportPos.x = schedPos.x + 2;
    var box = DIV({'id':'mnuQuicknav'},[hourButtons, dayButtons]);
    setElementPosition(box,viewportPos);
    swapDOM('mnuQuicknav',box);
};

var searchSubmit_click = function(e) {
    var d = doSimpleXMLHttpRequest('ruby/form_search.rb',
        {'title':$('txtSearchTitle').value});
    d.addCallbacks(gotSearch,fetchFailed);
};

var searchRecord_click = function(e) {
	var chkBox = $('searched').getElementsByTagName('input');
	var recArray = [];
	var removeIDs = [];
	for(var i = 0; i < chkBox.length; i++) {
		if(chkBox[i].checked == true) {
			recArray.push(doSimpleXMLHttpRequest('ruby/add_recording.rb',{'prog_id':chkBox[i].value}));
			recArray[recArray.length - 1].addCallbacks(gotAdd,fetchFailed);
		}
	}
	map(function(id) { removeElement("recording:" + id);}, removeIDs);
};
