const DEFAULTS = Object.freeze({
  OWNER: "ilikehercauseherpussypink",
  REPO: "archboot",
  BRANCH: "main",
});

function headers(contentType) {
  return {
    "Content-Type": contentType,
    "Cache-Control": "public, max-age=60, s-maxage=300",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
  };
}

function textResponse(message, status, method, extraHeaders = {}) {
  const body = method === "HEAD" ? null : `${message}\n`;
  return new Response(body, {
    status,
    headers: {
      ...headers("text/plain; charset=utf-8"),
      ...extraHeaders,
    },
  });
}

export default {
  async fetch(request, env = {}) {
    const method = request.method.toUpperCase();

    if (method !== "GET" && method !== "HEAD") {
      return textResponse("method not allowed", 405, method, {
        Allow: "GET, HEAD",
      });
    }

    const { pathname } = new URL(request.url);

    if (pathname === "/health") {
      return textResponse("ok", 200, method);
    }

    if (pathname !== "/" && pathname !== "/install.sh") {
      return textResponse("not found", 404, method);
    }

    const owner = env.OWNER || DEFAULTS.OWNER;
    const repo = env.REPO || DEFAULTS.REPO;
    const branch = env.BRANCH || DEFAULTS.BRANCH;
    const upstreamUrl = `https://raw.githubusercontent.com/${owner}/${repo}/${branch}/install.sh`;

    let upstream = null;
    try {
      upstream = await fetch(upstreamUrl, {
        method,
        headers: { Accept: "text/plain" },
        cf: { cacheEverything: true, cacheTtl: 60 },
      });
    } catch {
      return textResponse("upstream unavailable", 502, method);
    }

    if (upstream.status !== 200 || (method === "GET" && upstream.body === null)) {
      return textResponse("upstream unavailable", 502, method);
    }

    return new Response(method === "HEAD" ? null : upstream.body, {
      status: 200,
      headers: headers("text/x-shellscript; charset=utf-8"),
    });
  },
};
