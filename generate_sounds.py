import math
import struct
import wave

def generate_tone(filename, duration, frequency, sample_rate=44100):
    num_samples = int(duration * sample_rate)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1) # mono
        wav_file.setsampwidth(2) # 2 bytes per sample (16-bit)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            # Calculate the sample value
            t = float(i) / sample_rate
            value = int(32767.0 * math.sin(2.0 * math.pi * frequency * t))
            
            # Pack the value as a signed 16-bit integer (little-endian)
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

# Short beep (0.5 seconds, 800 Hz)
generate_tone('assets/audio/short_beep.wav', 0.5, 800)

# Long alarm (2.0 seconds, 600 Hz, simple simulation)
generate_tone('assets/audio/long_alarm.wav', 2.0, 600)

print("Sounds generated.")
