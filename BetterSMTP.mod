############################################################## 
## MOD Title: BetterSMTP
## MOD Author: Christian Lagerkvist; christian.lagerkvist@gmail.com
## MOD Description: Bridges phpBB to Squirrelmail's nice SMTP functions. No more send mail problems. (Theoretically.)
## MOD Version: 0.9.3; created for phpBB 2.0.18
## 
## Installation Level: Easy
## Installation Time: ~10 Minutes 
## Files To Edit: 
##		  admin/admin_board.php
##		  templates/subSilver/admin/board_config_body.tpl
##		  language/lang_english/lang_admin.php
##		  includes/emailer.php
## Included Files:
##		  includes/smtp_squirrelmail/class/deliver/Deliver_SMTP.class.php
##		  includes/smtp_squirrelmail/class/deliver/Deliver.class.php
##		  includes/smtp_squirrelmail/class/mime/AddressStructure.class.php
##		  includes/smtp_squirrelmail/class/mime/ContentType.class.php
##		  includes/smtp_squirrelmail/class/mime/Message.class.php
##		  includes/smtp_squirrelmail/class/mime/Rfc822Header.class.php
##		  includes/smtp_squirrelmail/functions/auth.php
##		  includes/smtp_squirrelmail/functions/date.php
##		  includes/smtp_squirrelmail/smtp_squirrelmail.php
############################################################## 
## License: http://opensource.org/licenses/gpl-license.php GNU General Public License v2
############################################################## 
## For security purposes, please check: http://www.phpbb.com/mods/ 
## for the latest version of this MOD. Although MODs are checked 
## before being allowed in the MODs Database there is no guarantee 
## that there are no security problems within the MOD. No support 
## will be given for MODs not found within the MODs Database which 
## can be found at http://www.phpbb.com/mods/
############################################################## 
## Author Notes: 
##
## Goal was to be able to use the squirrelmail files _unaltered_. Two major reasons were:
##		1) You would be able to use the squirrelmail files of your existing squirrelmail installation
## 		instead of having duplicates.
## 	2) You would easily be able to update the squirrelmail files as new versions come out.
## 	
## 	HOWEVER, in order to support systems not allowing global variables, this is not the case.
## 	(Back in the days, globals were not considered a bad thing.)
## 	So, if you're downloading and installing the squirrelmail files manually, you need to:
## 	a) alter Deliver_SMTP.class.php, namely changing the line saying:
## 		function initStream($message, $domain, $length=0, $host='', $port='', $user='', $pass='', $authpop=false) {
## 	    global $use_smtp_tls,$smtp_auth_mech;
## 	into:
## 		function initStream($message, $domain, $length=0, $host='', $port='', $user='', $pass='', $authpop=false, $use_smtp_tls, $smtp_auth_mech) {
## 	b) repaste the helper functions extracted from squirrelmail, found in smtp_squirrelmail.php:
## 		* check_php_version
## 		* sqgetGlobalVar
## 	That's it.
##
##		Also, if your php installation uses gettext, you might want to remove the _()-function in smtp_squirrelmail.php
## 	
## 	Many thanks to stekkel (#squirrelmail), the author of the squirrelmail smtp portion.
## 
############################################################## 
## MOD History: 
## 0.9.1 versioning start
## 0.9.3 Usability - don't offer secure auth yes box if !extension_loaded("openssl")
##		   Additionally a couple of help links on auth and tsl.
############################################################## 
## Before Adding This MOD To Your Forum, You Should Back Up All Files Related To This MOD 
############################################################## 

# 
#-----[ SQL ]------------------------------------------ 
# 

INSERT INTO phpbb_config( config_name, config_value ) VALUES ( 'smtp_port', '25' );
INSERT INTO phpbb_config( config_name, config_value ) VALUES ( 'smtp_auth_mech', 'none' );
INSERT INTO phpbb_config( config_name, config_value ) VALUES ( 'use_smtp_tls', '0' );

#
#-----[ COPY ]------------------------------------------
#
copy includes/smtp_squirrelmail/class/deliver/Deliver_SMTP.class.php to includes/smtp_squirrelmail/class/deliver/Deliver_SMTP.class.php
copy includes/smtp_squirrelmail/class/deliver/Deliver.class.php to includes/smtp_squirrelmail/class/deliver/Deliver.class.php
copy includes/smtp_squirrelmail/class/mime/AddressStructure.class.php to includes/smtp_squirrelmail/class/mime/AddressStructure.class.php
copy includes/smtp_squirrelmail/class/mime/ContentType.class.php to includes/smtp_squirrelmail/class/mime/ContentType.class.php
copy includes/smtp_squirrelmail/class/mime/Message.class.php to includes/smtp_squirrelmail/class/mime/Message.class.php
copy includes/smtp_squirrelmail/class/mime/Rfc822Header.class.php to includes/smtp_squirrelmail/class/mime/Rfc822Header.class.php
copy includes/smtp_squirrelmail/functions/auth.php to includes/smtp_squirrelmail/functions/auth.php
copy includes/smtp_squirrelmail/functions/date.php to includes/smtp_squirrelmail/functions/date.php
copy includes/smtp_squirrelmail/smtp_squirrelmail.php to includes/smtp_squirrelmail/smtp_squirrelmail.php


# 
#-----[ OPEN ]------------------------------------------ 
# 

admin/admin_board.php

# 
#-----[ FIND ]------------------------------------------ 
# 

$timezone_select = tz_select($new['board_timezone'], 'board_timezone');

# 
#-----[ AFTER, ADD ]------------------------------------------ 
# 

$smtp_auth_mech_select = smtp_auth_mech_select($new['smtp_auth_mech']);

# 
#-----[ FIND ]------------------------------------------ 
# 

"SMTP_HOST" => $new['smtp_host'],

# 
#-----[ AFTER, ADD ]------------------------------------------ 
# 

"SMTP_PORT" => $new['smtp_port'],
"SMTP_AUTH_MECH_SELECT" => $smtp_auth_mech_select,
"S_USE_SMTP_TLS_YES" => $use_smtp_tls_yes,
"S_USE_SMTP_TLS_NO" => $use_smtp_tls_no,


# 
#-----[ FIND ]------------------------------------------ 
# 

"L_SMTP_PASSWORD_EXPLAIN" => $lang['SMTP_password_explain'], 

# 
#-----[ AFTER, ADD ]------------------------------------------ 
# 

"L_SMTP_PORT" => $lang['SMTP_port'],
"L_SMTP_AUTH_MECH" => $lang['SMTP_auth_mech'],
"L_SMTP_AUTH_MECH_EXPLAIN" => $lang['SMTP_auth_mech_explain'],
"L_USE_SMTP_TLS" => $lang['use_smtp_tls'],
"L_USE_SMTP_TLS_EXPLAIN" => $use_smtp_tls_error,

# 
#-----[ FIND ]------------------------------------------ 
# 

$smtp_no = ( !$new['smtp_delivery'] ) ? "checked=\"checked\"" : "";

# 
#-----[ AFTER, ADD ]------------------------------------------ 
# 

$has_openssl = extension_loaded("openssl");
if ($new['use_smtp_tls']) {
    $use_smtp_tls_yes = "checked=\"checked\"";
} else {
    if ($has_openssl) {
        $use_smtp_tls_yes = "";
    } else {
        $use_smtp_tls_yes = "disabled";
        $use_smtp_tls_error = $lang['use_smtp_tls_error'];
    }
}
$use_smtp_tls_no = ( !$new['use_smtp_tls'] ) ? "checked=\"checked\"" : "";


# 
#-----[ OPEN ]------------------------------------------ 
# 

templates/subSilver/admin/board_config_body.tpl

# 
#-----[ FIND ]------------------------------------------ 
# 

<tr>
	<td class="row1">{L_SMTP_SERVER}</td>
	<td class="row2"><input class="post" type="text" name="smtp_host" value="{SMTP_HOST}" size="25" maxlength="50" /></td>
</tr>


# 
#-----[ AFTER, ADD ]------------------------------------------ 
# 

<tr>
	<td class="row1">{L_SMTP_PORT}</td>
	<td class="row2"><input class="post" type="text" name="smtp_port" value="{SMTP_PORT}" size="5" maxlength="5" /></td>
</tr>

# 
#-----[ FIND ]------------------------------------------ 
# 

<tr>
	<td class="row1">{L_SMTP_PASSWORD}<br /><span class="gensmall">{L_SMTP_PASSWORD_EXPLAIN}</span></td>
	<td class="row2"><input class="post" type="password" name="smtp_password" value="{SMTP_PASSWORD}" size="25" maxlength="255" /></td>
</tr>



# 
#-----[ AFTER, ADD ]------------------------------------------ 
# 

<tr>
	<td class="row1">{L_SMTP_AUTH_MECH}<br /><span class="gensmall">{L_SMTP_AUTH_MECH_EXPLAIN}</span></td>
	<td class="row2">{SMTP_AUTH_MECH_SELECT}</td>
</tr>
<tr>
	<td class="row1">{L_USE_SMTP_TLS}<br /><span class="gensmall">{L_USE_SMTP_TLS_EXPLAIN}</span></td>
	<td class="row2"><input type="radio" name="use_smtp_tls" value="1" {S_USE_SMTP_TLS_YES}/> {L_YES}&nbsp;&nbsp;<input type="radio" name="use_smtp_tls" value="0" {S_USE_SMTP_TLS_NO}/> {L_NO}</td>
</tr>

	
# 
#-----[ OPEN ]------------------------------------------ 
# 

language/lang_english/lang_admin.php

# 
#-----[ FIND ]------------------------------------------ 
# 

?>

# 
#-----[ BEFORE, ADD ]------------------------------------------ 
# 

// BetterSMTP (Squirrelmail) Stuff:
$lang['SMTP_port'] = 'SMTP Server Port';
$lang['SMTP_auth_mech'] = 'Authentication Method&nbsp;&nbsp;[&nbsp;<a href="http://www.bytewize.com/linux/BetterSMTPhelp.php#auth" target="_blank">help</a>&nbsp;]';
$lang['SMTP_auth_mech_explain'] = '&quot;none&quot; and &quot;login&quot; are the options originally supported by phpBB';
$lang['use_smtp_tls'] = 'Server uses Secure Authentication (SSL/TLS)&nbsp;&nbsp;[&nbsp;<a href="http://www.bytewize.com/linux/BetterSMTPhelp.php#tls" target="_blank">help</a>&nbsp;]';
$lang['use_smtp_tls_error'] = '<b>WARNING: This PHP engine cannot use secure authentication!</b><br />Make sure you\'re running PHP version >= 4.3.0 with <a href="http://www.php.net/openssl" target="_blank">openssl</a> enabled.';

# 
#-----[ OPEN ]------------------------------------------ 
# 

includes/functions_selects.php

# 
#-----[ FIND ]------------------------------------------ 
# 

?>

# 
#-----[ BEFORE, ADD ]------------------------------------------ 
# 

//
// Select smtp_auth_mech
//
function smtp_auth_mech_select($value) {
    # defaults to 'none'
    $methods = array("none", "login", "plain", "cram-md5", "digest-md5");
    $s = '<select name="smtp_auth_mech">' . chr(13);
    foreach ($methods as $method) {
        $s .= '<option value="' . $method . '"';
        if ($value == $method) {
            $s.= ' SELECTED';
        }
        $s.= '>' . $method . '</option>';
    }
    $s.= '</select>';
    return $s;
}

# 
#-----[ OPEN ]------------------------------------------ 
# 

includes/emailer.php

# 
#-----[ FIND ]------------------------------------------ 
# 

class emailer
{

# 
#-----[ BEFORE, ADD ]------------------------------------------ 
# 

require("smtp_squirrelmail/smtp_squirrelmail.php");

# 
#-----[ FIND ]------------------------------------------ 
# 

$result = smtpmail($to, $this->subject, $this->msg, $this->extra_headers);

# 
#-----[ REPLACE WITH ]------------------------------------------ 
# 

$result = smtpsquirrelmail($to, $this->subject, $this->msg, $this->extra_headers);

# 
#-----[ SAVE/CLOSE ALL FILES ]------------------------------------------ 
# 
# EoM