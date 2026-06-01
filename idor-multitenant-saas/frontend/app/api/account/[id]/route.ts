export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch(`http://backend:8000/account/${id}`, {
    headers: { cookie },
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}
