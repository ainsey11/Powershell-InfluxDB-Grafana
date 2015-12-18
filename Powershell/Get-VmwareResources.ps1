# ------------------------------------------------------------------------
# NAME: Get-VmwareResources.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: This script gets the Vmware VDI solution information via vcenter queries.
# It must be able to to connect to the vcenter server. it gets counts of Vm's starting with NOC and SMB (our 2 departments)
# and sends it to the API. It also gets the two VDI hosts ram usage and sends it into the API. Quite useful stuff.
#
# ------------------------------------------------------------------------
# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + 'vars.ps1'
Invoke-Expression -Command ($vars)

Add-PSSnapin VMware.VimAutomation.Core #Adds the snapin, you must have PowerCLI installed
Connect-VIServer "thq-vcc01" #ServerName
New-VIProperty -Name PercentFree -ObjectType Datastore -Value {"{0:N2}" -f ($args[0].FreeSpaceMB/$args[0].CapacityMB*100)} -Force #does some maths for me
 

$NumberofSMBVDI = (Get-VM -Name "*smb*"| where {$_.Powerstate -eq "PoweredOn"}).count #gets count of VM's
$NumberofNOCVDI = (Get-VM -Name "*noc*"| where {$_.Powerstate -eq "PoweredOn"}).count #same again, you wizard
$DatastoreFreeSpace = Get-Datastore -Name "thq-vdi01-01-datastore01" | foreach { $_.PercentFree} #Gets the datastore free space of the one DS I care about
$Host1MemUsage = Get-Vmhost "thq-vdi01-01.timicogroup.local" #Gets memory usage
$Host2MemUsage = Get-Vmhost "thq-vdi01-02.timicogroup.local" #gets memory usage
 
# API funkiness now:
 
#Building the array
[System.Collections.ArrayList]$VdiStats = @() #makes it into an array
$VdiStats.Add($NumberofSMBVDI) #ooh! one var
$VdiStats.Add($NumberofNOCVDI) # two var
$VdiStats.Add($DatastoreFreeSpace) #thre var's
$VdiStats.Add($Host1MemUsage.MemoryUsageGB) #four
$VdiStats.Add($Host2MemUsage.MemoryUsageGB) # five vars! wooah
 
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($VdiStats)
 
# Build the post body
$body = @{}
$body.Add('name',"vdistatistics")
$body.Add('columns',@('SMBCount','NOCCount', 'DSFreeSpace','host1mem','host2mem')) #headings
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
 
# Post to API
Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
Start-Sleep 20 # Dont want to be spamming the vcenter server with requests now do we? lets let it have a little rest for now
Disconnect-VIServer #Aaaaaaannn Disconnect
Start-Sleep 5 # bit more of a rest