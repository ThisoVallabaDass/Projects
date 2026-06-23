# .pyw extension = runs without terminal window on Windows
import sys
import os

# Set working directory to project root — critical for terminal agent
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
os.chdir(project_root)
sys.path.insert(0, project_root)

from overlay.nila_overlay import launch_overlay
launch_overlay()
