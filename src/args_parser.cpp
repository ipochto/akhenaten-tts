#include "tts.hpp"

#include <cxxopts.hpp>
#include <filesystem>
#include <fmt/base.h>
#include <fmt/ranges.h>
#include <string>

namespace fs = std::filesystem;

void parseCmdLineArguments(int argc, char* argv[], TTSConfig &config)
{
	auto options = cxxopts::Options{"akhenaten-tts", 
									"Tool to TTS akhenaten phrases"};
	options.add_options()
		("h,help", "Print usage")
		("i,input", "Input file with phrases to convert", cxxopts::value<fs::path>())
		("O,output-dir", "Output directory", cxxopts::value<fs::path>())
		("l,lang", "Language suffix(en, ru, cn, etc...)", cxxopts::value<std::string>())
		("v,voice", "Path to voice model file (.onnx)", cxxopts::value<fs::path>())
		("c,voice-cfg", "Path to voice model config file (.json)", cxxopts::value<fs::path>())
		("e,espeak-data", "Path to espeak-ng data dir", cxxopts::value<fs::path>());
	
	options.allow_unrecognised_options();
	const auto parsed = options.parse(argc, argv);
	
	const auto unmatched = parsed.unmatched();
	if (!unmatched.empty()) {
		fmt::println("Unrecognized command line argument(s): {}", unmatched);
		fmt::println("{}", options.help());
		exit(1);
	}	
	if (parsed.count("help")) {
		fmt::println("{}", options.help());
		exit(0);
	}
	if (parsed.count("input")) {
		const auto inputFile = fs::absolute(parsed["input"].as<fs::path>()).lexically_normal();
		if (fs::exists(inputFile)) {
			config.inputFile = inputFile;
		} else {
			fmt::println("The specified input file does not exist: \"{}\"", inputFile.string());
			exit(1);
		}
	} else {
		fmt::println("Input file is required (--input)");
	}

	if (parsed.count("output")) {
		config.outputDir = fs::absolute(parsed["output"].as<fs::path>()).lexically_normal();
	} else {
		fmt::println("Output dir is required (--output)");
	}

	if (parsed.count("lang")) {
		config.lang = parsed["lang"].as<std::string>();
	} else {
		fmt::println("Lang is required (--lang)");
	}

	if (parsed.count("voice")) {
		const auto voiceFile = fs::absolute(parsed["voice"].as<fs::path>()).lexically_normal();
		if (fs::exists(voiceFile)) {
			config.voiceModel = voiceFile;
		} else {
			fmt::println("The specified voice model file does not exist: \"{}\"", voiceFile.string());
			exit(1);
		}
	} else {
		fmt::println("Voice model file is required (--voice)");
	}

	if (parsed.count("voice-cfg")) {
		const auto voiceCfgFile = fs::absolute(parsed["voice-cfg"].as<fs::path>()).lexically_normal();
		if (fs::exists(voiceCfgFile)) {
			config.voiceCfg = voiceCfgFile;
		} else {
			fmt::println("The specified voice model file does not exist: \"{}\"", voiceCfgFile.string());
			exit(1);
		}
	} else {
		fmt::println("Voice model configuration file is required (--voice-cfg)");
	}

	if (parsed.count("espeak-data")) {
		const auto espeakDataDir = fs::absolute(parsed["espeak-data"].as<fs::path>()).lexically_normal();
		if (fs::exists(espeakDataDir)) {
			config.espeakData = espeakDataDir;
		} else {
			fmt::println("espeak-ng data directory is unavailable: \"{}\"", espeakDataDir.string());
			exit(1);
		}
	} else {
		fmt::println("espeak-ng data directory is required (--espeak-data)");
	}
}