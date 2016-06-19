Powershell input into grafana
======================
Building a simple monitoring solution for a Windows network using Grafana (front-end) and InfluxDB (back-end).

## Notes

This is very basic at the min, enjoy what documentation I've managed to do
work through each script and check the variables, I've put a # where they should be.

Launch them via scheduled tasks, I'll make a job engine for it all soon.

for the grafana / influxdb side -

    wget https://grafanarel.s3.amazonaws.com/builds/grafana_2.1.3_amd64.deb
	     sudo apt-get install -y adduser libfontconfig
	     sudo dpkg -i grafana_2.1.3_amd64.deb

	Add to /etc/apt/sources.list :
	deb https://packagecloud.io/grafana/stable/debian/ wheezy main

	then:
	curl https://packagecloud.io/gpg.key | sudo apt-key add -
	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install grafana

- Start Grafana Server:
	    sudo service grafana-server start

- Install InfluxDB on the same host
	    wget http://get.influxdb.org.s3.amazonaws.com/influxdb_0.8.9_amd64.deb
	    sudo dpkg -i influxdb_0.8.9_amd64.deb
- Start InfluxDB
	    sudo /etc/init.d/influxdb start

- Create a New database on influxDB
	    go to influxDB management page (<serverip>:8086
	    log in root / root
	    create database called DB01
	    create user for database (non admin) with username grafana and password grafana

 - Log into Grafana (<serverip>:3000
	    Set up a new data source
	    Name = DB01
	    Type = InfluxDB 0.8.X
	    URL = 127.0.0.1:8086
	    Access = Proxy
	Database = DB01
	User = grafana
	Password = grafana

 - Save and test connection


then create more databases as per my scripts, then make the graphs as you want them, when I get a few mins i'll export the xml from my setup.
