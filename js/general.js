// Some of the following variables can be changed depending on the specs you use
var speed = 1200; // speed of the sliding animation
var ext = ".html"; // file extension for the ajax files
var pages = "";
var urlString = "";
var downArrow = "  <span style='color:black'>&#9660;</span>"; // this is the downward-pointing arrow next to each menu link
var upArrow = "  <span style='color:red'>&#9650;</span>"; // ditto for up, when the menu item is selected
var dir = "dropdowns"; // this is the name of the directory that holds your ajax files; if files are in root, just make this blank



$j(document).ready(function(){

	var navLinks = $j("li.menu>a");
	var navLinksActiveSpan = $j("li.menu>a.active span");
	var dropDown = $j("#dropdown");
	// the loop below creates the string of classes each named after a menu's ajax page
	// these classes are used to identify which menu is currenly open
	for (var i = 0, j = navLinks.length; i < j; i++) {
		urlString = navLinks[i].href.split("/");
		urlString = urlString[urlString.length-1].replace(ext, "");
		pages = pages + " " + urlString;
	}
	var currHash = document.location.hash.replace("#","");
	var removeLoading = function() {
		dropDown.removeClass("loading"); // remove the "loading" graphic
	};
	var addLoading = function() {
		dropDown.addClass("loading"); // add the "loading" graphic
	};
	// the "close" link is injected with JS; we don't want non-JS users to see it anyhow
	var closeLinkString = "<div class='close'><a href='#' id='close-link' onclick='closeDropDown(); return false;'>close [x]</a></div>";
	var addCloseLink = function() {
		dropDown.append(closeLinkString);
	};

	navLinks.append(downArrow); // the down-pointing arrows are appended to each link with JS; they shouldn't appear to non-JS users
	
	// open the appropriate drop-down menu if a hash is present in the URL
	if (currHash) {
		dropDown.slideDown(speed, function() {
			// callback after slideDown is complete
			for (var i = 0, j = navLinks.length; i < j; i++) {
				if (navLinks[i].href.toString().indexOf(currHash) != -1) {
					navLinks[i].className = "active";
					dropDown.addClass("open " + currHash);
				}
			}
			// a timestamp is appended to the ajax-loaded file, to ensure no caching; you can remove this if you don't mind the files cached
			dropDown.load(dir+"/"+currHash.replace("#","")+ext+"?"+new Date().getTime(), function() {
				// callback after ajax call is complete
				navLinksActiveSpan.html(upArrow);
				addCloseLink();
				removeLoading();
			});
		});
	}
	
	// this is the click handler that decides the primary open/close actions
	navLinks.click(function(){
	
		var ajaxPage = this.href.split("/");
		ajaxPage = ajaxPage[ajaxPage.length-1];

		var ajaxPageName = ajaxPage.split(".")[0];
		
		// drop-down is already opened
		if (dropDown.hasClass("open")) {
			
			// it's open, and the clicked menu item is the same as the open drop-down
			// so it closes
			if (dropDown.hasClass(ajaxPageName)){
				dropDown.removeClass("open");
				$j(this).removeClass("active");
				dropDown.removeClass(pages);
				dropDown.slideUp(speed, function() {
					// callback after slideUp is complete
					$j(navLinks).find("span").html(downArrow);
					addLoading();
				});

			// if it's open, and the clicked item is different, keep it open
			// then load the new content
			} else {
				navLinks.find("span").html(downArrow);
				navLinks.removeClass("active");
				dropDown.removeClass(pages);
				dropDown.addClass(ajaxPage.split(".")[0]);
				dropDown.html("");
				dropDown.load(dir+"/"+ajaxPage+"?"+new Date().getTime(), function() {
					// callback after ajax call is complete
					addCloseLink();
					removeLoading();										   
				});
				$j(this).addClass("active");
				$j(this).find("span").html(upArrow);
			}

		// drop-down is not already opened; add the right classes, open it, and load the content
		} else {

			dropDown.addClass("open");
			dropDown.removeClass(pages);
			dropDown.addClass(ajaxPage.split(".")[0]);
			$j(this).addClass("active");
			dropDown.html("");
			dropDown.slideDown(speed, function() { 
				dropDown.load(dir+"/"+ajaxPage+"?"+new Date().getTime(), function() {
					// callback after ajax call is complete
					$j("li.menu>a.active span").html(upArrow);
					addCloseLink();
					removeLoading();
				});
			});
		}
		
		document.location.hash = ajaxPageName; // change the hash for deep linking
		return false;

	});
	
});

// this is a separate function that runs when the close button is clicked
// If anyone has a more efficient way to do this, I'm all ears
function closeDropDown(){
	$j("#dropdown").slideUp(speed, function() {
		$j("li.menu>a").find("span").html(" <span style='color:black'>&#9660;</span>");
		$j("li.menu>a").removeClass();
		$j("#dropdown").removeClass();
		document.location.hash = "";
		$j("#dropdown").addClass("loading");
	});
}