// JavaScript Document
var justCrossSections = false;
var useTemp = false;
var useOpticalDepth = false;
var useSolarActivity = true;
var useAxesScaling = false;
var useXAxisUnit = false;

function processLink (value) {
    justCrossSections = false;
		if(value=="home") {
				document.getElementById('home').className='main_tabs_link_div_sel';
				document.getElementById('photo').className='main_tabs_link_div';
				document.getElementById('blackbody').className='main_tabs_link_div';
				document.getElementById('interstellar').className='main_tabs_link_div';
				document.getElementById('solar').className='main_tabs_link_div';
				new Ajax.Updater('main_body', './home.html', {evalScripts:true});
		}
    else if (value == "photo") {
        useXAxisUnit = true;
        justCrossSections = true;
				document.getElementById('photo').className='main_tabs_link_div_sel';
				document.getElementById('home').className='main_tabs_link_div';
				document.getElementById('blackbody').className='main_tabs_link_div';
				document.getElementById('interstellar').className='main_tabs_link_div';
				document.getElementById('solar').className='main_tabs_link_div';
				new Ajax.Updater('main_body', './molecule.html', {evalScripts:true});
    } else if (value == "blackbody") {
               useTemp = true;
               useOpticalDepth = true;
               useSolarActivity = false;
               useAxesScaling = true;
								document.getElementById('blackbody').className='main_tabs_link_div_sel';
								document.getElementById('home').className='main_tabs_link_div';
								document.getElementById('photo').className='main_tabs_link_div';
								document.getElementById('interstellar').className='main_tabs_link_div';
								document.getElementById('solar').className='main_tabs_link_div';
								new Ajax.Updater('main_body', './molecule.html', {evalScripts:true});
    } else if (value == "interstellar") {
               useTemp = false;
               useOpticalDepth = true;
               useSolarActivity = false;
               useAxesScaling = true;
								document.getElementById('interstellar').className='main_tabs_link_div_sel';
								document.getElementById('home').className='main_tabs_link_div';
								document.getElementById('photo').className='main_tabs_link_div';
								document.getElementById('blackbody').className='main_tabs_link_div';
								document.getElementById('solar').className='main_tabs_link_div';
								new Ajax.Updater('main_body', './molecule.html', {evalScripts:true});
    } else if (value == "solar") {
               useTemp = false;
               useOpticalDepth = true;
               useSolarActivity = true;
               useAxesScaling = true;
								document.getElementById('solar').className='main_tabs_link_div_sel';
								document.getElementById('home').className='main_tabs_link_div';
								document.getElementById('photo').className='main_tabs_link_div';
								document.getElementById('blackbody').className='main_tabs_link_div';
								document.getElementById('interstellar').className='main_tabs_link_div';
								new Ajax.Updater('main_body', './molecule.html', {evalScripts:true});
    }
    //parent.right_frame.location = "molecule.html";
}

function homeSideMenuSelected(divName)
{
	if(divName == 'side_menu_info_div')
	{
		document.getElementById('side_menu_info_div').className='home_side_menu_button_sel';
		document.getElementById('side_menu_contact_div').className='home_side_menu_button';
		document.getElementById('side_menu_questionnaire_div').className='home_side_menu_button';
		new Ajax.Updater('home_main_content', './home_info.html', {evalScripts:true});
	}
	else if(divName == 'side_menu_contact_div')
	{
		document.getElementById('side_menu_contact_div').className='home_side_menu_button_sel';
		document.getElementById('side_menu_info_div').className='home_side_menu_button';
		document.getElementById('side_menu_questionnaire_div').className='home_side_menu_button';
		new Ajax.Updater('home_main_content', './contacts.html', {evalScripts:true});
	}
	else if(divName == 'side_menu_questionnaire_div')
	{
		document.getElementById('side_menu_questionnaire_div').className='home_side_menu_button_sel';
		document.getElementById('side_menu_info_div').className='home_side_menu_button';
		document.getElementById('side_menu_contact_div').className='home_side_menu_button';
		new Ajax.Updater('home_main_content', './questionnaire.html', {evalScripts:true});
	}
}
function runMolecule (value) {
    if (testNumbers () != 0) return;

    var URL = 'http://elmer.space.swri.edu/~joey/amop/data_files/';
    var programToUse;
    //var useSolarActivity = parent.left_frame.useSolarActivity;
    //var justCrossSections = parent.left_frame.justCrossSections;
    var use_electron_volts;
    var solar_activity;
    var use_semi_log;

    if (justCrossSections == true) {
        use_electron_volts = document.options.x_axis_unit[1].checked;
        var cross_sections = URL
            + 'cross_sections.cgi'
            + '?molecule=' + value
            + '?use_electron_volts=' + use_electron_volts 
            + '?use_semi_log=false' 
            + '?solar_activity=0.0';
        cross_sections_window = window.open (cross_sections, "cross_sections",
           "menubar=yes,resizable=yes,scrollbars=yes,width=600,height=500");
    } else {
        use_electron_volts = false;
        use_semi_log = document.options.axes_scaling[1].checked;
        if (useSolarActivity == true) {
            solar_activity = document.options.solar_activity.value;
        }

        var rate_numbers = URL
            + 'just_fotout.cgi'
            + '?molecule=' + value
            + '?use_electron_volts=' + use_electron_volts 
            + '?use_semi_log=' + use_semi_log
            + '?solar_activity=' + solar_activity;
        rate_numbers_window = window.open (rate_numbers, "rate_numbers",
            "menubar=yes,resizable=yes,scrollbars=yes,width=600,height=500");
        if (document.options.plots_desired[0].checked == true) {
            var solar_spectrum = URL
                + 'gp_spectrum.cgi'
                + '?use_semi_log=' + use_semi_log
                + '?solar_activity=' + solar_activity;
            solar_spectrum = window.open (solar_spectrum, "solar_spectrum",
                "menubar=yes,resizable=yes,scrollbars=yes,width=600,height=500");
        } 
        if (document.options.plots_desired[1].checked == true) {
            var cross_sections = URL
                + 'binned_cross_sections.cgi'
                + '?molecule=' + value
                + '?use_electron_volts=' + use_electron_volts 
                + '?use_semi_log=' + use_semi_log
                + '?solar_activity=' + solar_activity;

            cross_sections_window = window.open (cross_sections, "cross_sections",
                "menubar=yes,resizable=yes,scrollbars=yes,width=600,height=500");
        } 
        if (document.options.plots_desired[2].checked == true) {
            var rate_coeff = URL
                + 'binned_rate_coeff.cgi'
                + '?molecule=' + value
                + '?use_electron_volts=' + use_electron_volts 
                + '?use_semi_log=' + use_semi_log
                + '?solar_activity=' + solar_activity;

            rate_coeff_window = window.open (rate_coeff, "rate_coeff",
                "menubar=yes,resizable=yes,scrollbars=yes,width=600,height=500");
        } 
        if (document.options.plots_desired[3].checked == true) {
            var excess_energies = URL
                + 'excess_energies.cgi'
                + '?molecule=' + value
                + '?use_electron_volts=' + use_electron_volts 
                + '?use_semi_log=' + use_semi_log
                + '?solar_activity=' + solar_activity;

            excess_energies_window = window.open (excess_energies, "excess_energies",
                "menubar=yes,resizable=yes,scrollbars=yes,width=600,height=500");
        } 
    }
}

function testNumbers () {

    /*var justCrossSections = parent.left_frame.justCrossSections;
    var useTemp = parent.left_frame.useTemp;
    var useOpticalDepth = parent.left_frame.useOpticalDepth;
    var useSolarActivity = parent.left_frame.useSolarActivity;
    var useAxesScaling = parent.left_frame.useAxesScaling;*/

    if (justCrossSections == false) {
        if (useTemp == true) {
            var temp = document.options.temp;
        }
        if (useSolarActivity == true) {
            var solar_activity = document.options.solar_activity.value;
            if ((isNumberString (solar_activity) == false) || 
                (isBetweenXY (solar_activity, 0, 1) == false)) {
                alert ("Number between 0 and 1 is required for solar activity!")
                Ctrl.focus ();
                return (-1);
            }
            if (isBetweenXY (solar_activity, 0, 1) == false) {
                alert ("Number between 0 and 1 is required for solar activity!")
                Ctrl.focus ();
                return (-1);
            }
        }
        if (useOpticalDepth == true) {
            var optical_depth = document.options.optical_depth.value;
            if (isBetweenXY (optical_depth, 0, 1) == false) {
                alert ("Number between 0 and 1 is required for optical depth!")
                Ctrl.focus ();
                return (-1);
            }
        }
    }
    return (0);
}

function isBetweenXY (value, lower, upper) {
    if (value < lower) return false;
    if (value > upper) return false;
    return true;
}

function isNumberString (InString) {
    if (InString.length == 0) return false;
    var RefString = "1234567890.";
    for (Count = 0; Count < InString.length; Count++) {
        TempChar = InString.substring (Count, Count+1);
        if (RefString.indexOf (TempChar, 0) == -1)
            return (false);
    }
    return (true);
}
