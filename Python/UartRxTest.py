import numpy
import serial
import time

port     = 'com4'
baudRate = 12_000_000

uart = serial.Serial(port, baudrate = baudRate, bytesize = 8, parity = 'N', stopbits = 1)

stream = bytearray(list(numpy.arange(256)) * 4 * 4)

data = 0
t = 0

while (True):
    uart.write(stream)
    data = data + len(stream)

    if (time.time() > t + 1):
        print('%.1f Mb (%i s)' % ((data / 1_000_000), (10 * data / baudRate)))
        t = time.time()
