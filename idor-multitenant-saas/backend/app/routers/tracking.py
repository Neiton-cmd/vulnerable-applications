from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..dependencies.auth import get_db
from ..models import Order

router = APIRouter(tags=["tracking"])


@router.get("/track/{order_code}")
def track_order(order_code: str, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.order_code == order_code).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    return {
        "order_code": order.order_code,
        "status": "delivered",
        "product": order.product.name if order.product else "Unknown",
        "quantity": order.quantity,
        "reviewed_by": order.reviewed_by,
        "message": "Your order has been reviewed and approved by our moderation team.",
    }
