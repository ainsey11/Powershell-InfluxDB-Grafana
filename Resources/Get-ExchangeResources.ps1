# Simple one, gets CPU and RAM usage of the mail servers

$thqmail01cpu = Get-Counter -ComputerName "thq-mail01" '\Processor(_Total)\% Processor Time'
$thqmail02cpu = Get-Counter -ComputerName "thq-mail02" '\Processor(_Total)\% Processor Time'
$batmail01cpu = Get-Counter -ComputerName "bat-mail01" '\Processor(_Total)\% Processor Time'
$thqmail01ram = Get-Counter -ComputerName "thq-mail01" '\Processor(_Total)\% Processor Time'
$thqmail02ram = Get-Counter -ComputerName "thq-mail02" '\Processor(_Total)\% Processor Time'
$batmail01ram = Get-Counter -ComputerName "bat-mail01" '\Processor(_Total)\% Processor Time'

(get-Counter -ListSet memory).paths