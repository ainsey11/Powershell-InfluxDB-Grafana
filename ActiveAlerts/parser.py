import os
import sys
import fileinput
import time

# Adding html flags to file

f=open('swapiresult.html', 'a+')
f.seek(0)
f.write('<html>

		<title> Current Alerts </title>
		<body style="color:red">
		<body>'
f.close()

for line in fileinput.FileInput("swapiresult.html",inplace=1):
    line = line.replace("}","<br>").replace('"'," ").replace("{"," ").replace(","," ").replace("ObjectName","Server Name")
    print line

f2=open('swapiresult.html', 'a')
f2.seek(0, 0)
f2.write('</body></html>'
f2.close()
