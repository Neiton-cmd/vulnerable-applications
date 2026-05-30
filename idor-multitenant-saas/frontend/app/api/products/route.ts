export async function POST(
  request: Request
) {
  const body = await request.json()

  const response = await fetch(
    "http://backend:8000/login",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  )

  const data = await response.json()

  return Response.json(data, {
    status: response.status,
  })
}
export async function GET(request: Request) {
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch("http://backend:8000/products", {
    headers: {
      cookie,
    },
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}
