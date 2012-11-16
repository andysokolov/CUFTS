function clear_field (field_index, field_type, form_name) {
	if (!confirm("Clear field?")) {
		return false;
	}

	var search_string = field_index + '-' + field_type;

	var i;
	for (i = 0; i < document.forms[form_name].elements.length; i++) {
		var name = document.forms[form_name].elements[i].name;
		if (name.indexOf(search_string) == 0 && name.indexOf('exists') == -1) {
			document.forms[form_name].elements[i].value='';
		}
	}			

	return false;
}


function show_edit_line (field_type) {
    var row    = window['field_max'][field_type] + 1;
    var div_id = 'new' + row + '_' + field_type;
	var div    = document.getElementById(div_id);
	
	if (! div) {
	    alert('Unable to show new ' + field_type + ' field.  Please save this record and try editting again.');
	    return false;
	}
	
	div.style.display = '';

	window['field_max'][field_type] = row;

	return false;
}

function show_marc_line (field_type) {
    var row    = window['marc_field_max'][field_type] + 1;
    var div_id = row + '-' + field_type;
	var div    = document.getElementById(div_id);

	if (! div) {
	    alert('Unable to show new ' + field_type + ' field.  Please save this record and try editting again.');
	    return false;
	}
	
	div.style.display = '';

	window['marc_field_max'][field_type] = row;

	return false;
}


