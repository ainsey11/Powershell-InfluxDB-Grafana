# Pull in vars
#$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
#Invoke-Expression -Command ($vars)



function Get-RDSUsers{

param(
    [CmdletBinding()] 
    [Parameter(ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [string[]]$ComputerName = 'localhost'
)
begin {
    $ErrorActionPreference = 'Stop'
}

process {
    foreach ($Computer in $ComputerName) {
        try {
            quser /server:$Computer 2>&1 | Select-Object -Skip 1 | ForEach-Object {
                $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
                $HashProps = @{
                    UserName = $CurrentLine[0]
                    ComputerName = $Computer
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
                Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
            }
        } catch {
            New-Object -TypeName PSCustomObject -Property @{
                ComputerName = $Computer
                Error = $_.Exception.Message
            } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
        }
    }
}
}

$SessionCount = (Get-RDSUsers -ComputerName thq-rds01).Count

[System.Collections.ArrayList]$RDSUsers = @()
$RDSUsers.Add($SessionCount)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($RDSUsers)
 
# Build the post body
$body = @{}
$body.Add('name',"rds01usersessions")
$body.Add('columns',@('number'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress
$finalbody

# Post to API
 Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue