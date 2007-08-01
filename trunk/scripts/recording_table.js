
function formRecordingTable() {
	var disp_row = function (row) {
		var channelID = row.getAttribute('channel')
        var prog_start = row.getAttribute('start');
        var prog_stop = row.getAttribute('stop');
		var prog_start = prog_start.slice(0,prog_start.length - 6); // Drop the timezone in start time
		var prog_stop = prog_stop.slice(0,prog_stop.length - 6); // Drop the timezone in start time
		var progID = channelID + prog_start;
		
		var formed_row =[];
		formed_row.push(row.getElementsByTagName('title')[0].firstChild.nodeValue);
		var prog_episode_node = row.getElementsByTagName('episode-num');
        var prog_episode = "";
        for (var i = 0; i < prog_episode_node.length; i++) {
            if (getNodeAttribute(prog_episode_node[i],"system") == "onscreen") {
                prog_episode = prog_episode_node[i].firstChild.nodeValue;
                break;
            }
        }
		formed_row.push(prog_episode);
		var prog_desc = row.getElementsByTagName('desc');
		formed_row.push(prog_desc.length == 0 ? "" : prog_desc[0].firstChild.nodeValue);
		formed_row.push(zapTimeToDate(prog_start).toLocaleString());
		formed_row.push(zapTimeToDate(prog_stop).toLocaleString());
		//formed_row.push(row.getElementsByTagName('channel')[0].firstChild.nodeValue);
        formed_row.push("");
		formed_row.push(INPUT({'type':'checkbox','value':progID}));
		return TR({'id':"recording:" + progID},map(partial(TD,null), formed_row));	
	}
	
	var new_table = TABLE({'id':'recording','class':'tblRecord'},
		THEAD({'style':'width:100%'},
			TR({'class':'tblRecordHead'},
				map(partial(TD,{'class':'tblRecord'}), ['Title','Episode','Description','Start','End','Channel','Remove']))),
        TBODY({'style':'width:100%'},
			map(disp_row,recording.programmes)));
	swapDOM('recording',new_table);
}
