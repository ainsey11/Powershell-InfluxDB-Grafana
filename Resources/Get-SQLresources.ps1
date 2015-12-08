Function Get-SQLResources{ # Lets import our list of computers
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
    [System.Collections.ArrayList]$SQLresources = @()
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

While($true) {
 $i++
Get-SQLResources -computer "thq-billtest02"
Get-SQLResources -computer "thq-sql03"
Get-SQLResources -computer "thq-sql04"
}