var _ref;

if (((_ref = window.history) != null ? _ref.pushState : void 0) && window.history.replaceState) {
    document.addEventListener('page:change', (function(_this) {
        return function(event) {
            if (window.ga !== void 0) {
                //console.log('OPTION-1: href: '+location.href.split('#')[0])
                ga('set', 'location', location.href.split('#')[0]);
                return ga('send', 'pageview', {
                    "title": document.title
                });
            } else if (window._gaq !== void 0) {
                //console.log('OPTION-2')
                return _gaq.push(['_trackPageview']);
            } else if (window.pageTracker !== void 0) {
                //console.log('OPTION-3')
                return pageTracker._trackPageview();
            }
        };
    })(this));
}


function setPageAnalytics(href, title){

    //href = href || location.href.split('#')[0]
    href = href || location.pathname
    title = title || document.title
    if (window.ga !== void 0) {
        //console.log('OPTION-1: href: '+href)
        ga('set', 'location', href);
        return ga('send', 'pageview', {
            "title": title
        });
    }
}

$document.on("page:load page:change", function(e){
    //console.log("setAnalytics: ", e.type)
    setPageAnalytics()
})

