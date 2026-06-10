import json
import torch
import torch.nn as nn
from torchvision.models import (mobilenet_v2,MobileNet_V2_Weights)

class BirdClassifier:
    def __init__(self):
        self.model = None
        self.class_names = []
        self.load_model()
    def load_model(self):
        with open("app/models/class_names.json","r") as f:
            self.class_names = json.load(f)

        num_classes = len(self.class_names)
        self.model = mobilenet_v2(weights=MobileNet_V2_Weights.DEFAULT)
        self.model.classifier[1] = nn.Linear(1280,num_classes)
        self.model.load_state_dict(
            torch.load(
                "app/models/birds50_best.pth",
                map_location="cpu"
            )
        )
        self.model.eval()
        torch.set_grad_enabled(False)
    def predict(self,image_tensor):
        with torch.no_grad():
            outputs = self.model(image_tensor)
            probs = torch.softmax(outputs,dim=1)
            confidence, predicted = torch.max(probs,dim=1)
        return {
        "bird": self.class_names[predicted.item()],
        "confidence": round(confidence.item() * 100, 2),
        "is_confident": confidence.item() >= 0.65
        }
classifier = BirdClassifier()