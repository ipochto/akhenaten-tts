#pragma once

// sol2 configuration section:
#define SOL_ALL_SAFETIES_ON 1
#define SOL_LUA_VERSION 501
#define SOL_ENABLE_INTEROP 1 // MUST be defined to use interop features
// end of configuration section

#include <sol/sol.hpp>

#include <filesystem>
#include <fmt/base.h>
#include <vector>

namespace fs = std::filesystem;

using Phrase = std::pair<std::string, std::string>;

std::vector<Phrase> parsePhrases(const fs::path &srcScript);
