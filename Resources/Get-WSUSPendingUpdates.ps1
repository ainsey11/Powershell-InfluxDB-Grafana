#requires -Version 3

# Pull in vars
#$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
#Invoke-Expression -Command ($vars)

[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer(“thq-wsus01”,$False)
$Updates = $wsus.GetUpdates()
$NumberofUpdates = $updates.count

#InfluxDBFuntime!
$points.Add('WSUSPendingUpdates',$NumberofUpdates)

# Wrap the points into a null array to meet InfluxDB json requirements. Sad face
[System.Collections.ArrayList]$nullarray = @()
$nullarray.Add($points)

# Build the post body
$body = @{}
$body.Add('WSUSPendingUpdates')
$body.Add('columns',@('Count'))
$body.Add('points',$nullarray)

# Convert to json
$finalbody = $body | ConvertTo-Json

# Post to API
try 
{
    $r = Invoke-WebRequest -Uri $global:url -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Stop
    Write-Host -Object "Data has been posted, status is $($r.StatusCode) $($r.StatusDescription)"        
}
catch 
{
    throw 'Could not POST to InfluxDB API endpoint'
}
