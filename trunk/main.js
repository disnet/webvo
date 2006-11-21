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
schedule.timesHeader = [];          // used to fill the time slots on the top of the schedule table
schedule.numHours = 3;              // number of hours the schedule will display
schedule.slotsPerHour = 60;

var dayOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

// Once the page loads, connect up the events
function init() { 
 	initFormTime(); // init the time selection boxes
    
    // get the channels
    var ch = doSimpleXMLHttpRequest('ruby/form_channels.rb');
    ch.addCallbacks(gotChannels_init,fetchFailed);
	
    connect('btnLoad','onclick',btnLoad_click);
}

function initFormTime() {
	var day = new Date();
	var time = new Date();
	
    // Fill next n days
	for(var i = 0; i < 20; i++) {
		var opDate = OPTION({'value':day}, 
			[dayOfWeek[day.getDay()] + " " + day.getDate()]);
		$('selDate').appendChild(opDate);
		day.setDate(day.getDate() + 1);
	}

    // Fill 24 hours
	time.setHours(0); // start at 00:00
	for(var i = 0; i < 24; i++) {
		var opTime = OPTION({'value':time.getHours()},
			time.getHours() + ":00");
		$('selTime').appendChild(opTime);
		time.setHours(time.getHours() + 1);
	}
}

// Event handler for clicking a programme in the table
var prog_click = function(e) {
	var mousePos = e.mouse().page;
	var btnClose = INPUT({'id':'btnClose','type':'button','value':'x'},null);
	var btnRecord = INPUT({'id':'btnRecord','type':'submit','value':'record'}, null);
	var elProgramme = e.src();
	var elExtended = elProgramme.lastChild.firstChild.nodeValue;
	//var elSubtitled = elProgramme.getElement('sub-title');
	//log($('sub-title'));
	
	connect(btnClose,'onclick',btnClose_click);
	connect(btnRecord,'onclick',btnRecord_click);

	var boxTitle = "Show name: " + elProgramme.firstChild.nodeValue;
	var boxMessage = "Details: " + elExtended;
	var boxSubtitle = "Sub-title: ";
	
	var box = DIV({'id':'mnuRecord'},
		[btnClose, [boxTitle,BR(null,null),BR(null,null),boxMessage], btnRecord]);
		
	setElementPosition(box,mousePos);
	swapDOM('mnuRecord',box);
	makeVisible($('mnuRecord'));
	
};

var btnClose_click = function(e) {
	makeInvisible($('mnuRecord'));
};

var btnRecord_click = function(e) {
	log('record');
};

// Sets up the async request for the schedule
// Currently a btnLoad click event -- will eventually 
// be an `onload` event along with a form for changing
// the begin and end times.
var btnLoad_click = function(e) {  
    // Fill a Date object with the date stored in the select box
	var date = new Date($('selDate').value);
	date.setHours($('selTime').value);
	date.setMinutes(0);
	date.setSeconds(0);

    // initialize the time header
    schedule.timesHeader = [];
    for (var i = 0; i < schedule.numHours; i++) {
        schedule.timesHeader.push( (date.getHours() + i).toString() + ":00");
        schedule.timesHeader.push( (date.getHours() + i).toString() + ":30");
    }
	
    // find what date/time we want
	schedule.start = dateToZapTime(date);
	date.setHours(date.getHours() + schedule.numHours);
	schedule.stop = dateToZapTime(date);
	
    // init the request
    var d = doSimpleXMLHttpRequest('ruby/form_listing.rb',{'start_date_time':schedule.start,'end_date_time':schedule.stop});
    d.addCallbacks(gotProgrammes,fetchFailed);
};

// Parses the xml and form the Schedule table
var formListingTable = function () {
    var rows = Object();
    var xmldoc = schedule.xmlProgrammes;

    var root_node = xmldoc.getElementsByTagName('tv').item(0);
	// grab all the channels
    var xml_channels = schedule.xmlChannels.getElementsByTagName('channel');
	// grab all the programmes
    var xml_programmes = root_node.getElementsByTagName('programme');

    // 1.  Initialize <rows> Object(). Each channel is added as the first element of it's own property
    forEach(xml_channels, function(ch) { rows[ch.getAttribute('id')] = [ch]; });

    // 2.  Fill  <rows> Object() by pushing programmes into their associated channel slot
    forEach(xml_programmes, function(el) { rows[el.getAttribute('channel')].push(el); });

	
	// create the DOM table from <head_strings> and <rows> using the programm_row_display function
    var new_table = TABLE({'id':'schedule','class':'schedule'},
		THEAD({'style':'width:100%'}, 
			form_table_head(schedule.timesHeader)),
        TBODY({'style':'width:100%'},
			form_table_body(rows)));
	swapDOM('schedule',new_table);
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
		map(partial(TD,{'class':'empty'}),empty_data))];
	
	var head_row = [TR(null,
		[TD(null,'Ch.')].concat(map(partial(TD,{'colSpan':colSpan}),head)))];
	
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
    var formed_row = [TD({'id':'channelID'}, channel_name)];
    
	var programme_tds = []; 	//initialize the array of programme TDs
    for(var i = 1; i < row.length; i++) { // for every programme in <row>
        var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
        var prog_start = munge_date(row[i].getAttribute('start'));
		var prog_stop = munge_date(row[i].getAttribute('stop'));
        var progID =  channelID + prog_start; 
		
		var desc_els = row[i].getElementsByTagName('desc');//[0].firstChild.nodeValue
		if (desc_els.length != 0) {
			var prog_desc = desc_els[0].firstChild.nodeValue;
		}
		else {
			var prog_desc = "";
		}
		var subtitle_els = row[i].getElementsByTagName('sub-title');
		if(subtitle_els.length != 0) {
			var prog_subtitle = subtitle_els[0].firstChild.nodeValue;
		}
		else{
			var prog_subtitle = "";
		}
        var isoStart = isoTimestamp(munge_date(row[i].getAttribute('start')));
        var isoStop = isoTimestamp(munge_date(row[i].getAttribute('stop')));
		
		var show_length;
		// If the show starts before the current time schedule
		if (isoStart < isoTimestamp(munge_date(schedule.start))) {
			// If the end is after the current time schedule 
			if( isoStop > isoTimestamp(munge_date(schedule.stop))) {
				show_length = schedule.numHours; // set time full
			}
			// if the end is before the schedule end
			else {
				show_length = isoStop.getHours() - isoTimestamp(munge_date(schedule.start)).getHours();
				show_length +=  (isoStop.getMinutes() - isoTimestamp(munge_date(schedule.start)).getMinutes()) / 60;
			}
		}
		// if the show starts after the begining of the schedule
		else {
			// If the show end is after the schedule end
			if (isoStop > isoTimestamp(munge_date(schedule.stop))) {
				show_length = isoTimestamp(munge_date(schedule.stop)).getHours() - isoStart.getHours();
				show_length +=  (isoTimestamp(munge_date(schedule.stop)).getMinutes() - isoStart.getMinutes()) / 60;
			}
			// If the show end is before the schedule end
			else {
				show_length = isoStop.getHours() - isoStart.getHours();
				show_length +=  (isoStop.getMinutes() - isoStart.getMinutes()) / 60;
			}
		}

		var colSpan = show_length * schedule.slotsPerHour;  
		var prog_td = TD({'id':progID, 'colSpan':colSpan}, // colSpan *not* colspan -- I HATE IE!!!
			[prog_title, 
            SPAN({'id':'start','class':'invisible'},isoStart),
            SPAN({'id':'stop','class':'invisible'},isoStop),
            SPAN({'id':'sub-title','class':'invisible'},prog_subtitle),
			SPAN({'id':'desc','class':'invisible'},prog_desc)]); 
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
/*function toZapTimestamp(year,month,date,hour) {
    if(hour < 10) {
        hour = "0" + hour.toString();
    }
	return year.toString() + month.toString() + date.toString() + hour.toString() + "0000"
}*/

// Got the channels from server
var gotChannels_init = function(req) {
   schedule.xmlChannels = req.responseXML; 
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
