import boto3
from botocore.exceptions import ClientError

from config import settings


def get_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=settings.S3_ENDPOINT_URL,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_REGION,
    )


def ensure_bucket_exists():
    """Create bucket if in local environment."""
    if not settings.is_local:
        return

    client = get_s3_client()
    try:
        client.head_bucket(Bucket=settings.S3_BUCKET_NAME)
        print(f"Bucket '{settings.S3_BUCKET_NAME}' already exists")
    except ClientError:
        client.create_bucket(Bucket=settings.S3_BUCKET_NAME)
        print(f"Created bucket '{settings.S3_BUCKET_NAME}'")


def check_bucket_exists() -> bool:
    """Check if the bucket exists."""
    client = get_s3_client()
    try:
        client.head_bucket(Bucket=settings.S3_BUCKET_NAME)
        return True
    except ClientError:
        return False


def upload_file(file_content: bytes, s3_key: str) -> str:
    """Upload file content to S3 and return the key."""
    client = get_s3_client()
    client.put_object(
        Bucket=settings.S3_BUCKET_NAME,
        Key=s3_key,
        Body=file_content,
        ContentType="text/csv",
    )
    return s3_key
