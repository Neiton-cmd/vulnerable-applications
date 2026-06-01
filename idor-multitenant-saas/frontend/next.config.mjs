/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          {
            key: "X-Notification-Service",
            value: "enabled",
          },
        ],
      },
    ]
  },
  async rewrites() {
    return [
      {
        source: "/static/:path*",
        destination: "http://backend:8000/static/:path*",
      },
      {
        source: "/robots.txt",
        destination: "http://backend:8000/robots.txt",
      },
    ]
  },
  images: {
    remotePatterns: [],
  },
}

export default nextConfig
