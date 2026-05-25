from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from ..dependencies.auth import get_db, get_current_user
from ..utils.security import verify_password, hash_password

router = APIRouter(prefix="/account", tags=["account"])


class ResetPasswordRequest(BaseModel):
    current_password: str
    new_password: str


class UpdateUserRequest(BaseModel):
    email: EmailStr


@router.get("/me")
def me(user=Depends(get_current_user)):
    return {
        "id": user.id,
        "email": user.email,
        "is_admin": user.is_admin,
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

    db.commit()

    return {
        "message": "Account updated"
    }