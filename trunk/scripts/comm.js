// Derfered reqests handlers


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
	
	// Create the table
   	formListingTable();
};

// Make sure there was not error when adding a show
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
	// TODO: error handling
	recording.xmlRecording = req.responseXML;
	formRecordingTable();
};

var gotDelRecording = function(req) {
	log(req.responseText);
};
// Error handling for listing request
var fetchFailed = function (err) {
    log("Data is not available");
    log(err);
};
