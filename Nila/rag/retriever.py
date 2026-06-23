"""
RAG Retriever - Retrieval Augmented Generation for personalized context
"""

from typing import List, Dict
from .embeddings import EmbeddingEngine
from .vector_db import VectorDB


class RAGRetriever:
    """
    Combines embeddings + vector DB to retrieve relevant context for user queries.

    When user asks "What's my task today?":
    1. Embed the query
    2. Find similar facts/goals/notes in vector DB
    3. Return top-k relevant memories
    4. Local LLM uses these as context to generate personalized response
    """

    def __init__(self, vector_db: VectorDB, embedding_engine: EmbeddingEngine):
        """
        Args:
            vector_db: ChromaDB instance
            embedding_engine: SentenceTransformer instance
        """
        self.db = vector_db
        self.embeddings = embedding_engine

    def retrieve(self, query: str, top_k: int = 5) -> List[Dict]:
        """
        Retrieve relevant memories for a user query.

        Args:
            query: User question or statement
            top_k: Number of results to return

        Returns:
            List of relevant memories with text and relevance scores
        """
        # Embed the query
        query_embedding = self.embeddings.embed_text(query)

        # Search across all collections
        results = self.db.search_all(query_embedding.tolist(), top_k=top_k)

        return results

    def format_context(self, results: List[Dict]) -> str:
        """
        Format search results into a context string for the LLM.

        Args:
            results: List of search results from retrieve()

        Returns:
            Formatted context string
        """
        if not results:
            return "[No relevant memory found]"

        context_parts = []
        for i, result in enumerate(results, 1):
            result_type = result.get("type", "unknown").upper()
            text = result.get("text", "")
            confidence = 1.0 - result.get("distance", 1.0)  # Convert distance to confidence

            context_parts.append(f"{result_type}: {text} (confidence: {confidence:.2f})")

        return "\n".join(context_parts)

    def rerank(self, query: str, results: List[Dict], threshold: float = 0.3) -> List[Dict]:
        """
        Re-rank and filter results by relevance.

        Args:
            query: Original query
            results: Search results
            threshold: Min confidence to keep result (0-1)

        Returns:
            Filtered and re-ranked results
        """
        # Removed very low-confidence results
        filtered = [r for r in results if (1.0 - r.get("distance", 1.0)) >= threshold]

        return filtered[:5]  # Keep top 5
