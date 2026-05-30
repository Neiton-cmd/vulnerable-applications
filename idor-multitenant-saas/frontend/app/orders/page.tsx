"use client"

import { useEffect, useState } from "react"
import Navbar from "../components/Navbar"

type Order = {
  id: number
  order_code: string
  product_name: string
  quantity: number
  total: number
  status: string
  note: string
  reviewed_by: string | null
  created_at: string
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [notes, setNotes] = useState<Record<number, string>>({})
  const [saving, setSaving] = useState<number | null>(null)

  useEffect(() => {
    fetch("/api/orders")
      .then((r) => r.json())
      .then((data: Order[]) => {
        setOrders(data)
        const initial: Record<number, string> = {}
        data.forEach((o) => { initial[o.id] = o.note ?? "" })
        setNotes(initial)
      })
  }, [])

  const deleteOrder = async (orderId: number) => {
    const response = await fetch(`/api/orders/${orderId}`, { method: "DELETE" })
    if (!response.ok) return
    setOrders((prev) => prev.filter((o) => o.id !== orderId))
  }

  const saveNote = async (orderId: number) => {
    setSaving(orderId)
    await fetch(`/api/orders/${orderId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ note: notes[orderId] ?? "" }),
    })
    setSaving(null)
  }

  const reportIssue = async (orderId: number) => {
    const order = orders.find((o) => o.id === orderId)
    if (!order) return
    await fetch(`/api/orders/${orderId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ note: order.note ?? "", status: "disputed" }),
    })
    setOrders((prev) =>
      prev.map((o) => (o.id === orderId ? { ...o, status: "disputed" } : o))
    )
  }

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100">
      <Navbar />

      <section className="px-8 py-10 max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-8">My Orders</h1>

        {orders.length === 0 ? (
          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 text-zinc-400">
            No orders yet.
          </div>
        ) : (
          <div className="space-y-4">
            {orders.map((order) => (
              <div
                key={order.id}
                className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6"
              >
                <div className="flex items-start justify-between gap-4 mb-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h2 className="text-lg font-semibold">{order.product_name}</h2>
                      <span
                        className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                          order.status === "disputed"
                            ? "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30"
                            : order.status === "delivered"
                            ? "bg-green-500/20 text-green-400 border border-green-500/30"
                            : "bg-zinc-700 text-zinc-400"
                        }`}
                      >
                        {order.status ?? "unknown"}
                      </span>
                    </div>
                    <p className="text-zinc-400 text-sm">
                      <span className="font-mono text-zinc-300">#{order.id}</span>
                      {" · "}
                      <span className="font-mono text-zinc-300">{order.order_code}</span>
                      {" · "}Qty {order.quantity}
                    </p>
                    {order.reviewed_by && (
                      <p className="text-zinc-500 text-xs mt-1">
                        Reviewed by{" "}
                        <span className="text-zinc-400 font-mono">{order.reviewed_by}</span>
                      </p>
                    )}
                  </div>
                  <span className="text-lg font-bold shrink-0">${order.total}</span>
                </div>

                {/* Note field */}
                <div className="mb-4">
                  <label className="block text-xs text-zinc-500 mb-1.5">Order note</label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={notes[order.id] ?? ""}
                      onChange={(e) =>
                        setNotes((prev) => ({ ...prev, [order.id]: e.target.value }))
                      }
                      placeholder="Add a note for this order..."
                      className="flex-1 px-3 py-2 bg-zinc-950 border border-zinc-800 rounded-lg text-sm focus:outline-none focus:border-zinc-600 text-zinc-200 placeholder-zinc-600"
                    />
                    <button
                      onClick={() => saveNote(order.id)}
                      disabled={saving === order.id}
                      className="px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white rounded-lg text-sm transition disabled:opacity-50"
                    >
                      {saving === order.id ? "Saving..." : "Save"}
                    </button>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2">
                  <a
                    href={`/track/${order.order_code}`}
                    className="text-xs text-zinc-400 hover:text-white border border-zinc-700 px-3 py-1.5 rounded-lg transition"
                  >
                    Track
                  </a>
                  {order.status !== "disputed" && (
                    <button
                      onClick={() => reportIssue(order.id)}
                      className="text-xs text-yellow-400 hover:text-yellow-300 border border-yellow-500/40 px-3 py-1.5 rounded-lg transition"
                    >
                      Report issue
                    </button>
                  )}
                  <button
                    onClick={() => deleteOrder(order.id)}
                    className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-xs transition"
                  >
                    Remove
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}
