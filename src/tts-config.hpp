#pragma once

#include "script.hpp"

#include <filesystem>
#include <fmt/base.h>

namespace fs = std::filesystem;

class TTSConfig
{
private:
	sol::state lua;
	bool loaded {false};

	fs::path espeakData {};
	fs::path cache {};

public:
	TTSConfig() = default;
	TTSConfig(const fs::path &configFile)
	{
		loaded = parseConfigScript(configFile);
	}
	~TTSConfig() = default;

	operator bool() const { return loaded; }

	auto get() { return lua["config"]; }

	const fs::path &espeakDataPath() { return espeakData; }
	const fs::path &cachePath() { return cache; }

	[[nodiscard]]
	bool parseConfigScript(const fs::path &configFile);
};