#include "tts.hpp"
#include "script_parser.hpp"

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config);

int main(int argc, char* argv[])
{
	TTSConfig config;
	if (!parseCmdLineArguments(argc, argv, config)) {
		return 1;
	}
	if (!fs::exists(config.outputDir)) {
		fs::create_directories(config.outputDir);
	}
	TTS synth(config);

	for (const auto &[text, key] : parsePhrases(config.inputFile)) {
		fs::path dstFile = config.outputDir / key;
		dstFile += ".wav";
		synth.synthesizeWAV(text, dstFile);
	}

	return 0;
}