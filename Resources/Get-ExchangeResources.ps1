Function Get-ExchangeResources{ # Lets import our list of computers
param(
    [string]$computer = "localhost"
    )
    $freemem = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer
    $FreePhysicalMem = ([math]::round($freemem.FreePhysicalMemory / 1024, 2))
    $cpuusage = Get-Counter '\Processor(_Total)\% Processor Time'
    
    Write-Host -ForegroundColor Green "$computer"
    Write-Host -ForegroundColor Green "RAM USed :$FreePhysicalMem"
    Write-Host -ForegroundColor Green "CPU Used :$cpuusage"

# API funkiness now:

[System.Collections.ArrayList]$ExchangeResources = @()
$ExchangeStats.Add($FreePhysicalMem)
$ExchangeStats.Add($cpuusage)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($Exchangeresouces)
 
# Build the post body
$body = @{}
$body.Add('name',"$computer")
$body.Add('columns',@('MemoryUsed', 'CPU'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress

# Post to API
Invoke-WebRequest -Uri "http://10.159.25.13:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
}

Get-ExchangeResources -computer "localhost"
#Get-ExchangeResources -computer "thq-mail02"
#Get-ExchangeResources -computer "bat-mail01"