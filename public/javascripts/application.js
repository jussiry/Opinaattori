// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var op_clicked = false; // käytetään klikatessa uuden mielipiteen luonti tekstikenttää

$(function() {
	add_opinion_anims()
	
	// Round corners:
	DD_roundies.addRule('.round10', '10px', true);
	DD_roundies.addRule('.round15', '15px', true);
	DD_roundies.addRule('.round20', '20px', true);
	
	// expanding text areas - tää rikkoo koko filen toiminnan
	$('textarea.expanding').autogrow();
});

function add_opinion_anims() {
	
	// textalign center:
	$('.opinion_text').each(function() {
		$(this).css('width', $(this).parent().css('width')); 
	});	
	
	// corners:
	DD_roundies.addRule('.op_basic', '10px', true);
	DD_roundies.addRule('.op_more', '0 0 20px 20px', true);
	//DD_roundies.addRule('.opinion_bg', '10px', true);
	
	var anim_t = 140;
	$('.opinion_text_container').hover(function() {
		$(this).animate({opacity:1}, anim_t)
		//$('.opinion_bg', $(this).parent()).animate({opacity:1}, anim_t)
	}, function() {
		$(this).animate({opacity:0.7}, anim_t)
		//$('.opinion_bg', $(this).parent()).animate({opacity:0}, anim_t)
	});
	
	$('.opinion_creator').hover(function() {
		$(this).animate({opacity:1}, anim_t)
	}, function() {
		$(this).animate({opacity:0.8}, anim_t)
	});
	
	$('.transparent').hover(function() {
		$(this).animate({opacity:1}, anim_t)
	}, function() {
		$(this).animate({opacity:0.5}, anim_t)
	});
	
	// OP ACTIONS
	$('.os_given').click(function() {
		$(".no_os", $(this).parents(".op_actions")).fadeIn('slow');
		$(this).fadeOut('slow');
	});
	
	$('.button_positive a').click(function() {
		$op_actions = $(this).parents(".op_actions")
		$(".no_os", $op_actions).fadeOut('slow');
		$(".os_given img", $op_actions).attr('src', '/images/answer_v_big.gif')
		$(".os_given", $op_actions).fadeIn('slow');
	});
	$('.button_negative a').click(function() {
		$op_actions = $(this).parents(".op_actions")
		$(".no_os", $op_actions).fadeOut('slow');
		$(".os_given img", $op_actions).attr('src', '/images/answer_x_big.gif')
		$(".os_given", $op_actions).fadeIn('slow');
	});
	
	$('.remove a').click(function() {
		$opinion = $(this).parents(".opinion")
		//$opinion.unbind('mouseover').unbind('mouseout'); // tarpeeton, mutta pitäisi toimia
		$opinion.animate({ height:0, opacity:0 }, 600, 'linear', function(){$opinion.hide()} );
	});
}


function toggleOpinionMore(op_id) {
	//alert("plaa"+op_id)
	if ($('#op_more_'+op_id).css('display') == 'block') hideOpinion(op_id);
	else adjustOpinionHeight(op_id);
}

function preOpenOpinion(op_id) {
	if ($('#op_more_'+op_id).html() == "") 
		$('#op_more_'+op_id).css('height', 0).show().animate({height:282});
}

function adjustOpinionHeight(op_id) {
	$op_more = $('#op_more_'+op_id)
	var cur_height = $op_more.stop(true).height()
	var full_height = $op_more.css('height', '').height()
	$op_more.css('height', cur_height).animate({height:full_height}, 'normal', 'linear', function() {$op_more.css('height', '')})
	//if (cur_height != full_height) {
		//$('.op_more_content', $op_more).css('opacity', 0);
		$('.op_more_content', $op_more).animate({ opacity:1 });
	//}
}

function hideOpinion(op_id) {
	$op_more = $('#op_more_'+op_id)
	$op_more.animate({height:0}, 230, 'linear', function(){$op_more.hide()})
	$('.op_more_content', $op_more).animate({ opacity:0 })
}


function toggleTags() {
	var time = 500;
	if ($('#more_tags_link a').html() == '&gt;&gt;') {
		$('#more_tags_link a').html('&lt;&lt;').css('opacity', 0).animate({opacity:1}, time);
		$('#more_tags').css('display', '').css('opacity', 0).animate({opacity:1}, time);
	}
	else {
		$('#more_tags_link a').animate({opacity:0}, 400);
		$('#more_tags').animate({opacity:0}, 400, 'linear', function() {
			$(this).css('display', 'none');
			$('#more_tags_link a').html('&gt;&gt;').css('opacity', 1);
		});
	}
	//$('#more_tags_link a').html($('#more_tags').css('display')=='none'?'<<':'>>');$('#more_tags').toggle('slow');
}
/*
function toggleText(op_id) {
	short = document.getElementById("text_short_"+op_id);
	if (short == null) return;
	
	full = document.getElementById("text_full_"+op_id);
	if (short.style.display == "") {
	  	short.style.display = "none";
	  	full.style.display = "";
	  }
	else {
		short.style.display = "";
		full.style.display = "none";
	}
}*/


// NEW OPINION

function newOpinionLoaded() {
	// reset form:
	$('#new_op_ta').get(0).value='';
	$('#new_op_img').css('opacity', 1);
	$('#op_anonym_box').hide();
	$('#op_anonym_input')[0].checked = false;
	// show new opinion:
	$('#created_opinion div:first').hide().appear('slow');
	add_opinion_anims();
}



// ENDLESS PAGE
function checkScroll() {
  if (nearBottomOfPage()) {
	$.ajax({ url: '/main_page/insert_opinions', dataType: "script" })
    //new Ajax.Request('/main_page/insert_opinions', {asynchronous:true, evalScripts:true, method:'get'});
  } else {
    setTimeout("checkScroll()", 250);
  }
}
function nearBottomOfPage() {
  return scrollDistanceFromBottom() < 250;
}
function scrollDistanceFromBottom(argument) {
  return pageHeight() - ($(window).scrollTop() + $(window).height());
}
function pageHeight() {
  return Math.max(document.body.scrollHeight, document.body.offsetHeight);
}

// HELPER FUNCTION

function toggleOpacity($elm) {
	if ($elm.css('opacity') == 1) { $elm.animate({'opacity':0}, 500); }
	else { $elm.animate({'opacity':1}, 500); }
}