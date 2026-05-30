export async function PUT(
  request: Request
) {

  const cookie =
    request.headers.get("cookie") ?? ""

  const body =
    await request.json()

  const response = await fetch(
    "http://backend:8000/account/update",
    {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        cookie
      },
      body: JSON.stringify(body)
    }
  )

  const data = await response.json()

  return Response.json(
    data,
    {
      status: response.status
    }
  )
}
