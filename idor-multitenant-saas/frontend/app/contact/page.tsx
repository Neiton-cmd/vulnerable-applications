"use client"

import { useState } from "react"
import Navbar from "../components/Navbar"

export default function ContactPage() {
  const [sent, setSent] = useState(false)

  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100">
      <Navbar />

      <section className="px-8 py-12 max-w-4xl mx-auto">
        <div className="mb-10">
          <h1 className="text-4xl font-bold mb-2">Contact Us</h1>
          <p className="text-zinc-400">
            Have a question or need support? Reach out to our team.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
          <div className="space-y-6">
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
              <h3 className="font-semibold mb-1">General Support</h3>
              <p className="text-zinc-400 text-sm">support@vulnshop.htb</p>
            </div>
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
              <h3 className="font-semibold mb-1">Order Issues</h3>
              <p className="text-zinc-400 text-sm">orders@vulnshop.htb</p>
            </div>
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
              <h3 className="font-semibold mb-1">Business Inquiries</h3>
              <p className="text-zinc-400 text-sm">business@vulnshop.htb</p>
            </div>
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
              <h3 className="font-semibold mb-1">Office</h3>
              <p className="text-zinc-400 text-sm">
                14 Meridian Plaza, Floor 7<br />
                San Francisco, CA 94103
              </p>
            </div>
          </div>

          <form
            onSubmit={(e) => { e.preventDefault(); setSent(true) }}
            className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 space-y-4"
          >
            <h2 className="text-xl font-semibold">Send a message</h2>

            <div>
              <label className="block text-sm text-zinc-400 mb-1">Name</label>
              <input
                type="text"
                placeholder="Your name"
                className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl text-sm focus:outline-none focus:border-zinc-600"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-zinc-400 mb-1">Email</label>
              <input
                type="email"
                placeholder="your@email.com"
                className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl text-sm focus:outline-none focus:border-zinc-600"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-zinc-400 mb-1">Message</label>
              <textarea
                rows={4}
                placeholder="How can we help?"
                className="w-full px-4 py-3 bg-zinc-950 border border-zinc-800 rounded-xl text-sm focus:outline-none focus:border-zinc-600 resize-none"
                required
              />
            </div>

            {sent ? (
              <p className="text-emerald-400 text-sm">Message sent. We will get back to you shortly.</p>
            ) : (
              <button
                type="submit"
                className="w-full bg-white text-black py-3 rounded-xl font-medium hover:opacity-90 transition text-sm"
              >
                Send message
              </button>
            )}
          </form>
        </div>
      </section>
    </main>
  )
}
