import numpy
import serial
import scipy.signal as signal
import scipy.ndimage.interpolation as interpolation
import scipy.io.wavfile as wavfile

#filename      = '..\Data\Messiah.wav'
#filename      = '..\Data\WhenJohnnyComes.wav'
filename      = '..\Data\TallShips.wav'

port         = 'com4'
baudRate     = 12_000_000
blockSize    = 3
scale        = 2 ** 21     # 75 kHz frequency deviation
chunkSize    = 100_000
updatePeriod = 250

uart = serial.Serial(port, baudrate = baudRate, bytesize = 8, parity = 'N', stopbits = 1)

print('Loading file \'%s\'...' % filename)

audioRate, wave = wavfile.read(filename)
wave = numpy.mean(wave, axis = 1)

print('Resampling...')

symbolRate = baudRate / (blockSize * 10)
resampleScale = symbolRate / audioRate
wave = interpolation.zoom(wave, zoom = resampleScale, order = 3)

print('Signal conditioning...')

wave = wave / numpy.abs(wave).max()
wave = (wave * 0.5) * scale + (2. ** (8 * blockSize - 1))

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
