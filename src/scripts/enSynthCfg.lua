local config = {
    lang = "en",
    espeakData = "espeak-ng-data",
    voices = {
        default = "arctic",
        arctic = {
            voiceModel = "voices/en/en_US/arctic/medium/en_US-arctic-medium.onnx",
            speakers = 18
        }
    }
}

return config