from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String

from database import Base


class ProcessedFile(Base):
    __tablename__ = "processed_files"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, nullable=False)
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    s3_key = Column(String, nullable=False)
    row_count = Column(Integer, default=0)
    status = Column(String, default="processing")  # processing, completed, failed
