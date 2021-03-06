# Map the various jobs into a hashtable. Add or remove any jobs you wish to have this script run.
$jobMap = [Ordered]@{
    'Exchange Resources' = 'Get-ExchangeResources.ps1';
    'Exchange Statistics'   = 'Get-ExchangeStatistics.ps1';
    'SQL Resources'   = 'Get-SQLResources.ps1';
	'RDS User Check' = 'Get-UsersLoggedintoRDS.ps1';
    'Vmware Resources' = 'Get-VmwareResources.ps1';
    'WSUS Computers needing updates' = 'Get-WsusComputersNeedingUpdates.ps1';
    'WSUS Unapproved Updates' = 'Get-WSUSComputersNeedingUpdates.ps1';
}


# Code credit to cdituri
$jobMap.Keys | ForEach-Object -Process {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $jobMap[$_]
    Start-Job -Name "$($_)" -Scriptblock {
        Invoke-Expression -Command $args[0] 
    } -ArgumentList $scriptPath
}

# Display job status, and wait for the jobs to finish before removing them from the list (essentially garbage collection)
Get-Job | Wait-Job | Format-Table -AutoSize
Get-Job | Remove-Job | Format-Table -AutoSize