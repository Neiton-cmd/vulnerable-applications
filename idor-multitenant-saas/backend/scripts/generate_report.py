#!/usr/bin/env python3
import os
import sys
import subprocess
from datetime import date

sys.path.insert(0, "/app")

from jinja2 import Environment
from app.database import SessionLocal
from app.models import Order

REPORT_DIR = "/var/www/static/reports"
os.makedirs(REPORT_DIR, exist_ok=True)

TEMPLATE = """\
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>VulnShop Admin Report — {{ report_date }}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background: #f9f9f9; color: #222; }
    h1   { color: #111; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
    .meta { color: #888; font-size: 13px; margin-bottom: 24px; }
    .order { background: #fff; border: 1px solid #e0e0e0; border-radius: 8px;
             padding: 16px 20px; margin: 12px 0; }
    .order h3 { margin: 0 0 6px; font-size: 15px; }
    .order .info { color: #555; font-size: 13px; margin-bottom: 8px; }
    .note { background: #fffbe6; border-left: 3px solid #f5c518;
            padding: 8px 12px; font-size: 13px; margin-top: 8px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>VulnShop — Daily Order Report</h1>
  <p class="meta">Generated: {{ report_date }} &nbsp;|&nbsp; Total orders: {{ orders|length }}</p>

  {% for order in orders %}
  <div class="order">
    <h3>{{ order.order_code }}</h3>
    <div class="info">
      Product: {{ order.product_name }} &nbsp;|&nbsp;
      Qty: {{ order.quantity }} &nbsp;|&nbsp;
      Reviewed by: {{ order.reviewed_by or "pending" }}
    </div>
    <div class="note">Customer note: {{ order.note }}</div>
  </div>
  {% endfor %}
</body>
</html>"""


def main():
    db = SessionLocal()
    try:
        from app.models import User
        orders = (
            db.query(Order)
            .join(User, Order.user_id == User.id)
            .filter(User.is_admin == True, Order.status == "disputed")
            .all()
        )

        rows = [
            {
                "order_code":   o.order_code,
                "product_name": o.product.name if o.product else "Unknown",
                "quantity":     o.quantity,
                "reviewed_by":  o.reviewed_by,
                "note":         o.note or "",
            }
            for o in orders
        ]

        env = Environment(autoescape=False)
        html = env.from_string(TEMPLATE).render(
            orders=rows,
            report_date=str(date.today()),
        )

        filename = f"report_{date.today()}.pdf"
        output_path = os.path.join(REPORT_DIR, filename)

        result = subprocess.run(
            [
                "/usr/local/bin/wkhtmltopdf",
                "--enable-local-file-access",
                "--enable-javascript",
                "--javascript-delay", "1500",
                "--no-stop-slow-scripts",
                "--quiet",
                "-",
                output_path,
            ],
            input=html.encode("utf-8"),
            capture_output=True,
        )

        if result.returncode == 0:
            print(f"[+] Report saved: {output_path}")
            # TODO: re-enable SCP upload once backup.vulnshop.htb migration is done
            # subprocess.run([
            #     "scp", "-i", "/home/jonny/.ssh/id_rsa",
            #     "-o", "StrictHostKeyChecking=no",
            #     output_path, f"reports@backup.vulnshop.htb:/var/backups/omni-reports/{filename}",
            # ], capture_output=True)
        else:
            print(f"[-] wkhtmltopdf error: {result.stderr.decode()}", file=sys.stderr)

    finally:
        db.close()


if __name__ == "__main__":
    main()
