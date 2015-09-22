<?PHP

$user_name = "root";
$password = "carsrule";
$database = "observium";
$server = "10.1.1.90";

$db_handle = mysql_connect($server, $user_name, $password);
$db_found = mysql_select_db($database, $db_handle);

if ($db_found) {

$SQL = "SELECT sensor_value FROM `sensors_state` WHERE sensor_id = 29";
$result = mysql_query($SQL);

while ( $db_field = mysql_fetch_assoc($result) ) {

print $db_field['sensor_value'];

}

mysql_close($db_handle);

}
else {

print "Database NOT Found ";
mysql_close($db_handle);

}

?>

