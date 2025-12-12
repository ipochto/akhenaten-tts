#pragma once

#include <filesystem>
#include <fmt/base.h>
#include <piper.h>

namespace fs = std::filesystem;

struct TTSConfig
{
	fs::path inputFile;
	fs::path outputDir;
	std::string lang;
	fs::path voiceModel;
	fs::path voiceModelCfg;
	fs::path espeakData;
	int speakersNum {1};
};

class TTS
{
public:
	static const int cDefaultSpeaker = 0;

	TTS(const TTSConfig &config)
	{
		synth = piper_create(config.voiceModel.c_str(), 
							 config.voiceModelCfg.c_str(), 
							 config.espeakData.c_str());
		if (!synth) {
			fmt::println("Failed to create Piper synthesizer");
			exit (1);
		}
		options = piper_default_synthesize_options(synth);
		speakersNum = config.speakersNum;

		language = config.lang;
	}

	~TTS()
	{
		piper_free(synth);
	}

	void synthesizeWAV(const std::string &text,
					   const fs::path &filename,
					   const std::string &reqLang,
					   int speakerId = cDefaultSpeaker);
	

private:
	void changeSpeaker(int speakerId)
	{ 
		options.speaker_id = speakerId < speakersNum ? speakerId : speakerId % speakersNum;
	}

private:
	piper_synthesizer *synth;
	piper_synthesize_options options {};

	std::string language;
	int speakersNum = 1;
};


