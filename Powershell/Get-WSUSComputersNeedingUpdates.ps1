# ------------------------------------------------------------------------
# NAME: Get-WSUSComputersNeedingUpdates.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: Gets number of unapproved, undeclined updates from WSUS,then posts to the Dashboard API
# I might change it to query the DB instead, this method is rather slow
# ------------------------------------------------------------------------

# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
Invoke-Expression -Command ($vars)

#gets count from WSUS Server defined in vars
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") #Loads the .net stuffs.
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer(“thq-wsus-1”,$False,"8530") #connection string to WSUS
$Computersneedingupdates = $wsus.GetUpdateStatus($updatescope,$False)| Select ComputerTargetsneedingUpdatesCount #Gets the UpdatesCount

[System.Collections.ArrayList]$Numberneedingupdates = @()
$Numberneedingupdates.Add($Computersneedingupdates) #Adds to array
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($Numberneedingupdates)
 
# Build the post body
$body = @{}
$body.Add('name',"Computersneedingupdates")
$body.Add('columns',@('number'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
$finalbody

# Post to API
 Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue