/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "**.supabase.co" },
      { protocol: "https", hostname: "hokejbal.cz" },
      { protocol: "https", hostname: "www.hokejbal.cz" },
    ],
  },
};

export default nextConfig;
