$().ready( function() {

  $('.a-to-z select').change( function() {
  	$(this).parent('form').submit();
  });

  $('select.goto-value').change( function() {
  	window.location = $(this).val();
  })

  $('#browse-issn-input').typeahead({
    minLength: 3,
    source: function (q, process) {
        return $.get(URLs.data.ISSN, { q: q, rows: 8 }, function (data) {
            return process(data.results);
        });
    }
});

  $('#browse-tag-input').typeahead({
    minLength: 3,
    source: function (q, process) {
        return $.get(URLs.data.tag, { q: q, rows: 8 }, function (data) {
            return process(data.results);
        });
    }
});


});