function ListingData(url) {
    this._url = url;
    this._query = {'json':'true'};
    bindMethods(this);
}

/*  function will refresh data */
// TODO: add callback capability, code outside of data class to be
//  notified when data has been refreshed
ListingData.prototype.update = function() {
    var d = loadJSONDoc(this._url,this._query);
    d.addCallbacks(this._gotRequest,this._fetchFailed);
}

ListingData.prototype._gotRequest = function(req) {
    this.data = req;
    $('schedule').innerHTML = this.data.header;
}
