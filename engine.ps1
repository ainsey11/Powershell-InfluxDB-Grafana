#Requires -Version 2

# Map the various jobs into a hashtable. Add or remove any jobs you wish to have this script run.
# Code credit to cdituri
$jobMap = [Ordered]@{
    'WSUS' = '\Resources\Get-WSUSPendingUpates.ps1';
    'Mail Server Resources'   = 'Get-ExchangeResources.ps1';
    'Exchange Statistics'   = '\Resources\Get-ExchangeStatistics.ps1';
	'Backup Information' = '\Resources\Get-BackupExecInformation.ps1';
    'DHCP Statistics' = '\Resources\Get-DHCPStatistics.ps1'

}

# Collect data and send to dashboard
# Code credit to cdituri
$jobMap.Keys | ForEach-Object -Process {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $jobMap[$_]
    Start-Job -Name "$($_)" -ScriptBlock {
        Invoke-Expression -Command $args[0] 
    } -ArgumentList $scriptPath
}

# Display job status, and wait for the jobs to finish before removing them from the list (essentially garbage collection)
Get-Job | Wait-Job | Format-Table -AutoSize
Get-Job | Remove-Job | Format-Table -AutoSize