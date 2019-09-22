#!/usr/bin/python3
import Adafruit_DHT
import time
import os
from subprocess import PIPE, Popen
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-q", "--quiet", action="store_true", dest="verbose", default=False,
                  help="don't print output to stdout")
(options, args) = parser.parse_args()

sensor = Adafruit_DHT.DHT22
pin = 4


f = open('/home/pi/humidity.csv', 'a+')
if os.stat('/home/pi/humidity.csv').st_size == 0:
    f.write('Date,Time,Temperature,Humidity,CPU_Temp\r\n')
f.close()

while True:
    try:
        tFile = open('/sys/class/thermal/thermal_zone0/temp')
        cpu_temp = float(tFile.read())
        cpu_tempC = cpu_temp/1000
        tFile.close()
        humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)

        if humidity is not None and temperature is not None:
            if options.verbose is False:
                print("Temp={0:0.1f}*C\tHumidity={1:0.1f}%\t\tCPU Temp={2:0.1f}*C".format(temperature, humidity, cpu_tempC))
            f = open('/home/pi/humidity.csv', 'a+')
            time.sleep(1)
            f.write('{0},{1},{2:0.1f}*C,{3:0.1f}%,{4:0.1f}\r\n'.format(time.strftime('%d/%m/%y'),
                time.strftime('%H:%M'), temperature, humidity, cpu_tempC))
            time.sleep(1)
            f.close()
            time.sleep(900)
        else:
            if options.verbose is False:
                print("Failed to retrieve data from sensor")
    except:
        print("Sensor monitoring encountered exception. Closing.")
        if f.closed is False: 
            f.write("Sensor monitoring encountered exception. Closing.")
            f.close()
        if tFile.close is False:
            tFile.close()
