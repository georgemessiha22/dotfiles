#! /usr/bin/env python3

import json
import subprocess
# import logging

output = subprocess.getoutput("sensors -j")
# lines = output.splitlines()
# stdout = "".join("".join(lines).split("  "))

try:
    stdout = json.loads(output)
    sensors = dict(stdout)
except json.decoder.JSONDecodeError as e:
#    logging.warning("could not parse subprocess")
    print("E")
    exit()


temperature = sensors["coretemp-isa-0000"]["Package id 0"]["temp1_input"]
temperature += sensors["coretemp-isa-0000"]["Core 0"]["temp2_input"]
temperature += sensors["coretemp-isa-0000"]["Core 1"]["temp3_input"]
temperature += sensors["coretemp-isa-0000"]["Core 2"]["temp4_input"]
temperature += sensors["coretemp-isa-0000"]["Core 3"]["temp5_input"]
temperature /= 5

print(str(temperature).split('.')[0])
