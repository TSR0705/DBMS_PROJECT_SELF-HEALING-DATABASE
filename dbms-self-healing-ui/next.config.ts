import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: false, // Disabled for CI stability
  
  // Explicitly set the project root to avoid workspace detection issues
  // This prevents Next.js from looking in parent directories
  distDir: '.next',
};

export default nextConfig;
