export async function GET(request: Request) {
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch("http://backend:8000/account/me", {
    headers: { cookie },
  })

  const data = await response.json()
  return Response.json(data, { status: response.status })
}
