## Day 30: AI and AI Agents Hands-on Exercise
### Key concepts
- The core idea of AI and AI Agents hands-on exercise is to apply the concepts learned in the course to a practical project. A simple exercise in this context would be to create a basic game-playing agent. Common beginner mistakes include not understanding the game rules and not implementing the agent correctly.
### Examples
```python
import random

class GamePlayingAgent:
    def __init__(self):
        self.game_state = None
    def perceive(self, game_state):
        self.game_state = game_state
    def act(self):
        return random.choice(['up', 'down', 'left', 'right'])
```
### Practice notes
- Create a basic game-playing agent.
- Implement the agent correctly and test it.
### Questions I have
- Q: What is the purpose of AI and AI Agents hands-on exercise?
  A: The purpose is to apply the concepts learned in the course to a practical project and gain hands-on experience.
- Q: How do I create a basic game-playing agent?
  A: You can create a basic game-playing agent by defining its perception and action methods, and implementing them using a programming language like Python.