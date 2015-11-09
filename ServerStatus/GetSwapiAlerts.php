<?php
$data = array(
  'query' => "Select tolocal(AlertStatus.TriggerTimeStamp) as time, AlertStatus.ObjectName,  AlertStatus.Notes From Orion.AlertStatus WHERE (AlertStatus.ObjectType = 'Node' AND AlertStatus.ObjectName NOT LIKE 'THQ%' AND AlertStatus.State <> '1') ORDER BY AlertStatus.TriggerTimeStamp DESC"
  );
$url = "https://solarwinds.timico.co.uk:17778/SolarWinds/InformationService/v3/Json/Query";
$jdata = json_encode($data);
echo $result = CallAPI($url, $jdata);


function CallAPI($url, $data = false) {
   $ch = curl_init();

    // Authentication:
    curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($ch, CURLOPT_USERPWD, "robert.ainsworth:Ainsey11:)");
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($ch, CURLOPT_SSLVERSION, 3);
  curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
  curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
  curl_setopt($ch, CURLOPT_VERBOSE, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
  curl_setopt($ch, CURLOPT_HTTPHEADER, array(
                                        'Content-type: application/json',
                                        'Content-length: ' . strlen($data)
                                      ));

  $result = curl_exec($ch);
  $response = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $error = curl_error($ch);
  $info = curl_getinfo($ch);

  curl_close($ch);

    if ($result == false) {
  echo "Response: " . $response . "<br>";
  echo "Error: " . $error . "<br>";
  echo "Info: " . print_r($info);
  die();
  }
  $file = fopen("SwapiResult.txt", "w") or die("Unable to open file!");
  fwrite($file, $result);
  fclose($file);
}
?>
