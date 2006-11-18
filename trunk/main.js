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
var schedule = Object();

schedule.xmlChannels = null;
schedule.xmlProgrammes = null;
schedule.numHours = 3;
schedule.slotsPerHour = 60;

// Testing globals, at present they are the static begin and end times for the schedule
schedule.start = isoTimestamp(munge_date('20061023000000 -0800'));
schedule.stop = isoTimestamp(munge_date('20061023030000 -0800'));
var dayOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

// Once the page loads, connect up the events
function init() { 
	
 // log(schedule.start);
 	initFormTime();
    
	/*
    var ch = doSimpleXMLHttpRequest('ruby/form_channels.rb');
    ch.addCallbacks(gotChannels,fetchFailed);

    var pr = doSimpleXMLHttpRequest('ruby/form_listing.rb');
    pr.addCallbacks(gotProgrammes,fetchFailed);
	*/
    connect('btnLoad','onclick',btnLoad_click);
}

function initFormTime() {
	var day = new Date();
	var time = new Date();
	
	// ASSUME: date will never repeate. Using date as identifier
	for(var i = 0; i < 12; i++) {
		var opDate = OPTION({'value':day.getDate()}, 
			[dayOfWeek[day.getDay()] + " " + day.getDate()]);
		$('selDate').appendChild(opDate);
		day.setDate(day.getDate() + 1);
	}
	for(var i = 0; i < 24; i++) {
		var opTime = OPTION({'value':time.getHours()},
			time.getHours() + ":00");
		$('selTime').appendChild(opTime);
		time.setHours(time.getHours() + 1);
	}
}
var gotChannels = function(req) {
   schedule.xmlChannels = req.responseXML; 
};

var gotProgrammes = function(req) {
   schedule.xmlProgrammes = req.responseXML;
};
var boxTest = function(e) {
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
// 2006 10 23 03 00 00
	var objDate = new Date();
	var year = objDate.getFullYear();
	var month = objDate.getMonth() + 1;
	var date = $('selDate').value;
	var hour = $('selTime').value;

	var sendStart = toZapTimestamp(year,month,date,hour);
	var sendStop = toZapTimestamp(year,month,date, parseInt(hour) + 3);
	log("Start: " + sendStart);
	log("Stop: " + sendStop);
    var d = doSimpleXMLHttpRequest('ruby/form_listing.rb');//,{'start_date_time':sendStart,'end_date_time':sendStop});
    d.addCallbacks(gotSchedule,fetchFailed);
	
};


// Gets back the schedule in xml. 
// Parses the xml and form the Schedule table
var gotSchedule = function (req) {
    var rows = Object();
    var xmldoc = req.responseXML;

    var root_node = xmldoc.getElementsByTagName('tv').item(0);
	// grab all the channels
    var xml_channels = root_node.getElementsByTagName('channel');
	// grab all the programmes
    var all_xml_programmes = root_node.getElementsByTagName('programme');

    // Filters xml_programmes for the correct time -- unneeded in final version
    var form_programmes = function(pr) {
        var start = isoTimestamp(munge_date(pr.getAttribute('start')));
        var stop = isoTimestamp((pr.getAttribute('stop')));
		var testStart = isoTimestamp(munge_date('20061023000000 -0800'));
		var testStop = isoTimestamp(munge_date('20061023030000 -0800'));
        
		if(start <= testStart) { // if the programme started before the schedule start
			if (stop > testStart) {	// and ends after the schedule start
				return true;
			}
			else {
				return false;
			} 
		}
        else if (start > testStart && start < testStop) {	// if programme starts before the schedule end 
            return true;
		}
		else {
			return false;
		}
    };	
    
    // 0.  Filter programmes to the correct time (Don't need in furture versions)
    var xml_programmes = filter(form_programmes,all_xml_programmes); // grabs shows for correct time

    // 1.  Initialize <rows> Object(). Each channel is added as the first element of it's own property
    forEach(xml_channels, function(ch) { rows[ch.getAttribute('id')] = [ch]; });

    // 2.  Fill  <rows> Object() by pushing programmes into their associated channel slot
    forEach(xml_programmes, function(el) { rows[el.getAttribute('channel')].push(el); });

    var head_strings = ['12:00','12:30','1:00','1:30','2:00','2:30'];
	
	// create the DOM table from <head_strings> and <rows> using the programm_row_display function
    var new_table = TABLE({'class':'schedule'},
		THEAD({'style':'width:100%'}, 
			form_table_head(head_strings)),
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
        var progID =  "[" + channelID + "]" + prog_start + "==" + prog_stop; 
		
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
		if (isoStart < schedule.start) {
			// If the end is after the current time schedule 
			if( isoStop > schedule.stop) {
				show_length = schedule.numHours; // set time full
			}
			// if the end is before the schedule end
			else {
				show_length = isoStop.getHours() - schedule.start.getHours();
				show_length +=  (isoStop.getMinutes() - schedule.start.getMinutes()) / 60;
			}
		}
		// if the show starts after the begining of the schedule
		else {
			// If the show end is after the schedule end
			if (isoStop > schedule.stop) {
				show_length = schedule.stop.getHours() - isoStart.getHours();
				show_length +=  (schedule.stop.getMinutes() - isoStart.getMinutes()) / 60;
			}
			// If the show end is before the schedule end
			else {
				show_length = isoStop.getHours() - isoStart.getHours();
				show_length +=  (isoStop.getMinutes() - isoStart.getMinutes()) / 60;
			}
		}

		var colSpan = show_length * schedule.slotsPerHour;  
		var prog_td = TD({'id':progID, 'colSpan':colSpan}, // colSpan *not* colspan -- I HATE IE!!!
			[prog_title, SPAN({'id':'sub-title','class':'invisible'},prog_subtitle),
			SPAN({'id':'desc','class':'invisible'},prog_desc)]); 
		connect(prog_td,'onclick',boxTest);
		
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
function toZapTimestamp(datetime) {
    isoTime = toISOTimestamp(datetime);
    zapTime = isoTime.slice(0,4);
    zapTime += isoTime.slice(5,7);
    zapTime += isoTime.slice(8,10);

    zapTime += isoTime.slice(11,13);
    zapTime += isoTime.slice(14,16);
    zapTime += isoTime.slice(17,19);
    return zapTime;
}
function toZapTimestamp(year,month,date,hour) {
	return year.toString() + month.toString() + date.toString() + hour.toString() + "0000"
}
