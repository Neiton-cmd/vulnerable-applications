from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from ..database import SessionLocal
from ..dependencies.auth import get_db, get_current_user
from ..models import User
from ..utils.security import verify_password, hash_password

router = APIRouter(prefix="/account", tags=["account"])


class ResetPasswordRequest(BaseModel):
    current_password: str
    new_password: str


class UpdateUserRequest(BaseModel):
    email: EmailStr
    notification_url: str | None = None


@router.get("/me")
def me(user=Depends(get_current_user)):
    return {
        "id": user.id,
        "email": user.email,
        "is_admin": user.is_admin,
        "notification_url": user.notification_url,
    }


@router.get("/{user_id}")
def get_user(user_id: int):
    db: Session = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()
    db.close()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": user.id,
        "email": user.email,
        "notification_url": user.notification_url,
    }


@router.post("/reset-password")
def reset_password(
    data: ResetPasswordRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    if not verify_password(data.current_password, user.password):
        raise HTTPException(status_code=401, detail="Current password is wrong")

    user.password = hash_password(data.new_password)
    db.commit()

    return {"message": "Password updated"}


@router.put("/update")
def update_user(
    data: UpdateUserRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    user.email = data.email
    if data.notification_url is not None:
        user.notification_url = data.notification_url

    db.commit()

    return {"message": "Account updated"}
