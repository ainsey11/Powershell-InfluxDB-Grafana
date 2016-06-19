# ------------------------------------------------------------------------
# NAME: Get-ExchangeStatistcs.ps1
# AUTHOR: Robert Ainsworth
# WEB : https://ainsey11.com
#
#
# COMMENTS: This script gets mail counts, and mail size from the exchange servers.
# it then stores in an array, and posts to influxdb's api
#
# ------------------------------------------------------------------------
# Pull in vars

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://#/powershell
Import-PSSession $session

$vars = (Get-Item $PSScriptRoot).Parent.FullName + 'vars.ps1'
Invoke-Expression -Command ($vars)

# Initialize some variables used for counting and for output 
$startdate = Get-Date
$From = $startdate.AddHours(-1)
$To = $startdate.AddHours(1)
[Int64] $intSent = $intRec = 0
[Int64] $intSentSize = $intRecSize = 0
[String] $strEmails = $null

do 
{ 
    # Start building the variable that will hold the information for the day 
    $strEmails = "$($From.DayOfWeek),$($From.ToShortDateString())," 
    $intSent = $intRec = 0 
    #get the trackinglog results
    (Get-TransportServer -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)  | Get-MessageTrackingLog -ResultSize Unlimited -Start $From -End $To -ErrorAction SilentlyContinue -WarningAction SilentlyContinue| ForEach { 
        # Sent E-mails 
        If ($_.EventId -eq "RECEIVE" -and $_.Source -eq "STOREDRIVER")
		{
			$intSent++
			$intSentSize += $_.TotalBytes
		}
         
        # Received E-mails 
        If ($_.EventId -eq "DELIVER")
		{
			$intRec++
			$intRecSize += $_.TotalBytes
		}
    } 
    # gets mail sizes
 	$intSentSize = [Math]::Round($intSentSize/1MB, 0)
	$intRecSize = [Math]::Round($intRecSize/1MB, 0)
 
    # Add the numbers to the $strEmails variable and print the result for the day 
    $strEmails += "$intSent,$intSentSize,$intRec,$intRecSize" 
 
    # Increment the From and To by one day 
    $From = $From.AddDays(1) 
    $To = $From.AddDays(1) 
} 
While ($To -lt (Get-Date))

$NumberofMailboxes = (Get-Mailbox).Count #gets mailbox count
$NumberofDistribGroups = (Get-DistributionGroup).Count #Gets distribution group count
$thqmail01queue = (Get-Queue -Server "thq-mail01" | Get-Message).count #Gets mail queue
$thqmail02queue = (Get-Queue -Server "thq-mail02" | Get-Message).count #Gets mail queue
$batmail01queue = (Get-Queue -Server "bat-mail01" | Get-Message).count #Gets mail queue
$rawmail01iislogsize = "{0:N2}" -f ((Get-ChildItem -path C:\inetpub\logs\LogFiles\ -recurse | Measure-Object -property length -sum ).sum /1MB) # gets IIS log folder size
$rawmail02iislogsize = "{0:N2}" -f ((Get-ChildItem -path C:\#\c$\inetpub\logs\LogFiles\ -recurse | Measure-Object -property length -sum ).sum /1MB)# gets IIS log folder size
$mail01iislogsize = $rawmail01iislogsize.Replace(",","") # replaces , from above with nothing
$mail02iislogsize = $rawmail02iislogsize.Replace(",","") # same I guess


# API funkiness now:

#Building the array
[System.Collections.ArrayList]$ExchangeStats = @()----
$ExchangeStats.Add($intsent)
$ExchangeStats.Add($intsentsize)
$ExchangeStats.Add($intrec)
$ExchangeStats.Add($intrecsize)
$ExchangeStats.Add($NumberofMailboxes)
$ExchangeStats.Add($NumberofDistribGroups)
$ExchangeStats.Add($thqmail01queue)
$ExchangeStats.Add($thqmail02queue)
$ExchangeStats.Add($batmail01queue)
$ExchangeStats.Add($mail01iislogsize)
$ExchangeStats.Add($mail02iislogsize)

# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($ExchangeStats)
 
# Build the post body
$body = @{}
$body.Add('name',"exchangestatistics")
$body.Add('columns',@('Sent', 'sentsize', 'recieved', 'recievedsize', 'NumofMailboxes', 'NumofDistribGroups', 'thqmail01queue','thqmail02queue','batmail01queue','mail01logsize','mail02logsize'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress

# Post to API
 Invoke-WebRequest -Uri $global:DashboardServer -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue