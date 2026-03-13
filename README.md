
# Akhenaten-TTS

Akhenaten-TTS is a text-to-speech CLI-utility that allows generating audio from text using various voice models. It supports multiple languages and characters, with automatic downloading of voice models.

## Example
```
akhenaten-tts --figure immigrant --lang en --phrase "Who the heck are you?" --output immigrant-hello-stranger.wav
```

## Usage
```
  akhenaten-tts [OPTION...]

  -h, --help        Print usage
  -f, --figure arg  Character for which the phrase is voiced. Must be specified in the configuration script (--config)
  -p, --phrase arg  Text of the voiced phrase ("The phrase must be in quotes")
  -l, --lang arg    Two-letter language code - en, ru, etc.
  -o, --output arg  Name of the output audio file. Currently only generates WAV.
  -c, --config arg  Configuration script containing descriptions of voice models and characters (default: tts-config.lua)
```

As needed, voice model files are searched in the cache; if not there, they are downloaded automatically.

Generally, you can experiment with different voices. 
First, select them [here](https://rhasspy.github.io/piper-samples/), then specify them in [tts-config.lua](src/scripts/tts-config.lua).

```lua
local voices = {
  en = { -- language of the voice model
    ["libritts"] = { -- name of the voice model
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/libritts/high/en_US-libritts-high.onnx", -- address from which to download
      filename = "en/en_US/libritts/high/en_US-libritts-high.onnx", -- where to place the downloaded model and where to look for it later (relative path)
      speakers = { -- each model can contain several speakers
        num = 904, -- number of speakers in the model
        male = { 2, 3, 5, 6, 7, 8, 16, 19, 20, 22, 24, 27, 28, 31, 32, 34, 35}, -- for reference
        female = { 0, 1, 4, 9, 10, 11, 12, 13, 14, 15, 17, 18, 21, 23, 25, 26, 29, 30, 33 } -- for reference
      }
    },
    ...
  }
  ...
}
...
local figures = {
  ["immigrant"] = {                       -- character name
    en = {                                -- language
      voiceModel = voices.en["libritts"], -- model must be defined in voices (see above)
      speaker = 3 },                      -- speaker
    ru = {}
  },
  ...
}
```

## Building

This project uses CMake for building. Ensure you have CMake 3.30 or later installed.

### Prerequisites
- CMake 3.30+
- C++20 compatible compiler (e.g., GCC, Clang, MSVC)
- Dependencies are downloaded automatically via CMake.

### Build Steps
1. Clone the repository:
```
git clone https://github.com/ipochto/akhenaten-tts.git
cd akhenaten-tts
```
2. Run the following commands:
```bash
cmake --preset linux-gcc-release
cmake --build build
```

Also presets available:\
`linux-clang-release`, `windows-msvc-release`, `windows-clang-cl-release`, `macos-clang-release`\
Check [CMakePresets.json](CMakePresets.json) for more.

The executable and resource files will be placed in `build/bin/`.