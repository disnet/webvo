/*
WebVo: Web-based PVR
Copyright (C) 2006 Tim Disney, Daryl Siu, Molly Jo Bault

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

function init() {
    connect('btnLoad','onclick',getXML);
    connect('btnTest','onclick',test);
}
var test = function(e) {
/*    s = "20061023060000 -0800";
    b = "20061023070000 -0800";

    small = isoTimestamp(s);
    big = isoTimestamp(b);
    if(small < big)
        log("you win");
    else if(small >= big)
        log("you suck");
    else
        log("what!!");
        */
    var test =  TABLE({'border':'1px solid black'},
            [TR(null,map(partial(TD,null),[1,2,3,4])),TR(null,TD({'colSpan':'3'},'fun'))]);
    swapDOM('schedule',test);
};
var getXML = function(e) {
    var d = doSimpleXMLHttpRequest('schedTest.xml');
    d.addCallbacks(gotSchedule,fetchFailed);
};

var gotSchedule = function (req) {
    var rows = Object();
    var xmldoc = req.responseXML;

    var root_node = xmldoc.getElementsByTagName('tv').item(0);
    var xml_channels = root_node.getElementsByTagName('channel');
    var all_xml_programmes = root_node.getElementsByTagName('programme');

    // Filters xml_programmes for the correct time
    var form_programmes = function(pr) {
        var start = isoTimestamp(munge_date(pr.getAttribute('start')));
        var stop = isoTimestamp((pr.getAttribute('stop')));
        if( start >= isoTimestamp(munge_date('20061023000000 -0800')) && start < isoTimestamp(munge_date('20061023030000 -0800')))
            {return true;}
        else
            {return false;}
    };

    row_display = function(row) {
        return TR(null, TD(null, row));
    };

    programme_row_display = function(row) {
        var channelID = row[0].getAttribute('id');
        var channel_name = row[0].getElementsByTagName('display-name')[0].firstChild.nodeValue;


        var formed_row = [TD({'id':'channelID'}, channel_name)];
        var programme_divs = [];
        for(var i = 1; i < row.length; i++) {
            var prog_title = row[i].getElementsByTagName('title')[0].firstChild.nodeValue;
            var prog_start = row[i].getAttribute('start');
            var progID = prog_title + prog_start + channelID; // First attempt at progID -- should be unique?

            var isoStart = isoTimestamp(munge_date(row[i].getAttribute('start')));
            var isoStop = isoTimestamp(munge_date(row[i].getAttribute('stop')));

            var show_length = isoStop.getHours() - isoStart.getHours();
            show_length +=  (isoStop.getMinutes() + isoStart.getMinutes()) / 60;
            var width = (show_length / 3) * 100;
            width = width.toString() + '%';

            //var style = 'width: ' + width + '; ';
            var style = 'width:10%;'; //testing...
            style = style + 'background-color: gray; float: left; border:1px solid black; margin-left: -1px;';
            programme_divs.push(DIV({'id':progID, 'style':style}, prog_title));
        }
        formed_row.push(TD({'colSpan':'6'}, programme_divs)); // colSpan *not* colspan -- I HATE IE!!!
        return TR(null, formed_row);
    };
    
    // 0.  Filter programmes to the correct time (Don't need in furture versions)
    var xml_programmes = filter(form_programmes,all_xml_programmes); // grabs shows for correct time

    // 1.  Initialize <rows> Object(). Each channel is added as the first element of it's own property
    forEach(xml_channels, function(ch) { rows[ch.getAttribute('id')] = [ch]; });

    // 2.  Fill  <rows> Object() with correct program xml element for the correct channelID slot
    forEach(xml_programmes, function(el) { rows[el.getAttribute('channel')].push(el); });


    var head_strings = ['Ch.','12:00','12:30','1:00','1:30','2:00','2:30'];
    var new_table = TABLE({'class':'schedule'},
        //THEAD(null,null),//TR(null,TD(null,""))),
//            TR({'class':'listHead'}, map(partial(TD,null), head_strings)),
        TBODY(null,
            [TR({'class':'listHead'}, map(partial(TD,null), head_strings))].concat(map(programme_row_display, obj2arr(rows)))));
    swapDOM('schedule',new_table);
};

function obj2arr(obj) {
    var arr = [];
    var i = 0;
    for (name in obj) {
       arr[i++] = obj[name]; 
    }
    return arr;
}

// form the date into something more acceptable
function munge_date(str_date) {
    parsed_date = str_date.slice(0,4) + '-';
    parsed_date += str_date.slice(4,6) + '-';
    parsed_date += str_date.slice(6,8) + ' ';
    parsed_date += str_date.slice(8,10) + ':';
    parsed_date += str_date.slice(10,12) + ':';
    parsed_date += str_date.slice(12);
    return parsed_date;
}
var fetchFailed = function (err) {
    log("Data is not available");
    log(err);
};
