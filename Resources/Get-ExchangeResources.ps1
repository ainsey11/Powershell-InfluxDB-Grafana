Function Get-ExchangeResources{ # Lets import our list of computers
param(
    [string]$computer
    )

    # Lets get our stats
    # Lets create a re-usable WMI method for CPU stats
    $ProcessorStats = Get-WmiObject win32_processor -computer $computer
    $ComputerCpu = $ProcessorStats.LoadPercentage 
    # Lets create a re-usable WMI method for memory stats
    $OperatingSystem = Get-WmiObject win32_OperatingSystem -computer $computer
    # Lets grab the free memory
    $FreeMemory = $OperatingSystem.FreePhysicalMemory
    # Lets grab the total memory
    $TotalMemory = $OperatingSystem.TotalVisibleMemorySize
    # Lets do some math for percent
    $MemoryUsed = ($FreeMemory/ $TotalMemory) * 100
    $PercentMemoryUsed = "{0:N2}" -f $MemoryUsed
    echo "$ComputerCpu"
    
    Write-Host -ForegroundColor Green "RAM USed :$PercentMemoryUsed"
    Write-Host -ForegroundColor Green "CPU Used :$ComputerCpu"

# API funkiness now:

[System.Collections.ArrayList]$ExchangeResources = @()
$ExchangeStats.Add($PercentMemoryUsed)
$ExchangeStats.Add($ComputerCPU)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($Exchangeresouces)
 
# Build the post body
$body = @{}
$body.Add('name',"$computername")
$body.Add('columns',@('MemoryUsed', 'CPU'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress

# Post to API
Invoke-WebRequest -Uri "http://10.159.25.13:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
}

Get-ExchangeResources -computer "thq-mail01"
Get-ExchangeResources -computer "thq-mail02"
Get-ExchangeResources -computer "bat-mail01"