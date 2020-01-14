import numpy
import serial
import scipy.signal as signal
import scipy.ndimage.interpolation as interpolation
import scipy.io.wavfile as wavfile

port          = 'com4'
filename      = '..\Data\Messiah.wav'
#filename      = '..\Data\WhenJohnnyComes.wav'
#filename      = '..\Data\TallShips.wav'

baudRate      = 12_000_000
blockSize     = 3
scale         = 2 ** 21     # 75 kHz frequency deviation
lowPassCutOff = 15_000
lowPassOrder  = 11
chunkSize     = 20_000
updatePeriod  = 1000

uart = serial.Serial(port, baudrate = baudRate, bytesize = 8, parity = 'N', stopbits = 1)

print('Loading file \'%s\'...' % filename)

audioRate, wave = wavfile.read(filename)

print('Low-pass filtering...')

b, a = signal.butter(lowPassOrder, lowPassCutOff / (audioRate / 2.0), 'low')

waveL = signal.filtfilt(b, a, wave[:, 0].astype(numpy.float))
waveR = signal.filtfilt(b, a, wave[:, 1].astype(numpy.float))

print('Resampling...')

symbolRate = baudRate / (blockSize * 10)
resampleScale = symbolRate / audioRate
waveL = interpolation.zoom(waveL, zoom = resampleScale, order = 3)
waveR = interpolation.zoom(waveR, zoom = resampleScale, order = 3)

print('Normalizing...')

minL = numpy.abs(waveL.min())
maxL = numpy.abs(waveL.max())
minR = numpy.abs(waveR.min())
maxR = numpy.abs(waveR.max())

div = max(minL, maxL, minR, maxR)

waveL = waveL / div
waveR = waveR / div

print('Multiplexing...')

t = numpy.arange(waveL.shape[0]) / symbolRate
s19 = numpy.sin(2.0 * numpy.pi * 19_000 * t)
s38 = numpy.sin(2.0 * numpy.pi * 38_000 * t)

wave = 0.9 * ((waveL + waveR) / 2.0 + s38 * (waveL - waveR) / 2.0) + 0.1 * s19

print('Signal conditioning...')

wave = wave / max(numpy.abs(wave.min()), numpy.abs(wave.max()))
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
