#include "script.hpp"
#include "tts.hpp"

#include <cxxopts.hpp>
#include <filesystem>
#include <fmt/base.h>
#include <fmt/ranges.h>
#include <string>

namespace fs = std::filesystem;

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config, tts::SynthRequest &synthRequest)
{
	bool resultOk = true;

	auto options = cxxopts::Options{"akhenaten-tts", 
									"Tool to TTS akhenaten phrases"};
	options.add_options()
		("h,help", "Print usage")
		("f,figure", "Character for whom speech is synthesized.", cxxopts::value<std::string>())
		("p,phrase", "Phrase for which we synthesize speech.", cxxopts::value<std::string>())
		("l,lang", "The phrase's language.", cxxopts::value<std::string>())
		("o,output", "Output audio filename.", cxxopts::value<fs::path>())
		("c,config", "Synthesizer configuration file.", cxxopts::value<fs::path>()->default_value("tts-config.lua"));
	
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

	if (parsed.count("figure")) {
		synthRequest.figure = parsed["figure"].as<std::string>();
	} else {
		fmt::println("Figure/character is required (--figure)");
		resultOk = false;
	}

	if (parsed.count("phrase")) {
		synthRequest.phrase = parsed["phrase"].as<std::string>();
	} else {
		fmt::println("Text phrase to synthesize is required (--phrase)");
		resultOk = false;
	}

	if (parsed.count("output")) {
		synthRequest.outputFilename = fs::absolute(parsed["output"].as<fs::path>()).lexically_normal();
	} else {
		fmt::println("Output filename is required (--output)");
		resultOk = false;
	}

	if (parsed.count("lang")) {
		synthRequest.lang = parsed["lang"].as<std::string>();
	} else {
		fmt::println("Language is required (--lang)");
		resultOk = false;
	}

	const auto configFile = fs::absolute(parsed["config"].as<fs::path>()).lexically_normal();
	if (!config.parseConfigScript(configFile)) {
		fmt::println("Unable to parse configuration file: \"{}\"", configFile.string());
		return false;
	}
	return resultOk;
}