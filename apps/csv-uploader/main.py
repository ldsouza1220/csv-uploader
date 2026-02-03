import csv
import io
import uuid

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from config import settings
from database import get_db, init_db
from models import ProcessedFile
from s3_client import check_bucket_exists, ensure_bucket_exists, upload_file

app = FastAPI(title="CSV Processor")
templates = Jinja2Templates(directory="templates")


@app.on_event("startup")
async def startup_event():
    init_db()
    print(f"Environment: {settings.ENVIRONMENT}")

    if settings.is_local:
        try:
            ensure_bucket_exists()
        except Exception as e:
            print(f"Warning: Could not connect to S3: {e}")
    else:
        if check_bucket_exists():
            print(f"S3 bucket '{settings.S3_BUCKET_NAME}' is ready")
        else:
            print(f"Warning: S3 bucket '{settings.S3_BUCKET_NAME}' not found")


@app.get("/", response_class=HTMLResponse)
async def index(request: Request, db: Session = Depends(get_db)):
    files = db.query(ProcessedFile).order_by(ProcessedFile.uploaded_at.desc()).all()
    return templates.TemplateResponse("index.html", {"request": request, "files": files})


@app.post("/upload")
async def upload_csv(file: UploadFile = File(...), db: Session = Depends(get_db)):
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are allowed")

    content = await file.read()
    s3_key = f"{uuid.uuid4()}/{file.filename}"

    try:
        text_content = content.decode("utf-8")
        csv_reader = csv.reader(io.StringIO(text_content))
        row_count = sum(1 for _ in csv_reader) - 1
        if row_count < 0:
            row_count = 0
    except Exception:
        row_count = 0

    processed_file = ProcessedFile(
        filename=file.filename,
        s3_key=s3_key,
        row_count=row_count,
        status="processing",
    )
    db.add(processed_file)
    db.commit()
    db.refresh(processed_file)

    try:
        upload_file(content, s3_key)
        processed_file.status = "completed"
        db.commit()

        return JSONResponse(
            status_code=200,
            content={
                "status": "success",
                "message": f"File uploaded successfully",
                "file_id": processed_file.id,
                "filename": file.filename,
                "row_count": row_count,
            },
        )
    except Exception as e:
        processed_file.status = "failed"
        db.commit()

        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "message": str(e),
            },
        )


@app.get("/files")
async def list_files(db: Session = Depends(get_db)):
    files = db.query(ProcessedFile).order_by(ProcessedFile.uploaded_at.desc()).all()
    return [
        {
            "id": f.id,
            "filename": f.filename,
            "uploaded_at": f.uploaded_at.isoformat(),
            "s3_key": f.s3_key,
            "row_count": f.row_count,
            "status": f.status,
        }
        for f in files
    ]


@app.get("/files/{file_id}")
async def get_file(file_id: int, db: Session = Depends(get_db)):
    file = db.query(ProcessedFile).filter(ProcessedFile.id == file_id).first()
    if not file:
        raise HTTPException(status_code=404, detail="File not found")
    return {
        "id": file.id,
        "filename": file.filename,
        "uploaded_at": file.uploaded_at.isoformat(),
        "s3_key": file.s3_key,
        "row_count": file.row_count,
        "status": file.status,
    }
