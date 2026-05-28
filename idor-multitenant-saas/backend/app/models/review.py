from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from ..database import Base


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    author = Column(String, nullable=False)
    text = Column(String, nullable=False)
    rating = Column(Integer, nullable=False)
    verified_by = Column(String, nullable=True)
    is_moderator_verified = Column(Boolean, default=False)

    product = relationship("Product", back_populates="reviews")
