import numpy
import serial
import scipy.io.wavfile as wavfile

port         = 'com4'
baudRate     = 12_000_000
symbolRate   = 400_000
blockSize    = 3
scale        = 2 ** 20
chunkSize    = 20_000
updatePeriod = 1000

uart = serial.Serial(port, baudrate = baudRate, bytesize = 8, parity = 'N', stopbits = 1)

print('Generating signal...')

t = numpy.arange(0, 60, 1. / symbolRate)
wave = numpy.sin(t * 1000. * 2. * numpy.pi) * (2 ** 20) + (2 ** 23)
print(wave.size)
print(wave.ptp())

print('Generating bytestream...')

wave = wave.astype(numpy.int)

w1 =  wave        & 0xFF
w2 = (wave >>  8) & 0xFF
w3 = (wave >> 16) & 0xFF

binWave = list(numpy.reshape(numpy.vstack((w1, w2, w3)).T, (-1)))
stream = bytearray(binWave)

print('Broadcasting...')

data = 0

streamLength = len(stream)
extendedStream = numpy.concatenate((stream, stream[0 : chunkSize - 1]))

while (True):
    position = data % streamLength

    uart.write(extendedStream[position : position + chunkSize])

    data = data + chunkSize

    if ((data / chunkSize) % updatePeriod == 0):
        print('[%i s] Uploaded: %.1f Mb' % (10 * data / baudRate, data / 1_000_000))
