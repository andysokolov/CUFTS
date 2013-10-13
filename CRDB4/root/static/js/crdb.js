$().ready( function() {

  $('#name-select').bind('change', function(e) {
    $(this).parent().submit();
  });

  $('.show-more').bind('click', function(e) {
    $(this).parents('.facet-menu').find('.collapsable').show();
    $(this).hide();
  });

});

var CRDB = {};
CRDB.show_nodata_fields = 0;


function toggle_nodata_fields( ) {
    CRDB.show_nodata_fields = !CRDB.show_nodata_fields;
    nodata_fields();
}

function nodata_fields( ) {
    $('.no_data').each( function(i) {
        this.style.display = CRDB.show_nodata_fields ? '' : 'none';
    });
}

$( function ( ) {
    nodata_fields();
} );


function ajax_get_edit( field, url ) {
    $.ajax({
        type: 'GET',
        url: url,
        dataType: 'html',
        success: function( html ) {
            $('#resource-definition-' + field).find('.field-data').hide();

            $('#resource-definition-' + field).append(
                '<div class="field-editing">' + html + '</div>'
            );

            $('#resource-' + field).find('.resource-edit-control-savecancel').show();
            $('#resource-' + field).find('.resource-edit-control-edit').hide();

       }
    });
}

function ajax_cancel_edit( field ) {
    $('#resource-definition-' + field).find('.field-editing').remove();
    $('#resource-definition-' + field).find('.field-data').show();

    $('#resource-' + field).find('.resource-edit-control-savecancel').hide();
    $('#resource-' + field).find('.resource-edit-control-edit').show();

}

function ajax_save_edit( field, url ) {

    var editfield = $('#resource-definition-' + field + ' .validate');
    if ( editfield.length == 1 ) {
        if ( !validate_field(editfield) ) {
            return;
        }
    }

    $.ajax({
       type: 'POST',
       url: url,
       data: $('#resource-definition-' + field).find('.field-editing form').serialize(),
       success: function( html ) {
           $('#resource-' + field).replaceWith( html );

           $('#resource-' + field).find('.resource-edit-control-savecancel').hide();
           $('#resource-' + field).find('.resource-edit-control-edit').show();

           nodata_fields();
       }
    });
}

function validate_field( field ) {
    var message_field = field.parent().find('.validate-message');

    if ( field.hasClass('validate-date') ) {
        var val = field.val();
        if ( val == '' || val.search( /^\d{4}-\d{2}-\d{2}$/ ) != -1 ) {
            message_field.html('');
            return true;
        }
        else {
            message_field.html('Date fields must be blank or YYYY-MM-DD');
            return false;
        }
    }
    else if ( field.hasClass('validate-integer') ) {
        var val = field.val();
        if ( val == '' || val.search( /^-?\d+$/ ) != -1 ) {
            message_field.html('');
            return true;
        }
        else {
            message_field.html('Integer fields must be blank or contain a valid integer.');
            return false;
        }
    }

}

function delete_subject( subject_id ) {
    CRDB.to_delete[ subject_id ] = 1;
    CRDB.to_add[ subject_id ] = 0;

    $('#edit-subjects-add').addOption( subject_id, CRDB.all_subjects[subject_id], false ).sortOptions();
    $('div#edit-all-subjects-' + subject_id).hide();

    update_subject_fields();

    return false;
}

function add_subject() {
    var subject_id = $('#edit-subjects-add').find("option:selected")[0].value;

    CRDB.to_delete[ subject_id ] = 0;
    CRDB.to_add[ subject_id ] = 1;

    $('#edit-subjects-add').removeOption( subject_id, false );
    $('div#edit-all-subjects-' + subject_id).show();

    update_subject_fields();

    return false;
}

function update_subject_fields() {
    var key;
    var array = new Array();
    for (key in CRDB.to_add) {
        if ( CRDB.to_add[key] ) {
            array.push(key)
        }
    }
    $('#edit-subjects-add-field').val( array.join(',') );

    array = new Array();
    for (key in CRDB.to_delete) {
        if ( CRDB.to_delete[key] ) {
            array.push(key)
        }
    }
    $('#edit-subjects-delete-field').val( array.join(',') );
}