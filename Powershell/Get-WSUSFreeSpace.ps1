# ------------------------------------------------------------------------
# NAME: Get-WSUSFreeSpace.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: This gets the Wsus Server and sends the amount of free space on he data drive to
# the API
#
# ------------------------------------------------------------------------
# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
Invoke-Expression -Command ($vars)


$disk = Get-WmiObject Win32_LogicalDisk -ComputerName "thq-wsus01" -Filter "DeviceID='E:'" |
Select-Object FreeSpace
$space = $Disk.FreeSpace /1GB
[System.Collections.ArrayList]$FreeSpace = @()
$FreeSpace.Add($space)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($FreeSpace)
 
# Build the post body
$body = @{}
$body.Add('name',"WSUSFreeSpace")
$body.Add('columns',@('TotalSpace'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
$finalbody

# Post to API
 Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue