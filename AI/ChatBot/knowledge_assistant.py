from __future__ import annotations

import os
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import chromadb
import httpx
import ollama


os.environ.setdefault("TRANSFORMERS_NO_TF", "1")
os.environ.setdefault("USE_TF", "0")

BASE_DIR = Path(__file__).resolve().parent
DB_DIR = BASE_DIR / "dentix_knowledge_db" / "dentix_knowledge_db"
SQLITE_PATH = DB_DIR / "chroma.sqlite3"
COLLECTION_NAME = "langchain"
DEFAULT_LLM_MODEL = os.getenv("SHAGY_LLM_MODEL", "llama3.1")
DEFAULT_EMBEDDING_MODEL = os.getenv("SHAGY_EMBEDDING_MODEL", "all-MiniLM-L6-v2")
USE_VECTOR_RETRIEVAL = os.getenv("SHAGY_USE_VECTOR", "0").lower() in {"1", "true", "yes"}
OLLAMA_TIMEOUT_SECONDS = float(os.getenv("SHAGY_OLLAMA_TIMEOUT", "45"))


ARABIC_RE = re.compile(r"[\u0600-\u06ff]")
FRANCO_RE = re.compile(r"\b(?:ana|enta|enty|eh|eih|3andy|عندي|ders|dars|senn|sinna|asnany|bo2y|faky|ltha|7ashw|3asab|waga3|waram|soda3|sa2a|sokhn|khala3|taqwim)\b", re.I)

DENTAL_TERMS = {
    "tooth", "teeth", "gum", "gums", "dental", "dentist", "mouth", "jaw", "cavity",
    "filling", "root", "canal", "crown", "braces", "wisdom", "extraction", "bleeding",
    "swelling", "pus", "abscess", "pain", "sensitive", "sensitivity", "ulcer",
    "سن", "سنة", "اسنان", "أسنان", "ضرس", "لثة", "فم", "فك", "حشو", "عصب",
    "تقويم", "خلع", "تسوس", "خراج", "تورم", "صديد", "نزيف", "وجع", "الم",
    "3andy", "ders", "senn", "asnany", "ltha", "bo2y", "faky", "7ashw", "3asab",
    "waram", "waga3", "khala3", "taqwim",
}

EXTRA_FRANCO_DENTAL_TERMS = {
    "wag3", "bywg3", "byewga3", "bewga3", "sa2a", "sa23a", "elsa23a",
    "sokhn", "soda2", "soda3", "sensitive", "sensitivity",
    "implant", "braces", "whitening", "crown", "ulcer", "sores", "crack",
    "cracked", "loose", "gap", "feraghat", "met7assa",
}
DENTAL_TERMS.update(EXTRA_FRANCO_DENTAL_TERMS)
DENTAL_TERMS.update(
    {
        "سن", "سنة", "سني", "أسنان", "اسنان", "سناني", "ضرس", "ضرسي",
        "لثة", "اللثة", "فم", "الفم", "بقي", "فك", "الفك", "حشو", "حشوة",
        "عصب", "تقويم", "خلع", "تسوس", "خراج", "تورم", "ورم", "صديد",
        "نزيف", "وجع", "ألم", "الم", "ساقع", "سخن", "حساسية", "طربوش",
        "زراعة", "تقرحات", "قرح", "جير",
    }
)

FOLLOW_UP_DENTAL_TERMS = {
    "hurt", "hurts", "pain", "painful", "cold", "hot", "bleed", "blood",
    "swelling", "pus", "fever", "sensitive", "sensitivity", "bite", "chewing",
    "night", "sleep", "bywg3", "byewga3", "bewga3", "waga3", "wag3", "sa2a",
    "sa23a", "elsa23a", "sokhn", "soded", "waram", "ri7a", "we7sha",
    "وجع", "بيوجع", "ألم", "الم", "ساقع", "سخن", "نزيف", "دم", "تورم",
    "ورم", "صديد", "ريحة", "حساسية", "العض", "أعض", "ليل", "النوم",
}

URGENT_TERMS = {
    "swelling", "pus", "abscess", "fever", "severe pain", "severe tooth pain", "can't sleep",
    "difficulty swallowing", "difficulty breathing", "face swollen",
    "تورم", "ورم", "صديد", "خراج", "سخونية", "حرارة", "مش عارف ابلع",
    "مش عارفة ابلع", "مش عارف اتنفس", "وشي وارم", "وجع جامد",
    "waram", "soded", "khurag", "so3oba fel bala3", "mesh 3aref atnafas",
    "weshy warem", "waga3 gamed", "waga3 severe",
}


@dataclass
class RetrievedChunk:
    text: str
    source: str | None = None
    page: int | None = None


class LocalMiniLMEmbedding:
    def __init__(self, model_name: str = DEFAULT_EMBEDDING_MODEL) -> None:
        from sentence_transformers import SentenceTransformer

        self.model = SentenceTransformer(model_name, local_files_only=True)

    def __call__(self, input: list[str]) -> list[list[float]]:
        vectors = self.model.encode(input, normalize_embeddings=True)
        return vectors.tolist()


def detect_language_style(text: str) -> str:
    if ARABIC_RE.search(text):
        return "arabic"
    if re.search(r"[237589]", text) or FRANCO_RE.search(text):
        return "franco"
    return "english"


def is_dental_message(text: str, history: list[dict[str, str]] | None = None) -> bool:
    lowered = text.lower()
    if any(term.lower() in lowered for term in DENTAL_TERMS):
        return True

    recent_text = " ".join(msg.get("content", "") for msg in (history or [])[-4:])
    recent_is_dental = any(term.lower() in recent_text.lower() for term in DENTAL_TERMS)
    has_follow_up_signal = any(term.lower() in lowered for term in FOLLOW_UP_DENTAL_TERMS)
    return bool(recent_is_dental and has_follow_up_signal and len(text.strip()) <= 180)


def is_urgent(text: str) -> bool:
    lowered = text.lower()
    return any(term.lower() in lowered for term in URGENT_TERMS)


def _clean(text: str, max_chars: int = 650) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    return text[:max_chars]


class ShagyAssistant:
    def __init__(
        self,
        db_dir: Path = DB_DIR,
        collection_name: str = COLLECTION_NAME,
        llm_model: str = DEFAULT_LLM_MODEL,
        embedding_model: str = DEFAULT_EMBEDDING_MODEL,
    ) -> None:
        self.db_dir = Path(db_dir)
        self.sqlite_path = self.db_dir / "chroma.sqlite3"
        self.collection_name = collection_name
        self.llm_model = llm_model
        self.embedding_model = embedding_model
        self.use_vector_retrieval = USE_VECTOR_RETRIEVAL
        self.ollama_client = ollama.Client(timeout=OLLAMA_TIMEOUT_SECONDS)
        self._collection: Any | None = None
        self._embedding_fn: LocalMiniLMEmbedding | None = None

    def answer(self, user_message: str, history: list[dict[str, str]] | None = None) -> dict[str, Any]:
        history = history or []
        style = detect_language_style(user_message)
        urgent = is_urgent(user_message)

        if not is_dental_message(user_message, history):
            return {
                "assistant": "SHAGY",
                "language_style": style,
                "urgent": False,
                "sources": [],
                "answer": self._off_topic_reply(style),
            }

        chunks = self.retrieve(user_message)
        system_prompt, prompt = self._build_prompt(user_message, history, chunks, style, urgent)
        try:
            response = self.ollama_client.chat(
                model=self.llm_model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt},
                ],
                options={
                    "temperature": 0.25,
                    "top_p": 0.85,
                    "num_ctx": 2048,
                    "num_predict": 180,
                },
            )
            answer = response["message"]["content"].strip()
            answer_mode = "llm"
        except (httpx.TimeoutException, httpx.ConnectError, httpx.ReadError):
            answer = self._fallback_answer(user_message, style, urgent)
            answer_mode = "fallback"

        answer = self._apply_safety_floor(answer, style, urgent)
        return {
            "assistant": "SHAGY",
            "language_style": style,
            "urgent": urgent,
            "answer_mode": answer_mode,
            "sources": [
                {"source": chunk.source, "page": chunk.page}
                for chunk in chunks
                if chunk.source or chunk.page is not None
            ],
            "answer": answer,
        }

    def retrieve(self, query: str, n_results: int = 2) -> list[RetrievedChunk]:
        if not self.use_vector_retrieval:
            return self._retrieve_text(query, n_results)

        try:
            return self._retrieve_vector(query, n_results)
        except Exception:
            return self._retrieve_text(query, n_results)

    def _retrieve_vector(self, query: str, n_results: int) -> list[RetrievedChunk]:
        if self._embedding_fn is None:
            self._embedding_fn = LocalMiniLMEmbedding(self.embedding_model)
        if self._collection is None:
            client = chromadb.PersistentClient(path=str(self.db_dir))
            self._collection = client.get_collection(self.collection_name)

        query_embedding = self._embedding_fn([query])
        results = self._collection.query(
            query_embeddings=query_embedding,
            n_results=n_results,
            include=["documents", "metadatas"],
        )
        docs = results.get("documents", [[]])[0]
        metadatas = results.get("metadatas", [[]])[0]
        return [
            RetrievedChunk(
                text=_clean(doc),
                source=(metadata or {}).get("source"),
                page=(metadata or {}).get("page"),
            )
            for doc, metadata in zip(docs, metadatas)
            if doc
        ]

    def _retrieve_text(self, query: str, n_results: int) -> list[RetrievedChunk]:
        if not self.sqlite_path.exists():
            return []

        terms = self._query_terms(query)
        if not terms:
            return []

        with sqlite3.connect(self.sqlite_path) as con:
            cur = con.cursor()
            try:
                cur.execute(
                    """
                    SELECT rowid, string_value
                    FROM embedding_fulltext_search
                    WHERE embedding_fulltext_search MATCH ?
                    LIMIT ?
                    """,
                    (" OR ".join(terms), n_results),
                )
                rows = cur.fetchall()
            except sqlite3.OperationalError:
                rows = []

            chunks: list[RetrievedChunk] = []
            for row_id, text in rows:
                metadata = self._metadata_for_id(cur, row_id)
                chunks.append(
                    RetrievedChunk(
                        text=_clean(text),
                        source=metadata.get("source"),
                        page=metadata.get("page"),
                    )
                )
            return chunks

    def _query_terms(self, query: str) -> list[str]:
        latin_terms = re.findall(r"[A-Za-z]{3,}", query.lower())
        arabic_terms = re.findall(r"[\u0600-\u06ff]{3,}", query)
        terms = latin_terms + arabic_terms
        mapped_terms = []
        franco_map = {
            "ders": "tooth",
            "dars": "tooth",
            "senn": "tooth",
            "asnany": "teeth",
            "ltha": "gum",
            "bo2y": "mouth",
            "faky": "jaw",
            "waga3": "pain",
            "waram": "swelling",
            "soded": "pus",
            "7ashw": "filling",
            "3asab": "root canal",
            "sa2a": "cold sensitivity",
            "sa23a": "cold sensitivity",
            "elsa23a": "cold sensitivity",
            "sokhn": "hot sensitivity",
            "bywg3": "pain",
            "byewga3": "pain",
            "bewga3": "pain",
            "wag3": "pain",
        }
        for term in terms:
            mapped_terms.extend(franco_map.get(term, term).split())
        safe_terms = [re.sub(r"[^A-Za-z0-9_\u0600-\u06ff]", "", term) for term in mapped_terms]
        return [term for term in safe_terms if len(term) >= 3][:8]

    def _metadata_for_id(self, cur: sqlite3.Cursor, row_id: int) -> dict[str, Any]:
        cur.execute(
            """
            SELECT key, string_value, int_value
            FROM embedding_metadata
            WHERE id = ? AND key IN ('source', 'page')
            """,
            (row_id,),
        )
        metadata: dict[str, Any] = {}
        for key, string_value, int_value in cur.fetchall():
            metadata[key] = int_value if int_value is not None else string_value
        return metadata

    def _build_prompt(
        self,
        user_message: str,
        history: list[dict[str, str]],
        chunks: list[RetrievedChunk],
        style: str,
        urgent: bool,
    ) -> tuple[str, str]:
        language_instruction = {
            "arabic": "Reply in natural Arabic matching the patient's tone.",
            "franco": "Reply in Franco Arabic only: Egyptian Arabic written with Latin letters and numbers, like '3andy', 'el ders', 'lazem'. Do not reply in English, do not add translations in brackets, and do not use formal Arabic script.",
            "english": "Reply in natural, simple English.",
        }[style]
        recent_history = "\n".join(
            f"{msg.get('role', 'user')}: {msg.get('content', '')}"
            for msg in history[-8:]
        )
        context = "\n\n".join(
            f"[Source {i + 1}: {chunk.source or 'textbook'}, page {chunk.page or 'unknown'}]\n{chunk.text}"
            for i, chunk in enumerate(chunks)
        ) or "No retrieved textbook context was available for this turn."

        urgent_instruction = (
            "This message contains urgent red flags. Strongly advise same-day dental/medical assessment, and emergency care now if breathing/swallowing is difficult."
            if urgent
            else "No urgent red flags were clearly detected, but still advise a dentist visit when symptoms are persistent, severe, or worsening."
        )

        system_prompt = f"""
You are SHAGY, the AI dental assistant inside the Dentix system.

Core behavior:
- Stay strictly within dentistry and oral health.
- Use the retrieved dental textbook context when it is relevant.
- Keep the conversation natural and remember the recent chat context.
- Explain possible causes in simple language, without giving a final diagnosis.
- Do not prescribe medications, antibiotics, painkillers, doses, or drug names.
- Do not tell the patient to start/stop medication.
- Encourage professional dental consultation when needed.
- Ask 1-3 short follow-up questions only when they help triage the dental problem.
- Be calm, friendly, and concise.
- Never ignore urgent red flags. If urgent is true, the first part of the answer must clearly advise same-day dental care.

Language:
- Detected style: {style}
- {language_instruction}
- If style is franco, examples of the expected tone are: "fahemak", "momken ykoon", "el ahsan tekshaf", "matakhodsh dawa men nafsak", "hal fe waram aw soded?"

Safety:
- {urgent_instruction}
- If there is swelling, pus, fever, severe pain, trauma, uncontrolled bleeding, or difficulty swallowing/breathing, treat it as urgent.
""".strip()

        user_prompt = f"""
Recent chat:
{recent_history or "No previous chat in this session."}

Retrieved dental textbook context:
{context}

Patient message:
{user_message}

Answer as SHAGY. Start directly with the patient-facing answer:
""".strip()

        return system_prompt, user_prompt

    def _apply_safety_floor(self, answer: str, style: str, urgent: bool) -> str:
        if not urgent:
            return answer

        checks = {
            "arabic": ["نفس اليوم", "طوارئ", "دكتور", "طبيب", "كشف"],
            "franco": ["nafs el youm", "doctor", "dentist", "kashf", "taware2", "emergency"],
            "english": ["same-day", "same day", "urgent", "emergency", "dentist"],
        }[style]
        if any(check.lower() in answer.lower() for check in checks):
            return answer

        prefix = {
            "arabic": "بما إن فيه تورم/صديد أو وجع شديد، الأفضل تكشف عند دكتور أسنان في نفس اليوم. لو في صعوبة بلع أو تنفس، دي طوارئ فورًا.\n\n",
            "franco": "3ashan fe waram/soded aw waga3 gamed, el ahsan tekshaf 3and dentist nafs el youm. Law fe so3oba fel bala3 aw el tanafos, de emergency delwa2ty.\n\n",
            "english": "Because there is swelling/pus or severe pain, please arrange same-day dental care. If swallowing or breathing is difficult, seek emergency care now.\n\n",
        }[style]
        return prefix + answer

    def _tailored_fallback(self, user_message: str, style: str, urgent: bool) -> str | None:
        text = user_message.lower()

        if urgent:
            return None

        if any(word in text for word in ["bleed", "blood", "نزيف", "دم", "بتنزف", "nezif", "btenzef", "btinzef"]):
            if style == "franco":
                return "Nazif el ltha ma3 el tafreesh momken ykoon mn eltehab ltha aw geer metrakem. Estakhdem forsah soft w khali el tandif yomyan, w law el nazif byetkarar aw sheded, el ahsan tekshaf 3and dentist."
            if style == "arabic":
                return "نزيف اللثة مع التفريش ممكن يكون من التهاب لثة أو تراكم جير. استخدم فرشة ناعمة، ولو النزيف بيتكرر أو شديد الأفضل تكشف عند دكتور أسنان."
            return "Bleeding gums while brushing can happen with gum inflammation or tartar buildup. Use a soft brush and keep cleaning gently. If it keeps happening or is heavy, book a dental checkup."

        if any(word in text for word in ["bad breath", "ريحة", "رائحة", "وحشة", "ri7a", "ree7a", "we7sha", "smell"]):
            if style == "franco":
                return "El ri7a el we7sha momken tkoun mn geer, eltehab ltha, tasawos, ba2aya akl, aw gofaf el bo2. Naddaf lesanak, estakhdem floss, w eshrab maya. Law mostamera ma3 el tafreesh, el ahsan tekshaf."
            if style == "arabic":
                return "الريحة الوحشة ممكن تكون من جير، التهاب لثة، تسوس، بقايا أكل، أو جفاف الفم. نظف اللسان واستخدم الخيط، ولو مستمرة مع التفريش الأفضل تكشف."
            return "Bad breath can come from tartar, gum inflammation, decay, trapped food, or dry mouth. Clean your tongue, floss, and drink water. If it continues despite brushing, see a dentist."

        if any(word in text for word in ["gum infection", "gum pain", "التهاب لثة", "اللثة", "ltha", "gum"]):
            if style == "franco":
                return "Moshakel el ltha momken teb2a mn geer, tafreesh 3aneef, aw eltehab. Hafed 3ala tafreesh gentle w floss, w law fe nazif, waram, soded, aw waga3 mostamer, el ahsan tekshaf 3and dentist."
            if style == "arabic":
                return "مشاكل اللثة ممكن تكون من جير، تفريش عنيف، أو التهاب. حافظ على تفريش لطيف واستخدام الخيط، ولو في نزيف، تورم، صديد، أو ألم مستمر، الأفضل تكشف عند دكتور أسنان."
            return "Gum pain or infection signs can come from plaque/tartar, brushing trauma, or gum inflammation. Keep cleaning gently, and see a dentist if there is bleeding, swelling, pus, or persistent pain."

        if any(word in text for word in ["headache", "صداع", "soda3", "soda2"]):
            if style == "franco":
                return "Ah, waga3 el ders momken yesa3ed 3ala soda3, khosoosan law fe eltehab, pressure, aw gaz 3ala el asnan. Bas el soda3 leeh asbab kteer, fa law el ders byewga3 aw el soda3 mostamer, kashf dentist monaseb."
            if style == "arabic":
                return "ألم الضرس ممكن يسبب صداع أو يحسسك بألم في مناطق قريبة، خصوصًا مع التهاب أو ضغط/جز على الأسنان. لكن الصداع له أسباب كتير، فلو الضرس بيوجع أو الصداع مستمر الأفضل تكشف."
            return "Tooth problems can contribute to headache-like pain, especially with inflammation, bite pressure, or clenching. Headaches have many causes, so if tooth pain is present or it persists, get a dental check."

        if any(word in text for word in ["black", "turned black", "سن سودا", "سودا"]):
            if style == "franco":
                return "Law el senn eswed aw etghayar lonoh, da momken ykoon tasawos, staining, old trauma, aw moshkela fe el nerve. El ahsan kashf 3ashan el dentist ye3raf el sabab w el treatment el monaseb."
            if style == "arabic":
                return "لو السن اسود أو لونه اتغير، ده ممكن يكون تسوس، تصبغ، خبطة قديمة، أو مشكلة في العصب. الأفضل تكشف عشان الدكتور يحدد السبب والعلاج المناسب."
            return "A tooth turning black can be from decay, staining, old trauma, or nerve problems. A dentist should check it to identify the cause and the right treatment."

        if any(word in text for word in ["sweet", "حلويات", "الحلويات"]):
            if style == "franco":
                return "El waga3 ma3 el 7elw momken ykoon mn tasawos aw sensitivity fe enamel/root. 7awel te2alel el sugary snacks, w law el waga3 byetkarar, kashf dentist hayban el sabab."
            if style == "arabic":
                return "الوجع مع الحلويات ممكن يكون من تسوس أو حساسية في المينا/الجذر. حاول تقلل السكريات، ولو الألم بيتكرر الأفضل تكشف عشان يتحدد السبب."
            return "Pain with sweets can be a sign of decay or enamel/root sensitivity. Try to limit sugary snacks, and if it keeps happening, a dentist should check the cause."

        if any(word in text for word in ["root canal", "عصب", "3asab"]):
            if style == "franco":
                return "7ashw el 3asab byet3amel b banj, fa el mafrood maykoonsh fe waga3 gamed waqt el procedure. Momken te7es b pressure aw sensitivity ba3dha kam yom. 3adad el sessions beyefre2 7asab 7alet el ders, fa el dentist howa elly ye2dar ye7aded."
            if style == "arabic":
                return "حشو العصب بيتعمل ببنج، فالمفروض ميبقاش فيه وجع شديد أثناء الإجراء. ممكن تحس بحساسية أو ضغط كام يوم بعده. عدد الجلسات بيختلف حسب حالة الضرس، والدكتور يحدده بعد الكشف."
            return "Root canal treatment is done with local anesthesia, so it should not be severely painful during the procedure. Some soreness or pressure for a few days can happen. The number of sessions depends on the tooth, so the dentist decides after examining it."

        if any(word in text for word in ["extraction", "extract", "خلع", "khala3"]):
            if style == "franco":
                return "Khala3 el ders byet3amel b banj, fa el mafrood mat7essesh b waga3 gamed waqt el khala3, bas momken te7es b pressure. Ba3do, etba3 ta3leemat el dentist, w law fe bleeding keteer aw waga3 beyzeed lazem terga3lo."
            if style == "arabic":
                return "خلع الضرس بيتعمل ببنج، فالمفروض ميبقاش فيه وجع شديد وقت الخلع لكن ممكن تحس بضغط. بعده اتبع تعليمات دكتور الأسنان، ولو في نزيف كتير أو ألم بيزيد لازم تراجعه."
            return "Tooth extraction is done with local anesthesia, so it should not be sharply painful during the procedure, though pressure is common. Follow aftercare instructions, and seek care if bleeding is heavy or pain worsens."

        if any(word in text for word in ["wisdom", "ضرس العقل", "3a2l"]):
            if style == "franco":
                return "Waga3 ders el 3a2l momken ykoon 3ashan tale3 be zawaia aw 3amel eltehab fe el ltha 7awaleh. Law fe waram, soded, aw ma2darsh tefta7 bo2ak kwayes, keda lazem kashf 2orayeb."
            if style == "arabic":
                return "وجع ضرس العقل ممكن يكون بسبب إنه طالع بزاوية أو عامل التهاب في اللثة حواليه. لو في تورم، صديد، أو صعوبة تفتح فمك كويس، الأفضل تكشف قريب."
            return "Wisdom tooth pain can happen if it is erupting at an angle or irritating the gum around it. Swelling, pus, or trouble opening your mouth needs a dental check soon."

        if any(word in text for word in ["cleaning", "scaling", "جير", "تنظيف", "tandif", "geer"]):
            if style == "franco":
                return "Tandif el geer momken yeb2a feeh discomfort bas mesh mafrood yeb2a waga3 gamed. Law el ltha moltaheba, el sensitivity ba3do momken teban shwaya w te2el ma3 el wa2t."
            if style == "arabic":
                return "تنظيف الجير ممكن يسبب انزعاج بسيط، لكنه مش المفروض يبقى مؤلم جدًا. لو اللثة ملتهبة، ممكن تحس بحساسية بعدها شوية وتقل مع الوقت."
            return "Dental cleaning can cause some discomfort, especially if gums are inflamed, but it should not be severely painful. Mild sensitivity afterward can happen and usually settles."

        if any(word in text for word in ["braces", "تقويم", "taqwim"]):
            if style == "franco":
                return "El taqwim momken yewga3 aw yeday2 ba3d el tarkeeb aw el tightening kam yom. Da common, bas law fe wire beyegra7 aw waga3 gamed, kalem el orthodontist."
            if style == "arabic":
                return "التقويم ممكن يسبب وجع أو ضغط كام يوم بعد التركيب أو الشد. ده شائع، لكن لو في سلك بيجرح أو ألم شديد، كلم دكتور التقويم."
            return "Braces can cause soreness or pressure for a few days after fitting or tightening. If a wire is cutting your mouth or pain is severe, contact your orthodontist."

        if any(word in text for word in ["whitening", "yellow", "safra", "أفتح", "تبييض", "صفرا"]) and not any(word in text for word in ["jaw", "faky", "الفك", "فكي", "بيطق"]):
            if style == "franco":
                return "Taftee7 el asnan momken ykoon safe law et3amel 3and dentist aw b taree2a monasba. Momken ya3mel sensitivity mo2a2ata. Balash products 2aweya men gheir kashf 3ashan mat2azeesh el ltha aw el enamel."
            if style == "arabic":
                return "تبييض الأسنان ممكن يكون آمن لو اتعمل بطريقة مناسبة أو تحت إشراف دكتور. ممكن يسبب حساسية مؤقتة، وبلاش منتجات قوية من غير كشف عشان متأذيش اللثة أو المينا."
            return "Teeth whitening can be safe when done properly or supervised by a dentist. Temporary sensitivity can happen. Avoid strong unsupervised products because they can irritate gums or enamel."

        if any(word in text for word in ["cracked", "crack", "broken", "مكسور", "kasr", "maksoor"]):
            if style == "franco":
                return "Law el senn maksor aw feeh crack, balash takol 3aleh w 7awel te7gez kashf 2orayeb. El dentist haye7aded hal محتاج 7ashwa, crown, aw treatment tany 7asab 3om2 el kasr."
            if style == "arabic":
                return "لو السن مكسور أو فيه شرخ، متاكلش عليه واحجز كشف قريب. الدكتور يحدد هل محتاج حشو، طربوش، أو علاج تاني حسب عمق الكسر."
            return "If a tooth is cracked or broken, avoid chewing on it and book a dental exam soon. The dentist can decide whether it needs a filling, crown, or other treatment depending on depth."

        if any(word in text for word in ["loose", "moving", "بيتحرك", "met7arek"]):
            if style == "franco":
                return "Law el senn beyetharak, da momken ykoon mn el ltha, trauma, aw pressure 3ala el asnan. El ahsan tekshaf 3ashan el dentist ye2eem daraget el movement w sababha."
            if style == "arabic":
                return "لو السن بيتحرك، ده ممكن يكون من مشكلة في اللثة، خبطة، أو ضغط على الأسنان. الأفضل تكشف عشان الدكتور يحدد درجة الحركة وسببها."
            return "A loose tooth can be related to gum disease, trauma, or bite pressure. It is best to see a dentist so they can check the amount of mobility and the cause."

        if any(word in text for word in ["jaw", "click", "faky", "الفك", "فكي", "بيطق"]):
            if style == "franco":
                return "Waga3 aw click fe el fak momken ykoon mn el jaw joint, gaz 3ala el asnan, aw muscle tension. Law fe waga3 mostamer, locking, aw ma2darsh tefta7 bo2ak kwayes, kashf dentist monaseb."
            if style == "arabic":
                return "وجع أو طقطقة الفك ممكن تكون من مفصل الفك، الجز على الأسنان، أو شد عضلي. لو في ألم مستمر، قفل في الفك، أو صعوبة فتح الفم، الأفضل تكشف."
            return "Jaw pain or clicking can come from the jaw joint, clenching/grinding, or muscle tension. Persistent pain, locking, or trouble opening your mouth should be checked."

        if any(word in text for word in ["ulcer", "sores", "قرح", "تقرحات"]):
            if style == "franco":
                return "El ta2aro7at fe el bo2 ghaleban btet7asen lwa7daha, bas law betetkarar, kbera, aw mkamla aktar mn 2 weeks, lazem kashf. 7awel teb3ed 3an el akl el spicy aw el 7amed law beyzeodha."
            if style == "arabic":
                return "تقرحات الفم غالبًا بتتحسن لوحدها، لكن لو بتتكرر، كبيرة، أو مستمرة أكتر من أسبوعين، لازم كشف. حاول تبعد عن الأكل الحار أو الحمضي لو بيزودها."
            return "Mouth ulcers often heal on their own, but repeated, large, or longer-than-two-week ulcers should be checked. Avoid spicy or acidic foods if they make it worse."

        if any(word in text for word in ["crown", "طربوش", "tarboosh"]):
            if style == "franco":
                return "Waga3 ta7t el crown momken ykoon mn bite 3aly, tasawos ta7teh, gum irritation, aw nerve problem. Law el waga3 ma3 el 3ad aw ba3d el akl, lazem dentist yerage3 el crown."
            if style == "arabic":
                return "الوجع تحت الطربوش ممكن يكون من عضة عالية، تسوس تحته، التهاب لثة، أو مشكلة في العصب. لو الوجع مع العض أو بعد الأكل، لازم دكتور يراجع الطربوش."
            return "Pain under a crown can come from a high bite, decay under it, gum irritation, or nerve problems. If it hurts when biting or after eating, a dentist should check the crown."

        if any(word in text for word in ["implant", "زراعة", "زرعة"]):
            if style == "franco":
                return "Zera3et el asnan betet3amel b banj, fa waqt el procedure el waga3 el mafrood yeb2a limited. El modda btetghayar 7asab el 3adm w el healing, w el dentist ye2dar ye2olak el plan ba3d el kashf."
            if style == "arabic":
                return "زراعة الأسنان بتتعمل ببنج، فالألم وقت الإجراء المفروض يكون محدود. المدة بتختلف حسب العظم والالتئام، والدكتور يحدد الخطة بعد الكشف."
            return "Dental implants are placed with local anesthesia, so pain during the procedure should be limited. Timing depends on bone and healing, and the dentist decides the plan after assessment."

        if any(word in text for word in ["antibiotic", "antibiotics", "مضاد", "المضاد"]):
            if style == "franco":
                return "El antibiotics law7daha mesh bet7el sabab waga3 el ders fel ghaleb. Matakhodsh antibiotic men nafsak; lazem dentist yshof el sabab, w law fe waram aw fever kashf nafs el youm."
            if style == "arabic":
                return "المضاد الحيوي لوحده غالبًا مش بيحل سبب وجع الضرس. متاخدش مضاد من نفسك؛ لازم دكتور يحدد السبب، ولو في تورم أو حرارة يبقى كشف في نفس اليوم."
            return "Antibiotics alone usually do not fix the cause of tooth pain. Do not start antibiotics on your own; a dentist needs to check the cause, especially with swelling or fever."

        if any(word in text for word in ["biting", "bite", "chewing", "أعض", "العض", "bakol", "3ad"]):
            if style == "franco":
                return "El waga3 lama te3od aw takol momken ykoon mn crack, 7ashwa 3alya, eltehab 7awaleen el root, aw moshkela fe el ltha. Balash tedos 3aleh kteer w e7gez kashf."
            if style == "arabic":
                return "الوجع مع العض أو الأكل ممكن يكون من شرخ، حشو عالي، التهاب حول الجذر، أو مشكلة في اللثة. حاول متضغطش عليه واحجز كشف."
            return "Pain when biting or chewing can come from a crack, a high filling, inflammation around the root, or gum problems. Avoid heavy chewing on it and book a dental check."

        if any(word in text for word in ["gap", "gaps", "feraghat", "فراغات"]):
            if style == "franco":
                return "El feraghat ben el asnan momken tkoun tabee3eya aw mn ltha/haraket asnan. El 7al beyefre2: taqwim, bonding, veneers, aw treatment lel ltha law fe sabab. El dentist ye7aded el ansab."
            if style == "arabic":
                return "الفراغات بين الأسنان ممكن تكون طبيعية أو بسبب حركة الأسنان/مشاكل لثة. الحل يختلف بين تقويم، حشو تجميلي، فينير، أو علاج لثة حسب السبب."
            return "Gaps between teeth can be natural or related to tooth movement or gum issues. Options may include braces, bonding, veneers, or gum treatment depending on the cause."

        if any(word in text for word in ["filling fell", "حشو وقع", "حشوة وقعت", "7ashwa wa2e3a", "7ashw wa2e3", "wa2e3a", "fell out"]):
            if style == "franco":
                return "Law el 7ashwa wa2e3a, balash takol 3ala el na7ya di l7ad ma tekshaf, w khali el makan nedeef bel ra7a. Lazem dentist yshof el senn 3ashan may7salsh tasawos aw kasr aktar."
            if style == "arabic":
                return "لو الحشو وقع، حاول متاكلش على الناحية دي لحد الكشف وخلي المكان نضيف بلطف. لازم دكتور أسنان يشوف السن قريب عشان يمنع تسوس أو كسر أكتر."
            return "If a filling fell out, avoid chewing on that side and keep the area gently clean. A dentist should check it soon to prevent more decay or fracture."

        if any(word in text for word in ["after filling", "filling hurts", "بعد الحشو", "ba3d el 7ashwa", "ba3d el 7ashw", "7ashwa"]):
            if style == "franco":
                return "Waga3 ba3d el 7ashwa momken ykoon sensitivity mo2a2ata, 7ashwa 3alya, aw el cavity kan 3ame2. Law el waga3 ma3 el 3ad, beyzeed, aw mkamel aktar mn kam yom, lazem dentist yerage3 el 7ashwa."
            if style == "arabic":
                return "الوجع بعد الحشو ممكن يكون حساسية مؤقتة، حشو عالي، أو إن التسوس كان عميق. لو الوجع مع العض، بيزيد، أو مستمر أكتر من كام يوم، لازم الدكتور يراجع الحشو."
            return "Pain after a filling can be temporary sensitivity, a high filling, or a deep cavity close to the nerve. If it hurts when biting, worsens, or lasts more than a few days, the dentist should recheck it."

        if any(word in text for word in ["cold", "ساقع", "بارد", "حساسية", "sa2a", "sa23a", "elsa23a", "met7assa", "sensitive", "sensitivity"]):
            if style == "franco":
                return "El waga3 ma3 el sa2a momken ykoon sensitivity, tasawos, 7ashwa 2orayba mn el 3asab, aw bedayet eltehab 3asab. Law el waga3 byro7 besor3a ba3d el sa2a yeb2a ahwan, bas law beyefdal aw beyzeed lazem kashf."
            if style == "arabic":
                return "الوجع مع الساقع ممكن يكون حساسية، تسوس، حشو قريب من العصب، أو بداية التهاب عصب. لو الألم بيفضل بعد الساقع أو بيزيد، الأفضل تكشف."
            return "Pain with cold can be sensitivity, decay, a deep filling, or early nerve irritation. If it lingers after the cold or gets stronger, book a dental exam."

        if any(word in text for word in ["night", "sleep", "ليل", "النوم", "bel leil", "belleil"]):
            if style == "franco":
                return "Waga3 el ders elly beyzeed bel leil momken ykoon mn eltehab 3asab aw gaz/pressure 3ala el asnan. Law el waga3 beys7eek mn el nom aw mostamer, el ahsan tekshaf 2orayeb."
            if style == "arabic":
                return "وجع الأسنان اللي بيزيد بالليل ممكن يكون من التهاب عصب أو ضغط/جز على الأسنان. لو بيصحّيك من النوم أو مستمر، الأفضل تكشف قريب."
            return "Tooth pain that gets worse at night can happen with nerve inflammation or clenching/grinding. If it wakes you up or keeps coming back, arrange a dental exam soon."

        if any(word in text for word in ["random", "من غير سبب", "without reason"]):
            if style == "franco":
                return "Waga3 el ders elly beygy mn gher sabab wa2e7 momken ykoon mn sensitivity, tasawos badry, pressure, aw eltehab lesa bady. Law beytekarar, beyzeed, aw ma3ah waram, el ahsan tekshaf."
            if style == "arabic":
                return "وجع السن من غير سبب واضح ممكن يكون من حساسية، تسوس بدري، ضغط على الأسنان، أو بداية التهاب. لو بيتكرر، بيزيد، أو معاه تورم، الأفضل تكشف."
            return "Random tooth pain can come from sensitivity, early decay, bite pressure, or early inflammation. If it keeps happening, gets worse, or comes with swelling, book a dental check."

        return None

    def _fallback_answer(self, user_message: str, style: str, urgent: bool) -> str:
        tailored = self._tailored_fallback(user_message, style, urgent)
        if tailored:
            return tailored

        if urgent:
            return {
                "arabic": "فاهمك. الأعراض دي ممكن تكون من التهاب أو خراج، ومحتاجة كشف أسنان في نفس اليوم. لو في صعوبة بلع أو تنفس، روحي طوارئ فورًا. من غير كشف مقدرش أحدد التشخيص النهائي.",
                "franco": "Fahemak. Da momken ykoon eltehab aw khurag, wel ahsan tekshaf 3and dentist nafs el youm. Law fe so3oba fel bala3 aw el tanafos, ro7 emergency delwa2ty. Men gher kashf ma2darsh a2ool tashkhees final.",
                "english": "I understand. This could be inflammation or an abscess, so please arrange same-day dental care. If swallowing or breathing is difficult, seek emergency care now. I cannot give a final diagnosis without an exam.",
            }[style]

        if style == "arabic":
            return "فاهمك. وجع الأسنان ممكن يكون من تسوس، التهاب عصب، حساسية، أو مشكلة في اللثة/الحشو. الأفضل تكشف عند دكتور أسنان لو الوجع مستمر أو بيزيد. هل الوجع مع الساقع/السخن، ولا مع العض؟"
        if style == "franco":
            return "Fahemak. Waga3 el ders momken ykoon mn tasawos, eltehab 3asab, sensitivity, aw moshkela fe el ltha/7ashwa. El ahsan tekshaf law el waga3 mostamer aw beyzeed. El waga3 ma3 el sa2a/sokhn wala lama te3od?"
        return "I understand. Tooth pain can come from decay, nerve inflammation, sensitivity, gum problems, or a filling/crown issue. Please see a dentist if it continues or gets worse. Does it hurt with cold/heat, or when you bite?"

    def _off_topic_reply(self, style: str) -> str:
        if style == "arabic":
            return "أنا SHAGY، أقدر أساعدك في أسئلة الأسنان والفم بس. قولي إيه المشكلة اللي عندك في سنانك أو لثتك؟"
        if style == "franco":
            return "Ana SHAGY, a2dar asa3dek fe as2elet el asnan wel bo2 bas. Eh el moshkela elly 3andek fe senanek aw lsetak?"
        return "I am SHAGY, and I can help with dental and oral-health questions only. What is happening with your teeth, gums, or mouth?"


if __name__ == "__main__":
    shagy = ShagyAssistant()
    chat_history: list[dict[str, str]] = []
    print("SHAGY is ready. Type 'exit' to stop.")
    while True:
        user_text = input("Patient: ").strip()
        if user_text.lower() in {"exit", "quit"}:
            break
        if not user_text:
            continue
        result = shagy.answer(user_text, chat_history)
        print(f"SHAGY: {result['answer']}\n")
        chat_history.append({"role": "patient", "content": user_text})
        chat_history.append({"role": "assistant", "content": result["answer"]})
