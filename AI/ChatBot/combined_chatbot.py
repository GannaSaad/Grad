# -*- coding: utf-8 -*-
"""
Dentix Booking Chatbot - CMD/Windows version

Put firebase-key.json in the same folder, then run:
python dentix_chatbot_cmd_clean.py
"""

import json
import re
from datetime import datetime, timedelta

import torch
import firebase_admin
from firebase_admin import credentials, firestore
from rapidfuzz import process
import ollama

import os
import sys

os.system("chcp 65001 > nul")
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stdin.reconfigure(encoding="utf-8")
except Exception:
    pass

FIREBASE_KEY_PATH = "firebase-key.json"
DEBUG_AI_OUTPUT = False

print("Using Ollama model...")
OLLAMA_MODEL = "llama3.2:1b"

cred = credentials.Certificate(FIREBASE_KEY_PATH)
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()
print("Firebase connected")
def test_firebase_connection():
    try:
        test_data = {
            "test": True,
            "message": "Firebase connection works",
            "created_at": datetime.now().strftime("%Y-%m-%d %I:%M %p")
        }

        doc_ref = db.collection("connection_test").add(test_data)

        print("✅ Firebase write test passed")
        print("Test document ID:", doc_ref[1].id)

        docs = db.collection("connection_test").limit(1).stream()
        for doc in docs:
            print("✅ Firebase read test passed")
            print(doc.to_dict())

        return True

    except Exception as e:
        print("❌ Firebase connection failed")
        print("Error:", e)
        return False


test_firebase_connection()

def get_doctors():
    doctors = []
    for doc in db.collection("doctors").stream():
        data = doc.to_dict()
        if data.get("active") is True:
            name = str(data.get("name", "")).strip()
            if not name:
                continue
            if not name.lower().startswith("dr "):
                name = "Dr " + name.title()
            doctors.append(name)
    return sorted(list(set(doctors)))


def time_sort_key(time_str):
    try:
        return datetime.strptime(str(time_str).strip(), "%I:%M %p").time()
    except Exception:
        return datetime.max.time()


def get_available_slots(date=None, doctor_name=None):
    slots = []
    seen = set()

    now = datetime.now()
    today = now.date()

    for doc in db.collection("available_slots").stream():
        data = doc.to_dict()
        data["slot_id"] = doc.id

        if data.get("is_available") is not True:
            continue

        try:
            slot_date = datetime.strptime(
                data["date"],
                "%Y-%m-%d"
            ).date()

            slot_time = datetime.strptime(
                data["time"],
                "%I:%M %p"
            ).time()

            slot_datetime = datetime.combine(
                slot_date,
                slot_time
            )

        except Exception:
            continue

        # remove old dates
        if slot_date < today:
            continue

        # remove passed hours today
        if slot_datetime <= now:
            continue

        if date and data.get("date") != date:
            continue

        if doctor_name and data.get("doctor_name") != doctor_name:
            continue

        unique_key = (
            data.get("doctor_name"),
            data.get("date"),
            data.get("time")
        )

        if unique_key in seen:
            continue

        seen.add(unique_key)
        slots.append(data)

    return sorted(
        slots,
        key=lambda x: (
            x["date"],
            time_sort_key(x["time"])
        )
    )



def get_available_dates_for_doctor(doctor_name):
    slots = get_available_slots(doctor_name=doctor_name)
    return sorted(list(set(slot["date"] for slot in slots)))


def mark_slot_booked(slot_id):
    db.collection("available_slots").document(slot_id).update({"is_available": False})


def save_booking(patient_name, doctor_name, date, time, slot_id):
    now = datetime.now()
    booking_data = {
        "patient_name": patient_name,
        "doctor_name": doctor_name,
        "appointment_date": date,
        "appointment_time": time,
        "slot_id": slot_id,
        "booking_created_at": now.strftime("%Y-%m-%d %I:%M %p"),
        "status": "confirmed"
    }
    db.collection("appointments").add(booking_data)
    mark_slot_booked(slot_id)
    return True


def add_available_slot(doctor_name, date, time):
    slot_data = {
        "doctor_name": doctor_name,
        "date": date,
        "time": time,
        "is_available": True,
        "created_at": datetime.now().strftime("%Y-%m-%d %I:%M %p")
    }
    db.collection("available_slots").add(slot_data)
    return f"Slot added: {doctor_name} on {date} at {time}"


def add_or_update_doctor(doctor_name, specialty="Dentist"):
    doctor_data = {
        "name": doctor_name,
        "specialty": specialty,
        "active": True,
        "updated_at": datetime.now().strftime("%Y-%m-%d %I:%M %p")
    }
    db.collection("doctors").document(doctor_name).set(doctor_data, merge=True)
    return f"Doctor saved: {doctor_name} ({specialty})"


def is_valid_date(date_text):
    try:
        datetime.strptime(date_text, "%Y-%m-%d")
        return True
    except ValueError:
        return False


def is_valid_time(time_text):
    try:
        datetime.strptime(time_text.strip(), "%I:%M %p")
        return True
    except ValueError:
        return False


def interactive_add_slots():
    print("\nAdd doctor availability")
    print("Example doctor: Dr Ahmed")
    doctor = input("Doctor name: ").strip()

    if not doctor:
        print("No doctor entered. Cancelled.")
        return

    specialty = input("Specialty (press Enter for Dentist): ").strip() or "Dentist"
    print(add_or_update_doctor(doctor, specialty))

    date = input("Date (YYYY-MM-DD): ").strip()
    if not is_valid_date(date):
        print("Invalid date. Use format YYYY-MM-DD, example: 2026-05-25")
        return

    print("Enter times separated by commas")
    print("Example: 2:00 PM, 4:00 PM, 6:00 PM")
    times_text = input("Times: ").strip()

    if not times_text:
        print("No times entered. Cancelled.")
        return

    added_count = 0
    for raw_time in times_text.split(","):
        time = raw_time.strip()
        if not time:
            continue

        if not is_valid_time(time):
            print(f"Skipped invalid time: {time}. Use example format: 2:00 PM")
            continue

        print(add_available_slot(doctor, date, time))
        added_count += 1

    print(f"Done. Added {added_count} available slot(s).\n")


def seed_sample_data():
    doctors = [
        {"name": "Dr Ahmed", "specialty": "Dentist", "active": True},
        {"name": "Dr Sara", "specialty": "Orthodontist", "active": True},
        {"name": "Dr Ali", "specialty": "Endodontist", "active": True}
    ]
    for doctor in doctors:
        db.collection("doctors").document(doctor["name"]).set(doctor)

    slots_to_add = [
        ("Dr Ahmed", "2026-05-12", "2:00 PM"),
        ("Dr Ahmed", "2026-05-12", "4:00 PM"),
        ("Dr Ahmed", "2026-05-12", "10:00 PM"),
        ("Dr Ahmed", "2026-05-13", "2:00 PM"),
        ("Dr Ahmed", "2026-05-13", "4:00 PM"),
        ("Dr Ahmed", "2026-05-13", "10:00 PM"),
        ("Dr Ahmed", "2026-05-15", "10:00 AM"),
        ("Dr Ahmed", "2026-05-15", "2:00 PM"),
        ("Dr Ahmed", "2026-05-15", "10:00 PM"),
        ("Dr Ahmed", "2026-05-15", "11:00 PM"),
        ("Dr Sara", "2026-05-13", "3:00 PM"),
        ("Dr Sara", "2026-05-13", "5:00 PM"),
        ("Dr Ali", "2026-05-12", "6:00 PM"),
        ("Dr Ahmed", "2026-05-14", "6:00 PM"),
    ]
    for doctor_name, date, time in slots_to_add:
        print(add_available_slot(doctor_name, date, time))


def detect_user_language(text):
    text_lower = str(text).lower()
    if re.search(r"[\u0600-\u06FF]", text_lower):
        return "arabic"
    arabizi_words = [
        "ayez", "aayez", "3ayez", "ayza", "3ayza",
        "ahgez", "a7gez", "ehgez", "7gz", "hagz",
        "3nd", "m3", "bokra", "elsa3a", "sa3a",
        "yom", "tam", "ma3ad", "m3ad", "a7ma", "a7med"
    ]
    if any(word in text_lower for word in arabizi_words):
        return "arabizi"
    return "english"


def normalize_arabic_text(text):
    text = str(text).lower()
    replacements = {"ة": "ه", "أ": "ا", "إ": "ا", "آ": "ا", "ى": "ي"}
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def today_string():
    return datetime.now().strftime("%Y-%m-%d")


def tomorrow_string():
    return (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")


def get_next_weekday(target_day_index):
    today = datetime.now()
    diff = (target_day_index - today.weekday()) % 7
    if diff == 0:
        diff = 7
    return (today + timedelta(days=diff)).strftime("%Y-%m-%d")


def fallback_date_from_text(text):
    """Return a YYYY-MM-DD date only when the user truly mentioned a date.
    Fixes bug where doctor names like 'sara' were fuzzy-matched to 'saturday'.
    """
    text_norm = normalize_arabic_text(text)
    words = text_norm.split()

    tomorrow_words = ["tomorrow", "tommorow", "tomorow", "tmrw", "bokra", "بكره", "بكرة"]
    for word in words:
        match = process.extractOne(word, tomorrow_words, score_cutoff=78)
        if match:
            return tomorrow_string()

    weekday_map = {
        "monday": 0, "tuesday": 1, "wednesday": 2, "thursday": 3,
        "friday": 4, "saturday": 5, "sunday": 6,
        "الاتنين": 0, "الاثنين": 0, "الثلاثاء": 1, "التلات": 1,
        "الاربعاء": 2, "الاربع": 2, "الخميس": 3,
        "الجمعه": 4, "الجمعة": 4, "جمعه": 4,
        "السبت": 5, "الاحد": 6, "الأحد": 6
    }

    english_days = {"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"}
    arabic_day_words = [k for k in weekday_map.keys() if k not in english_days]

    # English weekdays: exact match only. This prevents "sara" -> "saturday".
    for word in words:
        if word in english_days:
            return get_next_weekday(weekday_map[word])

    # Arabic weekdays: allow fuzzy matching for typos like الجمعه / جمعه.
    for word in words:
        # Only fuzzy-match Arabic-looking tokens.
        if re.search(r"[؀-ۿ]", word):
            match = process.extractOne(word, arabic_day_words, score_cutoff=65)
            if match:
                return get_next_weekday(weekday_map[match[0]])

    # Full Arabic phrase fuzzy match as a fallback.
    if re.search(r"[؀-ۿ]", text_norm):
        match = process.extractOne(text_norm, arabic_day_words, score_cutoff=70)
        if match:
            return get_next_weekday(weekday_map[match[0]])

    return None


def user_has_date_word(text):
    return fallback_date_from_text(text) is not None


def user_has_time_word(text):
    text = normalize_arabic_text(text)
    time_words = ["pm", "am", "at", "time", "clock", "elsa3a", "sa3a", "الساعة", "الساعه"]
    if any(word in text for word in time_words):
        return True
    if re.search(r"\b\d{1,2}:\d{2}\b", text):
        return True
    if re.search(r"(الساعة|الساعه)\s*[0-9٠-٩]", text):
        return True
    return False


def user_has_doctor_word(text):
    """Return True only if the current user message really mentions a doctor.
    This prevents Llama from guessing Dr Sara/Dr Ahmed when user only says a date like 'bokra'.
    """
    text_lower = str(text).lower()
    words = re.findall(r"[\w\u0600-\u06FF]+", text_lower)

    doctors = get_doctors()
    doctor_short_names = [
        d.replace("Dr ", "").lower().strip()
        for d in doctors
    ]

    # Match actual doctor names only, e.g. ahmed, sara, ali, including typos.
    for word in words:
        match = process.extractOne(
            word,
            doctor_short_names,
            score_cutoff=75
        )
        if match:
            return True

    # Arabic/English doctor indicator only counts if another word nearby can match a doctor name.
    # So "maa ahmed" is true, but "ayza ahgez bokra" is false.
    has_indicator = any(k in text_lower for k in ["dr", "doctor", "دكتور", "د ", "maa", "m3", "مع"])
    if has_indicator:
        for word in words:
            match = process.extractOne(word, doctor_short_names, score_cutoff=65)
            if match:
                return True

    return False


def get_day_name(date_str, lang="english"):
    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
    except Exception:
        return date_str
    english_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    arabic_days = ["الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت", "الأحد"]
    arabizi_days = ["el etneen", "el talat", "el arba3", "el khamees", "el gom3a", "el sabt", "el a7ad"]
    index = date_obj.weekday()
    if lang == "arabic":
        return arabic_days[index]
    if lang == "arabizi":
        return arabizi_days[index]
    return english_days[index]


def extract_json(text):
    matches = re.findall(r"\{.*?\}", text, re.DOTALL)
    for match in matches:
        try:
            data = json.loads(match)
            if isinstance(data, dict):
                return data
        except Exception:
            continue
    return {"intent": "unknown", "doctor_name": None, "appointment_date": None, "appointment_time": None, "slot_number": None}


def normalize_doctor_name(name_or_message, doctors):
    if not name_or_message:
        return None
    if isinstance(name_or_message, dict):
        name_or_message = name_or_message.get("value") or name_or_message.get("name")
    text = str(name_or_message).strip()

    # exact match first
    for doctor in doctors:
        if text.lower() == doctor.lower():
            return doctor

    # contains full doctor name
    for doctor in doctors:
        if doctor.lower() in text.lower():
            return doctor

    result = process.extractOne(text, doctors, score_cutoff=60)
    return result[0] if result else None


def understand_booking(user_message):
    doctors = get_doctors()
    doctors_text = "\n".join([f"- {d}" for d in doctors])
    current_date = today_string()

    messages = [
        {"role": "system", "content": f"""
You are Dentix Booking AI.
You understand English, Arabic, and Egyptian Arabizi.
You understand spelling mistakes, shuffled words, and incomplete booking messages.
Today is: {current_date}
Available doctors:
{doctors_text}
Return ONLY valid JSON. No explanation. No markdown. No Python code.
Fields: intent, doctor_name, appointment_date, appointment_time, slot_number
Rules:
- If user wants appointment booking, intent = "booking".
- Use doctor name exactly from available doctors.
- If doctor is missing, doctor_name = null.
- If date is missing, appointment_date = null.
- If time is missing, appointment_time = null.
- If user only mentions doctor, do NOT invent date or time.
- If user only mentions date, do NOT invent doctor or time.
- Time format must be like "7:00 PM".
- If user says "slot 2", slot_number = 2.
- If no slot number, slot_number = null.
Examples:
User: book with ahmed
JSON: {{"intent":"booking","doctor_name":"Dr Ahmed","appointment_date":null,"appointment_time":null,"slot_number":null}}
User: i want to book tomorrow
JSON: {{"intent":"booking","doctor_name":null,"appointment_date":null,"appointment_time":null,"slot_number":null}}
User: عايز احجز مع د احمد
JSON: {{"intent":"booking","doctor_name":"Dr Ahmed","appointment_date":null,"appointment_time":null,"slot_number":null}}
User: slot 2
JSON: {{"intent":"booking","doctor_name":null,"appointment_date":null,"appointment_time":null,"slot_number":2}}
"""},
        {"role": "user", "content": user_message}
    ]

    response = ollama.chat(
        model=OLLAMA_MODEL,
        messages=messages,
        options={
            "temperature": 0,
            "num_predict": 80
        }
    )
    output = response["message"]["content"].strip()

    if DEBUG_AI_OUTPUT:
        print("AI extracted:")
        print(output)

    data = extract_json(output)

    if not user_has_date_word(user_message):
        data["appointment_date"] = None
    if not user_has_time_word(user_message):
        data["appointment_time"] = None

    forced_date = fallback_date_from_text(user_message)
    if forced_date:
        data["appointment_date"] = forced_date

    # Do not accept Llama's guessed doctor unless the user actually mentioned a doctor.
    if user_has_doctor_word(user_message):
        data["doctor_name"] = normalize_doctor_name(
            data.get("doctor_name") or user_message,
            doctors
        )
    else:
        data["doctor_name"] = None

    return {
        "intent": data.get("intent"),
        "doctor_name": data.get("doctor_name"),
        "appointment_date": data.get("appointment_date"),
        "appointment_time": data.get("appointment_time"),
        "slot_number": data.get("slot_number")
    }


def reply_home(lang):
    if lang == "arabic": return "تم الرجوع للرئيسية، تقدري تبدأي حجز جديد."
    if lang == "arabizi": return "rg3na lel home, momken tebda2 7agz gedid."
    return "Back to home. You can start a new booking."


def reply_ask_doctor(lang):
    doctors_text = ", ".join(get_doctors())
    if lang == "arabic": return f"تحب تحجز مع أي دكتور؟ الدكاترة المتاحين هم: {doctors_text}."
    if lang == "arabizi": return f"t7b t7gez m3 anhy doctor? el doctors el mota7een: {doctors_text}."
    return f"Which doctor would you like to book with? Available doctors are: {doctors_text}."


def reply_choose_date(lang, doctor_name, dates):
    lines = [f"{i+1}. {get_day_name(date, lang)} ({date})" for i, date in enumerate(dates)]
    dates_text = "\n".join(lines)
    if lang == "arabic": return f"الأيام المتاحة مع {doctor_name} هي:\n{dates_text}\nاختاري رقم اليوم."
    if lang == "arabizi": return f"el ayam el mota7a m3 {doctor_name}:\n{dates_text}\ne5tar rakam el youm."
    return f"Available days with {doctor_name} are:\n{dates_text}\nPlease choose a day number."


def reply_choose_doctor(lang, date, doctors):
    doctors_text = ", ".join(doctors)
    if lang == "arabic": return f"الدكاترة المتاحين يوم {date} هم: {doctors_text}. تحب تحجز مع مين؟"
    if lang == "arabizi": return f"el doctors el mota7een yom {date}: {doctors_text}. t7b t7gez m3 meen?"
    return f"Doctors available on {date} are: {doctors_text}. Who would you like to book with?"


def reply_choose_slot(lang, doctor, date, slots):
    slots_text = "\n".join([f"{i+1}. {slot['time']}" for i, slot in enumerate(slots)])
    if lang == "arabic": return f"مواعيد {doctor} المتاحة يوم {date}:\n{slots_text}\nاختاري رقم المعاد."
    if lang == "arabizi": return f"mawa3ed {doctor} el mota7a yom {date}:\n{slots_text}\ne5tar rakam el slot."
    return f"{doctor}'s available slots on {date} are:\n{slots_text}\nPlease choose a slot number."


def reply_success(lang, doctor, date, time):
    if lang == "arabic": return f"تم الحجز بنجاح مع {doctor} يوم {date} الساعة {time}."
    if lang == "arabizi": return f"tam el 7agz b naga7 m3 {doctor} yom {date} elsa3a {time}."
    return f"Successfully booked with {doctor} at {time} on {date}."


def reply_no_dates(lang, doctor):
    if lang == "arabic": return f"مفيش أيام متاحة حاليًا مع {doctor}. اكتبي home لو حابة تبدأي من جديد."
    if lang == "arabizi": return f"mafeesh ayam mota7a delwa2ty m3 {doctor}. ekteb home law 3ayz tebda2 mn el awel."
    return f"There are no available dates for {doctor}. Type home if you want to start over."


def reply_no_slots(lang, doctor, date):
    if lang == "arabic": return f"مفيش مواعيد متاحة مع {doctor} يوم {date}. اكتبي home لو حابة تبدأي من جديد."
    if lang == "arabizi": return f"mafeesh slots mota7a m3 {doctor} yom {date}. ekteb home law 3ayz tebda2 mn el awel."
    return f"There are no available slots for {doctor} on {date}. Type home if you want to start over."


def reply_no_doctors(lang, date):
    if lang == "arabic": return f"مفيش دكاترة متاحين يوم {date}. اكتبي home لو حابة تبدأي من جديد."
    if lang == "arabizi": return f"mafeesh doctors mota7een yom {date}. ekteb home law 3ayz tebda2 mn el awel."
    return f"No doctors are available on {date}. Type home if you want to start over."


def reset_booking_context():
    global booking_context
    booking_context = {"patient_name": None, "doctor_name": None, "appointment_date": None, "appointment_time": None, "offered_slots": [], "offered_dates": []}


def is_home_command(text):
    text = str(text).lower().strip()
    return text in ["home", "reset", "restart", "main menu", "back", "cancel", "الرئيسية", "الرئيسيه"]


def extract_slot_choice(user_message):
    text = str(user_message).strip().lower()
    match = re.search(r"(?:slot|number)?\s*(\d+)\s*$", text)
    return int(match.group(1)) if match else None


def extract_date_choice(user_message, offered_dates):
    """Choose from already offered dates by option number, exact date, or displayed day name.
    Example: if option 1 is Tuesday (2026-05-19), typing "tuesday" selects 2026-05-19,
    not the next Tuesday.
    """
    text = str(user_message).strip().lower()

    match = re.search(r"^(?:date|day)?\s*(\d+)$", text)
    if match:
        index = int(match.group(1)) - 1
        if 0 <= index < len(offered_dates):
            return offered_dates[index]

    # Exact date typed by user
    for date in offered_dates:
        if date in text:
            return date

    # Day name typed by user: choose the matching day from the offered options.
    for date in offered_dates:
        day_en = get_day_name(date, "english").lower()
        day_ar = get_day_name(date, "arabic").lower()
        day_arabizi = get_day_name(date, "arabizi").lower()

        normalized_text = normalize_arabic_text(text)
        normalized_day_ar = normalize_arabic_text(day_ar)

        if day_en in text or normalized_day_ar in normalized_text or day_arabizi in text:
            return date

    return None


def normalize_time_text(t):
    return str(t).lower().replace(" ", "").replace(".", "").strip()


def _to_english_digits(text):
    arabic_digits = "٠١٢٣٤٥٦٧٨٩"
    eastern_digits = "۰۱۲۳۴۵۶۷۸۹"
    for i, d in enumerate(arabic_digits):
        text = text.replace(d, str(i))
    for i, d in enumerate(eastern_digits):
        text = text.replace(d, str(i))
    return text


def extract_time_choice(user_message, offered_slots):
    text = _to_english_digits(str(user_message).lower())
    text_norm = normalize_time_text(text)

    # Case 1: 4 pm / 4:00 pm
    time_match = re.search(r"\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b", text)
    if time_match:
        hour = int(time_match.group(1))
        minute = time_match.group(2) or "00"
        period = time_match.group(3).upper()
        user_time = f"{hour}:{minute} {period}"
        for slot in offered_slots:
            if normalize_time_text(slot["time"]) == normalize_time_text(user_time):
                return slot

    # Case 2: Arabizi/Arabic phrases like "el saa 4", "elsa3a 4", "sa3a 4", "الساعة 4"
    phrase_match = re.search(
        r"(?:el\s*saa|elsa3a|el\s*sa3a|sa3a|saa|الساعة|الساعه)\s*(\d{1,2})",
        text
    )
    if phrase_match:
        hour = int(phrase_match.group(1))
        for possible_time in [f"{hour}:00 PM", f"{hour}:00 AM"]:
            for slot in offered_slots:
                if normalize_time_text(slot["time"]) == normalize_time_text(possible_time):
                    return slot

    # Case 3: bare number like "4" after slots were already offered.
    # Prefer exact PM then AM, because clinic slots are usually displayed with AM/PM.
    bare_match = re.fullmatch(r"\d{1,2}", text.strip())
    if bare_match:
        hour = int(bare_match.group(0))
        for possible_time in [f"{hour}:00 PM", f"{hour}:00 AM"]:
            for slot in offered_slots:
                if normalize_time_text(slot["time"]) == normalize_time_text(possible_time):
                    return slot

    # Case 4: direct partial match
    for slot in offered_slots:
        if normalize_time_text(slot["time"]) in text_norm:
            return slot

    return None


reset_booking_context()


def smart_chatbot(user_message, patient_name="Unknown"):
    global booking_context
    lang = detect_user_language(user_message)

    if is_home_command(user_message):
        reset_booking_context()
        return reply_home(lang)

    # HARD FIX: if bot asked "Who would you like to book with?"
    # and user replies with a doctor name, capture it directly.
    if booking_context.get("appointment_date") and not booking_context.get("doctor_name"):
        user_text = user_message.lower().strip()
        for doctor in get_doctors():
            doctor_text = doctor.lower().strip()
            doctor_parts = doctor_text.split()

            if (
                user_text == doctor_text
                or user_text in doctor_text
                or doctor_text in user_text
                or all(part in user_text for part in doctor_parts)
            ):
                booking_context["doctor_name"] = doctor
                slots = get_available_slots(
                    date=booking_context["appointment_date"],
                    doctor_name=doctor
                )
                booking_context["offered_slots"] = slots

                if not slots:
                    return reply_no_slots(lang, doctor, booking_context["appointment_date"])

                return reply_choose_slot(lang, doctor, booking_context["appointment_date"], slots)

    forced_doctor_early = normalize_doctor_name(user_message, get_doctors())
    if forced_doctor_early and not extract_slot_choice(user_message):
        booking_context["doctor_name"] = forced_doctor_early
        booking_context["offered_dates"] = []
        slots = []
        if booking_context.get("appointment_date"):
            slots = get_available_slots(date=booking_context["appointment_date"], doctor_name=booking_context["doctor_name"])
        if slots:
            booking_context["offered_slots"] = slots
            return reply_choose_slot(lang, booking_context["doctor_name"], booking_context["appointment_date"], slots)
        dates = get_available_dates_for_doctor(booking_context["doctor_name"])
        booking_context["offered_dates"] = dates
        if not dates:
            return reply_no_dates(lang, booking_context["doctor_name"])
        return reply_choose_date(lang, booking_context["doctor_name"], dates)

    if booking_context.get("offered_dates"):
        chosen_date = extract_date_choice(user_message, booking_context["offered_dates"])
        if chosen_date:
            booking_context["appointment_date"] = chosen_date
            booking_context["offered_dates"] = []
            slots = get_available_slots(date=booking_context["appointment_date"], doctor_name=booking_context["doctor_name"])
            booking_context["offered_slots"] = slots
            if not slots:
                return reply_no_slots(lang, booking_context["doctor_name"], booking_context["appointment_date"])
            return reply_choose_slot(lang, booking_context["doctor_name"], booking_context["appointment_date"], slots)

    if booking_context.get("offered_slots"):
        slot_number = extract_slot_choice(user_message)
        if slot_number and 1 <= slot_number <= len(booking_context["offered_slots"]):
            chosen_slot = booking_context["offered_slots"][slot_number - 1]
            save_booking(patient_name, chosen_slot["doctor_name"], chosen_slot["date"], chosen_slot["time"], chosen_slot["slot_id"])
            reply = reply_success(lang, chosen_slot["doctor_name"], chosen_slot["date"], chosen_slot["time"])
            reset_booking_context()
            return reply

        chosen_time_slot = extract_time_choice(user_message, booking_context["offered_slots"])
        if chosen_time_slot:
            save_booking(patient_name, chosen_time_slot["doctor_name"], chosen_time_slot["date"], chosen_time_slot["time"], chosen_time_slot["slot_id"])
            reply = reply_success(lang, chosen_time_slot["doctor_name"], chosen_time_slot["date"], chosen_time_slot["time"])
            reset_booking_context()
            return reply

    data = understand_booking(user_message)

    # HARD FIX: understand flexible date formats from user text
    msg_lower = user_message.lower().strip()
    forced_date_text = None

    m = re.search(r"(20\\d{2})[-/](\\d{1,2})[-/](\\d{1,2})", user_message)
    if m:
        forced_date_text = f"{m.group(1)}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"
    else:
        m = re.search(r"\\b(\\d{1,2})[-/](\\d{1,2})\\b", user_message)
        if m:
            forced_date_text = f"{datetime.now().year}-{int(m.group(2)):02d}-{int(m.group(1)):02d}"

    if "after tomorrow" in msg_lower or "day after tomorrow" in msg_lower or "b3d bokra" in msg_lower or "ba3d bokra" in msg_lower:
        forced_date_text = (datetime.now() + timedelta(days=2)).strftime("%Y-%m-%d")
    elif "tomorrow" in msg_lower or "bokra" in msg_lower or "بكرة" in msg_lower:
        forced_date_text = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

    if forced_date_text:
        data["appointment_date"] = forced_date_text
        booking_context["appointment_date"] = forced_date_text
        booking_context["offered_dates"] = []
        booking_context["offered_slots"] = []

    # If user message is only/mostly a doctor name, force-detect it from available doctors
    forced_doctor = normalize_doctor_name(user_message, get_doctors())
    if forced_doctor:
        data["doctor_name"] = forced_doctor

    booking_context["patient_name"] = patient_name

    old_doctor = booking_context.get("doctor_name")

    if data.get("doctor_name"):
        booking_context["doctor_name"] = data["doctor_name"]

        # Only reset date/time if user changed to a different doctor
        if old_doctor and data["doctor_name"] != old_doctor:
            booking_context["appointment_date"] = None
            booking_context["appointment_time"] = None
            booking_context["offered_slots"] = []
            booking_context["offered_dates"] = []

    elif booking_context.get("doctor_name"):
        data["doctor_name"] = booking_context["doctor_name"]
        

    if data.get("appointment_date") and user_has_date_word(user_message):
        booking_context["appointment_date"] = data["appointment_date"]

    if data.get("appointment_time") and user_has_time_word(user_message):
        booking_context["appointment_time"] = data["appointment_time"]

    if not booking_context["doctor_name"] and not booking_context["appointment_date"] and not booking_context["appointment_time"]:
        return reply_ask_doctor(lang)

    if booking_context["doctor_name"] and not booking_context["appointment_date"]:
        dates = get_available_dates_for_doctor(booking_context["doctor_name"])
        booking_context["offered_dates"] = dates
        if not dates:
            return reply_no_dates(lang, booking_context["doctor_name"])
        return reply_choose_date(lang, booking_context["doctor_name"], dates)

    if booking_context["appointment_date"] and not booking_context["doctor_name"]:
        slots = get_available_slots(date=booking_context["appointment_date"])
        doctors_available = sorted(list(set(slot["doctor_name"] for slot in slots)))
        if not doctors_available:
            return reply_no_doctors(lang, booking_context["appointment_date"])

        # FIX: if user replied with one of the available doctor names, choose it now
        user_text = user_message.lower().strip()
        for doctor in doctors_available:
            doctor_text = doctor.lower().strip()
            parts = doctor_text.split()
            if user_text == doctor_text or user_text in doctor_text or doctor_text in user_text or all(p in user_text for p in parts):
                booking_context["doctor_name"] = doctor
                doctor_slots = get_available_slots(date=booking_context["appointment_date"], doctor_name=doctor)
                booking_context["offered_slots"] = doctor_slots
                if not doctor_slots:
                    return reply_no_slots(lang, doctor, booking_context["appointment_date"])
                return reply_choose_slot(lang, doctor, booking_context["appointment_date"], doctor_slots)

        return reply_choose_doctor(lang, booking_context["appointment_date"], doctors_available)

    if booking_context["doctor_name"] and booking_context["appointment_date"] and not booking_context["appointment_time"]:
        slots = get_available_slots(date=booking_context["appointment_date"], doctor_name=booking_context["doctor_name"])
        booking_context["offered_slots"] = slots
        if not slots:
            return reply_no_slots(lang, booking_context["doctor_name"], booking_context["appointment_date"])
        return reply_choose_slot(lang, booking_context["doctor_name"], booking_context["appointment_date"], slots)

    if booking_context["doctor_name"] and booking_context["appointment_date"] and booking_context["appointment_time"]:
        slots = get_available_slots(date=booking_context["appointment_date"], doctor_name=booking_context["doctor_name"])
        chosen_slot = extract_time_choice(booking_context["appointment_time"], slots)
        if not chosen_slot:
            booking_context["offered_slots"] = slots
            if not slots:
                return reply_no_slots(lang, booking_context["doctor_name"], booking_context["appointment_date"])
            return reply_choose_slot(lang, booking_context["doctor_name"], booking_context["appointment_date"], slots)

        save_booking(patient_name, chosen_slot["doctor_name"], chosen_slot["date"], chosen_slot["time"], chosen_slot["slot_id"])
        reply = reply_success(lang, chosen_slot["doctor_name"], chosen_slot["date"], chosen_slot["time"])
        reset_booking_context()
        return reply

    return reply_ask_doctor(lang)




# =========================================================
# DENTIX COMBINED BOT: BOOKING + SHAGY DENTAL RAG
# =========================================================

# The RAG chatbot files must be in the same folder as this file:
# - shagy_assistant.py
# - dentix_knowledge_db/...

try:
    from shagy_assistant import ShagyAssistant, is_dental_message, detect_language_style
    shagy_bot = ShagyAssistant()
    SHAGY_AVAILABLE = True
except Exception as e:
    shagy_bot = None
    SHAGY_AVAILABLE = False
    SHAGY_IMPORT_ERROR = e

combined_history = []
recommended_specialty = None
last_mode = None


def booking_flow_active():
    return bool(
        booking_context.get("doctor_name")
        or booking_context.get("appointment_date")
        or booking_context.get("appointment_time")
        or booking_context.get("offered_slots")
        or booking_context.get("offered_dates")
    )


def is_booking_message(text):
    text_lower = str(text).lower().strip()

    booking_keywords = [
        "book", "booking", "appointment", "reserve", "schedule",
        "حجز", "احجز", "عايز احجز", "عايزة احجز", "موعد", "معاد",
        "ehgez", "ahgez", "a7gez", "7gz", "hagz", "ma3ad", "m3ad",
        "dr", "doctor", "دكتور"
    ]

    if any(k in text_lower for k in booking_keywords):
        return True

    # If booking options were already shown, numbers/times are booking replies.
    if booking_flow_active():
        if extract_slot_choice(text_lower):
            return True
        if re.search(r"\b\d{1,2}(?::\d{2})?\s*(am|pm)\b", text_lower):
            return True

    return False


def get_doctor_profiles():
    profiles = []
    for doc in db.collection("doctors").stream():
        data = doc.to_dict()
        if data.get("active") is True:
            profiles.append(data)
    return profiles


def get_doctors_by_specialty(specialty):
    if not specialty:
        return get_doctors()

    wanted = str(specialty).lower()
    matches = []

    for profile in get_doctor_profiles():
        name = profile.get("name")
        doc_specialty = str(profile.get("specialty", "")).lower()

        if name and (wanted in doc_specialty or doc_specialty in wanted):
            matches.append(name)

    return sorted(list(set(matches))) or get_doctors()


def recommend_dental_specialty(user_message, answer_text=""):
    text = (str(user_message) + " " + str(answer_text)).lower()

    # Keep these aligned with your Firebase doctor specialties.
    if any(k in text for k in ["braces", "تقويم", "taqwim", "orthodontic", "alignment"]):
        return "Orthodontist"

    if any(k in text for k in ["root canal", "عصب", "3asab", "nerve", "endodontic"]):
        return "Endodontist"

    if any(k in text for k in ["gum", "gums", "لثة", "اللثة", "ltha", "bleeding gums", "نزيف اللثة"]):
        return "Periodontist"

    if any(k in text for k in ["implant", "زراعة", "زرعة"]):
        return "Implantologist"

    if any(k in text for k in ["child", "kids", "طفل", "اطفال", "أطفال"]):
        return "Pediatric Dentist"

    # Most pain/cavity/checkup cases start with a general dentist.
    if any(k in text for k in ["tooth", "teeth", "pain", "cavity", "filling", "ضرس", "سن", "تسوس", "حشو", "وجع", "الم", "ألم", "ders", "senn", "waga3"]):
        return "Dentist"

    return None


def specialty_recommendation_text(lang, specialty):
    if not specialty:
        return ""

    if lang == "arabic":
        return f"\n\nأنسب نوع دكتور مبدئيًا: {specialty}. لو تحب، اكتب: احجز."

    if lang in {"franco", "arabizi"}:
        return f"\n\nEl no3 el monaseb mn el doctors: {specialty}. Law 3ayz te7gez, ekteb: ehgez."

    return f"\n\nRecommended dental provider type: {specialty}. If you want, type: book."


# Override the booking bot's doctor question to use the RAG specialty recommendation when available.
def reply_ask_doctor(lang):
    global recommended_specialty

    doctors = get_doctors_by_specialty(recommended_specialty)
    doctors_text = ", ".join(doctors)

    if recommended_specialty:
        if lang == "arabic":
            return f"بناءً على كلامك، الأنسب {recommended_specialty}. الدكاترة المتاحين: {doctors_text}. تحب تحجز مع مين؟"
        if lang == "arabizi":
            return f"3ala 7asab kalamak, el monaseb {recommended_specialty}. el doctors el mota7een: {doctors_text}. t7b t7gez m3 meen?"
        return f"Based on your case, {recommended_specialty} is recommended. Available doctors are: {doctors_text}. Who would you like to book with?"

    if lang == "arabic":
        return f"تحب تحجز مع أي دكتور؟ الدكاترة المتاحين هم: {doctors_text}."
    if lang == "arabizi":
        return f"t7b t7gez m3 anhy doctor? el doctors el mota7een: {doctors_text}."
    return f"Which doctor would you like to book with? Available doctors are: {doctors_text}."


def combined_chatbot(user_message, patient_name="Local Patient"):
    global combined_history, recommended_specialty, last_mode

    msg = str(user_message).strip()
    lang = detect_user_language(msg)

    if is_home_command(msg):
        reset_booking_context()
        last_mode = None
        recommended_specialty = None
        return reply_home(lang)

    # Continue booking flow if the bot already offered dates/slots or collected booking data.
    if booking_flow_active():
        last_mode = "booking"
        return smart_chatbot(msg, patient_name=patient_name)

    # Explicit booking request goes to booking chatbot.
    if is_booking_message(msg):
        last_mode = "booking"
        return smart_chatbot(msg, patient_name=patient_name)

    # Dental/RAG question goes to SHAGY.
    if SHAGY_AVAILABLE and is_dental_message(msg, combined_history):
        last_mode = "dental_rag"
        result = shagy_bot.answer(msg, combined_history)
        answer = result.get("answer", "")

        shagy_style = result.get("language_style") or detect_language_style(msg)
        specialty = recommend_dental_specialty(msg, answer)
        if specialty:
            recommended_specialty = specialty
            answer += specialty_recommendation_text(shagy_style, specialty)

        combined_history.append({"role": "patient", "content": msg})
        combined_history.append({"role": "assistant", "content": answer})
        combined_history = combined_history[-12:]
        return answer

    # If SHAGY is unavailable, explain once.
    if not SHAGY_AVAILABLE:
        return f"RAG chatbot is not loaded. Check shagy_assistant.py and dentix_knowledge_db. Error: {SHAGY_IMPORT_ERROR}"

    # General fallback.
    if lang == "arabic":
        return "أقدر أساعدك في معلومات عن الأسنان أو حجز موعد. تحب تسأل عن مشكلة أسنان ولا تحجز؟"
    if lang == "arabizi":
        return "a2dar asa3dak fe ma3loomat 3an el asnan aw 7agz m3ad. t7b tes2al wala te7gez?"
    return "I can help with dental-care questions or appointment booking. Would you like to ask a dental question or book an appointment?"


if __name__ == "__main__":
    print("\nDentix COMBINED chatbot started!")
    print("Type 'home' to reset. Type 'exit' to quit.")
    print("Type 'seed' ONLY if Firebase is empty and you want sample doctors/slots.")
    print("Type 'addslots' to add doctor availability to Firebase.")
    print("This combined bot routes between: Booking Bot + SHAGY Dental RAG.\n")

    if not SHAGY_AVAILABLE:
        print("WARNING: SHAGY/RAG did not load:", SHAGY_IMPORT_ERROR)
        print("Make sure shagy_assistant.py and dentix_knowledge_db are in this same folder.\n")

    while True:
        user_input = input("Patient: ").strip()

        if user_input.lower() == "exit":
            print("Chatbot stopped.")
            break

        if user_input.lower() == "seed":
            seed_sample_data()
            continue

        if user_input.lower() == "addslots":
            interactive_add_slots()
            continue

        response = combined_chatbot(user_input, patient_name="Local Patient")
        print("Dentix:", response)
