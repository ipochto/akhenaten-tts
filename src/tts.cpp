#include "tts.hpp"

#include <cstring>
#include <fmt/base.h>
#include <fstream>
#include <cpr/session.h>

namespace
{
	template <typename Fn>
	bool saveToWAV(Fn&& getNextChunk, const fs::path &filename)
	{
		struct WAVHeader_PCM {
			char riff[4] = {'R','I','F','F'};
			uint32_t chunkSize;
			char wave[4] = {'W','A','V','E'};
			char fmt[4] = {'f','m','t',' '};
			uint32_t subchunk1Size = 16;    // PCM
			uint16_t audioFormat = 1;       // PCM (int16)
			uint16_t numChannels = 1;       // Piper = mono
			uint32_t sampleRate;
			uint32_t byteRate;
			uint16_t blockAlign = 2;        // numChannels * (bitsPerSample / 8);
			uint16_t bitsPerSample = 16;

			char data[4] = {'d','a','t','a'};
			uint32_t dataSize;

			WAVHeader_PCM(uint32_t sampleRate, uint32_t samples)
			: sampleRate (sampleRate)
			{
				byteRate = sampleRate * blockAlign;
				dataSize = samples * numChannels * bitsPerSample / 8;
				chunkSize = 36 + dataSize;
			}
		};

		auto  floatToInt16 = [](float x) -> int16_t {
			if (x < -1.0f) x = -1.0f;
			if (x >  1.0f) x =  1.0f;
			return static_cast<int16_t>(x * 32767.0f);
		};

		std::ofstream audio_stream(filename, std::ios::binary);
		if (!audio_stream) {
			fmt::println("Failed to create output audio file: {}", filename.string());
			return false;
		}
		audio_stream.seekp(sizeof(WAVHeader_PCM), std::ios::beg); // Reserve space for header first

		uint32_t sampleRate = 0;
		uint32_t samplesCount = 0;

		do {
			const auto &[done, data] = getNextChunk();
			if (done) {
				break;
			}
			if (sampleRate == 0) {
				sampleRate = data.sample_rate;
			}
			for (size_t i = 0; i < data.num_samples; i++) {
				const int16_t sample = floatToInt16(data.samples[i]);
				audio_stream.write(reinterpret_cast<const char*>(&sample), sizeof(int16_t));
			}
			samplesCount += data.num_samples;
		} while(true);

		WAVHeader_PCM header(sampleRate, samplesCount);

		// Write header at beginning
		audio_stream.seekp(0, std::ios::beg);
		audio_stream.write(reinterpret_cast<char*>(&header), sizeof(header));
		audio_stream.close();

		return true;
	}
} // namespace

auto  TTS::makeSynthConfig(const tts::Figure &figure, const tts::Language &lang)
	-> tts::SynthesizerConfig
{
	auto result = tts::SynthesizerConfig();

	auto figureCfg = config->get()["figures"][figure];

	if (!figureCfg.valid()) {
		fmt::println("Unknown figure: \"{}\"", figure);
		return result;
	}

	auto voiceCfg = figureCfg[lang];

	if (!voiceCfg.valid()) {
		fmt::println("Undefined language \"{}\" for figure \"{}\".", lang, figure);
		return result;
	}

	result.voiceModel = (config->cachePath() / voiceCfg["voiceModel"]["filename"].get<std::string>()).lexically_normal();

	if (auto speakerID = voiceCfg["speaker"]; speakerID.valid()) {
		result.speakerID = speakerID;
	}

	result.voiceModelCfg = result.voiceModel;
	result.voiceModelCfg += ".json";

	result.espeakData = config->espeakDataPath();

	return result;
}

bool TTS::addSynthesizer(const SynthID &id)
{
	auto &[figure, lang] = id;

	auto synthCfg = makeSynthConfig(figure, lang);

	if (!synthCfg) {
		fmt::println("Unable get synthesizer's config for [figure: \"{}\", language: \"{}\"]",
					 figure, lang);
		return false;
	}
	if (!fs::exists(synthCfg.voiceModel) || !fs::exists(synthCfg.voiceModelCfg)) {

		if (!fetchVoice(config->get()["figures"][figure][lang]["voiceModel"])) {
			fmt::println("Unable fetch voice model files for [figure: \"{}\", language: \"{}\"]",
						 figure, lang);
			return false;
		}
	}
	auto [insertedIt, result] = synthesizers.emplace(id, tts::Synthesizer(synthCfg));
	if (!result) {
		fmt::println("Unable make synthesizer for [figure: \"{}\", language: \"{}\"]",
					 figure, lang);
		return false;
	}
	return true;
}

bool TTS::fetchVoice(sol::table voice)
{
	const std::string url = voice["url"];
	const auto voiceModelPath = (config->cachePath() / voice["filename"].get<std::string>())
								.lexically_normal();

	if (!downloadFile(url, voiceModelPath)) {
		fmt::println("Unable to get voice model file: \"{}\"", voiceModelPath.string());
		return false;
	}

	auto voiceModelCfgPath = voiceModelPath;
	voiceModelCfgPath += ".json";

	if (!downloadFile(url + ".json", voiceModelCfgPath)) {
		fmt::println("Unable to get voice model config file: \"{}\"", voiceModelCfgPath.string());
		return false;
	}
	return true;
}

bool TTS::downloadFile(const std::string &url, const fs::path &dstFilename)
{
	const auto parent = dstFilename.parent_path();
	if (!parent.empty()) {
		std::error_code ec;
		fs::create_directories(parent, ec);
		if (ec) {
			fmt::println("Unable to create directory \"{}\": {}", parent.string(), ec.message());
			return false;
		}
	}
	if (fs::exists(dstFilename)) {
		fs::remove(dstFilename);
	}
	cpr::Session session;
	session.SetUrl(cpr::Url{url});
	session.SetRedirect(cpr::Redirect{true});
	session.SetConnectTimeout(cpr::ConnectTimeout{10'000});
	session.SetTimeout(cpr::Timeout{120'000});

	std::ofstream dstFile(dstFilename, std::ios::binary);
	if (!dstFile) {
		fmt::println("Unable to open output file \"{}\"", dstFilename.string());
		return false;
	}
	session.SetWriteCallback(cpr::WriteCallback{
		[&dstFile](std::string_view data, intptr_t /*userdata*/) -> bool
		{
			if (!dstFile.good()) {
				return false;
			}
			dstFile.write(data.data(), static_cast<std::streamsize>(data.size()));
			if (!dstFile.good()) {
				return false;
			}
			return true;
		}
	});

	cpr::Response response = session.Get();

	dstFile.close();

	if (response.error.code != cpr::ErrorCode::OK) {
		fs::remove(dstFilename);
		fmt::println("Unable to download \"{}\", error: {}", url, response.error.message);
		return false;
	}
	if (response.status_code < 200 || response.status_code >= 300) {
		fs::remove(dstFilename);
		fmt::println("Unable to download \"{}\": HTTP error: {}", url, response.status_code);
		return false;
	}
	if (!dstFile.good()) {
		fs::remove(dstFilename);
		fmt::println("Failed to flush/close output file: \"{}\"", dstFilename.string());
		return false;
	}
	return true;
}

bool TTS::synthesize(const tts::SynthRequest &task)
{
	const auto synthID = SynthID(task.figure, task.lang);

	auto synthIt = synthesizers.find(synthID);
	if (synthIt == synthesizers.end()) {
		if (!addSynthesizer(synthID)) {
			return false;
		}
		synthIt = synthesizers.find(synthID);
	}
	auto &[ID, synthesizer] = *synthIt;

	if (!synthesizer) {
		fmt::println("Piper synthesizer for figure: {}, lang: {} is not initialized",
					 task.figure, task.lang);
		return false;
	}
	
	if (int result = piper_synthesize_start(synthesizer.synth,
											task.phrase.c_str(),
											&synthesizer.options);
		result != PIPER_OK) {

		fmt::println("Unable to start piper synthesizer, error code {}", result);
		return false;
	}
	piper_audio_chunk chunk;

	auto synth = synthesizer.synth;
	auto synthesizeChunk = [&]()
		-> std::pair<bool, piper_audio_chunk&>
	{
		bool result = piper_synthesize_next(synth, &chunk) != PIPER_DONE;
		return {result, chunk};
	};
	return saveToWAV(synthesizeChunk, task.outputFilename);
}
