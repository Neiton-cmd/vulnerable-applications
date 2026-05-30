import Navbar from "../components/Navbar"

const team = [
  {
    name: "Jonathan \"Jonny\" Reeves",
    username: "jonny",
    role: "Head of Operations",
    bio: "Overseeing platform integrity, order processing, and team coordination across all departments.",
    initials: "JR",
    color: "bg-blue-600",
  },
  {
    name: "Michael Torres",
    username: "mike",
    role: "Senior Moderator",
    bio: "Responsible for product listing verification, review moderation, and seller compliance.",
    initials: "MT",
    color: "bg-violet-600",
  },
  {
    name: "Sarah Nolan",
    username: "sarah",
    role: "Content Moderator",
    bio: "Manages product descriptions, customer-facing content quality, and brand consistency.",
    initials: "SN",
    color: "bg-rose-600",
  },
  {
    name: "Thomas Webb",
    role: "Customer Support Lead",
    bio: "Handles escalated customer inquiries, dispute resolution, and satisfaction metrics.",
    initials: "TW",
    color: "bg-emerald-600",
  },
  {
    name: "Lisa Park",
    role: "Marketing Manager",
    bio: "Drives campaigns, partnerships, and growth strategy for the VulnShop platform.",
    initials: "LP",
    color: "bg-amber-600",
  },
  {
    name: "Daniel Cruz",
    role: "Backend Developer",
    bio: "Maintains platform infrastructure, API services, and internal tooling.",
    initials: "DC",
    color: "bg-cyan-600",
  },
]

export default function StaffPage() {
  return (
    <main className="min-h-screen bg-zinc-950 text-zinc-100">
      <Navbar />

      <section className="px-8 py-12 max-w-5xl mx-auto">
        <div className="mb-10">
          <h1 className="text-4xl font-bold mb-2">Our Team</h1>
          <p className="text-zinc-400">
            Meet the people behind VulnShop — moderators, support staff, and developers
            working to keep the platform running smoothly.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {team.map((member) => (
            <div
              key={member.name}
              className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 hover:border-zinc-700 transition"
            >
              <div className={`w-12 h-12 rounded-full ${member.color} flex items-center justify-center text-white font-bold text-lg mb-4`}>
                {member.initials}
              </div>
              <h3 className="text-lg font-semibold">{member.name}</h3>
              {"username" in member && (
                <p className="text-xs text-zinc-500 font-mono mb-1">@{member.username}</p>
              )}
              <p className="text-sm text-zinc-400 font-medium mb-3">{member.role}</p>
              <p className="text-sm text-zinc-500 leading-relaxed">{member.bio}</p>
            </div>
          ))}
        </div>
      </section>
    </main>
  )
}
