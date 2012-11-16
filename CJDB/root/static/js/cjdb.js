function createCookie(name,value,days)
{
	if (days)
	{
		var date = new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires = "; expires="+date.toGMTString();
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name)
{
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++)
	{
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name)
{
	createCookie(name,"",-1);
}

function imageSwap(image, image1, image2) {
	var currentSrc = document[image].src;
	imgregex = new RegExp(image1 + '$')	

	if (currentSrc.match(imgregex) == image1) {
		document[image].src = image2;
	} else {
		document[image].src = image1;
	}

	return false;
}


function showDiv(show, hide, field, displayStyle) {

    var show_obj;
    if (show) {
        show_obj = $(show);
	    if (!show_obj) return true;
    }

    var hide_obj;
    if (hide) {
        hide_obj = $(hide);
	    if (!hide_obj) return true;
    }

    var field_obj;
    if (field) {
        field_obj = $(field);
	    if (!field_obj) return true;
    }

    Element.hide(hide);
    show_obj.style.display = displayStyle || 'block';
    if (field_obj) {
        field_obj.focus();
    }

    return false;
}


function showTagManageDivs() {
	var sd1 = showDiv('manage-tags','show-manage-tags');
	var sd2 = showDiv(undefined, 'my-tags-group');

	// Why Javascript wont let me && the above two calls directly is beyond me.

	return(sd1 && sd2);
}



function simpleHideClick(contentlayer, hiddenclass, visibleclass, imagelayer, hiddenimage, visibleimage) {
	classSwap(contentlayer, hiddenclass, visibleclass);

	if (imagelayer && hiddenimage && visibleimage) {
		imageSwap(imagelayer, hiddenimage, visibleimage);
	}

	return false;
}


function classSwap(layer, class1, class2) {
	if (document.layers) {   // NS4x?
		if (document.layers[layer]) {
			if (document.layers[layer].className == class1) {
				document.layers[layer].className = class2;
			} else {
				document.layers[layer].className = class1;
			}
		}
	} else if (document.all) {   // IE
		if (document.all[layer]) {
			if (document.all[layer].className == class1) {
				document.all[layer].className = class2;
			} else {
				document.all[layer].className = class1;
			}
		}
	} else if (document.getElementById) {  // Mozilla, Safari, etc.
		if (document.getElementById(layer)) {
			if (document.getElementById(layer).className == class1) {
				document.getElementById(layer).className = class2;
			} else {
				document.getElementById(layer).className = class1;
			}
		} 
	}

	return false;
}


function changeBrowseAlt(activate) {
   var actions = new Array('title', 'subject', 'association', 'tag', 'issn');
   
   // Switch active tab
   
   actions.each( function(action) {
       Element.removeClassName("tab-" + action, 'current');
   });
   
   Element.addClassName("tab-" + activate, 'current');

   // Switch active div

   actions.each( function(action) {
      Element.hide("search-" + action);
   });
   
   Element.show("search-" + activate);
  
   // Set focus and select any existing text  
   
   var fields = Form.getInputs("form-" + activate, "text", "search_terms");
   Field.activate(fields[0]);

   createCookie('cjdb_activate_tab', activate);
   
   return false;
}

function rememberTab() {
    activate = readCookie('cjdb_activate_tab');
    if (activate) {
        changeBrowseAlt(activate);
    }
}