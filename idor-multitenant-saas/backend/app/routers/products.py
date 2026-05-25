from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..dependencies.auth import get_db, get_current_user
from ..models import Product

router = APIRouter(prefix="/products", tags=["products"])


@router.get("")
def list_products(
    db: Session = Depends(get_db),
    _user=Depends(get_current_user),
):
    products = db.query(Product).all()
    return [
        {
            "id": p.id,
            "name": p.name,
            "price": p.price,
            "image": p.image,
            "description": p.description,
        }
        for p in products
    ]