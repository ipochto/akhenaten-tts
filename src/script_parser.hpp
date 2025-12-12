#pragma once

#include <filesystem>
#include <fmt/base.h>
#include <vector>

namespace fs = std::filesystem;

using Phrase = std::pair<std::string, std::string>;

std::vector<Phrase> parsePhrases(const fs::path &srcScript);
