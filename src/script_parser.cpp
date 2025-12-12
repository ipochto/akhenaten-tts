#include "script.hpp"
#include "script_parser.hpp"


 auto parsePhrases(const fs::path &srcScript)
    -> std::pair<std::string, std::vector<Phrase>>
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
		const sol::table phrase = elem.as<sol::table>();

        const int voiceId = phrase["unit_id"].get_or(0);
        const std::string text = phrase["text"];
		const std::string key = phrase["key"];

		result.push_back({voiceId, text, key});
	}
    std::string lang = lua["source"]["lang"];
    return {lang, result};
}