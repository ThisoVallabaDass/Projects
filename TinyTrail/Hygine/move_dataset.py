import torch
import torch.nn as nn
import torchvision.models as models

from torchvision import datasets, transforms
from torch.utils.data import DataLoader

# image preprocessing
transform = transforms.Compose([
    transforms.Resize((224,224)),
    transforms.ToTensor()
])

# load dataset
dataset = datasets.ImageFolder(
    root="dataset",
    transform=transform
)

train_loader = DataLoader(
    dataset,
    batch_size=32,
    shuffle=True
)

print("Classes:", dataset.classes)

# load pretrained model
model = models.resnet18(weights="DEFAULT")

# modify output layer for 3 classes
model.fc = nn.Linear(model.fc.in_features, 3)

# loss function
criterion = nn.CrossEntropyLoss()

# optimizer
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

epochs = 5

for epoch in range(epochs):

    running_loss = 0

    for images, labels in train_loader:

        outputs = model(images)

        loss = criterion(outputs, labels)

        optimizer.zero_grad()

        loss.backward()

        optimizer.step()

        running_loss += loss.item()

    print(f"Epoch {epoch+1}/{epochs} Loss: {running_loss}")

# save trained model
torch.save(model.state_dict(), "models/hygiene_model.pth")

print("Model saved in models/hygiene_model.pth")