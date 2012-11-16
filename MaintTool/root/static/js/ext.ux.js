// A mix of helpful utility functions and user extensions for ExtJS
// - Todd Holbrook

Ext.namespace( 'Ext.ux' );

Ext.ux.utils = {
    
    formSubmitFailure: function(form, action) {
        if ( action.result && !action.result.success ) {
            if ( action.result.errorMessage ) {
                Ext.MessageBox.alert( 'Error', action.result.errorMessage );
            }
            else if ( action.result.errors ) {
                Ext.MessageBox.alert('Error', 'There was an error with one or more fields.');
                form.markInvalid( action.result.errors );
            }
            else {
                Ext.MessageBox.alert('Error', 'Unknown form submission error.');
            }
        }
        else {
            Ext.ux.utils.ajaxServerFailure( action.response )
        }
    },

    ajaxCheckResponse: function(response) {
      response_json = Ext.decode(response.responseText);
      if ( !response_json.success ) {
          if ( response_json.errorMessage ) {
              Ext.MessageBox.alert( 'Error', response_json.errorMessage );
          }
          else {
              Ext.MessageBox.alert( 'Error', 'No errorMessage found.');
          }
          return false;
      }
      return true;
    },

    ajaxServerFailure: function(response) {
        Ext.MessageBox.alert(
            'Server Error',
            'There was an error communicating with the server:<br /><b>' 
            + response.statusText
            + '</b>'
        );

    },
    
    handleEmptyCombo: function( combo, record, index ) {
        var v = record.get('id');
        if ( v===undefined || v === null || v==='' ) {
            combo.clearValue();
        }
    }
    
};

Ext.ux.AdvancedPagingToolbar = Ext.extend( Ext.PagingToolbar, {
    doLoad: function(start) {
        if ( this.hash_state ) {
            this.hash_state.paging['start'] = start;
            this.hash_state.setState();
        }
        Ext.ux.AdvancedPagingToolbar.superclass.doLoad.call(this, start);
    }
} );


// Get and set state using URI hashes

HashState = function() {
    this.params = {};
    this.paging = {};
    return this.getState();
};

Ext.override( HashState, {
    getState: function() {
        // Get state from location hash
        var hash = window.location.hash;
        if ( hash.length > 2 && hash.charAt(0) == "#" && hash.charAt(1) == '?' ) {
            hash = hash.substring(2);
        }
        else if ( hash.length > 1 && hash.charAt(0) == "#" ) {
            hash = hash.substring(1);
        }

        var decodedURL = Ext.urlDecode(hash);
        var params = {};
        for ( var key in decodedURL ) {
            params[decodeURI(key)] = decodeURI( decodedURL[key] ).replace(/\+/g, ' ');
        }
        this.params = params;
        this.paging = {};

        // Move paging from params to paging if present

        Ext.each( ['start', 'limit'], function(param) {
            if ( this.params[param] ) {
                this.paging[param] = parseInt(this.params[param]);
                delete this.params[param];
            }
        }, this );

        return this;
    },
    
    setState: function() {
        var newhash = {};
        Ext.apply( newhash, this.params, this.paging );
        for ( var key in newhash ) {
            if ( typeof newhash[key] == 'undefined' || newhash[key] == '' ) {
                delete newhash[key];
            }
        }
        window.location.hash = '#?' + Ext.urlEncode(newhash);

        return this;
    }
    
} );

