from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Secrets configuration from .env"""

    # Mongo - database
    MONGO_URI: str
    MONGO_DB: str
    MONGO_ROOMS_COLLECTION: str

    # Google Places API (New) — accepts GOOGLE_PLACES_API_KEY or legacy GOOGLE_API_KEY
    GOOGLE_PLACES_API_KEY: str = Field(
        default="",
        validation_alias=AliasChoices("GOOGLE_PLACES_API_KEY", "GOOGLE_API_KEY"),
    )

    # GitGuardian - Secrets Management
    GITGUARDIAN_API_KEY: str = ""

    model_config = SettingsConfigDict(env_file="./.env")

    @property
    def google_places_key(self) -> str:
        return (self.GOOGLE_PLACES_API_KEY or "").strip()
