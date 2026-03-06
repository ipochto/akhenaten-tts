#pragma once

#include "lua/runtime.hpp"

#include <filesystem>
#include <fmt/base.h>

namespace fs = std::filesystem;

class TTSConfig
{
private:
	LuaRuntime luaRuntime;
	LuaSandbox lua;
	inline static const fs::path allowAnyPath{"/"};
	
	bool loaded {false};

	fs::path espeakData {};
	fs::path cache {};

public:
	TTSConfig() 
		: luaRuntime(lua::memory::cDefaultMemLimit),
		  lua(luaRuntime, LuaSandbox::Presets::Minimal, fs::current_path(), {allowAnyPath})
	{}
	
	TTSConfig(const fs::path &configFile)
		: luaRuntime(lua::memory::cDefaultMemLimit),
		  lua(luaRuntime, LuaSandbox::Presets::Minimal, fs::current_path(), {allowAnyPath})
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