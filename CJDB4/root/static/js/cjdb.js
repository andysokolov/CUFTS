jQuery(document).ready( function($) {

  $('.a-to-z select').change( function() {
  	$(this).parent('form').submit();
  });

  $('select.goto-value').change( function() {
  	window.location = $(this).val();
  })

  $('#browse-issn-input').typeahead({
    minLength: 3,
    source: function (q, process) {
        return $.get(URLs.data.ISSN, { q: q, rows: 8 }, function(data) {
            return process(data.results);
        });
    }
  });

  $('#browse-tag-input').typeahead({
    minLength: 3,
    source: function (q, process) {
        return $.get(URLs.data.tag, { q: q, rows: 8 }, function(data) {
            return process(data.results);
        });
    }
  });

  /* Toggle blocks in the LCC browse hierarchy */

  $('#lcc-browse a.lcc-browse-trigger').on('click', function(event) {
    $(this).find('.trigger-content').toggle();
    $( '#group-' + $(this).attr('data-group') ).toggle();
    return false;
  });


  /* Display "My Tags" on a journal page if someone is logged in */

  $('#journal-account-tag-management-trigger').on('click', function(event) {
    $('#journal-account-tags-existing').hide();
    $('#journal-account-tag-management').toggle();
    return false;
  });

});