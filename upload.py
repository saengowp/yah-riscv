#! /bin/python

# For use with boot.S Boot Loader

import serial
import time
import sys


with open(sys.argv[2], 'r') as f, serial.Serial(sys.argv[1], 9600) as s:
    ls = f.readlines()
    for i, l in enumerate(ls):
        s.write(l.encode('ascii'))
        time.sleep(0.1)
        if i % 100 == 0:
            print("{} of {} line transffered".format(i, len(ls)))
