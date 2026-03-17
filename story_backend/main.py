# ไฟล์: main.py
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware


from models import StoryRequest 
from services import create_story_with_audio

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Endpoint สำหรับสร้างนิทานและเสียง
@app.post("/generate") 
async def generate_story_api(request: StoryRequest): # ใช้ StoryRequest จาก models.py
    print(f" API Received: {request.topic}, Voice: {request.voice}")
    
    try:
        # ส่ง topic และ voice ไปให้ services ทำงาน
        response_data = await create_story_with_audio(request.topic, request.voice)
        return response_data
    
    except Exception as e:
        print(f" Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    print(" Server starting on port 8000...")
    uvicorn.run(app, host="0.0.0.0", port=8000)