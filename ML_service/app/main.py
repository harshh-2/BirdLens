from fastapi import FastAPI
from app.routes.prediction import router as prediction_router

app = FastAPI()
app.include_router(prediction_router)

@app.get("/health")
def health_check():
    return {"status":"ok"}

@app.get("/")
def root():
    return {"message":"BirdLens API is working fine!"}