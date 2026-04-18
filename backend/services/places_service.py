"""
Google Places API (New): Text Search + Place Details + photo media URLs.
"""

from __future__ import annotations

import logging
from typing import Any
from urllib.parse import quote

import httpx

logger = logging.getLogger(__name__)

PLACES_BASE = "https://places.googleapis.com/v1"

# Text Search (New) — field mask for initial discovery
SEARCH_FIELD_MASK = (
    "places.id,places.displayName,places.formattedAddress,places.rating,"
    "places.photos,places.types"
)

# Place Details — fields within Essentials / Pro / Enterprise (avoid Atmosphere-only SKUs)
DETAILS_FIELD_MASK = (
    "id,displayName,formattedAddress,rating,googleMapsUri,websiteUri,photos,priceLevel"
)


def _display_name(place: dict[str, Any]) -> str:
    dn = place.get("displayName") or {}
    if isinstance(dn, dict):
        return (dn.get("text") or dn.get("name") or "Restaurant").strip()
    return str(dn or "Restaurant")


def internal_photo_path(photo_name: str, max_px: int = 800) -> str:
    """Relative URL served by our API proxy (no Google API key exposed to clients)."""
    return f"/api/place-photo?photoName={quote(photo_name, safe='')}&maxPx={max_px}"


async def _search_text(
    client: httpx.AsyncClient,
    api_key: str,
    text_query: str,
    latitude: float,
    longitude: float,
    radius_m: float = 6000.0,
    page_token: str | None = None,
) -> dict[str, Any]:
    body: dict[str, Any] = {
        "textQuery": text_query,
        "locationBias": {
            "circle": {
                "center": {"latitude": latitude, "longitude": longitude},
                "radius": radius_m,
            }
        },
        "maxResultCount": 10,
    }
    if page_token:
        body["pageToken"] = page_token

    r = await client.post(
        f"{PLACES_BASE}/places:searchText",
        headers={
            "Content-Type": "application/json",
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": SEARCH_FIELD_MASK,
        },
        json=body,
    )
    r.raise_for_status()
    return r.json()


async def _place_details(
    client: httpx.AsyncClient, api_key: str, place_id: str
) -> dict[str, Any]:
    r = await client.get(
        f"{PLACES_BASE}/places/{place_id}",
        headers={
            "X-Goog-Api-Key": api_key,
            "X-Goog-FieldMask": DETAILS_FIELD_MASK,
        },
    )
    r.raise_for_status()
    return r.json()


async def fetch_restaurant_options_for_cuisines(
    api_key: str,
    cuisines: list[str],
    latitude: float,
    longitude: float,
    *,
    min_options: int = 8,
    max_options: int = 12,
) -> tuple[list[dict[str, Any]], str | None]:
    """
    For each cuisine label, run Text Search (New), merge with dedupe, cap at max_options.
    Returns (option dicts ready for Mongo, error_message or None).
    """
    if not api_key:
        return [], "Google Places API key not configured"

    cuisines = [c.strip() for c in cuisines if c.strip()]
    if not cuisines:
        return [], "No cuisines to search"

    # Per-cuisine ordered place ids from search
    per_cuisine_ids: list[list[str]] = []
    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            for cuisine in cuisines:
                query = f"{cuisine} restaurant"
                collected: list[str] = []
                next_token: str | None = None
                for _ in range(3):  # at most 3 pages per cuisine
                    data = await _search_text(
                        client,
                        api_key,
                        query,
                        latitude,
                        longitude,
                        page_token=next_token,
                    )
                    for p in data.get("places") or []:
                        pid = p.get("id")
                        if pid and pid not in collected:
                            collected.append(pid)
                    next_token = data.get("nextPageToken")
                    if not next_token or len(collected) >= 10:
                        break
                per_cuisine_ids.append(collected)

            # Round-robin merge, dedupe globally, cap max_options ids
            seen: set[str] = set()
            merged_ids: list[str] = []
            place_source_cuisine: dict[str, str] = {}
            max_rounds = max((len(x) for x in per_cuisine_ids), default=0)
            for i in range(max_rounds):
                for idx, bucket in enumerate(per_cuisine_ids):
                    if len(merged_ids) >= max_options:
                        break
                    if i < len(bucket) and bucket[i] not in seen:
                        seen.add(bucket[i])
                        merged_ids.append(bucket[i])
                        if idx < len(cuisines):
                            place_source_cuisine[bucket[i]] = cuisines[idx]
                if len(merged_ids) >= max_options:
                    break

            if not merged_ids:
                return [], "No restaurants found for those cuisines nearby"

            options: list[dict[str, Any]] = []
            for place_id in merged_ids:
                detail = await _place_details(client, api_key, place_id)
                name = _display_name(detail)
                address = (detail.get("formattedAddress") or "").strip()
                rating = detail.get("rating")
                if isinstance(rating, (int, float)):
                    rating_f = float(rating)
                else:
                    rating_f = None

                photos = detail.get("photos") or []
                image_url = ""
                if photos and isinstance(photos[0], dict):
                    pname = photos[0].get("name")
                    if pname:
                        image_url = internal_photo_path(pname)

                highlights: list[str] = []
                pl = detail.get("priceLevel")
                if pl is not None and str(pl):
                    highlights.append(f"Price level {pl}")

                originating = place_source_cuisine.get(place_id, "") or "restaurant"

                options.append(
                    {
                        "name": name,
                        "votes": 0,
                        "source": "restaurant",
                        "cuisineType": originating,
                        "address": address or None,
                        "rating": rating_f,
                        "imageUrl": image_url or None,
                        "placeId": place_id,
                        "googleMapsUri": detail.get("googleMapsUri"),
                        "websiteUri": detail.get("websiteUri"),
                        "menuHighlights": highlights,
                    }
                )

            if len(options) < min_options:
                logger.warning(
                    "Only %s restaurant options after merge (wanted %s–%s)",
                    len(options),
                    min_options,
                    max_options,
                )

            return options, None

    except httpx.HTTPStatusError as e:
        msg = f"Places API error: {e.response.status_code}"
        logger.exception(msg)
        return [], msg
    except Exception as e:
        logger.exception("Places fetch failed")
        return [], str(e) or "Places request failed"
