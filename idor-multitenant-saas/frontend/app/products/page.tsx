"use client"

import { useEffect, useState } from "react"
import Image from "next/image"
import Navbar from "../components/Navbar"

type Product = {
  id: number
  name: string
  price: number
  image: string
  description: string
}

type Review = {
  id: number
  author: string
  text: string
  rating: number
  verified_by: string | null
  is_moderator_verified: boolean
}

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [reviews, setReviews] = useState<Record<number, Review[]>>({})
  const [expanded, setExpanded] = useState<number | null>(null)
  const [added, setAdded] = useState<number | null>(null)

  useEffect(() => {
    fetch("/api/products")
      .then((r) => r.json())
      .then(setProducts)
  }, [])

  async function loadReviews(productId: number) {
    if (expanded === productId) { setExpanded(null); return }
    if (!reviews[productId]) {
      const data = await fetch(`/api/products/${productId}/reviews`).then((r) => r.json())
      setReviews((prev) => ({ ...prev, [productId]: data }))
    }
    setExpanded(productId)
  }

  async function addToCart(productId: number) {
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ product_id: productId, quantity: 1 }),
    })
    if (response.ok) {
      setAdded(productId)
      setTimeout(() => setAdded(null), 1500)
    }
  }

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100">
      <Navbar />

      <section className="px-8 py-10 max-w-6xl mx-auto">
        <div className="mb-8">
          <h2 className="text-4xl font-bold mb-2">Products</h2>
          <p className="text-zinc-400">Verified by our moderation team</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {products.map((product) => (
            <div
              key={product.id}
              className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 hover:border-zinc-700 transition"
            >
              <div className="relative h-44 rounded-xl overflow-hidden mb-5">
                <Image src={product.image} alt={product.name} fill className="object-cover" />
              </div>

              <h3 className="text-xl font-semibold mb-1">{product.name}</h3>
              <p className="text-zinc-400 text-sm mb-5">{product.description}</p>

              <div className="flex items-center justify-between mb-4">
                <span className="text-xl font-bold">${product.price}</span>
                <button
                  onClick={() => addToCart(product.id)}
                  className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
                    added === product.id
                      ? "bg-emerald-500 text-white"
                      : "bg-white text-black hover:opacity-90"
                  }`}
                >
                  {added === product.id ? "Added ✓" : "Add to cart"}
                </button>
              </div>

              <button
                onClick={() => loadReviews(product.id)}
                className="text-xs text-zinc-500 hover:text-zinc-300 transition"
              >
                {expanded === product.id ? "Hide reviews ▲" : "Show reviews ▼"}
              </button>

              {expanded === product.id && reviews[product.id] && (
                <div className="mt-4 space-y-3 border-t border-zinc-800 pt-4">
                  {reviews[product.id].map((r) => (
                    <div key={r.id} className="text-sm">
                      <div className="flex items-center gap-2 mb-1 flex-wrap">
                        <span className="text-zinc-300 font-medium">{r.author}</span>
                        <span className="text-yellow-400">{"★".repeat(r.rating)}</span>
                        {r.is_moderator_verified && r.verified_by && (
                          <span className="text-xs text-emerald-500 border border-emerald-800 px-1.5 py-0.5 rounded font-mono">
                            ✓ {r.verified_by}
                          </span>
                        )}
                      </div>
                      <p className="text-zinc-400">{r.text}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </section>
    </main>
  )
}
