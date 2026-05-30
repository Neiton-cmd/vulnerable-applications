export async function POST(request: Request) {
  const cookie = request.headers.get("cookie") ?? ""

  const response = await fetch("http://backend:8000/logout", {
    method: "POST",
    headers: { cookie },
  })

  const data = await response.json()
  const res = Response.json(data, { status: response.status })
  res.headers.set("Set-Cookie", "access_token=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax")
  return res
}
