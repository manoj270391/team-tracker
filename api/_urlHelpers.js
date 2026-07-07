const FILE_TYPE_EXTENSIONS = {
  pdf: ["pdf"],
  doc: ["doc", "docx"],
  ppt: ["ppt", "pptx"],
  xlsx: ["xls", "xlsx"],
};

function rootDomain(hostname) {
  const parts = hostname.split(".");
  if (parts.length <= 2) return hostname;
  return parts.slice(-2).join(".");
}

function isInScope(seedHost, candidateHost, scope) {
  if (scope === "single") return false;
  if (scope === "site") return candidateHost === seedHost;
  if (scope === "subdomains") return rootDomain(candidateHost) === rootDomain(seedHost);
  return false;
}

function extensionOf(pathname) {
  const clean = pathname.split("?")[0].split("#")[0];
  const idx = clean.lastIndexOf(".");
  if (idx === -1) return "";
  return clean.slice(idx + 1).toLowerCase();
}

function matchFileType(ext, wanted) {
  for (const key of wanted) {
    if ((FILE_TYPE_EXTENSIONS[key] || []).includes(ext)) return key;
  }
  return null;
}

const NON_HTML_EXT = [
  "jpg", "jpeg", "png", "gif", "svg", "webp", "ico", "css", "js", "json",
  "mp4", "mp3", "avi", "mov", "zip", "rar", "woff", "woff2", "ttf",
];

function isCrawlableHtmlLink(url) {
  const ext = extensionOf(url.pathname);
  return ext === "" || !NON_HTML_EXT.includes(ext);
}

function fileNameFromUrl(url) {
  try {
    const u = new URL(url);
    const last = u.pathname.split("/").filter(Boolean).pop();
    return last ? decodeURIComponent(last) : url;
  } catch {
    return url;
  }
}

module.exports = {
  FILE_TYPE_EXTENSIONS,
  rootDomain,
  isInScope,
  extensionOf,
  matchFileType,
  isCrawlableHtmlLink,
  fileNameFromUrl,
};
