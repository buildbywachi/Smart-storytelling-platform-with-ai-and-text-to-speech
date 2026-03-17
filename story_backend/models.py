from pydantic import BaseModel


class StoryRequest(BaseModel):
    topic: str  # หัวข้อนิทาน
    voice: str #ตัวเลือกเสียง 