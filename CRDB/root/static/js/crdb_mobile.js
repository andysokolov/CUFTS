var CRDB_mobile = {

    // Message displayed above group record buttons
    group_record_message: 'This resource is available from multiple vendors. Please select a link button below.',

    // Sets up a mapping of resource field internal names to display names. Customizable by sites.
    field_map: {
        access: 'Access',
        alert: 'Alert',
        allows_coursepacks: 'Allows Coursepacks',
        allows_ereserves: 'Allows Electronic Reserves',
        allows_ill: 'Allows Interlibrary Loans',
        coverage: 'Coverage',
        description_full: 'Description',
        ill_notes: 'Interlibrary Loan Notes',
        name: 'Name',
        open_access: 'Open Access',
        print_equivalents: 'Print Equivalents',
        refworks_compatible: 'Refworks Compatible',
        resolver_enabled: 'Resolver Enabled',
        resource_type: 'Resource Type',
        simultaneous_users: 'Simultaneous Users',
        subjects: 'Subjects',
        title_list_url: 'Title List URL',
        update_frequency: 'Update Frequency',
        url: 'Connect',
        user_documentation: 'User Documentation',
        vendor: 'Vendor'
    },


    // Override display fields - if you want to show different fields in your mobile site than in your
    // main site, you can override the list of fields for display here.

    display_fields_override: null,

    /* --- jQuery Mobile page setups. These can be overridden if necessary, but I'm trying to
           add hooks to avoid that where I can --- */

    initApp: function() {
        var app = this;
        this.initPages();
        
        $('#home').one( 'pagecreate', function() {
            var url = document.URL;
            var reg = /id=(\d+)/;
            var match = reg.exec(url);

            if ( match ) {
                app.saveToSessionStorage({ resource_id: match[1] });
                $.mobile.changePage( '#full' );
            }
        });
        
        
    },
    
    initPages: function() {
        this.initAZPage();
        this.initSubjectsPage();
        this.initResourcesPage();
        this.initFullPage();
    },

    initAZPage: function() {
        var app = this;

        $('div#az').live('pagebeforecreate', function(event) {

            var page = $(event.currentTarget);
            var az_list = page.find('ul');

            az_list.delegate('a', 'click', function() {
                app.saveToSessionStorage({
                    resources_search_type: 'name',
                    resources_search_value: $(this).attr('letter'),
                    resources_title_text: $(this).attr('letter')
                }, 'resources_reload');
            });
            
        });
        
    },

    initSubjectsPage: function() {
        var app = this;

        $('div#subjects').live('pagebeforecreate', function(event) {

            var page = $(event.currentTarget);
            var subject_list = page.find('ul');

            var loader = app.createLoader();
            page.append(loader);

            $.getJSON( app.subjects_json_url, function(data) {

                $.each(data.subjects, function(i,subject) {
                    subject_list.append('<li><a href="#resources" subject-id="' + subject.value + '">' + subject.text + '</a></li>');
                });

                // When a subject is clicked, save the info to the HTML5 sessionStorage so that the
                // next page (list of resources) can pick it up and do the appropriate AJAX call.
                subject_list.delegate('a', 'click', function() {
                    app.saveToSessionStorage({
                        resources_search_type: 'subject',
                        resources_search_value: $(this).attr('subject-id'),
                        resources_title_text: $(this).text()
                    }, 'resources_reload');
                });

                loader.remove();
                subject_list.listview('refresh');
            });
        });

    },

    initResourcesPage: function() {
        
        var app = this;

        $('div#resources').live('pagebeforeshow', function(event) {

            var page = $(event.currentTarget);
            var resource_list = page.find('ul');
            
            // Don't bother reloading the list if the user hasn't clicked on a new subject/A-Z name
            if ( sessionStorage.resources_reload != 1 && resource_list.find('li').length > 0 ) {
                return;
            }

            // Use HTML5 sessionStorage to get the current browse type and value
            var search_type  = sessionStorage.resources_search_type;
            var search_value = sessionStorage.resources_search_value;
            var title_text   = sessionStorage.resources_title_text;

            // Set the title header
            page.find('[data-role="header"] h1').text(title_text);

            // Loop through the resources. If we find a "group" (A, B, C, Top Resources, Other Resources, etc.) we haven't seen before, print it as a list-divider
            resource_list.empty();

            var loader = app.createLoader();
            page.append(loader);

            var last_group = ''; 
            $.getJSON( app.resources_json_url + '?' + app.URLEncode(search_type) + '=' + app.URLEncode(search_value), function(data) {
                
                $.each(data.resources, function(i,resource) {
                    if ( resource.group != last_group ) {
                        resource_list.append( $('<li>').attr('data-role', 'list-divider').text(resource.group) );
                        last_group = resource.group;
                    }

                    var resource_link =   resource.url 
                                        ? app.getGotoURL(resource.id).text(resource.name)
                                        : $('<a>').attr('href','#full').attr('resource-id', resource.id).text(resource.name);

                    // TODO: Deal with the edge case of resources without a connect URL
                    resource_list.append( 
                        $('<li>').append(
                            resource_link.append(
                                $('<br>'),
                                $('<span>').attr('class', 'brief-description').text( app.capLongText(resource.description_brief, 95) )
                            ),
                            $('<a>').attr('href','#full').attr('resource-id', resource.id).attr('data-icon','info').text('Info')
                        )
                    );
                });

                // Use HTML5 sessionStorage to set the resource id for the full view
                resource_list.delegate('a[href=#full]', 'click', function() {
                    app.saveToSessionStorage({ resource_id: $(this).attr('resource-id') });
                });

                loader.remove();
                resource_list.listview('refresh');
            });

            // Reload is done, don't do it again.
            app.saveToSessionStorage({ resources_reload: 0 });
        });    
    },
    
    initFullPage: function() {
        var app = this;
        
        $('div#full').live('pagebeforeshow', function(event) {

            var page = $(event.currentTarget);
            var container = page.find('#resource');
            var content = $('<div>');

            container.empty();
            var loader = app.createLoader();
            page.append(loader);

            // Use HTML5 sessionStorage to get the current browse type and value
            var resource_id = sessionStorage.resource_id;

            $.getJSON( app.resource_json_url + '?resource_id=' + app.URLEncode(resource_id), function(data) {
                var resource = data.resource;
                content.append( $('<h2>').attr('id', 'resource-data-name').text( resource['name'] ) );

                $.each( data.display_fields, function(i,field) {
                    app.fullDisplay( content, field.field, field.type, resource[field.field], resource );
                });

                loader.remove();
                content.appendTo(container);
                content.page();  // Process the added fields with JQM so things like buttons get rendered
            });

        });

    },

    /* --- Full display field rendering --- */

    fullDisplay: function(content, field_name, field_type, value, resource) {
        var func = this.field_name_override_map[field_name];
        if ( func != null && typeof(func) == 'string' ) {
            return this[func](content, field_name, value, resource);
        }
        
        func = this.field_type_map[field_type];
        if ( func != null && typeof(func) == 'string' ) {
            return this[func](content, field_name, value, resource);
        }
        
        return this.fullDisplayDefault(content, field_name, value, resource);
    },

    fullDisplayDefault: function(content, field_name, value, resource) {
        return this.fullDisplayText(field_name, value);
    },

    fullDisplayText: function(content, field_name, value, resource) {
        if ( typeof(value) != 'undefined' && value != null ) {
            content.append( $('<h3>').text( this.getDisplayFieldLabel(field_name) ) );
            content.append( $('<div>').attr('class', 'resource-data').attr('id', 'resource-data-' + field_name).html(value) );
        }
    },

    fullDisplayBoolean: function(content, field_name, value, resource) {
        if ( typeof(value) != 'undefined' && value != null ) {
            content.append( $('<h3>').text( this.getDisplayFieldLabel(field_name) ) );
            content.append( $('<div>').attr('class', 'resource-data').attr('id', 'resource-data-' + field_name).text( value ? 'yes' : 'no' ) );
        }
    },

    fullDisplayFieldURL: function(content, field_name, value, resource) {
        if ( typeof(value) != 'undefined' && value != null ) {
            content.append( this.getGotoURL(resource.id).attr('data-role', 'button').text('Connect') );
        }
    },

    fullDisplayFieldGroupRecords: function(content, field_name, value, resource) {
        if ( typeof(value) != 'undefined' && value != null ) {
            var app = this;
            content.append( this.group_record_message );
            $.each( value, function(i, group_record) {
                content.append( app.getGotoURL(group_record.id).attr('data-role', 'button').text(group_record.name) );
            });
        }
    },

    field_name_override_map: {
        url: 'fullDisplayFieldURL',
        group_records: 'fullDisplayFieldGroupRecords',
    },
    
    field_type_map: {
        boolean: 'fullDisplayBoolean',
        text: 'fullDisplayText'
    },

    /* --- You generally don't want to override stuff past here... --- */

    // These MUST be overridden in the mobile_app_setup template
    subjects_json_url:  null,
    resources_json_url: null,
    resource_json_url:  null,
    goto_url: null,

    /* --- Utility functions --- */
    createLoader: function() {
        return $.mobile.loadingMessage ?
            $( "<div class='ui-loader crdb-loading ui-body-a ui-corner-all'>" +
                        "<span class='ui-icon ui-icon-loading spin'></span>" +
                        "<h1>" + $.mobile.loadingMessage + "</h1>" +
                    "</div>" )
            : undefined;
    },
    
    getGotoURL: function(id) {
        return $('<a>').attr('href', this.goto_url.replace('XXX', id)).attr('rel', 'external');
    },
    
    getDisplayFieldLabel: function(field) {
        return typeof(this.field_map[field]) == 'undefined' ? field : this.field_map[field];
    },

    // Save data into HTML5 sessionStorage. If a flag name is passed in, set it to "1" if there were any changes
    saveToSessionStorage: function(data, flag) {
        var changes = 0;
        $.each(data, function(field, value) {
            if ( sessionStorage[field] != value ) {
                sessionStorage[field] = value;
                changes += 1;
            }
        });
        if ( changes > 0 && typeof(flag) != 'undefined' ) {
            sessionStorage[flag] = 1;
        }
        return changes > 0;
    },

    // Function to cap long text fields - used mainly for the brief descriptions in resource lists
    capLongText: function(text, max) {
        var output = text;

        if ( output.length > max ) {
            output = text.substring( 0, max+1 );
            output = output.substring( 0, output.lastIndexOf(" ") ) + " ...";
        }
        return(output);
    },

    // URL encoding stolen from the JQuery plugin
    URLEncode: function(c){var o='';var x=0;c=c.toString();var r=/(^[a-zA-Z0-9_.]*)/;
      while(x<c.length){var m=r.exec(c.substr(x));
        if(m!=null && m.length>1 && m[1]!=''){o+=m[1];x+=m[1].length;
        }else{if(c[x]==' ')o+='+';else{var d=c.charCodeAt(x);var h=d.toString(16);
        o+='%'+(h.length<2?'0':'')+h.toUpperCase();}x++;}}return o;
    }
}