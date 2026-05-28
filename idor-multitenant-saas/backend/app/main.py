import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import PlainTextResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import OperationalError
from starlette.middleware.base import BaseHTTPMiddleware

from .database import engine, Base
from .models import User, Product, Order, Review  # noqa: F401 — SQLAlchemy registration
from .routers.auth import router as auth_router
from .routers.products import router as products_router
from .routers.orders import router as orders_router
from .routers.account import router as account_router
from .routers.tracking import router as tracking_router

for _ in range(10):
    try:
        Base.metadata.create_all(bind=engine)
        break
    except OperationalError:
        print("Database not ready, retrying...")
        time.sleep(2)

from .seed import *  # noqa: F401,F403


class PDFGeneratorHeader(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-PDF-Generator"] = "wkhtmltopdf/0.12.6"
        return response


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(lifespan=lifespan)
app.add_middleware(PDFGeneratorHeader)


@app.get("/robots.txt", response_class=PlainTextResponse)
def robots():
    return "User-agent: *\nDisallow: /static/reports/\n"


REPORTS_DIR = "/var/www/static/reports"
os.makedirs(REPORTS_DIR, exist_ok=True)
app.mount("/static", StaticFiles(directory="/var/www/static"), name="static")

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(orders_router)
app.include_router(account_router)
app.include_router(tracking_router)
