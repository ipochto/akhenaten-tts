#pragma once

#include <filesystem>
#include <fmt/base.h>
#include <vector>

namespace fs = std::filesystem;

using Phrase = std::tuple<int, std::string, std::string>;

auto parsePhrases(const fs::path &srcScript)
	-> std::pair<std::string, std::vector<Phrase>>;

