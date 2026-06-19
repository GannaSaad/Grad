from faster_whisper import WhisperModel


whisper_model = WhisperModel(
    "medium",
    device="cpu",
    compute_type="int8"
)


def transcribe_audio(audio_path: str) -> dict:
    segments, info = whisper_model.transcribe(
        audio_path,
        language=None,
        task="transcribe"
    )

    transcript = " ".join(segment.text for segment in segments).strip()

    return {
        "language": info.language,
        "transcript": transcript
    }