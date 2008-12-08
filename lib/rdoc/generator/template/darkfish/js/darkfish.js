/**
 * 
 * Darkfish Page Functions
 * $Id: darkfish.js 30 2008-08-20 01:28:01Z deveiant $
 * 
 * Author: Michael Granger <mgranger@laika.com>
 * 
 */

/* Provide console simulation for firebug-less environments */
if (!("console" in window) || !("firebug" in console)) {
    var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml",
    "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];

    window.console = {};
    for (var i = 0; i < names.length; ++i)
        window.console[names[i]] = function() {};
};


/**
 * Unwrap the first element that matches the given @expr@ from the targets and return them.
 */
$.fn.unwrap = function( expr ) {
  return this.each( function() {
     $(this).parents( expr ).eq( 0 ).after( this ).remove();
  });
};


function showSource( e ) {
	var target = e.target;
	var codeSections = $(target).
		parents('.method-detail').
		find('.method-source-code');

	$(target).
		parents('.method-detail').
		find('.method-source-code').
		slideToggle();
};

function hookSourceViews() {
	$('.method-description,.method-heading').click( showSource );
};

function hookQuickSearch() {
	$('.quicksearch-field').each( function() {
		var searchElems = $(this).parents('.section').find( 'li' );
		$(this).quicksearch( this, searchElems, {
			noSearchResultsIndicator: 'no-class-search-results',
			focusOnLoad: false
		});
	});
};

function highlightTarget( anchor ) {
	console.debug( "Highlighting target '%s'.", anchor );

	$("a[name=" + anchor + "]").each( function() {
		if ( !$(this).parent().parent().hasClass('target-section') ) {
			console.debug( "Wrapping the target-section" );
			$('div.method-detail').unwrap( 'div.target-section' );
			$(this).parent().wrap( '<div class="target-section"></div>' );
		} else {
			console.debug( "Already wrapped." );
		}
	});
};

function highlightLocationTarget() {
	console.debug( "Location hash: %s", window.location.hash );
	if ( ! window.location.hash || window.location.hash.length == 0 ) return;
	
	var anchor = window.location.hash.substring(1);
	console.debug( "Found anchor: %s; matching %s", anchor, "a[name=" + anchor + "]" );

	highlightTarget( anchor );
};

function highlightClickTarget( event ) {
	console.debug( "Highlighting click target for event %o", event.target );
	try {
		var anchor = $(event.target).attr( 'href' ).substring(1);
		console.debug( "Found target anchor: %s", anchor );
		highlightTarget( anchor );
	} catch ( err ) {
		console.error( "Exception while highlighting: %o", err );
	};
};

