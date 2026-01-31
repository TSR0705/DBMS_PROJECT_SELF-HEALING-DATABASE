import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-sans)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "ui-monospace", "monospace"], // Reserved for logs/code
      },
      
      // 8px-based spacing scale for consistent layout rhythm
      spacing: {
        xs: "0.5rem",   // 8px  - tight spacing within components
        sm: "0.75rem",  // 12px - small gaps between related elements
        md: "1rem",     // 16px - standard component spacing
        lg: "1.5rem",   // 24px - section spacing
        xl: "2rem",     // 32px - major section breaks
        "2xl": "3rem",  // 48px - page-level spacing
        "3xl": "4rem",  // 64px - major layout divisions
      },

      // Typography scale optimized for dashboard density and readability
      fontSize: {
        xs: ["0.75rem", { lineHeight: "1rem" }],     // 12px - metadata, timestamps
        sm: ["0.875rem", { lineHeight: "1.25rem" }], // 14px - table data, secondary text
        base: ["1rem", { lineHeight: "1.5rem" }],    // 16px - body text, form inputs
        lg: ["1.125rem", { lineHeight: "1.75rem" }], // 18px - section headings
        xl: ["1.25rem", { lineHeight: "1.75rem" }],  // 20px - page titles
        "2xl": ["1.5rem", { lineHeight: "2rem" }],   // 24px - dashboard titles (rare)
      },

      // Content width constraints for optimal reading and layout
      maxWidth: {
        "content-sm": "32rem",   // 512px - narrow forms, sidebars
        "content-md": "48rem",   // 768px - main content areas
        "content-lg": "64rem",   // 1024px - wide tables, dashboards
        "content-xl": "80rem",   // 1280px - full-width layouts
      },

      // Line heights tuned for dashboard context
      lineHeight: {
        tight: "1.25",    // Dense tables, compact lists
        normal: "1.5",    // Standard body text
        relaxed: "1.75",  // Headings, important content
      },
    },
  },
  plugins: [],
};

export default config;