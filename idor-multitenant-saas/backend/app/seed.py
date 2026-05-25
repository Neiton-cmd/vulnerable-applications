from .database import SessionLocal
from .models import User, Product
from .utils.security import hash_password

db = SessionLocal()

if not db.query(User).first():
    alice = User(
    email="alice@test.com",
    password=hash_password("password"),
    is_admin=False,
)

    bob = User(
        email="bob@test.com",
        password=hash_password("password"),
        is_admin=True,
    )
    db.add_all([alice, bob])
    db.commit()

if not db.query(Product).first():
    db.add_all([
        Product(
            name="MacBook Pro",
            price=2400,
            image="/macbook-pro.jpeg",
            description="M3 Pro • 36GB RAM",
        ),
        Product(
            name="iPhone 16 Pro",
            price=1400,
            image="/iphone-16-pro.jpeg",
            description="256GB • Titanium",
        ),
        Product(
            name="AirPods Max",
            price=700,
            image="/airpods.jpeg",
            description="USB-C • Space Gray",
        ),
    ])
    db.commit()

print("Seeded users + products")