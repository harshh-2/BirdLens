from pydantic import BaseModel

class PredictionResponse(BaseModel):
    bird: str
    confidence: float
    is_confident:bool