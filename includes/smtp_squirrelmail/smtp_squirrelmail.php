<?

/**
 * smtp_squirrelmail.php
 * SEND MAIL USING SQUIRRELMAILs NICE(R) SMTP FUNCTIONS
 *
 * Author: christian.lagerkvist@gmail.com, which takes no responsibilities, use at your own risk.
 * Licensed under the GNU GPL. (thanks stekkel, #squirrelmail, irc.freenode.net)
 *
 * this interface (glue) file between phpbb and squirrelmail requires the following files
 * from squirrelmail

 <phpBB_root>/includes/smtp_squirrelmail/class/deliver/Deliver_SMTP.class.php
 <phpBB_root>/includes/smtp_squirrelmail/class/deliver/Deliver.class.php
 <phpBB_root>/includes/smtp_squirrelmail/class/mime/AddressStructure.class.php
 <phpBB_root>/includes/smtp_squirrelmail/class/mime/ContentType.class.php
 <phpBB_root>/includes/smtp_squirrelmail/class/mime/Message.class.php
 <phpBB_root>/includes/smtp_squirrelmail/class/mime/Rfc822Header.class.php
 <phpBB_root>/includes/smtp_squirrelmail/functions/auth.php
 <phpBB_root>/includes/smtp_squirrelmail/functions/date.php
 
INSTALLATION:

1. PREPARE:
    Create the directory structure above. (I e, move this entire folder to the includes/
    directory of your phpBB installation.

2. IMPLEMENT:
a. Locate includes/emailer.php in your phpBB installation
b. Immediately above the line

    class emailer

, add
    
    require("smtp_squirrelmail/smtp_squirrelmail.php");

c. Change the line: $result = smtpmail($to, $this->subject, $this->msg, $this->extra_headers);
into this:  $result = smtpsquirrelmail($to, $this->subject, $this->msg, $this->extra_headers);

(should be somewhere around line 206)


(d. 
This part means altering one of the squirrelmail files, which I've already done in this package.
I don't like, but it's necessary unless you're registering_globals.
In Deliver_SMTP.class.php, locate this section:

    function initStream($message, $domain, $length=0, $host='', $port='', $user='', $pass='', $authpop=false) {
    global $use_smtp_tls,$smtp_auth_mech;

and change it into this:

    function initStream($message, $domain, $length=0, $host='', $port='', $user='', $pass='', $authpop=false, $use_smtp_tls, $smtp_auth_mech) {
        
that is, we're moving $use_smtp_tls, $smtp_auth_mech into to function definition instead of keeping them global. Sucky, aye?)

e. Set smtp_auth_mech, port and use_smtp_tls in the configuration section of your phpBB installation.

3. ENJOY
You can now send mails using hard-to-please smtp servers. (In theory.)
Set your phpBB to use smtp and enter smtp user and pass in the admin section.

To find out WHAT protocols your smtp server handles, do this in a shell window (such as xterm):
telnet your.mail.server.com 25 (or whatever port)
then type
EHLO domain.com
Hopefully, you'll now get a listing of what your mailserver can handle.
If not, try
HELO domain.com

Good luck,

    christian.lagerkvist@gmail.com
*/

/* So in theory, you shouldn't have to change anything below this line... */

define("SM_PATH", $phpbb_root_path . "includes/smtp_squirrelmail/");
define('SQ_INORDER',0);
define('SQ_GET',1);
define('SQ_POST',2);
define('SQ_SESSION',3);
define('SQ_COOKIE',4);
define('SQ_SERVER',5);
define('SQ_FORM',6);

require_once("class/deliver/Deliver_SMTP.class.php");
require_once("functions/auth.php");
require_once("functions/date.php");
require_once("class/mime/Rfc822Header.class.php");
require_once("class/mime/AddressStructure.class.php");
require_once("class/mime/ContentType.class.php");
require_once("class/mime/Message.class.php");

// Encode a string according to RFC 1522 for use in headers if it
// contains 8-bit characters or anything that looks like it should
// be encoded.
function encodeHeader ($string) {
   global $default_charset;

   // Encode only if the string contains 8-bit characters or =?
   if (ereg("([\200-\377])|=\\?", $string)) {
      $newstring = "=?$default_charset?Q?";
      
      // First the special characters
      $string = str_replace("=", "=3D", $string);
      $string = str_replace("?", "=3F", $string);
      $string = str_replace("_", "=5F", $string);
      $string = str_replace(" ", "_", $string);


      while (ereg("([\200-\377])", $string, $regs)) {
         $replace = $regs[1];
         $insert = "=" . strtoupper(bin2hex($replace));
         $string = str_replace($replace, $insert, $string);
      }

      $newstring = "=?$default_charset?Q?".$string."?=";
      
      return $newstring;
   }

   return $string;
}

/* If you want to remove the line below, you're probably running php with gettext... :> */
function _($str) { # emulate gettext syntax to avoid errors
    message_die(GENERAL_ERROR,$str, "", __LINE__, __FILE__);
}

function check_php_version ($a = '0', $b = '0', $c = '0')
{
    return version_compare ( PHP_VERSION, "$a.$b.$c", 'ge' );
}

function sqgetGlobalVar($name, &$value, $search = SQ_INORDER) {

    /* NOTE: DO NOT enclose the constants in the switch
       statement with quotes. They are constant values,
       enclosing them in quotes will cause them to evaluate
       as strings. */
    switch ($search) {
        /* we want the default case to be first here,
           so that if a valid value isn't specified,
           all three arrays will be searched. */
      default:
      case SQ_INORDER: // check session, post, get
      case SQ_SESSION:
        if( isset($_SESSION[$name]) ) {
            $value = $_SESSION[$name];
            return TRUE;
        } elseif ( $search == SQ_SESSION ) {
            break;
        }
      case SQ_FORM:   // check post, get
      case SQ_POST:
        if( isset($_POST[$name]) ) {
            $value = $_POST[$name];
            return TRUE;
        } elseif ( $search == SQ_POST ) {
          break;
        }
      case SQ_GET:
        if ( isset($_GET[$name]) ) {
            $value = $_GET[$name];
            return TRUE;
        }
        /* NO IF HERE. FOR SQ_INORDER CASE, EXIT after GET */
        break;
      case SQ_COOKIE:
        if ( isset($_COOKIE[$name]) ) {
            $value = $_COOKIE[$name];
            return TRUE;
        }
        break;
      case SQ_SERVER:
        if ( isset($_SERVER[$name]) ) {
            $value = $_SERVER[$name];
            return TRUE;
        }
        break;
    }
    /* Nothing found, return FALSE */
    return FALSE;
}

function dump($obj) {
    echo "<pre style='font-face=verdana;font-size:9px;background:#ffcccc'>";
    print_r($obj);
    echo "</pre>";
}

/*

    ...but that's just theory
    function smtpsquirrelmail
    is an extract of Squirrelmails mail sending part (compose.php) but with phpbb's error checking
*/

function smtpsquirrelmail($mail_to, $subject, $message, $headers='') {
    global $board_config;
    
    if (isset($board_config['smtp_auth_mech']) && $board_config['smtp_auth_mech'] != "") {
        $smtp_auth_mech = $board_config['smtp_auth_mech'];
    } elseif (!empty($board_config['smtp_username'])) {
        $smtp_auth_mech = "login";
    } else {
        $smtp_auth_mech = "none";
    }

    if (isset($board_config['use_smtp_tls']) && $board_config['use_smtp_tls'] == "1") {
        $use_smtp_tls = true;
    } else {
        $use_smtp_tls = false;
    }

    if (isset($board_config['smtp_port']) && $board_config['smtp_port'] != "") {
        $smtp_port = $board_config['smtp_port'];
    } else {
        $smtp_port = 25;
    }
    

    $from = new AddressStructure();
    $to = new AddressStructure();
    
    if (trim($mail_to) == '') {
        $mail_to = "Undisclosed-recipients:;";
    } else {
        $mail_to = trim($mail_to);
        list($to->mailbox, $to->host) = split("@", $mail_to);
    }

    $m = new Message();
    $rfc = new Rfc822Header();
    list($from->mailbox, $from->host) = split("@", $board_config['board_email']);

    $rfc->parseField('subject', $subject);
    $rfc->to = array($to);
    $rfc->parseHeader($headers);
    $from->personal = $board_config['sitename'];

    $m->rfc822_header = $rfc;
    $m->setBody($message);

    # <CODE FROM PHPBBs SMTPMAIL>
    $message = preg_replace("#(?<!\r)\n#si", "\r\n", $message);
    
    
    if ($headers != '')
    {
            if (is_array($headers))
            {
                    if (sizeof($headers) > 1)
                    {
                            $headers = join("\n", $headers);
                    }
                    else  
                    {
                            $headers = $headers[0];
                    }
            }   
        
            $headers = chop($headers);

            // Make sure there are no bare linefeeds in the headers
            $headers = preg_replace('#(?<!\r)\n#si', "\r\n", $headers);

            // Ok this is rather confusing all things considered,
            // but we have to grab bcc and cc headers and treat them differently
            // Something we really didn't take into consideration originally
            $header_array = explode("\r\n", $headers);
            @reset($header_array);

            $headers = '';
            while(list(, $header) = each($header_array))
            {
                    if (preg_match('#^cc:#si', $header))
                    {
                            $cc = preg_replace('#^cc:(.*)#si', '\1', $header);
                    }
                    else if (preg_match('#^bcc:#si', $header))
                    {
                            $bcc = preg_replace('#^bcc:(.*)#si', '\1', $header);
                            $header = '';
                    }
                    $headers .= ($header != '') ? $header . "\r\n" : '';
            }

            $headers = chop($headers);
            $cc = explode(', ', $cc);
            $bcc = explode(', ', $bcc);
    }  
    
    if (trim($subject) == '')
    {
            message_die(GENERAL_ERROR, "No email Subject specified", "", __LINE__, __FILE__);
    }

    if (trim($message) == '')
    {
            message_die(GENERAL_ERROR, "Email message was blank", "", __LINE__, __FILE__);
    }
    
    # </CODE FROM PHPBBs SMTPMAIL>

    
    $deliver = new Deliver_SMTP();
    $stream = $deliver->initStream($m, $board_config['server_name'],0, $board_config['smtp_host'], $smtp_port, $board_config['smtp_username'], $board_config['smtp_password'], false,  $use_smtp_tls, $smtp_auth_mech);

    $success = false;
    
    if ($stream) {
        $length = $deliver->mail($m, $stream);
        $success = $deliver->finalizeStream($stream);
    }
    if (!$success) {
        $msg  = $deliver->dlv_msg . '<br />' .
            _("Server replied:") . ' ' . $deliver->dlv_ret_nr . ' ' .
            $deliver->dlv_server_msg;
        plain_error_message($msg, $color);
    }
return $success;

}

?>