"""Quick evaluation without fancy formatting"""
import torch
import torch.nn as nn
from pathlib import Path
from torch.utils.data import DataLoader
import numpy as np
from utils import HygieneImageFolder, resolve_dataset_dir
from torchvision import transforms, models

device = "cuda" if torch.cuda.is_available() else "cpu"
dataset_dir = resolve_dataset_dir(None)

# Load checkpoint
checkpoint = torch.load("models/hygiene_model.pth", map_location=device, weights_only=False)
arch = checkpoint.get("arch", "resnet18")
idx_to_class = checkpoint.get("idx_to_class", {})

# Build model
model = models.resnet18(weights=None)
num_classes = len(idx_to_class) if idx_to_class else 3
in_features = model.fc.in_features
model.fc = nn.Linear(in_features, num_classes)
model.load_state_dict(checkpoint["model_state_dict"])
model = model.to(device).eval()

class_names = [idx_to_class[i] for i in sorted(idx_to_class.keys())]

# Create dataset
eval_transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

dataset = HygieneImageFolder(root=str(dataset_dir), transform=eval_transform)
loader = DataLoader(dataset, batch_size=32, shuffle=False, num_workers=0)

# Evaluate
all_preds = []
all_labels = []
correct = 0
total = 0

print("Evaluating...")
with torch.no_grad():
    for i, (images, labels) in enumerate(loader):
        images, labels = images.to(device), labels.to(device)
        outputs = model(images)
        preds = outputs.argmax(dim=1)
        
        correct += (preds == labels).sum().item()
        total += labels.size(0)
        
        all_preds.extend(preds.cpu().numpy())
        all_labels.extend(labels.cpu().numpy())
        
        if (i + 1) % 10 == 0:
            print(f"  Processed {min(total, len(dataset))}/{len(dataset)}")

overall_acc = correct / total
print(f"\nOVERALL ACCURACY: {overall_acc*100:.2f}%")

# Per-class metrics
from sklearn.metrics import confusion_matrix, precision_recall_fscore_support
cm = confusion_matrix(all_labels, all_preds)
prec, rec, f1, support = precision_recall_fscore_support(all_labels, all_preds)

print(f"\nPER-CLASS METRICS:")
for i, class_name in enumerate(class_names):
    print(f"  {class_name:15} Acc:{(cm[i,i]/cm[i].sum()*100):5.1f}% Prec:{prec[i]*100:5.1f}% Rec:{rec[i]*100:5.1f}% F1:{f1[i]*100:5.1f}%")

print(f"\nCONFUSION MATRIX:")
print("Predicted -->")
print("True |", " "*10, " ".join(f"{c[:8]:>10}" for c in class_names))
for i, row in enumerate(cm):
    print(f"{class_names[i][:12]:>14}", " ".join(f"{v:>10}" for v in row))
