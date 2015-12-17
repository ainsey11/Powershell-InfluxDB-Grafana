# ------------------------------------------------------------------------
# NAME: Get-WSUSPendingUpdates.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: Gets number of unapproved, undeclined updates from WSUS,then posts to the Dashboard API
#

# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
Invoke-Expression -Command ($vars)

#gets count from WSUS Server defined in vars
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") #gets net stuffs
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer(“$global:wsusserver”,$False,$global:wsusserverport) #connects to server
$Unapproved = $wsus.GetUpdates() | Where {$_.IsApproved -eq $False -and $_.IsDeclined -eq $False}  #runs check
$count = $Unapproved.Count

[System.Collections.ArrayList]$NumberUnapproved = @()
$NumberUnapproved.Add($Count)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($NumberUnapproved)
 
# Build the post body
$body = @{}
$body.Add('name',"unnaprovedupdates")
$body.Add('columns',@('number'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
$finalbody

# Post to API
 Invoke-WebRequest -Uri $global:url -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue