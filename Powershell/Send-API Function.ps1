function Send-API {

param ([string] $seriesname),
      ([string] $column)
      ([string] $point)

 
#Building the array
[System.Collections.ArrayList]$array = @()
$array.Add($point)

# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($array)
 
# Build the post body
$body = @{}
$body.Add('name',$seriesname)
$body.Add('columns',@($column))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
 
# Post to API
Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
}
