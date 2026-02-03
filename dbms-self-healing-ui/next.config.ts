import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: false, // Disabled for CI stability
  experimental: {
    turbo: {
      // Disable turbopack for CI stability
    },
  },
};

export default nextConfig;
