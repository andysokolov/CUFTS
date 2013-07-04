$().ready( function() {

  $('.a-to-z select').change( function() {
  	$(this).parent('form').submit();
  });

  $('select.goto-value').change( function() {
  	window.location = $(this).val();
  })

});