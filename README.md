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

**NB:** If your IP address is located in the Russian Federation, downloading voice models may require connecting through a VPN. Alternatively, you can download them via a browser and place them manually into the `.cache` folder. The exact path is specified by the `config.cache` and the voice model's `filename` parameters in the configuration script (see below).

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
- A C++20-compatible compiler (GCC, Clang, MSVC, or clang-cl)
- Ninja (for presets that use the Ninja generator)
- Dependencies are downloaded automatically by CMake.

### Build Steps
1. Clone the repository:
```
git clone https://github.com/ipochto/akhenaten-tts.git
cd akhenaten-tts
```
2. Configure:
```bash
cmake --preset linux-gcc-release
```
3. Build portable package:
```bash
cmake --build --preset linux-gcc-release --target portable_package --parallel
```
4. Run:
```bash
cd build/bin/portable
./akhenaten-tts --figure immigrant --lang en --phrase "Who the heck are you?" --output immigrant-hello-stranger.wav
```

### Presets
Common presets:
- Linux: `linux-gcc-debug`, `linux-gcc-release`, `linux-clang-debug`, `linux-clang-release`
- macOS: `macos-clang-debug`, `macos-clang-release`
- Windows: `windows-msvc-debug`, `windows-msvc-release`, `windows-clang-cl-debug`, `windows-clang-cl-release`

See all available presets in [CMakePresets.json](CMakePresets.json).

### Portable package layout
The `portable_package` target creates a self-contained runtime in `build/bin/portable`:
- `akhenaten-tts` or `akhenaten-tts.exe`
- `tts-config.lua`
- `espeak-ng-data/`
- bundled runtime libraries:
  - Linux/macOS: `build/bin/portable/lib/`
  - Windows: `build/bin/portable/`

Voice models are downloaded on demand to the cache path defined in `tts-config.lua`.
