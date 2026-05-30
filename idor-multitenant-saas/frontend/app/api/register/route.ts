export async function POST(request: Request) {
  const body = await request.json()

  const response = await fetch("http://backend:8000/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  })

  const data = await response.json()

  const res = Response.json(data, { status: response.status })

  const setCookie = response.headers.get("set-cookie")
  if (setCookie) res.headers.set("Set-Cookie", setCookie)

  return res
}
