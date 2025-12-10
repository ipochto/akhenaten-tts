#include "tts.hpp"

#include <cstring>
#include <fmt/base.h>
#include <fstream>

struct WAVHeader_PCM {
	char riff[4] = {'R','I','F','F'};
	uint32_t chunkSize;
	char wave[4] = {'W','A','V','E'};
	char fmt[4] = {'f','m','t',' '};
	uint32_t subchunk1Size = 16;    // PCM
	uint16_t audioFormat = 1;       // PCM (int16)
	uint16_t numChannels = 1;       // Piper = mono
	uint32_t sampleRate;
	uint32_t byteRate;
	uint16_t blockAlign = 2;        // numChannels * (bitsPerSample / 8);
	uint16_t bitsPerSample = 16;

	char data[4] = {'d','a','t','a'};
	uint32_t dataSize;

	WAVHeader_PCM(uint32_t sampleRate, uint32_t samples)
	: sampleRate (sampleRate)
	{
		byteRate = sampleRate * blockAlign;
		dataSize = samples * numChannels * bitsPerSample / 8;
		chunkSize = 36 + dataSize;			
	}
};

static inline int16_t floatToInt16(float x) {
	if (x < -1.0f) x = -1.0f;
	if (x >  1.0f) x =  1.0f;
	return static_cast<int16_t>(x * 32767.0f);
}

void TTS::synthesizeWAV(const std::string &text, fs::path &filename)
{
	std::ofstream audio_stream(filename, std::ios::binary);
	if (!audio_stream) {
		fmt::println("Failed to create output audio file: {}", filename.c_str());
		return;
	}
    audio_stream.seekp(sizeof(WAVHeader_PCM), std::ios::beg); // Reserve space for header first
	
	piper_synthesize_start(synth, text.c_str(), &options);

	piper_audio_chunk chunk;

	uint32_t sampleRate = 0;
    uint32_t samplesCount = 0;

	while (piper_synthesize_next(synth, &chunk) != PIPER_DONE) {
        if (sampleRate == 0) {
            sampleRate = chunk.sample_rate;
		}
        for (size_t i = 0; i < chunk.num_samples; i++) {
            const int16_t sample = floatToInt16(chunk.samples[i]);
            audio_stream.write(reinterpret_cast<const char*>(&sample), sizeof(int16_t));
        }
		samplesCount += chunk.num_samples;
	}
	WAVHeader_PCM header(sampleRate, samplesCount);

    // Write header at beginning
    audio_stream.seekp(0, std::ios::beg);
    audio_stream.write(reinterpret_cast<char*>(&header), sizeof(header));

    audio_stream.close();
}