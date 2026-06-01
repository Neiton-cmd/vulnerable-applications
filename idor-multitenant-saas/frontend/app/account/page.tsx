"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import Navbar from "../components/Navbar"

type Me = { id: number; email: string; is_admin: boolean; notification_url: string | null }

export default function AccountPage() {
  const router = useRouter()
  const [me, setMe] = useState<Me | null>(null)
  const [currentPassword, setCurrentPassword] = useState("")
  const [newPassword, setNewPassword] = useState("")
  const [email, setEmail] = useState("")
  const [notificationUrl, setNotificationUrl] = useState("")
  const [message, setMessage] = useState("")

  useEffect(() => {
    fetch("/api/me")
      .then(async (res) => {
        if (!res.ok) { router.push("/"); return null }
        return res.json()
      })
      .then((data) => {
        if (data) {
          setMe(data)
          setEmail(data.email)
          setNotificationUrl(data.notification_url ?? "")
        }
      })
  }, [router])

  async function handleUpdateAccount(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const body: Record<string, string> = { email }
    if (notificationUrl) body.notification_url = notificationUrl
    const response = await fetch("/api/account/update", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    })
    if (response.ok) setMessage("Account updated")
  }

  async function handleResetPassword(e: React.FormEvent) {
    e.preventDefault()
    setMessage("")
    const response = await fetch("/api/account/reset-password", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ current_password: currentPassword, new_password: newPassword }),
    })
    const data = await response.json()
    if (!response.ok) { setMessage(data.detail ?? "Failed"); return }
    setMessage("Password updated")
    setCurrentPassword("")
    setNewPassword("")
  }

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100">
      <Navbar />

      <section className="px-8 py-10 max-w-xl mx-auto space-y-6">
        <h1 className="text-4xl font-bold">Account</h1>

        <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
          <p className="text-zinc-400 text-sm mb-1">Email</p>
          <p className="text-lg mb-4">{me?.email ?? "—"}</p>
          <p className="text-zinc-400 text-sm mb-1">Role</p>
          <p className="text-lg mb-4">{me?.is_admin ? "Administrator" : "User"}</p>
          <p className="text-zinc-400 text-sm mb-1">Notification URL</p>
          <p className="text-sm font-mono text-zinc-300 break-all">{me?.notification_url ?? "—"}</p>
        </div>

        <form
          onSubmit={handleUpdateAccount}
          className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 space-y-4"
        >
          <h2 className="text-xl font-semibold">Update account</h2>
          <div className="space-y-2">
            <label className="block text-sm text-zinc-400">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl focus:outline-none focus:border-zinc-600"
              required
            />
          </div>
          <div className="space-y-2">
            <label className="block text-sm text-zinc-400">Order notification URL</label>
            <input
              type="text"
              value={notificationUrl}
              onChange={(e) => setNotificationUrl(e.target.value)}
              placeholder="https://your-server.com/webhook"
              className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl focus:outline-none focus:border-zinc-600"
            />
            <p className="text-xs text-zinc-500">Called when your order status changes to disputed.</p>
          </div>
          {message && <p className="text-sm text-zinc-400">{message}</p>}
          <button className="bg-white text-black px-4 py-2.5 rounded-xl font-medium text-sm hover:opacity-90 transition">
            Save changes
          </button>
        </form>

        <form
          onSubmit={handleResetPassword}
          className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 space-y-4"
        >
          <h2 className="text-xl font-semibold">Change password</h2>
          <input
            type="password"
            placeholder="Current password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl focus:outline-none focus:border-zinc-600"
            required
          />
          <input
            type="password"
            placeholder="New password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl focus:outline-none focus:border-zinc-600"
            required
          />
          {message && <p className="text-sm text-zinc-400">{message}</p>}
          <button className="bg-white text-black px-4 py-2.5 rounded-xl font-medium text-sm hover:opacity-90 transition">
            Update password
          </button>
        </form>
      </section>
    </main>
  )
}
