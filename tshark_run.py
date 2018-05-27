#!/usr/bin/env python3
import subprocess
args = ("/usr/sbin/tshark", "-i","enp4s0")
#Or just:
#args = "bin/bar -csomefile.xml -d text.txt -r aString -f anotherString".split()
#popen = subprocess.Popen(args, stdout=subprocess.PIPE)
popen = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
popen.wait()
out,err = pipe.communicate()
result = out.decode()
output = popen.stdout.read()
print(output,result)
