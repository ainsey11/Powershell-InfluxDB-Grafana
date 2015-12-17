Function Get-ComputerUptimeStats{
   	Param(
      	[string] $ComputerName = $env:computername,
      	[int] $NumberOfDays = 30,
      	[switch] $DebugInfo
	)
	Process {
		# Ensure the server is reachable
		if (Test-Connection -ComputerName $ComputerName -Count 1 -TimeToLive 10 -Quiet) {
		
			# Ensure that this is a Windows server that we are working with and 
			# that we have the appropriate permissions
			if (Test-Path -Path "\\$ComputerName\C$") 
			{
				# Did the user pass in an appropriate value for number of days?
				# If not, we will assume the default, 30 days.  If the value is
				# more than 365, we use 365 as the maximum.
				if ($NumberOfDays -le 0) 
				{
					$NumberOfDays = 30
					Write-Host "Defaulting to 30 days..."
				} # end if
				elseif ($NumberOfDays -gt 365) 
				{
					$NumberOfDays = 365
					Write-Host "Using maximum value (365 days)..."
				} # end elseif
				
				# If the -debug switch is set, we set the $DebugPreference variable
      			if($DebugInfo) { $DebugPreference = "Continue" }
      			
      			# We begin by assuming 100% uptime.  We will calculate effective 
      			# uptime by subtracting downtime from this value
				[timespan]$uptime = New-TimeSpan -Days $NumberOfDays
				[timespan]$downtime = 0
				$currentTime = Get-Date
				$startUpID = 6005
				$shutDownID = 6006
				$minutesInPeriod = $uptime.TotalMinutes
				$startingDate = (Get-Date).adddays(-$NumberOfDays)
				
				# Output some useful debugging info
				Write-Debug "Uptime:         $uptime"
				Write-Debug "Downtime:       $downtime"
				write-debug "Current time:   $currentTime"
				Write-Debug "Start time:     $startingDate"
				Write-Debug "Computer:       $ComputerName"
				
				# Warn the user that this could take a while
				Write-Host -NoNewline "Retrieving shutdown and startup events from "
				Write-Host "$ComputerName for the past $NumberOfDays days..."
								
				# Create a new PSSession to be used throughout the script
				$mySession = New-PSSession -ComputerName $ComputerName #-ErrorAction SilentlyContinue
				
				# Remotely retrieve the events from the system event log that 
				# occurred in the past $NumberOfDays days ago
				$events = Invoke-Command -Session $mySession -ScriptBlock {`
					param($days,$up,$down) 
					Get-EventLog `
						-After (Get-Date).AddDays(-$days) `
						-LogName System `
						-Source EventLog `
					| Where-Object { 
						$_.eventID -eq  $up `
						-OR `
						$_.eventID -eq $down }
				} -ArgumentList $NumberOfDays,$startUpID,$shutDownID -ErrorAction Stop
				
				# Create a new sorted array object
				$sortedList = New-object system.collections.sortedlist
				
				# If there are shutdown or startup events, add them to the 
				# sorted array, otherwise add zeroes to the array as placeholders
				if ($events.Count -ge 1) 
				{
					ForEach($event in $events)
					{
						$sortedList.Add( $event.timeGenerated, $event.eventID )
					} #end foreach event
				} # end if
				else 
				{ # There were no shutdown events during this time period
					$sortedList.Add( 0, 0 )
				} # end else
				
				# Count the number of system crashes
				$crashCounter = 0
				
				# Count the number of reboots
				$rebootCounter = 0
				
				# Iterate through the sorted events and add up the downtime
				For($i = 1; $i -lt $sortedList.Count; $i++ )
				{ 
					if(	`
						($sortedList.GetByIndex($i) -eq $startupID) `
						-AND `
						($sortedList.GetByIndex($i) -ne $sortedList.GetByIndex($i-1)) ) 
					{ # There was a shutdown event paired to the startup event, 
					  # thus it was a planned shutdown
					  
						# Write each event to the Debug pipeline
						Write-Debug "Shutdown `t $($sortedList.Keys[$i-1])" # Shutdown
						Write-Debug "Startup  `t $($sortedList.Keys[$i])" # Startup
						
						# Outage duration = startup timestamp - shutdown timestamp
						$duration = ($sortedList.Keys[$i] - $sortedList.Keys[$i-1])
						$downtime += $duration
						Write-Debug "           Outage duration: $duration"
						Write-Debug "           Downtime is now: $downtime"
						Write-Debug ""
						
						# Bump the reboot counter
						$rebootCounter++
					} # end if
					elseif(	`
						($sortedList.GetByIndex($i) -eq $startupID) `
						-AND `
						($sortedList.GetByIndex($i) -eq $sortedList.GetByIndex($i-1)) )
					{ 	# This was an unplanned outage (a system crash). 
						# Basically this means that we have 2 startup events 
						# with no shutdown event
												
						# Get the date from the event stating that there was an
						# unexpected shutdown
						$tempevent = Invoke-Command `
							-Session $mySession `
							-ScriptBlock {`
								param([datetime]$date, [string]$log)
								Get-EventLog `
									-Before $date.AddSeconds(1) `
									-Newest 1 `
									-LogName System `
									-Source EventLog `
									-EntryType Error `
									-ErrorAction "SilentlyContinue" | `
								Where-Object {$_.EventID -eq 6008}
							} -ArgumentList $sortedList.Keys[$i],$($eventlog.log)
						
						# The 6008 event has the data we're looking for in the 
						# ReplacementStrings property but the date portion of the
						# data has a special character that we need to remove,
						# [char]8206, so we replace it with a space.
						$lastEvent = [datetime](`
							($tempevent.ReplacementStrings[1]).Replace([char]8206, " ")`
							+ " " + $tempevent.ReplacementStrings[0])
						
						# Write each event to the Debug pipeline
						Write-Debug "CRASH    `t $lastEvent"
						Write-Debug "Startup  `t $($sortedList.Keys[$i])" # Startup
						
						# Calculate downtime = Startup timestamp - Last event 
						# written to any log timestamp
						$duration = ($sortedList.Keys[$i] - $lastEvent)
						$downtime += $duration
						Write-Debug "           Outage duration: $duration"
						Write-Debug "           Downtime is now: $downtime"
						Write-Debug ""
						
						# Bump the crash counter
						$crashCounter++						
					} # end elseif
				} #end for item
				
				# Subtract downtime from calculated uptime to get true uptime
				$uptime -= $downtime
				
			    $percentageavailable = "{0:p4}" -f ($uptime.TotalMinutes/$minutesInPeriod)
                $sanitisedpercentage = $percentageavailable.Replace("%","")
                Write-Host -Foregroundcolor Green $sanitisedpercentage
				# Kill our session to the remote computer
				Remove-PSSession -Session $mySession

      		} # end if
      		else 
      		{
      			# This usually means that you've encountered a server that 
      			# is not running Windows, like a Linux server
      			Write-Warning -Message "No access to the default share - \\$ComputerName\C`$"
      		} # end else
      	} # end if
      	else 
      	{ # This server is not online
      		Write-Warning -Message "Unable to connect - $ComputerName"
      	} #end else
    } # end Process
}

$ServerList = get-Content .\ServerNames.txt 

foreach ($server in $ServerList ){
    $Serveravailability = Get-ComputerUptimeStats -ComputerName "$Server" -NumberOfDays 30
    $seriesname = "$Server"+"percentageavailable"
    [System.Collections.ArrayList]$ServerUptime = @()
    $ServerUptime.Add($ServerAvailability)
 
# Stick the data points into the null array for required JSON format
[System.Collections.ArrayList]$nullpoints = @()
$nullpoints.Add($ServerUptime)
 
 #Build the post body
$body = @{}
$body.Add('name',"$seriesname")
$body.Add('columns',@('percentavailable'))
$body.Add('points',$nullpoints)
 
# Convert to json
$finalbody = $body | ConvertTo-Json  -Compress

# Post to API
Invoke-WebRequest -Uri "http://thq-dash01:8086/db/DB3/series?u=dash&p=dash" -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Continue    
   
 }