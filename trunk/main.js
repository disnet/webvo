/*
 WebVo: Web-based PVR
Copyright (C) 2006 Molly Jo Bault, Tim Disney, Daryl Siu

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

window.onload = init;

// Global var which will hold the xml formatted channels and programmes
// along with misc values relating to the schedule
var schedule = Object();

schedule.xmlChannels = null;        // holds the channels -- packed when the user first navigates to the site
schedule.xmlProgrammes = null;      // holds the progrmames -- packed when the user selectes a time  
schedule.rows = Object();
schedule.timesHeader = [];          // used to fill the time slots on the top of the schedule table
schedule.numHours = 3;              // number of hours the schedule will display
schedule.startDate = null;			// first day that we have programme information on
schedule.stopDate = null;			// last day that we have programme information on
schedule.slotsPerHour = 60;

var dayOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

// Once the page loads, connect up the events
function init() { 
    makeVisible($('boxLoading'));

    // get the channels
    var ch = doSimpleXMLHttpRequest('ruby/form_channels.rb');
    ch.addCallbacks(gotChannels_init,fetchFailed);
	
	//var rec = doSimpleXMLHttpRequest('ruby/form_recording.rb');
	//rec.addCallbacks(gotRecording,fetchFailed);
	
    connect('btnListing','onclick',btnListing_click);
	connect('btnRecording','onclick',btnRecording_click);
}

function initFormTime() {
	var day = isoDate(schedule.startDate.slice(0,4) + "-" +
		schedule.startDate.slice(4,6) + "-" + schedule.startDate.slice(6,8));
	var end = isoDate(schedule.stopDate.slice(0,4) + "-" +
		schedule.stopDate.slice(4,6) + "-" + schedule.stopDate.slice(6,8));
	var time = new Date();
	
	$('boxInfo').firstChild.nodeValue = time.toLocaleDateString();
	
    // Fill next n days
	while(day <= end) { // add all the days we have on the server
		var opDate = OPTION({'value':day}, 
			[dayOfWeek[day.getDay()] + " " + day.getDate()]);
		$('selDate').appendChild(opDate);
		day.setDate(day.getDate() + 1);
	}
	
    // Fill 24 hours
	time.setHours(0); // start at 00:00
	for(var i = 0; i < 24; i++) {
		var opTime = OPTION({'value':time.getHours()},
			mil2std(time.getHours() + ":00"));
		$('selTime').appendChild(opTime);
		time.setHours(time.getHours() + 1);
	}
	$('selTime').value = 18;	// default to 6pm
	
	connect('btnLoad','onclick',btnLoad_click);
	makeInvisible('boxLoading');
	
	btnLoad_click(null);	// load up default time
}

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
// Parses the xml and form the Schedule table
var formListingTable = function () {
    var xmldoc = schedule.xmlProgrammes;

    var root_node = xmldoc.getElementsByTagName('tv').item(0);
	// grab all the channels
	var xml_channels = new Array();
    xml_channels = schedule.xmlChannels.getElementsByTagName('channel');
	// grab all the programmes
    var xml_programmes = root_node.getElementsByTagName('programme');
	

	var cmpChannels = function(ch1,ch2) {
		var num1 = ch1.getElementsByTagName('display-name')[2].firstChild.nodeValue;
		var num2 = ch2.getElementsByTagName('display-name')[2].firstChild.nodeValue;
		return num1 - num2;
	};
	
	xml_channels = map(function(el){ return el}, xml_channels);	// convert from nodelist to array
	xml_channels.sort(cmpChannels);								// so we can sort it

    // 1.  Initialize <rows> Object(). Each channel is added as the first element of it's own property
    forEach(xml_channels, function(ch) { schedule.rows[ch.getAttribute('id')] = [ch]; });
	
    // 2.  Fill  <rows> Object() by pushing programmes into their associated channel slot
    forEach(xml_programmes, function(el) { schedule.rows[el.getAttribute('channel')].push(el); });

	
	// create the DOM table from <head_strings> and <rows> using the programm_row_display function
    var new_table = TABLE({'id':'schedule','class':'schedule'},
		THEAD({'style':'width:100%'}, 
			form_table_head(schedule.timesHeader)),
        TBODY({'style':'width:100%'},
			form_table_body(schedule.rows)));
	swapDOM('schedule',new_table);
	makeInvisible('boxLoading');
};

// Forms the listing table head. It includes a row with empty TD used for spacing and 
// a row with the time
function form_table_head(head) {
	var empty_slots = schedule.numHours * schedule.slotsPerHour; // gets the number of minutes in the schedule
	var colSpan = empty_slots / (schedule.numHours * 2);	// number of slots that a 1/2 hour needs to span
	 
	var empty_data = [];
	for (var i = 0; i < empty_slots; i++) {
		empty_data.push('');
	}
	
	var empty_row = [TR(null,
		map(partial(TD,{'class':'empty', 'style':'border:0px;'}),empty_data))];
	
	var head_row = [TR(null,
		[TD({'class':'head'},'Ch.')].concat(map(partial(TD,{'class':'head','colSpan':colSpan}),head)))];
	
	return empty_row.concat(head_row);
}

function form_table_body(rows) {
	return map(programme_row_display,obj2arr(rows));
}

// Returns DOM TRs for the schedule
// formed by individual <rows> property arrays which hold 
// xml elements for each channel and associated programmes
// INPUT: <row> array of xml elements -- first element is channel, rest are associated programmes
// RETURNS: DOM TR with channel and associated programmes
// KNOWN BUG: This will not work correctly if there is nothing being aired for a given time slot
programme_row_display = function(row) {
    var channelID = row[0].getAttribute('id');
    var channel_name = row[0].getElementsByTagName('display-name')[0].firstChild.nodeValue;

	// first TD has the channel name and it's ID property is the associated channelID
    var formed_row = [TD({'class':'channelName'}, channel_name)];
    
	var programme_tds = []; 	//initialize the array of programme TDs
    for(var i = 1; i < row.length; i++) { // for every programme in <row>
        var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
        var prog_start = row[i].getAttribute('start');
		var prog_stop = row[i].getAttribute('stop');
        var progID =  channelID + prog_start; 
		
        var isoStart = isoTimestamp(munge_date(prog_start));
        var isoStop = isoTimestamp(munge_date(prog_stop));
		
		var show_length;
		// If the show starts before the current time schedule
		if (isoStart < schedule.start) {
			// If the end is after the current time schedule 
			if( isoStop > schedule.stop) 
				{ show_length = schedule.numHours; }// set time full
			// if the end is before the schedule end
			else 
				{ show_length = (isoStop-schedule.start) / 3600000; } // 3600000 to convert from ms to hours
		}
		// if the show starts after the begining of the schedule
		else {
			// If the show end is after the schedule end
			if (isoStop > schedule.stop) 
				{show_length = (schedule.stop-isoStart) / 3600000;}  // 3600000 to convert from ms to hours
			// If the show end is before the schedule end
			else 
			{show_length = (isoStop-isoStart) / 3600000; }// 3600000 to convert from ms to hours			
			
		}

		var colSpan = show_length * schedule.slotsPerHour;  
		var prog_td = TD({'id':progID,'class':'programme','colSpan':colSpan},prog_title); // colSpan *not* colspan -- I HATE IE!!!
	
		connect(prog_td,'onmouseover',prog_mouseOver);
		connect(prog_td,'onmouseout',prog_mouseOut);
		connect(prog_td,'onclick',prog_click);
		
		// insert the formed programme TDs into the TD array
        programme_tds.push(prog_td); 
        
    }
	
    formed_row.push(programme_tds); 
    return TR({'style':'height:100%; width:100%;'},formed_row);
};

// Converts an object to an 2D array (sort of)
// for every property in obj (assume each property is an array)
// arr[i] = obj.property
function obj2arr(obj) {
    var arr = [];
    var i = 0;
    for (name in obj) {
       arr[i++] = obj[name]; 
    }
    return arr;
}

// Forms the zap2it date into an isoTimestamp
function munge_date(str_date) {
    parsed_date = str_date.slice(0,4) + '-';
    parsed_date += str_date.slice(4,6) + '-';
    parsed_date += str_date.slice(6,8) + ' ';
    parsed_date += str_date.slice(8,10) + ':';
    parsed_date += str_date.slice(10,12) + ':';
    parsed_date += str_date.slice(12);
    return parsed_date;
}

// Error handling for listing request
var fetchFailed = function (err) {
    log("Data is not available");
    log(err);
};

function makeInvisible(el) {
	addElementClass(el,'invisible');
}

function makeVisible(el) {
	removeElementClass(el,'invisible');
}
function dateToZapTime(date) {
    isoTime = toISOTimestamp(date);
	
    zapTime = isoTime.slice(0,4);	//year
    zapTime += isoTime.slice(5,7);	//month
    zapTime += isoTime.slice(8,10);	//day

	if(date.getHours() < 10) {	// need to pad an extra zero for the hour
		zapTime += "0" + isoTime.slice(11,12);
		zapTime += isoTime.slice(13,15);
		zapTime += isoTime.slice(16,18);
	}
	else {
		zapTime += isoTime.slice(11,13);	//hour
		zapTime += isoTime.slice(14,16);	//miniute
    	zapTime += isoTime.slice(17,19);	//second
	}
    
    
    return zapTime;
}
// Got the channels from server
var gotChannels_init = function(req) {
   schedule.xmlChannels = req.responseXML; 
   var xmlStartStop = req.responseXML.getElementsByTagName('programme_date_range')[0];
   schedule.startDate = xmlStartStop.getAttribute('start');
   schedule.stopDate = xmlStartStop.getAttribute('stop');
   initFormTime(); // init the time selection boxes
};

// Get the programmes from server
var gotProgrammes = function(req) {
   schedule.xmlProgrammes = req.responseXML;
   // Check for and deal with error return
   var error = schedule.xmlProgrammes.getElementsByTagName('error');
   if(error.length != 0) {
       log(error[0].firstChild.nodeValue);
       schedule.xmlProgrammes = null;
       return;
    }
   formListingTable();
};

var gotAdd = function(req) {
	xmldoc = req.responseXML;
	var error = xmldoc.getElementsByTagName('error');
	var success = xmldoc.getElementsByTagName('success');
	if(error.length != 0 ) {
		$('mnuAddStatus').innerHTML = error[0].firstChild.nodeValue;
	}
	else if(success.length != 0) {
		makeInvisible('mnuAddStatus');
	}
	else {
		log('add recording error: ' + req.responseText);
	}
	makeInvisible('boxLoading'); 
};
var gotRecording = function(req) {
	log(req.responseText);
};

function mil2std(mil) {
	var hour = parseInt(mil.slice(0,2));
	if (hour < 12) {
		if(hour == 0) {
			return "12:" + mil.slice(2) + "AM";
		}
		return mil + "AM";
	}
	if(hour == 12) {
		return mil + "PM";
	}
	else {
		hour -= 12;
		return (hour.toString()) + mil.slice(2) + "PM";
	}
}
