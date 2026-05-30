import { NextRequest, NextResponse } from "next/server"

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  const protectedRoutes = ["/products", "/orders", "/account"]
  const isProtected = protectedRoutes.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`)
  )

  if (!isProtected) return NextResponse.next()

  const token = request.cookies.get("access_token")?.value
  if (!token) {
    return NextResponse.redirect(new URL("/", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/products/:path*", "/orders/:path*", "/account/:path*"],
}
