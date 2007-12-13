// Collection of utility functions

var Util = {
    makeVisible: function(el) {
        removeElementClass(el,'invisible');
    },
    makeInvisible: function(el) {
        addElementClass(el,'invisible');
    },
    toggleCheck: function(el) {
        el.checked = !el.checked
    },

    // Converts military time to standard
    // TODO: make this fcn more robust...fails unless `:00` is passed in
    mil2std: function(mil) {
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
    },

    getOffset: function(isoString) {
        return isoTimestamp(isoString).getTimezoneOffset() / 60;
    },

    // todo: need to deal with this sometime
    utcToLocal: function(utcString,offset) {
        return utcString;
    },

    dateToZapTime: function(date) {
        isoTime = toISOTimestamp(date);
        
        zapTime = isoTime.slice(0,4);	//year
        zapTime += isoTime.slice(5,7);	//month
        zapTime += isoTime.slice(8,10);	//day

        if(date.getHours() < 10) {	// need to pad an extra zero for the hour
            zapTime += "0" + isoTime.slice(11,12);
            zapTime += isoTime.slice(13,15);
            zapTime += isoTime.slice(16,18);
        } else {
            zapTime += isoTime.slice(11,13);	//hour
            zapTime += isoTime.slice(14,16);	//miniute
            zapTime += isoTime.slice(17,19);	//second
        }
        return zapTime;
    }
}

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

// Converts zap2it timestamp to a date object
// expects input like:     20070330180000 +0000
// parsed to look like:    2007-03-30 18:00:00Z +00:00
// Output is a date object
//We want the timezone to reflect the server
//So, find the difference between the server localtime and the browser offset 
//ASSUMPTION: zap2it data is always in UTC
function zapTimeToDate(str_date) {
    parsed_date = str_date.slice(0,4) + '-';    //year
    parsed_date += str_date.slice(4,6) + '-';   //month
    parsed_date += str_date.slice(6,8) + ' ';   //day
    parsed_date += str_date.slice(8,10) + ':';  //hour
    parsed_date += str_date.slice(10,12) + ':'; //minitues
    parsed_date += '00';                     //tack on the timezone

    return isoTimestamp(parsed_date);
}

// Convets a date object to a zap2it timestamp
function dateToZapTime(date) {
    isoTime = toISOTimestamp(date);
	
    zapTime = isoTime.slice(0,4);	//year
    zapTime += isoTime.slice(5,7);	//month
    zapTime += isoTime.slice(8,10);	//day

	if(date.getHours() < 10) {	// need to pad an extra zero for the hour
		zapTime += "0" + isoTime.slice(11,12);
		zapTime += isoTime.slice(13,15);
		zapTime += isoTime.slice(16,18);
	} else {
		zapTime += isoTime.slice(11,13);	//hour
		zapTime += isoTime.slice(14,16);	//miniute
    	zapTime += isoTime.slice(17,19);	//second
	}
    return zapTime;
}

// Converts military time to standard
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

// Hide an element
function makeInvisible(el) {
	addElementClass(el,'invisible');
}
// Unhide an element
function makeVisible(el) {
	removeElementClass(el,'invisible');
}

function getChanNum(chanID) {
    chanNum = ""
    for (var i = 0; i < schedule.xmlChannels.length; i++) {
        if (chanID == getNodeAttribute(schedule.xmlChannels[i],"id")) {
            chanName = getFirstElementByTagAndClassName('display-name',null,schedule.xmlChannels[i])
            chanNum = chanName.firstChild.nodeValue
            break;
        }
    }
    return chanNum
}
