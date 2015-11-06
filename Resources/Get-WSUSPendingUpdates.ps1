#requires -Version 3

# Pull in vars
#$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
#Invoke-Expression -Command ($vars)

#[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
#$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer(“10.159.25.24”,$False,8530)
#$Unapproved = $wsus.GetUpdates() | Where {$_.IsApproved -eq $False -and $_.IsDeclined -eq $False}
$NumberUnapproved = 8 #$Unapproved.Count

# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($NumberUnapproved)

# Build the post body
$body = @{}
$body.Add('name',"unnaprovedupdates")
$body.Add('columns',"number")
$body.Add('points',$nullpoints)

# Convert to json
$finalbody = $body | ConvertTo-Json

# Post to API

 Invoke-WebRequest -Uri "http://10.159.25.13:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Stop
 