#include "script.hpp"
#include "phrases_parser.hpp"


auto parsePhrases(const fs::path &srcScript)
	-> std::pair<std::string, std::vector<Phrase>>
{
	auto result = std::vector<Phrase>();

	sol::state lua;

	lua["source"] = lua.script_file(srcScript.string());
	if (!lua["source"].valid() || !lua["source"]["phrases"].valid()) {
		fmt::println("Failed to open the input script or the script is invalid");
		exit (1);       
	}
	sol::table phrases = lua["source"]["phrases"];

	for (auto &[index, elem] : phrases) {
		const sol::table phrase = elem.as<sol::table>();

		result.emplace_back(phrase["text"].get<std::string>(), 
							phrase["key"].get<std::string>(),
							phrase["unit_id"].get_or(0));
	}
	std::string lang = lua["source"]["lang"];
	return {std::move(lang), std::move(result)};
}