function InfoTable(sContainerId,sUpdateUrl, sSubmitUrl)
{
    bindMethods(this);

    // backend files to hit
    this._update_url = sUpdateUrl;
    this._submit_url = sSubmitUrl;

    // tag ids to use
    this._container = $(sContainerId);
    this._table = sContainerId + '_table'; // tables will have the same id as the containing div with `_table` appended

    this.data = {};
    this._callbackChain = [];

    this._markAdjacent = false;
}

InfoTable.prototype = {
    update : function(sQuery) {
        var url = this._update_url + "?" + sQuery;
        var d = loadJSONDoc(url);   
        this._deffered = d;

        d.addCallbacks(this._gotRequest,this._fetchFailed);
        for(var i = 0; i < this._callbackChain.length; i++) {
            d.addCallback(this._callbackChain[i]);
        }
    },

    addUpdateCallback: function(fCallback) {
        throw new Error("Function turned off for now");
        //this._callbackChain.push(fCallback);
    },

    // todo: can I do something with properties?
    setMarkAdjacent: function(val) {
        this._markAdjacent = val;
    },

    // this function is no longer specific to scheduled data and should be renamed - dmh
    _markScheduledAdjacent: function() {
        var previousEnd = "";
        for(var i = 0; i < this.data.programmes.length; i++) {
            if (this.data.programmes[i].start == previousEnd) {
                addElementClass(this.data.programmes[i].html_id, "adjacentBefore");
           }
            else {
                removeElementClass(this.data.programmes[i].html_id, "adjacentBefore");
            }
            previousEnd = this.data.programmes[i].stop;
        }
    },

    _gotRequest: function(req){
        this.data = req;
        var oldTable = this._container;
        var temp_html = '<table id="' + this._table + '" class="' + this._table + '">';

        temp_html += this.data.header;
        for(var i = 0; i < req.programmes.length; i++){
            temp_html += this.data.programmes[i].html;
        }
        temp_html += '</table>';
        oldTable.innerHTML = temp_html;

        if (this._markAdjacent) {
            this._markScheduledAdjacent();
        }

        this._connectClick();
    },

    _connectClick: function() {
        for( var i = 0; this.data.programmes.length; i++) {
            connect(this.data.programmes[i].html_id,'onclick', this._clicked);
        }
    },
    
    _clicked: function(e) {
        var input = getFirstElementByTagAndClassName('input', null,e.src());
        if (input != e.target()) {
            Util.toggleCheck(input);
        }
        if (input.checked) {
            addElementClass(e.src(), "programmeSelected");
        }
        else {
            removeElementClass(e.src(), "programmeSelected");
        }
    },
    _fetchFailed: function(req) {
        console.error('Problem retrieving search rsults: ');
        console.error(req);
    }
};
