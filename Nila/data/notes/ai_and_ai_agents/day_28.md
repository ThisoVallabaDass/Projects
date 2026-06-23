## Day 28: AI and AI Agents Core Building Blocks
### Key concepts
- The core idea of AI and AI Agents core building blocks is to understand the fundamental components of AI and AI Agents. A simple exercise in this context would be to create a basic agent that can perceive its environment and take actions. Common beginner mistakes include not understanding the different types of agents and not implementing them correctly.
### Examples
```python
import random

class Agent:
    def __init__(self):
        self.perception = None
    def perceive(self, environment):
        self.perception = environment
    def act(self):
        return random.choice(['left', 'right'])
```
### Practice notes
- Create a basic agent that can perceive its environment and take actions.
- Implement different types of agents and test them.
### Questions I have
- Q: What are the core building blocks of AI and AI Agents?
  A: The core building blocks include agents, environments, and actions.
- Q: How do I create a basic agent that can perceive its environment and take actions?
  A: You can create a basic agent by defining its perception and action methods.