import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import '../styles/globals.css';

// Primary font for the DBMS dashboard - clean, readable, professional
const inter = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'DBMS Self-Healing Dashboard',
  description: 'AI-assisted database management and observability platform',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="font-sans antialiased">
        {/* Root wrapper for future dashboard layout zones */}
        <div id="dashboard-root">
          {/* Future: Header/Navigation zone */}
          {/* Future: Sidebar/Navigation zone */}
          {/* Future: Main content zone */}
          {children}
        </div>
      </body>
    </html>
  );
}
