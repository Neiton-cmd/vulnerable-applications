from .database import SessionLocal
from .models import User, Product, Order, Review
from .utils.security import hash_password

db = SessionLocal()

if not db.query(User).first():
    alice = User(
        email="alice@vulnshop.com",
        password=hash_password("alice2024!"),
        is_admin=False,
    )
    jonny = User(
        email="jonny@vulnshop.com",
        password=hash_password("J0nny_4dm1n!"),
        is_admin=True,
    )
    mike = User(
        email="mike@vulnshop.com",
        password=hash_password("m1ke_m0d_2024"),
        is_admin=True,
    )
    sarah = User(
        email="sarah@vulnshop.com",
        password=hash_password("s4r4h_m0d_2024"),
        is_admin=True,
    )
    db.add_all([alice, jonny, mike, sarah])
    db.commit()

if not db.query(Product).first():
    macbook = Product(
        name="MacBook Pro",
        price=2400,
        image="/macbook-pro.jpeg",
        description="M3 Pro • 36GB RAM",
    )
    iphone = Product(
        name="iPhone 16 Pro",
        price=1400,
        image="/iphone-16-pro.jpeg",
        description="256GB • Titanium",
    )
    airpods = Product(
        name="AirPods Max",
        price=700,
        image="/airpods.jpeg",
        description="USB-C • Space Gray",
    )
    db.add_all([macbook, iphone, airpods])
    db.commit()

    db.add_all([
        Review(
            product_id=macbook.id,
            author="tech_buyer_99",
            text="Incredible machine. Best laptop I have owned in years. Highly recommended for developers.",
            rating=5,
            verified_by="jonny",
            is_moderator_verified=True,
        ),
        Review(
            product_id=macbook.id,
            author="dev_maria",
            text="Fast, silent, amazing battery life. Worth every cent.",
            rating=5,
            verified_by="jonny",
            is_moderator_verified=True,
        ),
        Review(
            product_id=iphone.id,
            author="mobilefan_k",
            text="Best iPhone to date. The camera system is absolutely insane.",
            rating=5,
            verified_by="mike",
            is_moderator_verified=True,
        ),
        Review(
            product_id=iphone.id,
            author="alex_t",
            text="Smooth performance, great display. No complaints.",
            rating=4,
            verified_by="mike",
            is_moderator_verified=True,
        ),
        Review(
            product_id=airpods.id,
            author="audiophile_k",
            text="Best noise cancellation I have ever heard. Worth the premium.",
            rating=5,
            verified_by="sarah",
            is_moderator_verified=True,
        ),
        Review(
            product_id=airpods.id,
            author="sound_james",
            text="Comfortable fit, excellent sound quality. USB-C is a welcome upgrade.",
            rating=4,
            verified_by="sarah",
            is_moderator_verified=True,
        ),
    ])
    db.commit()

if not db.query(Order).first():
    users = {u.email: u for u in db.query(User).all()}
    products = db.query(Product).all()

    alice = users["alice@vulnshop.com"]
    jonny = users["jonny@vulnshop.com"]
    mike  = users["mike@vulnshop.com"]

    # jonny's internal test order — id=1, this is the IDOR target
    db.add(Order(
        user_id=jonny.id,
        product_id=products[0].id,
        quantity=1,
        status="disputed",
        note="",
        order_code="ORD-2024-0099",
        reviewed_by="jonny",
    ))
    db.commit()

    # alice's orders — id=2,3,4; player sees these first and notices IDs start at 2
    db.add_all([
        Order(
            user_id=alice.id,
            product_id=products[0].id,
            quantity=1,
            status="delivered",
            note="Please include receipt",
            order_code="ORD-2024-0042",
            reviewed_by="jonny",
        ),
        Order(
            user_id=alice.id,
            product_id=products[1].id,
            quantity=1,
            status="delivered",
            note="Gift wrap if possible",
            order_code="ORD-2024-0043",
            reviewed_by="mike",
        ),
        Order(
            user_id=alice.id,
            product_id=products[2].id,
            quantity=2,
            status="delivered",
            note="",
            order_code="ORD-2024-0044",
            reviewed_by="sarah",
        ),
    ])
    db.commit()

db.close()
print("Seeded users + products + reviews + orders")
