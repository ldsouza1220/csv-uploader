import os


class Settings:
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "local")

    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./csv_processor.db")
    S3_ENDPOINT_URL: str = os.getenv("S3_ENDPOINT_URL", "http://localhost:9000")
    S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "csv-files")
    AWS_ACCESS_KEY_ID: str = os.getenv("AWS_ACCESS_KEY_ID", "minioadmin")
    AWS_SECRET_ACCESS_KEY: str = os.getenv("AWS_SECRET_ACCESS_KEY", "minioadmin")
    AWS_REGION: str = os.getenv("AWS_REGION", "us-east-1")

    @property
    def is_local(self) -> bool:
        return self.ENVIRONMENT == "local"


settings = Settings()
