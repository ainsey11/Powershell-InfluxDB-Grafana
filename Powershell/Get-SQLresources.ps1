# ------------------------------------------------------------------------
# NAME: Get-ExchangeStatistcs.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: Gets CPU and RAM usage for the SQL servers, might expand to get
# sql specific data if there becomes a need for it.
#
# ------------------------------------------------------------------------
# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + 'vars.ps1'
Invoke-Expression -Command ($vars)

function Get-SQLResources{
param(
    [string]$computer # Get Params
    )
  $OperatingSystem = Get-WmiObject win32_OperatingSystem -computer $computer #Get computer info
  $FreeMemory = $OperatingSystem.FreePhysicalMemory #Gets free ph mem
  $TotalMemory = $OperatingSystem.TotalVisibleMemorySize # gets total visible
  $MemoryUsed = $MemoryUsed = 100 - (($FreeMemory/ $TotalMemory) * 100) #maths
  $PercentMemoryUsed = "{0:N2}" -f $MemoryUsed #maths
       
    $cpu = Get-WmiObject win32_processor # processor info
    $cpuusage = $cpu.LoadPercentage # get percentage
    $seriesname = $computer+"resources" # set var
    
    Write-Host -ForegroundColor Green "$computer" # debug
    Write-Host -ForegroundColor Green "RAM Used :$PercentMemoryUsed" #debug
    Write-Host -ForegroundColor Green "CPU Used :$cpuusage" #debug
    
    [System.Collections.ArrayList]$SQLresources = @() #make array
    $SQLresources.Add($PercentMemoryUsed)
    $SQLresources.Add($cpuusage)
 
    # Stick the data points into the null array for required JSON format
    [System.Collections.ArrayList]$nullpoints = @()
    $nullpoints.Add($SQLresources)
    # Build the post body
    $body = @{}
    $body.Add('name',"$seriesname")
    $body.Add('columns',@('Ram', 'CPU'))
    $body.Add('points',$nullpoints)
 
    # Convert to json
    $finalbody = $body | ConvertTo-Json  -Compress
    $finalbody
  # Post to API
 
 Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
 }
#run function
Get-SQLResources -computer "thq-billtest02"
Get-SQLResources -computer "thq-sql03"
Get-SQLResources -computer "thq-sql04"