## Day 12: AI and AI Agents Debugging and Review
### Key concepts
- The core idea of AI and AI Agents is to create intelligent systems that can perform tasks autonomously. Debugging and review are essential steps in ensuring that the system works correctly. Common beginner mistakes include not testing the system thoroughly and not using debugging tools.
### Examples
```python
# Example of debugging a simple AI agent
import pdb

class Agent:
    def __init__(self):
        self.actions = ['move', 'jump', 'shoot']
    def act(self):
        pdb.set_trace()
        return random.choice(self.actions)
```
### Practice notes
- Students should practice debugging and reviewing their AI and AI Agents code.
- They should use debugging tools and test the system thoroughly.
### Questions I have
- Q: What is the purpose of debugging in AI and AI Agents?
  A: The purpose of debugging is to identify and fix errors in the system.
- Q: How do I review my AI and AI Agents code?
  A: To review your code, you should test it thoroughly, use debugging tools, and seek feedback from others.