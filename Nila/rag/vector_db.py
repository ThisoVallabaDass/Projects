"""
Vector Database - ChromaDB wrapper for memory indexing and retrieval
"""

import chromadb
from chromadb.config import Settings
from typing import List, Dict, Optional
import json


class VectorDB:
    """
    ChromaDB wrapper for storing and retrieving memory with semantic search.

    Storage types:
    - In-memory: Fast, ephemeral (default for testing)
    - SQLite: Persistent across sessions
    """

    def __init__(self, db_path: str = ":memory:"):
        """
        Args:
            db_path: Path to SQLite file or ":memory:" for ephemeral
        """
        self.db_path = db_path

        # Initialize ChromaDB
        if db_path == ":memory:":
            self.client = chromadb.Client()
        else:
            settings = Settings(
                chroma_db_impl="duckdb+parquet",
                persist_directory=db_path,
                anonymized_telemetry=False,
            )
            self.client = chromadb.Client(settings)

        # Create collections
        self.facts_collection = self.client.get_or_create_collection(
            name="facts",
            metadata={"hnsw:space": "cosine"},
        )
        self.goals_collection = self.client.get_or_create_collection(
            name="goals",
            metadata={"hnsw:space": "cosine"},
        )
        self.notes_collection = self.client.get_or_create_collection(
            name="notes",
            metadata={"hnsw:space": "cosine"},
        )

    def add_fact(self, key: str, value: str, embedding: List[float]):
        """
        Add or update a fact.

        Args:
            key: Unique fact identifier
            value: Fact content
            embedding: 384-dim embedding vector
        """
        self.facts_collection.upsert(
            ids=[key],
            embeddings=[embedding],
            documents=[value],
            metadatas=[{"type": "fact", "key": key}],
        )

    def add_goal(self, goal_id: str, goal_text: str, embedding: List[float], status: str = "active"):
        """
        Add or update a goal.

        Args:
            goal_id: Unique goal identifier
            goal_text: Goal description
            embedding: 384-dim embedding vector
            status: "active" or "completed"
        """
        self.goals_collection.upsert(
            ids=[goal_id],
            embeddings=[embedding],
            documents=[goal_text],
            metadatas=[{"type": "goal", "status": status}],
        )

    def add_note(self, note_id: str, note_text: str, embedding: List[float]):
        """
        Add a note.

        Args:
            note_id: Unique note identifier
            note_text: Note content
            embedding: 384-dim embedding vector
        """
        self.notes_collection.upsert(
            ids=[note_id],
            embeddings=[embedding],
            documents=[note_text],
            metadatas=[{"type": "note"}],
        )

    def search_facts(self, query_embedding: List[float], top_k: int = 3) -> List[Dict]:
        """Search facts by semantic similarity."""
        results = self.facts_collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
        )
        return self._format_results(results)

    def search_goals(self, query_embedding: List[float], top_k: int = 3) -> List[Dict]:
        """Search goals by semantic similarity."""
        results = self.goals_collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
        )
        return self._format_results(results)

    def search_notes(self, query_embedding: List[float], top_k: int = 3) -> List[Dict]:
        """Search notes by semantic similarity."""
        results = self.notes_collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
        )
        return self._format_results(results)

    def search_all(self, query_embedding: List[float], top_k: int = 5) -> List[Dict]:
        """
        Search across all collections (facts, goals, notes).
        Returns top-k results from all combined, sorted by relevance.
        """
        all_results = []

        # Search each collection
        for collection, collection_name in [
            (self.facts_collection, "fact"),
            (self.goals_collection, "goal"),
            (self.notes_collection, "note"),
        ]:
            results = collection.query(
                query_embeddings=[query_embedding],
                n_results=top_k,
            )
            formatted = self._format_results(results, collection_name)
            all_results.extend(formatted)

        # Sort by distance (ascending) and return top-k
        all_results.sort(key=lambda x: x["distance"])
        return all_results[:top_k]

    def clear(self):
        """Clear all collections."""
        self.client.delete_collection(name="facts")
        self.client.delete_collection(name="goals")
        self.client.delete_collection(name="notes")

        # Recreate empty collections
        self.facts_collection = self.client.get_or_create_collection(name="facts")
        self.goals_collection = self.client.get_or_create_collection(name="goals")
        self.notes_collection = self.client.get_or_create_collection(name="notes")

    def get_stats(self) -> Dict:
        """Get database statistics."""
        return {
            "facts_count": self.facts_collection.count(),
            "goals_count": self.goals_collection.count(),
            "notes_count": self.notes_collection.count(),
        }

    @staticmethod
    def _format_results(chromadb_results: dict, collection_type: str = None) -> List[Dict]:
        """Convert ChromaDB results to standard format."""
        formatted = []

        ids = chromadb_results.get("ids", [[]])[0] if chromadb_results.get("ids") else []
        documents = chromadb_results.get("documents", [[]])[0] if chromadb_results.get("documents") else []
        distances = chromadb_results.get("distances", [[]])[0] if chromadb_results.get("distances") else []
        metadatas = chromadb_results.get("metadatas", [[]])[0] if chromadb_results.get("metadatas") else []

        for i, doc_id in enumerate(ids):
            formatted.append(
                {
                    "id": doc_id,
                    "text": documents[i] if i < len(documents) else "",
                    "distance": distances[i] if i < len(distances) else 1.0,
                    "type": collection_type or (metadatas[i].get("type") if i < len(metadatas) else None),
                    "metadata": metadatas[i] if i < len(metadatas) else {},
                }
            )

        return formatted
