#include "tts.hpp"

#include <cxxopts.hpp>
#include <filesystem>
#include <fmt/base.h>
#include <fmt/ranges.h>
#include <string>

namespace fs = std::filesystem;

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config)
{
	bool resultOk = true;

	auto options = cxxopts::Options{"akhenaten-tts", 
									"Tool to TTS akhenaten phrases"};
	options.add_options()
		("h,help", "Print usage")
		("i,input", "Input file with phrases to convert", cxxopts::value<fs::path>())
		("O,output-dir", "Output directory", cxxopts::value<fs::path>())
		("l,lang", "Language suffix(en, ru, cn, etc...)", cxxopts::value<std::string>())
		("v,voice", "Path to voice model file (.onnx)", cxxopts::value<fs::path>())
		("e,espeak-data", "Path to espeak-ng data dir", cxxopts::value<fs::path>());
	
	options.allow_unrecognised_options();
	const auto parsed = options.parse(argc, argv);
	
	const auto unmatched = parsed.unmatched();
	if (!unmatched.empty()) {
		fmt::println("Unrecognized command line argument(s): {}", unmatched);
		fmt::println("{}", options.help());
		return false;
	}
	if (parsed.count("help") || argc == 1) {
		fmt::println("{}", options.help());
		exit(0);
	}
	if (parsed.count("input")) {
		const auto inputFile = fs::absolute(parsed["input"].as<fs::path>()).lexically_normal();
		if (fs::exists(inputFile)) {
			config.inputFile = inputFile;
		} else {
			fmt::println("The specified input file does not exist: \"{}\"", inputFile.string());
			return false;
		}
	} else {
		fmt::println("Input file is required (--input)");
		resultOk = false;
	}

	if (parsed.count("output-dir")) {
		config.outputDir = fs::absolute(parsed["output-dir"].as<fs::path>()).lexically_normal();
	} else {
		fmt::println("Output dir is required (--output-dir)");
		resultOk = false;
	}

	if (parsed.count("lang")) {
		config.lang = parsed["lang"].as<std::string>();
	} else {
		fmt::println("Lang is required (--lang)");
		resultOk = false;
	}

	if (parsed.count("voice")) {
		const auto voiceFile = fs::absolute(parsed["voice"].as<fs::path>()).lexically_normal();
		if (fs::exists(voiceFile)) {
			config.voiceModel = voiceFile;
		} else {
			fmt::println("The specified voice model file does not exist: \"{}\"", voiceFile.string());
			return false;
		}
		const auto voiceCfgFile = fs::path(voiceFile.string() + ".json");
		if (fs::exists(voiceCfgFile)) {
			config.voiceModelCfg = voiceCfgFile;
		} else {
			fmt::println("The specified voice model cfg file does not exist: \"{}\"", voiceCfgFile.string());
			return false;
		}
	} else {
		fmt::println("Voice model file is required (--voice)");
		resultOk = false;
	}

	if (const auto espeakDataDir 
			= fs::absolute(parsed.count("espeak-data") ? parsed["espeak-data"].as<fs::path>()
													   : config.espeakData).lexically_normal();
		fs::exists(espeakDataDir)) {

		config.espeakData = espeakDataDir;

	} else {
		fmt::println("espeak-ng data directory is unavailable: \"{}\"",
					 espeakDataDir.lexically_normal().string());
		return false;
	}
	return true;
}