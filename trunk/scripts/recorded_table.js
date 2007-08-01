
function formRecordedTable() {
	var disp_row = function (row) {
		var channelID = row.getAttribute('channel')
        var prog_start = row.getAttribute('start');
        var prog_stop = row.getAttribute('stop');
		var prog_start = prog_start.slice(0,prog_start.length - 6); // Drop the timezone in start time
		var prog_stop = prog_stop.slice(0,prog_stop.length - 6); // Drop the timezone in start time
		var progID = channelID + prog_start;

		var formed_row =[];
        var path = row.getElementsByTagName('path')[0].firstChild.nodeValue;
        var title = row.getElementsByTagName('title')[0].firstChild.nodeValue;
        
		formed_row.push(A({'href': path},title));
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
		var size = parseInt(row.getElementsByTagName('size')[0].firstChild.nodeValue);
		size = Math.round( size / (1024*1024));
		formed_row.push(size.toString() + " MB");
		formed_row.push(INPUT({'type':'checkbox','value':progID}));
		return TR({'id':"recorded:" + progID},map(partial(TD,null), formed_row));	
	}
	
	var new_table = TABLE({'id':'recorded','class':'tblRecord'},
		THEAD({'style':'width:100%'},
			TR({'class':'tblRecordHead'},
				map(partial(TD,{'class':'tblRecord'}), ['Title','Episode','Description','Start','End','Size','Delete']))),
        TBODY({'style':'width:100%'},
			map(disp_row,recorded.programmes)));
	swapDOM('recorded',new_table);
}
