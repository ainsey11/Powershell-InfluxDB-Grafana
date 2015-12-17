# ------------------------------------------------------------------------
# NAME: Get-ExchangeResources.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: This script is to be used standalone, or part of the Power-Grafana toolset.
# this particular function contacts exchange to get the amount of RAM and CPU used then
# post it into influxdb / grafana
#
# ------------------------------------------------------------------------

Function Get-ExchangeResources{
param(
    [string]$computer # Gets computer name from switch
    )
  $OperatingSystem = Get-WmiObject win32_OperatingSystem -computer $computer #Pulls info
  $FreeMemory = $OperatingSystem.FreePhysicalMemory # makes var for free mem
  $TotalMemory = $OperatingSystem.TotalVisibleMemorySize # makes var for total mem
  $MemoryUsed = $MemoryUsed = 100 - (($FreeMemory/ $TotalMemory) * 100) # does the maths
  $PercentMemoryUsed = "{0:N2}" -f $MemoryUsed # more maths
       
    $cpu = Get-WmiObject win32_processor # Gets proc info
    $cpuusage = $cpu.LoadPercentage # Gets percentage
    
    $seriesname = $computer+"resources" #sets influxdb series name
    
    Write-Host -ForegroundColor Green "$computer" #Not really needed, just added for debug
    Write-Host -ForegroundColor Green "RAM Used :$PercentMemoryUsed" #not really needed, just added for debug
    Write-Host -ForegroundColor Green "CPU Used :$cpuusage"#not really needed, just added for debug

    [System.Collections.ArrayList]$Exchangeresources = @() #Making the array for the API send
    $Exchangeresources.Add($PercentMemoryUsed) #Adding 1st var
    $Exchangeresources.Add($cpuusage) # Adding second var
 
    # Stick the data points into the null array for required JSON format
    [System.Collections.ArrayList]$nullpoints = @()
    $nullpoints.Add($Exchangeresources)
 
    # Build the post body
    $body = @{}
    $body.Add('name',"$seriesname")
    $body.Add('columns',@('Ram', 'CPU'))
    $body.Add('points',$nullpoints)
 
    # Convert to json
    $finalbody = $body | ConvertTo-Json  -Compress
    $finalbody
  # Post to API
    Invoke-WebRequest -Uri "http://10.159.25.13:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Stop
}
# run the function itself

Get-ExchangeResources -computer "thq-mail01" # run the function itself
Get-ExchangeResources -computer "thq-mail02"
Get-ExchangeResources -computer "bat-mail01"
