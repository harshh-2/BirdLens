from fastapi import APIRouter, UploadFile, File

from app.services.prediction import predict_bird
from app.schemas.prediction_schema import PredictionResponse

router = APIRouter(prefix="/api/predict",tags=["Prediction"])
@router.post("/",response_model=PredictionResponse)
async def predict(file: UploadFile = File(...)):
    return await predict_bird(file)