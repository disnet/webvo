App = {
    init: function() {
        this.page = new ScheduledFrame();
        this.page.init();
    }
};

window.onload = App.init;
