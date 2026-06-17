import os

for folder in os.listdir("dataset"):
    path = os.path.join("dataset", folder)
    print(folder, len(os.listdir(path)))