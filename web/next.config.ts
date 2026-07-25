/** @type {import('next').NextConfig} */
const nextConfig = {
  // Dev: prohlížeč na 127.0.0.1 vs localhost by jinak blokoval /_next/*
  allowedDevOrigins: ["127.0.0.1", "localhost"],
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "**.supabase.co" },
      { protocol: "https", hostname: "hokejbal.cz" },
      { protocol: "https", hostname: "www.hokejbal.cz" },
      { protocol: "https", hostname: "ui-avatars.com" },
    ],
  },
};

export default nextConfig;
