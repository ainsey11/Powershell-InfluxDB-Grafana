import os
import time
from influxdb.influxdb08 import InfluxDBClient

while True:

	serverlist = open("ServerNames.txt", "rw+")
	for server in serverlist:
		hostname = server
		response = os.system("ping -c 1 " + hostname)
	   # and then check the response...
		if response == 0:
		        pingstatus = 1 #up
		else:
		        pingstatus = 2 #down	
		name = server.replace("-", "")
		newname = name.rstrip('\n')
		status_json = [
		{
	            "name" : newname,
	            "columns" : ["value","sensor"],
	            "points" : [
				[pingstatus,"name"]
		   ]
	          }
		]
	        
		client = InfluxDBClient('10.159.25.13', 8086, 'dash', 'dash', 'DB2')
		client.write_points(status_json)
		print "Data sent to database for:"
		print name
		print pingstatus
		time.sleep(1)
