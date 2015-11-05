#requires -Version 3

# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
Invoke-Expression -Command ($vars)

[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer(“$wsuserver”,$False)
$wsus.GetUpdates()