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

// Testing globals, at present they are the static begin and end times for the schedule
schedStart = isoTimestamp(munge_date('20061023000000 -0800'));
schedStop = isoTimestamp(munge_date('20061023030000 -0800'));

// Once the page loads, connect up the events
function init() { 
    connect('btnLoad','onclick',getXML);
    connect('btnTest','onclick',test);
}

// TODO: REMOVE, testing for javascript table creation
var test = function(e) { 
    var test =  TABLE({'border':'1px solid black'},
            [TR(null,map(partial(TD,null),[1,2,3,4])),TR(null,TD({'colSpan':'3'},'fun'))]);
    swapDOM('schedule',test);
};

// Sets up the async request for the schedule
// Currently a btnLoad click event -- will eventually 
// be an `onload` event along with a form for changing
// the begin and end times.
var getXML = function(e) {  
    var d = doSimpleXMLHttpRequest('schedTest.xml');
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

    // Filters xml_programmes for the correct time
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
		THEAD(null, 
			form_table_head(head_strings)),
        TBODY({'style':'width:100%'},
			form_table_body(rows)));
	swapDOM('schedule',new_table);
};

// Forms the listing table head. It includes a row with empty TD used for spacing and 
// a row with the time
function form_table_head(head) {
	var numHours = head.length * 2;
	var empty_slots = numHours * 60; // gets the number of minutes in the schedule
	var colSpan = empty_slots / head.length;
	 
	var empty_data = [];
	for (var i = 0; i < empty_slots; i++) {
		empty_data.push('');
	}
	
	var empty_row = [TR(null,
		map(partial(TD,{'class':'empty','style':'width:.01%;'}),empty_data))];
	
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
programme_row_display = function(row) {
    var channelID = row[0].getAttribute('id');
    var channel_name = row[0].getElementsByTagName('display-name')[0].firstChild.nodeValue;

	// first TD has the channel name and it's ID property is the associated channelID
    var formed_row = [TD({'id':'channelID'}, channel_name)];
    
	var programme_tds = []; 	//initialize the array of programme DIVs
    for(var i = 1; i < row.length; i++) { // for every programme in <row>
        var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
        var prog_start = munge_date(row[i].getAttribute('start'));
		var prog_stop = munge_date(row[i].getAttribute('stop'));
        var progID =  "[" + channelID + "]" + prog_start + " " + prog_stop; 

        var isoStart = isoTimestamp(munge_date(row[i].getAttribute('start')));
        var isoStop = isoTimestamp(munge_date(row[i].getAttribute('stop')));
		
		var show_length;
		// If the show starts before the current time schedule
		if (isoStart < schedStart) {
			// If the end is after the current time schedule 
			if( isoStop > schedStop) {
				show_length = 3; // set time full
			}
			// if the end is before the schedule end
			else {
				show_length = isoStop.getHours() - schedStart.getHours();
				show_length +=  (isoStop.getMinutes() - schedStart.getMinutes()) / 60;
			}
		}
		// if the show starts after the begining of the schedule
		else {
			// If the show end is after the schedule end
			if (isoStop > schedStop) {
				show_length = schedStop.getHours() - isoStart.getHours();
				show_length +=  (schedStop.getMinutes() - isoStart.getMinutes()) / 60;
			}
			// If the show end is before the schedule end
			else {
				show_length = isoStop.getHours() - isoStart.getHours();
				show_length +=  (isoStop.getMinutes() - isoStart.getMinutes()) / 60;
			}
		}
        //show_length = isoStop.getHours() - isoStart.getHours();
        //show_length +=  (isoStop.getMinutes() + isoStart.getMinutes()) / 60;
        var width = (show_length / 3) * 100;
		//width = Math.floor(width);
		//width -= .1;
        width = width.toString() + '%';

		var numHours = 3;
		var empty_slots = numHours * 60; // gets the number of minutes in the schedule
		var colSpan = show_length * 60;
	
        var style = 'width: ' + width + '; ';
        /*var colSpan = show_length * 6;
		if(colSpan < 1) {
			colSpan = 1;
		}*/
		//var style = 'width:10%;'; //TODO: set correctly, for now just test with all programmes at 10% width
		//style = "width:16.66666%";
		// insert the formed programme DIV into the div array
        programme_tds.push(TD({'id':progID, 'colSpan':colSpan}, prog_title));
    }
	// second TD hold programme DIV66s
    formed_row.push(/*TD({'class':'progContainer','colSpan':'6','style':'width:100%'},
		/*TABLE({'style':'width:100%'},TR({'style':'width:100%'},*/ programme_tds); // colSpan *not* colspan -- I HATE IE!!!
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
