## Day 24: AI and AI Agents Basic Workflow
### Key concepts
- The core idea of AI and AI Agents basic workflow is to understand the steps involved in creating an AI agent. This involves understanding the simple exercise of creating an agent, identifying common beginner mistakes such as not testing the agent, and learning from them to improve the project.
### Examples
```python
# Example of a basic workflow of an AI agent
import random

class Agent:
    def __init__(self):
        self.actions = ['move', 'jump', 'shoot']
    def act(self):
        return random.choice(self.actions)
    def test(self):
        print('Testing the agent')
```
### Practice notes
- Implement a basic workflow of an AI agent using a programming language of your choice.
- Identify and fix common beginner mistakes in your project.
### Questions I have
- Q: What is the basic workflow of AI and AI Agents?
  A: The basic workflow includes creating an agent, defining its actions and goals, testing the agent, and refining its performance.
- Q: How do I test my AI agent?