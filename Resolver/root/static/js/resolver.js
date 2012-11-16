function toggleOthers(layer_number) {
    var layer = '#others' + layer_number;
    $(layer).toggle();
    var showhide = '#showhide' + layer_number;
    var message = $(layer).is(':visible') ? '(hide other services)' : '(show other services)';
    $(showhide).html(message);
}
