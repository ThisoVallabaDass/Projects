"""
Embeddings - Convert text to dense vectors for semantic search
"""

from sentence_transformers import SentenceTransformer
from typing import List
import numpy as np


class EmbeddingEngine:
    """
    Convert text to embeddings using Sentence Transformers.

    Model: all-MiniLM-L6-v2
    - Fast (few ms per text)
    - 384-dimensional embeddings
    - Good for semantic search
    """

    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        """
        Args:
            model_name: HuggingFace model name
        """
        self.model_name = model_name
        self.model = SentenceTransformer(model_name)

    def embed_text(self, text: str) -> np.ndarray:
        """
        Convert single text to embedding.

        Args:
            text: Input text

        Returns:
            384-dimensional embedding vector
        """
        if not isinstance(text, str) or not text.strip():
            return np.zeros(384)

        embedding = self.model.encode(text, convert_to_tensor=False)
        return embedding.astype(np.float32)

    def embed_batch(self, texts: List[str]) -> np.ndarray:
        """
        Convert multiple texts to embeddings (faster than individual calls).

        Args:
            texts: List of input texts

        Returns:
            Shape (len(texts), 384) array of embeddings
        """
        # Filter out empty strings
        valid_texts = [t for t in texts if isinstance(t, str) and t.strip()]
        if not valid_texts:
            return np.zeros((len(texts), 384), dtype=np.float32)

        embeddings = self.model.encode(valid_texts, convert_to_tensor=False)
        return embeddings.astype(np.float32)

    def similarity(self, embedding1: np.ndarray, embedding2: np.ndarray) -> float:
        """
        Compute cosine similarity between two embeddings.

        Range: [-1, 1] where 1 = identical, 0 = orthogonal, -1 = opposite

        Args:
            embedding1: First embedding vector
            embedding2: Second embedding vector

        Returns:
            Similarity score
        """
        # Cosine similarity
        dot_product = np.dot(embedding1, embedding2)
        norm1 = np.linalg.norm(embedding1)
        norm2 = np.linalg.norm(embedding2)

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return float(dot_product / (norm1 * norm2))

    def batch_similarity(
        self, query_embedding: np.ndarray, embeddings: np.ndarray
    ) -> np.ndarray:
        """
        Compute similarity between one query and multiple embeddings.

        Args:
            query_embedding: Shape (384,)
            embeddings: Shape (N, 384)

        Returns:
            Shape (N,) array of similarity scores
        """
        # Normalize for cosine similarity
        query_norm = query_embedding / (np.linalg.norm(query_embedding) + 1e-8)
        embeddings_norm = embeddings / (np.linalg.norm(embeddings, axis=1, keepdims=True) + 1e-8)

        # Batch dot product
        similarities = np.dot(embeddings_norm, query_norm)
        return similarities
