#pragma once

#include "tts-config.hpp"

#include <filesystem>
#include <fmt/base.h>
#include <map>
#include <piper.h>

namespace fs = std::filesystem;

namespace tts
{
	using Figure = std::string;
	using Language = std::string;

	struct SynthRequest
	{
		Figure figure;
		Language lang;
		std::string phrase;
		fs::path outputFilename;

		bool isEmpty() const { return figure.empty() || lang.empty() || phrase.empty(); }
		operator bool() const { return !isEmpty(); }
	};

	struct SynthesizerConfig
	{
		fs::path voiceModel;
		fs::path voiceModelCfg;
		fs::path espeakData;

		int speakerID {0};

		operator bool() const {
			return !voiceModel.empty() && !voiceModelCfg.empty() && !espeakData.empty();
		}
	};

	struct Synthesizer
	{
		bool initialized {false};
		piper_synthesizer *synth {nullptr};
		piper_synthesize_options options {};

		Synthesizer(const SynthesizerConfig &cfg)
		{
			synth = piper_create(cfg.voiceModel.string().c_str(),
								 cfg.voiceModelCfg.string().c_str(),
								 cfg.espeakData.string().c_str());
			if (synth) {
				options = piper_default_synthesize_options(synth);
				options.speaker_id = cfg.speakerID;
				initialized = true;
			}
		}
		~Synthesizer()
		{
			if(synth) {
				piper_free(synth);
			}
		}
		operator bool() { return synth != nullptr; }
	};
}

class TTS
{
private:

	using SynthID = std::pair<tts::Figure, tts::Language>;

	TTSConfig *config;

	std::map<SynthID, tts::Synthesizer> synthesizers;

public:
	static const int cDefaultSpeaker = 0;

	TTS(TTSConfig &cfg) : config(&cfg) {}
	~TTS() = default;

	bool synthesize(const tts::SynthRequest &task);

private:
	[[nodiscard]]
	auto makeSynthConfig(const tts::Figure &figure, const tts::Language &lang)
		-> tts::SynthesizerConfig;

	bool addSynthesizer(const SynthID &id);
	bool fetchVoice(sol::table voice);
	bool downloadFile(const std::string &url, const fs::path &dstFilename);
};
