#include "script.hpp"
#include "tts.hpp"

#include <cxxopts.hpp>
#include <filesystem>
#include <fmt/base.h>
#include <fmt/ranges.h>
#include <string>

namespace fs = std::filesystem;

namespace {
	bool parseConfigScript(const fs::path &configFile, TTSConfig &config)
	{
		if (!fs::exists(configFile)) {
			fmt::println("The specified configuration file does not exist: \"{}\"", configFile.string());
			return false;
		}
		sol::state lua;

		lua["config"] = lua.script_file(configFile.string());
		if (!lua["config"].valid()) {
			return false;
		}
		config.lang = lua["config"]["lang"];

		const std::string espeakData = lua["config"]["espeakData"];
		config.espeakData = fs::absolute(espeakData).lexically_normal();

		if (!fs::exists(config.espeakData)) {
			fmt::println("The specified espeak-ng data folder does not exist: \"{}\"", config.espeakData.string());
			return false;
		}

		const std::string defaultVoice = lua["config"]["voices"]["default"];
		sol::table voice = lua["config"]["voices"][defaultVoice];

		config.voiceModel = fs::absolute(voice["voiceModel"].get<std::string>()).lexically_normal();
		if (!fs::exists(config.voiceModel)) {
			fmt::println("The specified voice model file does not exist: \"{}\"", config.voiceModel.string());
			return false;
		}
		config.voiceModelCfg = config.voiceModel;
		config.voiceModelCfg += ".json";
		if (!fs::exists(config.voiceModelCfg)) {
			fmt::println("The specified voice model configuration file does not exist: \"{}\"", config.voiceModelCfg.string());
			return false;
		}
		config.speakersNum = voice["speakers"];
		
		return true;
	}
} // namespace

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config)
{
	bool resultOk = true;

	auto options = cxxopts::Options{"akhenaten-tts", 
									"Tool to TTS akhenaten phrases"};
	options.add_options()
		("h,help", "Print usage")
		("i,input", "Input file with phrases to convert", cxxopts::value<fs::path>())
		("c,config", "Synthesizer configuration file", cxxopts::value<fs::path>())
		("O,output-dir", "Output directory", cxxopts::value<fs::path>());
	
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

	if (parsed.count("config")) {
		const auto configFile = fs::absolute(parsed["config"].as<fs::path>()).lexically_normal();
		if (!parseConfigScript(configFile, config)) {
			fmt::println("Unable to parse configuration file: \"{}\"", configFile.string());
			return false;
		}
	} else {
		fmt::println("Synthesizer configuration file is required (--config)");
		resultOk = false;
	}

	return resultOk;
}