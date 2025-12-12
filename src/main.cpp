#include "tts.hpp"
#include "script_parser.hpp"

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config);

int main(int argc, char* argv[])
{
	TTSConfig config;
	if (!parseCmdLineArguments(argc, argv, config)) {
		return 1;
	}
	const fs::path dstPath = config.outputDir / config.lang;
	if (!fs::exists(dstPath)) {
		fs::create_directories(dstPath);
	}
	TTS synth(config);

	const auto [lang, phrases] = parsePhrases(config.inputFile);
	for (const auto &[voiceId, text, key] : phrases) {
		fs::path dstFile = dstPath / key;
		dstFile += ".wav";
		fmt::println("log: Synthesizing {}", dstFile.c_str());
		synth.synthesizeWAV(text, dstFile, lang, voiceId);
	}
	return 0;
}