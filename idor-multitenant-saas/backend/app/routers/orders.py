from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..dependencies.auth import get_db, get_current_user
from ..models import Order, Product

router = APIRouter(prefix="/orders", tags=["orders"])


class OrderCreate(BaseModel):
    product_id: int
    quantity: int = 1


class OrderNoteUpdate(BaseModel):
    note: str
    status: str | None = None


@router.get("")
def list_orders(
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    orders = db.query(Order).filter(Order.user_id == user.id).all()
    return [
        {
            "id": o.id,
            "order_code": o.order_code,
            "product_id": o.product_id,
            "product_name": o.product.name if o.product else "Unknown",
            "quantity": o.quantity,
            "status": o.status,
            "note": o.note,
            "reviewed_by": o.reviewed_by,
            "price": o.product.price if o.product else 0,
            "total": (o.product.price if o.product else 0) * o.quantity,
            "created_at": o.created_at,
        }
        for o in orders
    ]


@router.get("/{order_id}")
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    return {
        "id": order.id,
        "order_code": order.order_code,
        "user_id": order.user_id,
        "product_id": order.product_id,
        "product_name": order.product.name if order.product else "Unknown",
        "quantity": order.quantity,
        "status": order.status,
        "note": order.note,
        "reviewed_by": order.reviewed_by,
        "created_at": order.created_at,
    }


@router.put("/{order_id}")
def update_order_note(
    order_id: int,
    data: OrderNoteUpdate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    order.note = data.note
    if data.status is not None:
        order.status = data.status
    db.commit()

    return {"message": "Note updated"}


@router.post("")
def create_order(
    data: OrderCreate,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    product = db.query(Product).filter(Product.id == data.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    import random, string
    code = "ORD-" + "".join(random.choices(string.digits, k=8))

    order = Order(
        user_id=user.id,
        product_id=product.id,
        quantity=data.quantity,
        note="",
        order_code=code,
        reviewed_by=None,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    return {
        "message": "Added to orders",
        "order_id": order.id,
        "order_code": order.order_code,
    }


@router.delete("/{order_id}")
def delete_order(
    order_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    db.delete(order)
    db.commit()

    return {"message": "Order deleted"}
