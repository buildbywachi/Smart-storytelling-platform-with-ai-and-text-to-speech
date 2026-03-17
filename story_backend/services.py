import base64
import re
from openai import OpenAI
import edge_tts

# LM Studio (Local Server)
client = OpenAI(base_url="http://localhost:1234/v1", api_key="lm-studio")

# ====== Content Policy / Prompt ======
SYSTEM_PROMPT = """
คุณคือ AI นักเล่านิทานภาษาไทยสำหรับผู้ใช้ทั่วไป
ข้อกำหนด:
- ตอบเป็นภาษาไทยล้วน ใช้คำสะกดถูกต้อง อ่านลื่น เป็นธรรมชาติ
- แต่งนิทานสั้น 8-10 ประโยค มีต้นเรื่อง-ปัญหา-คลี่คลาย-คติสอนใจ-จบ
- ห้ามมีเนื้อหาล่อแหลมทางเพศ, อนาจาร, หรือเกี่ยวกับเด็กในเชิงไม่เหมาะสม
- ห้ามมีความรุนแรง, อาวุธ, หรือการทำร้าย เช่น ปืน มีด ระเบิด เลือด การฆ่า
- ห้ามคำหยาบ คำเหยียด หรือเนื้อหาที่ทำให้ผู้อื่นเสื่อมเสีย
- ห้ามมีอักษรหรือคำต่างชาติปน (เช่น อังกฤษ รัสเซีย) ถ้าจำเป็นให้ใช้คำไทยแทน
หากหัวข้อเสี่ยง ให้ปรับให้เป็นนิทานเชิงบวกและปลอดภัย
""".strip()

# เสียงที่อนุญาต (ให้ตรงกับที่ TTS รองรับ)
ALLOWED_VOICES = {
    "th-TH-PremwadeeNeural": "เสียงผู้หญิง (Premwadee)",
    "th-TH-NiwatNeural": "เสียงผู้ชาย (Niwat)",
}

# BANNED_WORDS ใช้ตรวจสอบคำต้องห้ามในเนื้อหา
BANNED_WORDS = [
    "ปืน", "มีด", "ระเบิด", "ยิง", "ฆ่า", "เลือด", "ทำร้าย",
    "เซ็กส์", "อนาจาร", "ลามก", "เด็กไม่ควรดู", "คำหยาบ", "คำเหยียด",
]

# ฟังก์ชันตรวจสอบคำต้องห้ามและอักษรต่างชาติ
def contains_banned(text: str) -> bool:
    t = text or ""
    return any(w in t for w in BANNED_WORDS)

# ฟังก์ชันตรวจสอบอักษรละตินหรือซีริลลิก (กันกรณีคำเพี้ยนแบบแปลก ๆ)
def has_foreign_letters(text: str) -> bool:
    # ตรวจอักษรละติน + ซีริลลิก (เพื่อความแน่ใจว่าไม่มีตัวอักษรต่างชาติปน)
    return bool(re.search(r"[A-Za-z\u0400-\u04FF]", text or ""))

# ฟังก์ชันสร้าง prompt สำหรับ LM Studio
def _make_messages(topic: str, voice: str, extra_instruction: str = ""):
    voice_hint = ALLOWED_VOICES.get(voice, "เสียงมาตรฐาน")
    user_prompt = (
        f"หัวข้อ: {topic}\n"
        f"เสียงผู้บรรยายที่เลือก: {voice_hint}\n"
        "กรุณาแต่งนิทานตามข้อกำหนดด้านบน"
    )
    if extra_instruction:
        user_prompt += "\n" + extra_instruction

    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt},
    ]

# ฟังก์ชันหลักในการสร้างนิทานและเสียง 
def _generate_story_text(topic: str, voice: str, extra_instruction: str = "") -> str:
    completion = client.chat.completions.create(
        model="thaistorymodel",
        messages=_make_messages(topic, voice, extra_instruction),
        temperature=0.8,
        top_p=0.95, 
        max_tokens=500,   # ปรับตามความยาวที่ต้องการ (ตัวอย่างนี้ประมาณ 8-10 ประโยค)
    )
    return (completion.choices[0].message.content or "").strip()

# ฟังก์ชันหลักที่ถูกเรียกจาก main.py
async def create_story_with_audio(topic: str, voice: str):
    """
    Return:
      {
        "story": <thai story>,
        "audio": <base64 audio or null>,
        "voice": <final voice id>
      }
    """
    # 1) Validate voice
    if voice not in ALLOWED_VOICES:
        voice = "th-TH-PremwadeeNeural"

    # 2) Generate story (try 1)
    story = _generate_story_text(topic, voice)

    # 3) If violates rules → retry once with stricter instruction
    if contains_banned(story) or has_foreign_letters(story):
        story = _generate_story_text(
            topic,
            voice,
            extra_instruction=(
                "โปรดเขียนใหม่ให้ปลอดภัย ห้ามมีคำเกี่ยวกับอาวุธ/ความรุนแรง/คำไม่เหมาะสม "
                "และห้ามมีอักษรต่างชาติปน ตรวจคำสะกดภาษาไทยก่อนตอบ"
            ),
        )

    # 4) Final safeguard
    if not story or contains_banned(story) or has_foreign_letters(story):
        story = (
            "ขออภัย ระบบไม่สามารถสร้างนิทานที่เหมาะสมจากหัวข้อนี้ได้ "
            "กรุณาลองเปลี่ยนหัวข้อให้เป็นเชิงบวกและปลอดภัยมากขึ้น"
        )

    # 5) Generate TTS
    try:
        communicate = edge_tts.Communicate(story, voice)
        audio_bytes = b""
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_bytes += chunk["data"]

        audio_base64 = base64.b64encode(audio_bytes).decode("utf-8") if audio_bytes else None

    except Exception:
        # ถ้า TTS ล้มเหลว ยังส่ง story กลับได้
        audio_base64 = None

    return {
        "story": story,
        "audio": audio_base64,
        "voice": voice,
    }