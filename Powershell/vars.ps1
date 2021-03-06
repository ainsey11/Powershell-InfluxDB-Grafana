# ------------------------------------------------------------------------
# NAME: Vars.ps1
# WEB : https://ainsey11.com
#
#
# COMMENTS: This script is for use in all the powershell scripts. it contains the list of variables 
# that are used within the scripts.
#
# ------------------------------------------------------------------------

#Main API URL, in format http://<servername>:<port>/db/<dbname>/series?u=<username>/&p=<password>

$global:DashboardServer = "http:/#:8086/db/DB1/series?u=#&p=#"

#WSUS Server Settings:
$global:WSUSServer = "#" #Server Name
$global:WSUSServerPort = "8530" #Port WSUS is accepting communications on
$global:WSUSServerDataDrive = "D:" #Drive letter that WSUS data is stored on

#Exchange Server Settings:
$global:ExchangeServer1 = "#" # Servername
$global:ExchangeServer2 = "#" # Servername
$global:ExchangeServer3 = "#" # Servername

#SQL Server Settings:
$global:SQLServer1 = "#" 
$global:SQLServer2 = "#"
$global:SQLServer3 = "#"

#RDS Server Settings:
$global:RDSServer = "#"

#VDI / Vcenter Server Settings:
$global:VcenterServer = "thq-vcc01"
$global:VDIServer1 = ""
$global:VDIServer2 = ""