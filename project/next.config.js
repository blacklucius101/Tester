/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  // Allow all domains for development
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
}

module.exports = nextConfig
