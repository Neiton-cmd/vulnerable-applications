export async function GET(request: Request) {
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch("http://backend:8000/orders", {
    headers: {
      cookie,
    },
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}

export async function POST(request: Request) {
  const cookie = request.headers.get("cookie") ?? ""
  const body = await request.json()

  const response = await fetch("http://backend:8000/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      cookie,
    },
    body: JSON.stringify(body),
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}
