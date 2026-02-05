/** @type {import('next').NextConfig} */
const nextConfig = {
  // Remove static export for auth to work properly
  // output: 'export',
  images: {
    unoptimized: true,
  },
}

module.exports = nextConfig
