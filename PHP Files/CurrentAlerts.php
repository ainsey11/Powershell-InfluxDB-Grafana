<?PHP

$user_name = "root";
$password = "#######";
$database = "observium";
$server = "####";

$db_handle = mysql_connect($server, $user_name, $password);
$db_found = mysql_select_db($database, $db_handle);

if ($db_found) {

$SQL = "SELECT message,device_id FROM alerts where time_logged >= DATE(NOW())";
$result = mysql_query($SQL);

while ( $db_field = mysql_fetch_assoc($result) ) {

print $db_field['Message'];
print $db_field['device_id'];

}

mysql_close($db_handle);

}
else {

print "Database NOT Found ";
mysql_close($db_handle);

}

?>

