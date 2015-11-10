Function Get-ExchangeResources{ # Lets import our list of computers
param(
    [string]$computer
    )
  $OperatingSystem = Get-WmiObject win32_OperatingSystem -computer $computer
  $FreeMemory = $OperatingSystem.FreePhysicalMemory
  $TotalMemory = $OperatingSystem.TotalVisibleMemorySize
  $MemoryUsed = $MemoryUsed = 100 - (($FreeMemory/ $TotalMemory) * 100)
  $PercentMemoryUsed = "{0:N2}" -f $MemoryUsed
       
    $cpu = Get-WmiObject win32_processor
    $cpuusage = $cpu.LoadPercentage
    
    $seriesname = $computer+"resources"
    
    Write-Host -ForegroundColor Green "$computer"
    Write-Host -ForegroundColor Green "RAM Used :$PercentMemoryUsed"
    Write-Host -ForegroundColor Green "CPU Used :$cpuusage"

    [System.Collections.ArrayList]$Exchangeresources = @()
    $Exchangeresources.Add($PercentMemoryUsed)
    $Exchangeresources.Add($cpuusage)
 
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
 
 Invoke-WebRequest -Uri "http://10.159.25.13:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
}

Get-ExchangeResources -computer "thq-mail01"
Get-ExchangeResources -computer "thq-mail02"
Get-ExchangeResources -computer "bat-mail01"