## Day 3: AI and AI Agents: Key terms and mental models
### Key concepts
- Key terms in AI and AI Agents include machine learning, deep learning, neural networks, and natural language processing. Mental models include the concept of agents, environments, and actions. Understanding these key terms and mental models is crucial for building and working with AI and AI Agents.
### Examples
```python
# Example of a simple neural network
import numpy as np

class NeuralNetwork:
    def __init__(self, inputs, outputs):
        self.inputs = inputs
        self.outputs = outputs
    def forward(self, inputs):
        return np.dot(inputs, self.outputs)

neural_network = NeuralNetwork(np.array([1, 2, 3]), np.array([4, 5, 6]))
print(neural_network.forward(np.array([1, 2, 3])))
```
### Practice notes
- Research and list 5 key terms in AI and AI Agents
- Draw a diagram of a simple neural network
### Questions I have
- Q: What is the plain-English definition of AI and AI Agents?
  A: AI stands for Artificial Intelligence, which refers to the development of computer systems that can perform tasks that typically require human intelligence. AI Agents are programs that use AI to make decisions and take actions autonomously.
- Q: What are the key terms in AI and AI Agents?
  A: Key terms in AI and AI Agents include machine learning, deep learning, neural networks, and natural language processing.