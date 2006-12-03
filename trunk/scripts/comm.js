// Derfered reqests handlers

var errMsg = "\n\nPlease contact your System Administrator";

// Got the channels from server
var gotChannels_init = function(req) {
    schedule.xmlChannels = req.responseXML; 

    var error = schedule.xmlChannels.getElementsByTagName('error');
    if(error.length != 0) { 
        alert("Error: " + error[0].firstChild.nodeValue + errMsg);
        schedule.xmlChannels = null;
        return;     // If we get an error at this point no point in going on
    }
    var xmlStartStop = req.responseXML.getElementsByTagName('programme_date_range')[0];
    schedule.startDate = xmlStartStop.getAttribute('start');
    schedule.stopDate = xmlStartStop.getAttribute('stop');

    initFormTime(); // init the time selection boxes
};

// Get the programmes from server
var gotProgrammes = function(req) {
   schedule.xmlProgrammes = req.responseXML;

   var error = schedule.xmlProgrammes.getElementsByTagName('error');
   if(error.length != 0) {
       alert("Error: " + error[0].firstChild.nodeValue + errMsg);
       schedule.xmlProgrammes = null;
       return;
    }
	
	// Create the table
   	formListingTable();
};

// Make sure there was not error when adding a show
var gotAdd = function(req) {
	xmldoc = req.responseXML;

	var error = xmldoc.getElementsByTagName('error');
	var success = xmldoc.getElementsByTagName('success');
	
	if(error.length != 0 ) {
		$('boxContent').innerHTML = error[0].firstChild.nodeValue;
	}
	else if(success.length != 0) {
		var progID = success[0].firstChild.nodeValue;
		updateNodeAttributes(progID,{'class':'recordingProgramme'});    // change the style of the programe TD
		makeInvisible('mnuRecord');
	}
	else {
		alert('Error: ' + req.responseText + errMsg);
	}

    var d = doSimpleXMLHttpRequest('ruby/form_recording.rb');
    d.addCallbacks(gotRecording,fetchFailed);

	makeInvisible('boxLoading'); 
};

// got list of shows that will be recorded
var gotRecording = function(req) {
	recording.programmes = req.responseXML.getElementsByTagName('programme');
    var error = req.responseXML.getElementsByTagName('error');

    if(error.length != 0) {
       alert('Error: ' + error[0].firstChild.nodeValue + errMsg);
       return;  // no point in going on
    }

	recording.programmes = map(function(el) {return el;}, recording.programmes); 	// convert nodelist to array
    var now = new Date();
    forEach(recording.programmes, function(prog) {
         if(zapTimeToDate(prog.getElementsByTagName('start')[0].firstChild.nodeValue) < now) {
            $('boxCurrRecord').firstChild.nodeValue = " -- Currently Recording '" +
                prog.getElementsByTagName('title')[0].firstChild.nodeValue + "'";
            
        }
    });
	formRecordingTable();
};

var gotRecorded = function(req) {
	recorded.programmes = req.responseXML.getElementsByTagName('programme');
    var error = req.responseXML.getElementsByTagName('error');

    if(error.length != 0) {
        alert('Error: ' + error[0].firstChild.nodeValue + errMsg);
    }

	recorded.programmes = map(function(el) {return el;}, recorded.programmes); 	// convert nodelist to array
	formRecordedTable();
};

var gotDelRecording = function(req) {
    var error = req.responseXML.getElementsByTagName('error');
    var progID = req.responseXML.getElementsByTagName('success')[0];
    if(error.length != 0) {
        alert("Error: " + error[0].firstChild.nodeValue + errMsg);
    }
    updateNodeAttributes(progID.firstChild.nodeValue,{'class':'programme'});

};

var gotDelRecorded = function(req) {
    var error = req.responseXML.getElementsByTagName('error');
    if(error.length != 0) {
        alert("Error: " + error[0].firstChild.nodeValue + errMsg);
    }
};

var gotSpace = function(req) {
    var error = req.responseXML.getElementsByTagName('error');
    if(error.length != 0) {
        alert("Error: " + error[0].firstChild.nodeValue + errMsg);
    }
    var avail = req.responseXML.getElementsByTagName('available')[0];
    avail = parseInt(avail.firstChild.nodeValue) / (1024*1024);
    avail = Math.round(avail);
    $('boxSpace').firstChild.nodeValue = " -- Available Disk Space: " + avail + "GB";
}
// Error handling for listing request
var fetchFailed = function (err) {
    alert("Error: " + err + errMsg);
};
