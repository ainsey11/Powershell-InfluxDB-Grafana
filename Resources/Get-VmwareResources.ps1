Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer "thq-vcc01"
New-VIProperty -Name PercentFree -ObjectType Datastore -Value {"{0:N2}" -f ($args[0].FreeSpaceMB/$args[0].CapacityMB*100)} -Force

function Get-VDIStats{
$NumberofSMBVDI = (Get-VM -Name "*smb*"| where {$_.Powerstate -eq "PoweredOn"}).count
$NumberofNOCVDI = (Get-VM -Name "*noc*"| where {$_.Powerstate -eq "PoweredOn"}).count
$DatastoreFreeSpace = Get-Datastore -Name "thq-vdi01-01-datastore01" | foreach { $_.PercentFree}
 
# API funkiness now:

#Building the array
[System.Collections.ArrayList]$VdiStats = @()
$VdiStats.Add($NumberofSMBVDI)
$VdiStats.Add($NumberofNOCVDI)
$VdiStats.Add($DatastoreFreeSpace)


# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($VdiStats)
 
# Build the post body
$body = @{}
$body.Add('name',"vdistatistics")
$body.Add('columns',@('SMBCount','NOCCount', 'DSFreeSpace'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress

# Post to API
Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
Start-Sleep 5
Get-VDIStats
}

Get-VDIStats
Disconnect-VIServer -Server "thq-vcc01"