#include "tts-config.hpp"

bool TTSConfig::parseConfigScript(const fs::path &configFile)
{
	if (!fs::exists(configFile)) {
		fmt::println("The specified configuration file does not exist: \"{}\"", configFile.string());
		return false;
	}

	lua["config"] = lua.script_file(configFile.string());
	if (!lua["config"].valid()) {
		fmt::println("Lua: Unable to load specified configuration file: \"{}\"", configFile.string());
		return false;
	}

	bool result {true};

	const std::string espeakDataStr = lua["config"]["espeakData"];
	espeakData = fs::absolute(espeakDataStr).lexically_normal();

	if (!fs::exists(espeakData)) {
		fmt::println("The specified espeak-ng data folder does not exist: \"{}\"", espeakData.string());
		result = false;
	}

	const std::string cacheStr = lua["config"]["cache"];
	cache = fs::absolute(cacheStr).lexically_normal();

	if (!lua["config"]["figures"].valid()) {
		fmt::println("Figures definitions are missed in the config script.");
		result = false;
	}
	if (!lua["config"]["voices"].valid()) {
		fmt::println("Voices definitions are missed in the config script.");
		result = false;
	}
	loaded = result;
	return result;
}