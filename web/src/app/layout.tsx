import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Hokejbal",
  description: "Webová verze aplikace Hokejbal — zápasy, LIVE, fantasy a tipovačka.",
  applicationName: "Hokejbal",
  appleWebApp: {
    capable: true,
    title: "Hokejbal",
    statusBarStyle: "default",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#C92A2A",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="cs" data-theme="light">
      <body className="antialiased">{children}</body>
    </html>
  );
}
