import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
from sqlalchemy.exc import OperationalError

from .database import engine, Base
from .models import User, Product, Order, Review  # noqa: F401 — SQLAlchemy registration
from .routers.auth import router as auth_router
from .routers.products import router as products_router
from .routers.orders import router as orders_router
from .routers.account import router as account_router
from .routers.tracking import router as tracking_router
from .routers.internal import router as internal_router

for _ in range(10):
    try:
        Base.metadata.create_all(bind=engine)
        break
    except OperationalError:
        print("Database not ready, retrying...")
        time.sleep(2)

from .seed import *  # noqa: F401,F403


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(lifespan=lifespan)


@app.get("/robots.txt", response_class=PlainTextResponse)
def robots():
    return "User-agent: *\nDisallow: /internal/\n"


app.include_router(auth_router)
app.include_router(products_router)
app.include_router(orders_router)
app.include_router(account_router)
app.include_router(tracking_router)
app.include_router(internal_router)
