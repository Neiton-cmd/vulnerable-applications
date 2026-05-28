from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..dependencies.auth import get_db, get_current_user
from ..models import Product, Review

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


@router.get("/{product_id}/reviews")
def get_reviews(product_id: int, db: Session = Depends(get_db)):
    reviews = db.query(Review).filter(Review.product_id == product_id).all()
    return [
        {
            "id": r.id,
            "author": r.author,
            "text": r.text,
            "rating": r.rating,
            "verified_by": r.verified_by,
            "is_moderator_verified": r.is_moderator_verified,
        }
        for r in reviews
    ]
