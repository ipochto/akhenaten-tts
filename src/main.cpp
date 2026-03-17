#include "tts.hpp"

#include <iostream>

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config, tts::SynthRequest &synthRequest);

int main(int argc, char* argv[])
{
	TTSConfig config;
	tts::SynthRequest reqToSynth;

	if (!parseCmdLineArguments(argc, argv, config, reqToSynth)) {
		return 1;
	}
	TTS synth(config);
	if (!synth.synthesize(reqToSynth)) {
		std::cerr << "Failed to synthesize audio.\n";
		return 1;
	}
	return 0;
}