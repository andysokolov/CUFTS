var CRDB = {};
CRDB.show_nodata_fields = 0;

String.prototype.escape_html = function() {
    return this.replace(/&/g, "&amp;")
               .replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/"/g, "&quot;");
}

jQuery(document).ready( function($) {

    $('#facet-menu select, #facet-menu input, #main select, #main input').on( 'change', function(event) {
        $(this).parent().submit();
    });

    $('.show-more').on('click', function(event) {
        $(this).hide().parents('.facet-menu').find('.collapsable').show();
    });

    $('.browse-resources.sortable').sortable({
        group: 'browse-resources',
        nested: false,
        onDragStart: function(item, container, _super) {
            var offset = item.offset(),
                pointer = container.rootGroup.pointer

            adjustment = {
                left: pointer.left - offset.left,
                top: pointer.top - offset.top
            }

            _super(item, container)
        },
        onDrag: function(item, position) {
            item.css({
                left: position.left - adjustment.left,
                top: position.top - adjustment.top
            });
        },
        onDrop: function(item, container, _super) {
            var top = $('.browse-resources-top').find('li').map(
                function() { return $(this).data('resource'); }
            ).get();

            var other = $('.browse-resources-other').find('li').map(
                function() { return $(this).data('resource'); }
            ).get();

            var subject = $('#browse').data('subject');

            $.ajax({
                type: 'POST',
                url: CRDB.URLs.rerank,
                dataType: 'json',
                traditional: true,
                data: {
                    subject: subject,
                    resource_order: top,
                    resource_other: other
                },
                success: function( data ) {
                    $('#browse .results').remove();
                    if ( data.success ) {
                        $('#browse').prepend( $('<div />').addClass('alert alert-success results').text(data.message) );
                    }
                    else {
                        $('#browse').prepend( $('<div />').addClass('alert alert-error results').text(data.message) );
                    }
                }
            });

            _super(item, container);
        }

    });

    $('.edit-browse-subject').on( 'click', function(event) {

        event.preventDefault();

        $.ajax({
            type: 'POST',
            url:  CRDB.URLs.subject_description,
            dataType: 'json',
            data: {
                subject_id: $('#browse').data('subject')
            },
            success: function(data) {

                var subject_description = data.subject_description ? data.subject_description.escape_html() : '';

                var content_field = $('#browse-brief-subject_description-content');
                $('#browse-brief-subject_description-edit').remove();
                var edit_field = $('<div />')
                    .attr('id', 'browse-brief-subject_description-edit')
                    .append( '<textarea id="browse-brief-subject_description-textarea" rows="5">' + subject_description + '</textarea><br />' )
                    .append( '<button class="btn" id="browse-brief-subject_description-submit">save</button> ' )
                    .append( '<button class="btn" id="browse-brief-subject_description-cancel">cancel</button>' )
                    .insertAfter(content_field);
                content_field.hide();

                $('#browse-brief-subject_description-textarea')[0].focus();

                $('#browse-brief-subject_description-submit').bind( 'click', function(event) {
                    event.preventDefault();
                    $.ajax({
                        type: 'POST',
                        url:  CRDB.URLs.subject_description,
                        dataType: 'json',
                        data: {
                            subject_id: $('#browse').data('subject'),
                            subject_description: $('#browse-brief-subject_description-textarea').val(),
                            change: 1
                        },
                        success: function( new_data ) {
                            $('#browse .results').remove();
                            if ( new_data.success ) {
                                content_field.empty().append( new_data.subject_description ? new_data.subject_description : 'No subject description.' ).show();
                                edit_field.hide().remove();
                                $('#browse').prepend( $('<div />').addClass('alert alert-success results').text(new_data.message) );
                            } else {
                                $('#browse').prepend( $('<div />').addClass('alert alert-error results').text(new_data.message) );
                            }
                        }
                    });
                });

                 /* Cancel button - empty the div tag and put back the regular description */

                $( '#browse-brief-subject_description-cancel' ).bind( 'click', function(event) {
                    event.preventDefault();
                    content_field.empty().append( data.subject_description ? data.subject_description : 'No subject description.' ).show();
                    edit_field.hide().remove();
                });

            }
        });

    });

    $('#resource-fields').on( 'click', 'a.edit-edit', function(event) {

        event.preventDefault();

        var control = $(this).parents('.resource-edit-control');
        var url     = control.data('url');
        var field   = control.data('field');

        $.ajax({
            type: 'GET',
            url: url,
            dataType: 'html',
            success: function( html ) {
                var resource_field = $('#resource-' + field + '-data');

                resource_field.find('.field-data').hide();
                resource_field.append(
                    $('<span />').addClass('field-editing').append(html)
                );

                resource_field.find('.resource-edit-control-savecancel').show();
                resource_field.find('.resource-edit-control-edit').hide();
           }
        });

    });

    $('#resource-fields').on( 'click', 'a.edit-cancel', function(event) {

        event.preventDefault();

        var control = $(this).parents('.resource-edit-control');
        var field   = control.data('field');

        var resource_field = $('#resource-' + field + '-data');

        resource_field.find('.field-editing').remove();
        resource_field.find('.field-data').show();

        resource_field.find('.resource-edit-control-savecancel').hide();
        resource_field.find('.resource-edit-control-edit').show();

    });

    $('#resource-fields').on( 'click', 'a.edit-save', function(event) {

        event.preventDefault();

        var control = $(this).parents('.resource-edit-control');
        var url     = control.data('url');
        var field   = control.data('field');

        var editfield = $('#resource-definition-' + field + ' .validate');
        if ( editfield.length == 1 ) {
            if ( !validate_field(editfield) ) {
                return;
            }
        }

        $.ajax({
           type: 'POST',
           url: url,
           data: control.parents('.resource-data').find('form').serialize(),
           success: function( html ) {

               var resource_label = $('#resource-' + field + '-label');
               var resource_data  = $('#resource-' + field + '-data');

               resource_label.before(html);

               resource_data.remove();
               resource_label.remove();

               hide_nodata_fields();

               $('#resource .results').remove();
               $('#resource').prepend( $('<div />').addClass('alert alert-success results').text('Updated field data.') );

           }
        });

    });


    $('#toggle-empty-fields').on( 'click', function(event) {
        event.preventDefault();
        toggle_nodata_fields();
    });

    hide_nodata_fields();

});


function toggle_nodata_fields() {
    CRDB.show_nodata_fields = !CRDB.show_nodata_fields;
    hide_nodata_fields();
}

function hide_nodata_fields() {
    jQuery('.no-data').each( function(i) {
        this.style.display = CRDB.show_nodata_fields ? 'block' : 'none';
    });
}

function validate_field(field) {
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