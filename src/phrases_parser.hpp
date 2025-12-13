#pragma once

#include <filesystem>
#include <fmt/base.h>
#include <vector>

namespace fs = std::filesystem;

struct Phrase
{
	std::string text;
	std::string key;
	int voiceId = 0;
	Phrase() = default;
	explicit Phrase(std::string &&text, std::string &&key, int voiceId)
		: text(std::move(text)), key(std::move(key)), voiceId(voiceId) {};
};

auto parsePhrases(const fs::path &srcScript)
	-> std::pair<std::string, std::vector<Phrase>>;

