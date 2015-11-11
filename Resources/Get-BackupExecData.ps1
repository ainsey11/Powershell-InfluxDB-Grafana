Enter-PSSession thq-bksrv01

Import-Module BEMCLI
$NumberofJobsRunning = (Get-BEActiveJobDetail).Count
$NumberofAlerts = (Get-BEAlert).Count

[System.Collections.ArrayList]$Bedata = @()
$Exchangeresources.Add($NumberofJobsRunning)
$Exchangeresources.Add($NumberofAlerts)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
    $nullpoints.Add($Bedata)

# Build the post body
$body = @{}
$body.Add('name',"backupexec")
$body.Add('columns',@('ActiveJobs', 'NumberofAlerts'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
$finalbody

# Post to API 
 Invoke-WebRequest -Uri "http://10.159.25.13:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue}
