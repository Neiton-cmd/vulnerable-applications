export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params

  const response = await fetch(`http://backend:8000/products/${id}/reviews`)
  const data = await response.json()
  return Response.json(data, { status: response.status })
}
