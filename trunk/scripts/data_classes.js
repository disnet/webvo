 /* @class JSONRequest Base data structure for holding JSON responses from server.
    Handles async requests to server and stores data internally. Response data is 
    stored at `this.data`
    @scope Abstract base class. Maintained by convention.
    @url location of server resource
 */
function JSONRequest(url) {
    this._url = url;
    this._query = {'json':'true'};
}
/*  function will refresh data */
// TODO: add callback capability, code outside of data class to be
//  notified when data has been refreshed
JSONRequest.prototype.update = function() {
    var d = loadJSONDoc(this._url,this._query);
    d.addCallbacks(this._gotRequest,this._fetchFailed);
}
/* private function to store response data and call decendent's response handler */
JSONRequest.prototype._gotRequest = function(req) {
    this.data = req;
    this.reqHandler();
}
JSONRequest.prototype.reqHandler = function() {
    console.log('Abstract method...should have been implemented in child');
}
JSONRequest.prototype._fetchFailed = function(req) {
    console.log('Abstract method...should have been implemented in child');
}

function ListingData() {
    bindMethods(this);
}
ListingData.prototype = new JSONRequest('ruby/form_listing.rb');

ListingData.prototype.reqHandler = function () {
    $('schedule').innerHTML = this.data.listing.header;
    
}

/*  @class Data storage class to hold and display recorded information 
    @base JSONRequest
*/
function RecordedData() {
    bindMethods(this); /* remember `this` */
}
RecordedData.prototype = new JSONRequest('ruby/form_recorded.rb');

/* swap recorded table with new data */
RecordedData.prototype.reqHandler = function() {
    var oldRecordedTable = $('recorded');
    var temp_html = '<table id="recorded_table" class="recorded_table">';
    temp_html += this.data.recorded.header;
    for(var i = 0; i < this.data.recorded.programmes.length; i++) {
        temp_html += this.data.recorded.programmes[i].html;
    }
    temp_html += '</table>';
    oldRecordedTable.innerHTML = temp_html;
}

function ScheduledData() {
    bindMethods(this);
}
ScheduledData.prototype = new JSONRequest('ruby/form_scheduled.rb');

/* swap scheduled table with new data */
ScheduledData.prototype.reqHandler = function() {
    var oldScheduledTable = $('scheduled');
    var temp_html = '<table id="scheduled_table" class="scheduled_table">';
    temp_html += this.data.scheduled.header;
    for(var i = 0; i < this.data.scheduled.programmes.length; i++) {
        temp_html += this.data.scheduled.programmes[i].html;
    }
    temp_html += '</table>';
    oldScheduledTable.innerHTML = temp_html;
    this.markAdjacent();
}

/* mark scheduled listings if adjacent to other scheduled shows 
   this depends on the programme data being sequentially ordered 
*/
ScheduledData.prototype.markAdjacent = function() {
    var previousEnd = "";
    for(var i = 0; i < this.data.scheduled.programmes.length; i++) {
        if (this.data.scheduled.programmes[i].start == previousEnd) {
            addElementClass(this.data.scheduled.programmes[i].id, "adjacentBefore");
        }
        else {
            removeElementClass(this.data.scheduled.programmes[i].id, "adjacentBefore");
        }
        previousEnd = this.data.scheduled.programmes[i].stop;
    }

}

function SearchData() {
    bindMethods(this); /* preserve `this` for callbacks */
}
SearchData.prototype = new JSONRequest('ruby/form_search.rb');

/* change the query string (set search terms) */
SearchData.prototype.setQuery = function(term,val) {
    this._query[term] = val;
}
/* swap search table with new data */
SearchData.prototype.reqHandler = function() {
    var oldSearchTable = $('searched');
    var temp_html = '<table id="searched_table" class="searched_table">';
    temp_html += this.data.search.header;
    for(var i = 0; i < this.data.search.programmes.length; i++) {
        temp_html += this.data.search.programmes[i].html;
    }
    temp_html += '</table>';
    oldSearchTable.innerHTML = temp_html
}
SearchData.prototype.searchFailed = function(req) { 
    console.error("Problem retrieving search results:");
    console.error(req);
}

