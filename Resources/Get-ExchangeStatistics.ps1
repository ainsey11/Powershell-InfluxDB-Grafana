While ($True){
 $i++

# Initialize some variables used for counting and for output 
$startdate = Get-Date
$From = $startdate.AddHours(-1)
$To = $startdate.AddHours(1)
 
[Int64] $intSent = $intRec = 0
[Int64] $intSentSize = $intRecSize = 0
[String] $strEmails = $null 
 
Do 
{ 
    # Start building the variable that will hold the information for the day 
    $strEmails = "$($From.DayOfWeek),$($From.ToShortDateString())," 
   
 
    $intSent = $intRec = 0 
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
 
 	$intSentSize = [Math]::Round($intSentSize/1MB, 0)
	$intRecSize = [Math]::Round($intRecSize/1MB, 0)
 
    # Add the numbers to the $strEmails variable and print the result for the day 
    $strEmails += "$intSent,$intSentSize,$intRec,$intRecSize" 
    $strEmails 
 
    # Increment the From and To by one day 
    $From = $From.AddDays(1) 
    $To = $From.AddDays(1) 
} 
While ($To -lt (Get-Date))

Write-Host -ForegroundColor Green $intRecSize

$NumberofMailboxes = (Get-Mailbox).Count
$NumberofDistribGroups = (Get-DistributionGroup).Count
$thqmail01queue = (Get-Queue -Server "thq-mail01" | Get-Message).count
$thqmail02queue = (Get-Queue -Server "thq-mail02" | Get-Message).count
$batmail01queue = (Get-Queue -Server "bat-mail01" | Get-Message).count
$mail01iislogsize = "{0:N2}" -f ((Get-ChildItem -path C:\inetpub\logs\LogFiles\ -recurse | Measure-Object -property length -sum ).sum /1MB)
$mail02iislogsize = "{0:N2}" -f ((Get-ChildItem -path \\thq-mail02\c$\inetpub\logs\LogFiles\ -recurse | Measure-Object -property length -sum ).sum /1MB)

# API funkiness now:

[System.Collections.ArrayList]$ExchangeStats = @()
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
 Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB1/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue
 }