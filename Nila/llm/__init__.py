"""Nila LLM module — Local model, web search chain, router, and online providers"""
from .ollama_client import OllamaClient
from .router import HybridRouter, classify_speed
from .local_model import LocalModel
from .web_search_chain import WebSearchChain

__all__ = ["OllamaClient", "HybridRouter", "classify_speed", "LocalModel", "WebSearchChain"]
