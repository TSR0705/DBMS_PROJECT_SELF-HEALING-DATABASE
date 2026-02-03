import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: false, // Disabled for CI stability
};

export default nextConfig;
