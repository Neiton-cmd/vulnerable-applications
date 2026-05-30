"use client"

import { useEffect, useState } from "react"
import { useParams } from "next/navigation"

type TrackingResult = {
  order_code: string
  status: string
  product: string
  quantity: number
  reviewed_by: string | null
  message: string
}

export default function TrackPage() {
  const params = useParams()
  const code = params?.code as string
  const [result, setResult] = useState<TrackingResult | null>(null)
  const [error, setError] = useState("")

  useEffect(() => {
    if (!code) return
    fetch(`/api/track/${code}`)
      .then(async (r) => {
        if (!r.ok) { setError("Order not found"); return null }
        return r.json()
      })
      .then((data) => { if (data) setResult(data) })
  }, [code])

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100 p-10">
      <div className="max-w-xl">
        <h1 className="text-4xl font-bold mb-2">Order Tracking</h1>
        <p className="text-zinc-400 mb-8 font-mono text-sm">{code}</p>

        {error && (
          <div className="bg-zinc-900 border border-red-900 text-red-400 rounded-2xl p-6">
            {error}
          </div>
        )}

        {result && (
          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 space-y-4">
            <div className="flex items-center gap-3">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 inline-block"></span>
              <span className="text-emerald-400 font-semibold capitalize">{result.status}</span>
            </div>

            <div>
              <p className="text-zinc-500 text-sm">Product</p>
              <p className="text-lg font-medium">{result.product} × {result.quantity}</p>
            </div>

            {result.reviewed_by && (
              <div>
                <p className="text-zinc-500 text-sm">Reviewed by</p>
                <p className="text-lg font-medium">{result.reviewed_by}</p>
              </div>
            )}

            <p className="text-zinc-400 text-sm border-t border-zinc-800 pt-4">
              {result.message}
            </p>
          </div>
        )}

        <a href="/orders" className="inline-block mt-6 text-zinc-500 hover:text-white text-sm transition">
          ← Back to orders
        </a>
      </div>
    </main>
  )
}
