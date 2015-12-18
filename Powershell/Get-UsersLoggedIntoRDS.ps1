# ------------------------------------------------------------------------
# NAME: Get-UsersLoggedIntoRDS.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: This script Gets the number of users logged into a single RDS server. 
#
# ------------------------------------------------------------------------
# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + 'vars.ps1'
Invoke-Expression -Command ($vars)


# Pull in vars
#$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
#Invoke-Expression -Command ($vars)

function Get-RDSUsers{

param(
    [CmdletBinding()] 
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [string[]]$ComputerName = 'localhost' #sets default computername
)
begin {
    $ErrorActionPreference = 'Stop' #fancied a bit of error logging
}

process { #loopy loop time
    foreach ($Computer in $ComputerName) { # loop here
        try {
            quser /server:$Computer 2>&1 | Select-Object -Skip 1 | ForEach-Object {
                $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
                $HashProps = @{
                    UserName = $CurrentLine[0]
                    ComputerName = $Computer #Well, duh!
                }

                # If session is disconnected different fields will be selected
                if ($CurrentLine[2] -eq 'Disc') {
                        $HashProps.SessionName = $null
                        $HashProps.Id = $CurrentLine[1]
                        $HashProps.State = $CurrentLine[2]
                        $HashProps.IdleTime = $CurrentLine[3]
                        $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
                        $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '                } else {
                        $HashProps.SessionName = $CurrentLine[1]
                        $HashProps.Id = $CurrentLine[2]
                        $HashProps.State = $CurrentLine[3]
                        $HashProps.IdleTime = $CurrentLine[4]
                        $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '                }

                New-Object -TypeName PSCustomObject -Property $HashProps |
                Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error #just so I can pull more info if I want
            }
        } catch { #moar logging
            New-Object -TypeName PSCustomObject -Property @{
                ComputerName = $Computer
                Error = $_.Exception.Message
            } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
        }
    }
}
}

$SessionCount = (Get-RDSUsers -ComputerName thq-rds01).Count #Counts and makes into variable

[System.Collections.ArrayList]$RDSUsers = @()
$RDSUsers.Add($SessionCount) #adds var into array
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @() #makes null array
$nullpoints.Add($RDSUsers) #adds it
 
# Build the post body
$body = @{}
$body.Add('name',"rds01usersessions")
$body.Add('columns',@('number'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
$finalbody

# Post to API
 Invoke-WebRequest -Uri $global:DashboardServer -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue