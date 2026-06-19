import os
import tempfile

from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware

from speech_to_text import transcribe_audio
from extract_record import extract_dental_record


app = FastAPI(title="Dentix Voice Record API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def home():
    return {"message": "Dentix Voice Record API is running"}


@app.post("/api/voice-to-record")
async def voice_to_record(file: UploadFile = File(...)):
    suffix = os.path.splitext(file.filename)[1] or ".wav"

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_audio:
        temp_audio.write(await file.read())
        audio_path = temp_audio.name

    try:
        stt_result = transcribe_audio(audio_path)
        transcript = stt_result["transcript"]

        record = extract_dental_record(transcript)

        return {
            "language": stt_result["language"],
            "diagnosis": record.get("diagnosis", ""),
            "procedure_performed": record.get("procedure_performed", ""),
            "treatment_plan": record.get("treatment_plan", "")
        }

    finally:
        if os.path.exists(audio_path):
            os.remove(audio_path)