from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..dependencies.auth import get_db, get_current_user
from ..models import Order, Product

router = APIRouter(prefix="/orders", tags=["orders"])

from fastapi import HTTPException

class OrderCreate(BaseModel):
    product_id: int
    quantity: int = 1


@router.get("")
def list_orders(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    orders = (
        db.query(Order)
        .filter(Order.user_id == user.id)
        .all()
    )

    return [
        {
            "id": o.id,
            "product_id": o.product_id,
            "product_name": o.product.name if o.product else "Unknown",
            "quantity": o.quantity,
            "price": o.product.price if o.product else 0,
            "total": (o.product.price if o.product else 0) * o.quantity,
            "created_at": o.created_at,
        }
        for o in orders
    ]


@router.post("")
def create_order(
    data: OrderCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    product = db.query(Product).filter(Product.id == data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    order = Order(
        user_id=user.id,
        product_id=product.id,
        quantity=data.quantity,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    return {
        "message": "Added to orders",
        "order_id": order.id,
    }

@router.delete("/{order_id}")
def delete_order(
    order_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):

    order = (
        db.query(Order)
        .filter(
            Order.id == order_id,
            # can be vulnerable if not exists
            #Order.user_id == user.id
        )
        .first()
    )

    if not order:
        raise HTTPException(
            status_code=404,
            detail="Order not found"
        )

    db.delete(order)
    db.commit()

    return {
        "message": "Order deleted"
    }