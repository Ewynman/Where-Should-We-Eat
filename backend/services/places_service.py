"""
Google Places API (New) - Text Search for nearby restaurants by cuisine.
Requires GOOGLE_PLACES_API_KEY environment variable.
"""

from typing import Any


def fetch_restaurants_for_cuisines(
    cuisines: list[str],
    latitude: float,
    longitude: float,
    radius_meters: float = 5000,
    room_id: str = "",
) -> list[dict[str, Any]]:
    """
    For each cuisine string, run a text search and return one restaurant option.
    Returns at most len(cuisines) options (one per cuisine).
    TODO: Integrate Google Places API.
    """
    return []
