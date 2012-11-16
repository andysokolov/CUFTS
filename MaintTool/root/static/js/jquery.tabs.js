$.fn.extend( {
    tabs:  function(initial, settings) {

        // settings

    if (typeof initial == 'object') settings = initial; // no initial tab given but a settings object
    settings = $.extend({
        initial: (initial && typeof initial == 'number' && initial > 0) ? --initial : 0,
        navClass: 'tabs-nav',
        selectedClass: 'tabs-nav-active',
        disabledClass: 'tabs-disabled',
        containerClass: 'tabs-nav-page',
        hideClass: 'tabs-hide',
        loadingClass: 'tabs-loading'
    }, settings || {});

    return this.each(function() {

        var container = this;

        // set up tabs
        var nav = $('ul.' + settings.navClass, container);
        nav = nav.size() && nav || $('>ul:eq(0)', container);  // fallback to default structure
        var tabs = $('a', nav);

        // set up containers
        var containers = $('div.' + settings.containerClass, container);
        containers = containers.size() && containers || $('>div', container); // fallback to default structure

        // attach classes for styling if not present
        nav.is('.' + settings.navClass) || nav.addClass(settings.navClass);
        containers.each(function() {
            var $$ = $(this);
            $$.is('.' + settings.containerClass) || $$.addClass(settings.containerClass);
        });

        // set active tab & page
        containers.hide();
        var a = $('li', nav).removeClass(settings.selectedClass).eq(settings.initial).addClass(settings.selectedClass).children('a').eq(0).attr('href');
        a = a.replace( /^.*#/, '#' );
        $(a).show();
        
        // set up click bindings
        tabs.bind('click', function(event) {
            event.preventDefault();
            this.blur();

            // Check to see if the tab is active already

            var thisTab = $(this).parents('li:eq(0)');
            if ( thisTab.is('.' + settings.selectedClass) ) {
                return false;
            }

            // hide all divs, show the newly active one
            containers.hide();
            var x = this.href;
            x = x.replace( /^.*#/, '#' );
            $(x).show();

            $('li', nav).removeClass(settings.selectedClass);
            thisTab.addClass(settings.selectedClass);
        });
        
        containers.bind('triggerPage', function(event)  {
            $('a[@href=#' + this.id + ']').trigger('click');
        });
        
    })
}
});