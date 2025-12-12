#include "script.hpp"
#include "script_parser.hpp"


std::vector<Phrase> parsePhrases(const fs::path &srcScript)
{
	auto result = std::vector<Phrase>();

	sol::state lua;

	lua["source"] = lua.script_file(srcScript);
	if (!lua["source"].valid() || !lua["source"]["phrases"].valid()) {
		fmt::println("Failed to open the input script or the script is invalid");
		exit (1);       
	}
	sol::table phrases = lua["source"]["phrases"];

	for (auto &[index, elem] : phrases) {
		sol::table phrase = elem.as<sol::table>();
		std::string text = phrase["text"];
		std::string key = phrase["key"];

		result.push_back({text, key});
	}
    return result;
}