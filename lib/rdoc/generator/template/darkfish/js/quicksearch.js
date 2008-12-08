/**
 * 
 * JQuery QuickSearch - Hook up a form field to hide non-matching elements.
 * $Id: quicksearch.js 38 2008-09-25 16:50:52Z deveiant $
 * 
 * Author: Michael Granger <mgranger@laika.com>
 * 
 */
jQuery.fn.quicksearch = function( target, searchElems, options ) {
	// console.debug( "Quicksearch fn" );

	var settings = {
		delay: 250,
		clearButton: false,
		highlightMatches: false,
		focusOnLoad: false,
		noSearchResultsIndicator: null
	};
	if ( options ) $.extend( settings, options );
	
	return jQuery(this).each( function() {
		// console.debug( "Creating a new quicksearch on %o for %o", this, searchElems );
		new jQuery.quicksearch( this, searchElems, settings );
	});
};


jQuery.quicksearch = function( searchBox, searchElems, settings ) {
	var timeout;
	var boxdiv = $(searchBox).parents('div').eq(0);

	function init() {
		setupKeyEventHandlers();
		focusOnLoad();
	};

	function setupKeyEventHandlers() {
		// console.debug( "Hooking up the 'keypress' event to %o", searchBox );
		$(searchBox).
			unbind( 'keyup' ).
			keyup( function(e) { return onSearchKey( e.keyCode ); });
		$(searchBox).
			unbind( 'keypress' ).
			keypress( function(e) {
				switch( e.which ) {
					// Execute the search on Enter, Tab, or Newline
					case 9:
					case 13:
					case 10:
						clearTimeout( timeout );
						e.preventDefault();
						doQuickSearch();
						break;

					// Allow backspace
					case 8:
						return true;
						break;
					
					// Only allow valid search characters
					default:
						return validQSChar( e.charCode );
				}
			});
	};

	function focusOnLoad() {
		if ( !settings.focusOnLoad ) return false;
		$(searchBox).focus();
	};

	function onSearchKey ( code ) {
		clearTimeout( timeout );
		// console.debug( "...scheduling search." );
		timeout = setTimeout( doQuickSearch, settings.delay );
	};

	function validQSChar( code ) {
		var c = String.fromCharCode( code );
		return (
			(c == ':') ||
			(c >= 'a' && c <= 'z') ||
			(c >= 'A' && c <= 'Z')
		  );
	};

	function doQuickSearch() {
		var searchText = searchBox.value;
		var pat = new RegExp( searchText, "im" );
		var shownCount = 0;
	
		if ( settings.noSearchResultsIndicator ) {
			$('#' + settings.noSearchResultsIndicator).hide();
		}

		// All elements start out hidden
		$(searchElems).each( function(index) {
			var str = $(this).text();
			
			if ( pat.test(str) ) {
				shownCount += 1;
				$(this).fadeIn();
			} else {
				$(this).hide();
			}
		});

		if ( shownCount == 0 && settings.noSearchResultsIndicator ) {
			$('#' + settings.noSearchResultsIndicator).slideDown();
		}
		

		var boxpos = $(boxdiv).offset();
		var boxHeight = $(boxdiv).height() - boxpos.top;
		var viewHeight = $(window).height();
		
		console.debug( "Boxpos: %o, boxHeight: %d, viewHeight: %d", boxpos, boxHeight, viewHeight );
		
		// Center the quicksearch's container div vertically if it can all fit
		if ( viewHeight > boxHeight ) {
			var y = Math.ceil(( viewHeight - boxHeight ) / 2);
			console.debug( "Center-scrolling strategy: %d", y );
			$(window).scrollTop( 0, y );
		}
		
		// Or else position the page such that the search field is at the bottom of the viewport.
		else {
			var y = boxpos.top + $(boxpos).height() - viewHeight;
			console.debug( "Bottom-aligned strategy: %d", y );
			$(window).scrollTop( 0, y );
		}
	};

	init();
};
