from fastapi import HTTPException
from PIL import Image
from io import BytesIO

from app.models.bird_classifier import classifier
from app.utils.image_processor import preprocess_image

MAX_FILE_SIZE = 3*1024*1024

ALLOWED_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp"
}

async def predict_bird(file):

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400,detail="Only JPG, PNG and WEBP images are allowed.")
    contents = await file.read()
    if len(contents) > MAX_FILE_SIZE:raise HTTPException(status_code=413,detail="File too large. Maximum size is 3MB.")
    try:
        Image.open(BytesIO(contents)).verify()
        image = Image.open(
            BytesIO(contents)
        ).convert("RGB")
        width, height = image.size
        if width > 10000 or height > 10000:
            raise HTTPException(
        status_code=400,
        detail="Image dimensions too large."
        )
    except Exception:
        raise HTTPException(status_code=400,detail="Invalid image file.")
    tensor = preprocess_image(image)
    prediction = classifier.predict(tensor)
    return prediction