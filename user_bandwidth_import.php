<?php
try{

  $url = 'https://movies.watchflx.tv/internal/bandwidth-stats';

  $ch = curl_init($url);

  curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_TIMEOUT => 30,
  ]);

  $response = curl_exec($ch);

  if ($response === false) {
      throw new Exception('cURL Error: ' . curl_error($ch));
  }

  $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  if ($httpCode !== 200) {
      throw new Exception("HTTP Error: {$httpCode}");
  }

  $data = json_decode($response, true);

  if( empty($data) ){
      throw new Exception("Bandwidth logs not found.");
  }

  $finalArray = [];

  foreach($data as $info){
    list($domain, $date, $userId, $streamType) = explode(":", $info['upid']);
    $finalArray[] = [
      "domain" => $domain,
      "date" => $date,
      "userId" => $userId,
      "type" => $streamType,
      "usage" => $info['usage'],
      "bytes" => $info['bytes'],
    ];
  }

  echo "<pre>";
  print_r($finalArray);
  echo "</pre>";

}catch(Exception $e){
  echo $e->getMessage();
}
die;
?>