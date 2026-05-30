export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch(`http://backend:8000/orders/${id}`, {
    headers: { cookie },
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}

export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const cookie = request.headers.get("cookie") ?? ""
  const body = await request.json()

  const response = await fetch(`http://backend:8000/orders/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", cookie },
    body: JSON.stringify(body),
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}

export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch(`http://backend:8000/orders/${id}`, {
    method: "DELETE",
    headers: { cookie },
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}
