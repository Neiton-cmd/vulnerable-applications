export async function GET(
  _request: Request,
  context: { params: Promise<{ code: string }> }
) {
  const { code } = await context.params

  const response = await fetch(`http://backend:8000/track/${code}`)
  const data = await response.json()
  return Response.json(data, { status: response.status })
}
