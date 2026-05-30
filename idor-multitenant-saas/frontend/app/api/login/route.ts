import { NextResponse } from "next/server"

export async function POST(request: Request) {
  const body = await request.json()

  const backendResponse = await fetch("http://backend:8000/login", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  })

  const data = await backendResponse.json()
  const res = NextResponse.json(data, { status: backendResponse.status })

  const setCookie = backendResponse.headers.get("set-cookie")
  if (setCookie) {
    res.headers.set("set-cookie", setCookie)
  }

  return res
}
