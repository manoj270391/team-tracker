const { PDFDocument } = require("pdf-lib");
const JSZip = require("jszip");

const MAX_DETAIL_BYTES = 40 * 1024 * 1024; // 40MB safety cap

async function getFileMeta(url, fileType, fetchDetails) {
  let sizeBytes = null;
  try {
    const head = await fetch(url, { method: "HEAD" });
    const len = head.headers.get("content-length");
    if (len) sizeBytes = parseInt(len, 10);
  } catch {
    /* some servers block HEAD; fall back to GET below if we need it */
  }

  if (fileType === "doc") {
    // Word page count isn't reliably stored in the file itself -> left blank by design.
    return { sizeBytes, pages: null };
  }

  if (!fetchDetails) return { sizeBytes, pages: null };
  if (sizeBytes && sizeBytes > MAX_DETAIL_BYTES) return { sizeBytes, pages: null };

  try {
    const res = await fetch(url);
    if (!res.ok) return { sizeBytes, pages: null };
    const buf = Buffer.from(await res.arrayBuffer());
    if (!sizeBytes) sizeBytes = buf.byteLength;
    if (sizeBytes > MAX_DETAIL_BYTES) return { sizeBytes, pages: null };

    if (fileType === "pdf") {
      const doc = await PDFDocument.load(buf, { ignoreEncryption: true });
      return { sizeBytes, pages: doc.getPageCount() };
    }

    if (fileType === "ppt") {
      if (!url.split("?")[0].toLowerCase().endsWith(".pptx")) return { sizeBytes, pages: null };
      const zip = await JSZip.loadAsync(buf);
      const slideFiles = Object.keys(zip.files).filter((f) => /^ppt\/slides\/slide\d+\.xml$/.test(f));
      return { sizeBytes, pages: slideFiles.length || null };
    }

    if (fileType === "xlsx") {
      if (!url.split("?")[0].toLowerCase().endsWith(".xlsx")) return { sizeBytes, pages: null };
      const zip = await JSZip.loadAsync(buf);
      const workbookXml = await zip.file("xl/workbook.xml")?.async("string");
      if (!workbookXml) return { sizeBytes, pages: null };
      const sheetMatches = workbookXml.match(/<sheet\s/g);
      return { sizeBytes, pages: sheetMatches ? sheetMatches.length : null };
    }

    return { sizeBytes, pages: null };
  } catch {
    return { sizeBytes, pages: null };
  }
}

module.exports = { getFileMeta };
