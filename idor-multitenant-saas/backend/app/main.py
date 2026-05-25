from fastapi import FastAPI
from contextlib import asynccontextmanager
from sqlalchemy.exc import OperationalError
from .database import engine, Base
from .routers.auth import router as auth_router
import time
from .models import User, Product, Order # needed for SQLAlchemy model registration
from .routers.products import router as products_router
from .routers.orders import router as orders_router
from .routers.account import router as account_router

for _ in range(10):
    try:
        Base.metadata.create_all(bind=engine)
        break

    except OperationalError:
        print("Database not ready, retrying...")
        time.sleep(2)

from .seed import *

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(lifespan=lifespan)

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(orders_router)
app.include_router(account_router)