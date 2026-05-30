"use client"

import { useEffect, useState } from "react"
import Link from "next/link"

type User = { email: string; is_admin: boolean }

export default function Navbar() {
  const [user, setUser] = useState<User | null>(null)
  const [ready, setReady] = useState(false)

  useEffect(() => {
    fetch("/api/me")
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => { setUser(data); setReady(true) })
      .catch(() => setReady(true))
  }, [])

  const logout = async () => {
    await fetch("/api/logout", { method: "POST" })
    window.location.href = "/"
  }

  return (
    <header className="border-b border-zinc-800 px-8 py-4 flex items-center justify-between">
      <Link href={user ? "/products" : "/"} className="text-xl font-bold tracking-tight">
        VulnShop
      </Link>

      <nav className="flex items-center gap-6 text-sm text-zinc-400">
        <Link href="/staff" className="hover:text-white transition">Team</Link>
        <Link href="/contact" className="hover:text-white transition">Contact</Link>

        {ready && (
          user ? (
            <>
              <Link href="/products" className="hover:text-white transition">Products</Link>
              <Link href="/orders" className="hover:text-white transition">Orders</Link>
              <Link href="/account" className="hover:text-white transition">Account</Link>
              <button
                onClick={logout}
                className="text-zinc-500 hover:text-red-400 transition"
              >
                Logout
              </button>
            </>
          ) : (
            <>
              <Link href="/" className="hover:text-white transition">Login</Link>
              <Link
                href="/register"
                className="bg-white text-black px-4 py-1.5 rounded-lg text-xs font-semibold hover:opacity-90 transition"
              >
                Register
              </Link>
            </>
          )
        )}
      </nav>
    </header>
  )
}
