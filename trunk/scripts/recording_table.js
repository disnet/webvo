
function formRecordingTable() {
	var progs = recording.xmlRecording.getElementsByTagName('programme');
	progs = map(function(el) {return el;}, progs); 	// convert nodelist to array
	
	var disp_row = function (row) {
		var channelID = row.getElementsByTagName('channelID')[0].firstChild.nodeValue
		var start = row.getElementsByTagName('start')[0].firstChild.nodeValue
		var progID = channelID + start;
		
		var formed_row =[];
		formed_row.push(row.getElementsByTagName('title')[0].firstChild.nodeValue);
		//formed_row.push(row.getElementsByTagName('desc')[0].firstChild.nodeValue);
		formed_row.push( zapTimeToDate(row.getElementsByTagName('start')[0].firstChild.nodeValue).toLocaleString());
		formed_row.push(zapTimeToDate(row.getElementsByTagName('stop')[0].firstChild.nodeValue).toLocaleString());
		formed_row.push(row.getElementsByTagName('channel')[0].firstChild.nodeValue);
		formed_row.push(INPUT({'type':'checkbox','value':progID}));
		return TR({'id':progID},map(partial(TD,null), formed_row));	
	}
	
	var new_table = TABLE({'id':'recording','class':'tblRecording'},
		THEAD({'style':'width:100%'},
			TR({'class':'tblRecordingHead'},
				map(partial(TD,{'class':'tblRecording'}), ['Title','Start','End','Channel','Delete']))),
        TBODY({'style':'width:100%'},
			map(disp_row,progs)));
	swapDOM('recording',new_table);
}
