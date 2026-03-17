from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Secrets configuration from .env"""

    # Mongo - database
    MONGO_URI: str
    MONGO_DB: str
    MONGO_ROOMS_COLLECTION: str

    # Google - restaurant apis
    GOOGLE_API_KEY: str

    # GitGuardian - Secrets Management
    GITGUARDIAN_API_KEY: str = ""

    model_config = SettingsConfigDict(env_file="./.env")
