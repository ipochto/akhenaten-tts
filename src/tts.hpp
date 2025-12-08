#pragma once

#include <filesystem>

namespace fs = std::filesystem;

struct TTSConfig
{
	fs::path inputFile;
	fs::path outputDir;
	fs::path voiceModel;
	fs::path voiceCfg;
	fs::path espeakData;
	std::string lang;
};