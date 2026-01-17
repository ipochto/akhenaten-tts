local config = {
  espeakData = "./espeak-ng-data",
  cache = "./.cache",
  voices = {},
  figures = {}
}

local voices = {
  en = {
    ["libritts"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/libritts/high/en_US-libritts-high.onnx",
      filename = "en/en_US/libritts/high/en_US-libritts-high.onnx", -- relative to cache folder
      speakers = {
        num = 904,
        male = { 2, 3, 5, 6, 7, 8, 16, 19, 20, 22, 24, 27, 28, 31, 32, 34, 35}, -- and more
        female = { 0, 1, 4, 9, 10, 11, 12, 13, 14, 15, 17, 18, 21, 23, 25, 26, 29, 30, 33 } -- and more
      }
    },
    ["arctic"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/arctic/medium/en_US-arctic-medium.onnx",
      filename = "en/en_US/arctic/medium/en_US-arctic-medium.onnx", -- relative to cache folder
      speakers = {
        num = 18,
        male = { 0, 1, 3, 6 ,7 ,8 ,9, 10, 13, 14, 17 },
        female = { 2, 4, 5, 11, 12, 15, 16 }
      }
    },
    ["bryce"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/bryce/medium/en_US-bryce-medium.onnx",
      filename = "en/en_US/bryce/medium/en_US-bryce-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["danny"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/danny/low/en_US-danny-low.onnx",
      filename = "en/en_US/bryce/danny/low/en_US-danny-low.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["hfc_male"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/hfc_male/medium/en_US-hfc_male-medium.onnx",
      filename = "en/en_US/hfc_male/medium/en_US-hfc_male-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["joe"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/joe/medium/en_US-joe-medium.onnx",
      filename = "en/en_US/joe/medium/en_US-joe-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["john"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/john/medium/en_US-john-medium.onnx",
      filename = "en/en_US/john/medium/en_US-john-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["kusal"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/kusal/medium/en_US-kusal-medium.onnx",
      filename = "en/en_US/kusal/medium/en_US-kusal-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["norman"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/norman/medium/en_US-norman-medium.onnx",
      filename = "en/en_US/norman/medium/en_US-norman-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
    ["ryan"] = {
      url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx",
      filename = "en/en_US/ryan/medium/en_US-ryan-medium.onnx", -- relative to cache folder
      speakers = {
        num = 1,
        male = { 0 },
        female = {}
      }
    },
  }
}

local figures = {
  trader = { en = { voiceModel = voices.en["arctic"], speaker = 0 }}, -- for single speaker models 'speaker' could be omitted
  hunter_ostrich = { en = { voiceModel = voices.en["arctic"], speaker = 1 }},
  immigrant = { en = { voiceModel = voices.en["arctic"], speaker = 3 }},
  emigrant = { en = { voiceModel = voices.en["arctic"], speaker = 6 }},
  recruiter = { en = { voiceModel = voices.en["arctic"], speaker = 7 }},
  barge = { en = { voiceModel = voices.en["arctic"], speaker = 8 }},
  dancer = { en = { voiceModel = voices.en["arctic"], speaker = 9 }},
  homeless = { en = { voiceModel = voices.en["arctic"], speaker = 10 }},
  marketboy = { en = { voiceModel = voices.en["arctic"], speaker = 13 }},
  engineer = { en = { voiceModel = voices.en["arctic"], speaker = 14 }},
  fireman = { en = { voiceModel = voices.en["arctic"], speaker = 17 }},
  policeman = { en = { voiceModel = voices.en["libritts"], speaker = 3 }},
  lumberjack = { en = { voiceModel = voices.en["libritts"], speaker = 5 }},
  musician = { en = { voiceModel = voices.en["libritts"], speaker = 6 }},
  taxman = { en = { voiceModel = voices.en["libritts"], speaker = 7 }},
  worker = { en = { voiceModel = voices.en["libritts"], speaker = 8 }},
  doctor = { en = { voiceModel = voices.en["libritts"], speaker = 16 }},
  water = { en = { voiceModel = voices.en["libritts"], speaker = 19 }},
  osiris = { en = { voiceModel = voices.en["libritts"], speaker = 20 }},
  ra = { en = { voiceModel = voices.en["libritts"], speaker = 22 }},
  ptah = { en = { voiceModel = voices.en["libritts"], speaker = 24 }},
  seth = { en = { voiceModel = voices.en["libritts"], speaker = 27 }},
  bast = { en = { voiceModel = voices.en["libritts"], speaker = 28 }},
  antelope_hunter = { en = { voiceModel = voices.en["libritts"], speaker = 31 }},
  scriber = { en = { voiceModel = voices.en["libritts"], speaker = 32 }},
  dentist = { en = { voiceModel = voices.en["libritts"], speaker = 34 }},
  magistrate = { en = { voiceModel = voices.en["libritts"], speaker = 35 }}
}

config.voices = voices
config.figures = figures

return config
