import json
import re
import ollama


def clean_json_response(text: str) -> str:
    text = text.strip()
    text = text.replace("```json", "").replace("```", "").strip()

    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        return match.group(0)

    return text


def extract_dental_record(transcript: str) -> dict:
    prompt = f"""
You are an expert dental assistant.

Extract these fields from the doctor's note:
1. diagnosis
2. procedure_performed
3. treatment_plan

Return ONLY valid JSON.
No explanation.
No markdown.
No extra text.

If a field is missing, return an empty string.

JSON format:
{{
  "diagnosis": "",
  "procedure_performed": "",
  "treatment_plan": ""
}}

Doctor note:
{transcript}
"""

    response = ollama.chat(
        model="gemma3:1b",
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    answer = response["message"]["content"]
    cleaned = clean_json_response(answer)

    try:
        return json.loads(cleaned)
    except Exception:
        return {
            "diagnosis": "",
            "procedure_performed": "",
            "treatment_plan": ""
        }