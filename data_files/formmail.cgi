#!/usr/bin/perl
######################
# General Mail Form To Work With Any Fields
# Created 6/9/95                Last Modified 6/11/95
# Version 1.0
# http://clever.net/cgi-bin/formmail.cgi?http://mydomain.com/mypage.html
# Define Variables
$mailprog = '/usr/lib/sendmail';
$date = `date`; chop ($date);

$recipient = "joey\@swri.edu";
$subject = "Questionnaire answers!";

######################
# Necessary Fields in HTML Form:   (Read the README file for more info)
# recipient = specifies who mail is sent to
# username = specifies the remote users email address for replies
# realname = specifies the remote users real identity
# subject = specifies what you want the subject of your mail to be

# Print the Initial Output Heading
print "Location: ";
print  $ENV{'QUERY_STRING'};
print "\n\n";

# Get the input
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

# Split the name-value pairs
@pairs = split(/&/, $buffer);

foreach $pair (@pairs)
{
    ($name, $value) = split(/=/, $pair);
  
    # Un-Webify plus signs and %-encoding

    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $name =~ tr/+/ /;
    $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
            
    # Stop people from using subshells to execute commands
    # Not a big deal when using sendmail, but very important
    # when using UCB mail (aka mailx).
    # $value =~ s/~!/ ~!/g;
                    
    # Uncomment for debugging purposes
    print "Setting $name to $value<P>";
                        
    $FORM{$name} = $value;
}
                            
# Print Return HTML
print "<html><head><title>Thanks You</title></head>\n";
print "<body><h1>Thank You For Filling Out This Form</h1>\n";
print "Thank you for taking the time to fill out our feedback form.";
print $ENV{'QUERY_STRING'};
                            
# Open The Mail
open (MAIL, "|$mailprog $recipient") || die "Can't open $mailprog!\n";
print MAIL "From: $FORM{'username'} ($FORM{'realname'})\n";
print MAIL "Reply-To: $FORM{'username'} ($FORM{'realname'})\n";
print MAIL "To: $recipient\n";
print MAIL "Subject: $subject\n\n";
print MAIL "Below is the result of your feedback form.  It was submitted by $FORM{'realname'} $FORM{'username'} on $date\n";
print MAIL "--------------------------------------------------------------\n";
foreach $pair (@pairs)
{
    ($name, $value) = split(/=/, $pair);

    # Un-Webify plus signs and %-encoding
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $name =~ tr/+/ /;
    $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

    # Stop people from using subshells to execute commands
    # Not a big deal when using sendmail, but very important
    # when using UCB mail (aka mailx).
    # $value =~ s/~!/ ~!/g;
    # Uncomment for debugging purposes
    # print "Setting $name to $value<P>";
    $FORM{$name} = $value;
    # Print the MAIL for each name value pair
    print MAIL "$name:  $value\n";
    print MAIL "____________________________________________\n\n";
                                                           
    # Print the Return HTML for each name value pair.
    #  print "$name = $value<hr>\n";
}
close (MAIL);
print "</body></html>";
