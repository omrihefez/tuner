// bt-4d32: tuner.omrihefez.com -> bass.omrihefez.com used vercel.json's
// declarative `redirects`, which Vercel serves straight off the CDN/filesystem
// layer without ever applying this repo's `headers` block — measured live,
// the 308 carried only Vercel's bare platform-default
// `Strict-Transport-Security: max-age=63072000`, missing includeSubDomains,
// and none of the other security headers either. A plain `rewrites` entry to
// a Function has the same problem for any path that collides with a real
// static file (e.g. `/` -> index.html): Vercel serves the static file before
// consulting rewrites. Middleware runs before both, so it's the only layer
// that can override the redirect for every path on this host, including `/`.
import { next } from "@vercel/functions";

export const config = {
  matcher: "/:path*",
};

export default function middleware(request) {
  const host = request.headers.get("host") || "";
  if (host !== "tuner.omrihefez.com") {
    return next();
  }

  const url = new URL(request.url);
  const destination = `https://bass.omrihefez.com${url.pathname}${url.search}`;
  return new Response(null, {
    status: 308,
    headers: {
      Location: destination,
      "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
      "Cache-Control": "public, max-age=0, must-revalidate",
      Refresh: `0;url=${destination}`,
      "Content-Type": "text/plain",
    },
  });
}
