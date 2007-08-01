
function formSearchedTable() {
	var disp_row = function (row) {
		var channelID = row.getAttribute('channel')
        var prog_start = row.getAttribute('start');
        var prog_stop = row.getAttribute('stop');
		var prog_start = prog_start.slice(0,prog_start.length - 6); // Drop the timezone in start time
		var prog_stop = prog_stop.slice(0,prog_stop.length - 6); // Drop the timezone in start time
		var progID = channelID + prog_start;
		
		var formed_row =[];
		formed_row.push(row.getElementsByTagName('title')[0].firstChild.nodeValue);
		var prog_desc = row.getElementsByTagName('desc');
		formed_row.push(prog_desc.length == 0 ? "" : prog_desc[0].firstChild.nodeValue);
		formed_row.push(zapTimeToDate(prog_start).toLocaleString());
		formed_row.push(zapTimeToDate(prog_stop).toLocaleString());
		//formed_row.push(row.getElementsByTagName('channel')[0].firstChild.nodeValue);
        formed_row.push("");
		formed_row.push(INPUT({'type':'checkbox','value':progID}));
		var table_row = TR({'id':"recording:" + progID},map(partial(TD,null), formed_row));	
		var isRecording = recording.find(progID); 
		if(isRecording != -1) {
            updateNodeAttributes(table_row,{'class':'recordingProgramme'});
        }
        else {
            updateNodeAttributes(table_row,{'class':'programme'});
        }
        return table_row
	}
	
	var new_table = TABLE({'id':'searched','class':'schedule'},
		THEAD({'style':'width:100%'},
			TR({'class':'head'},
				map(partial(TD,{'class':'head'}), ['Title','Description','Start','End','Channel','Record']))),
        TBODY({'style':'width:100%'},
			map(disp_row,searched.programmes)));
	swapDOM('searched',new_table);
}
