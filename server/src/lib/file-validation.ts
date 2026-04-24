interface MagicSignature {
  mime: string;
  bytes: number[];
  offset?: number;
  /** Additional bytes that must match at a second offset */
  extra?: { bytes: number[]; offset: number };
}

const IMAGE_SIGNATURES: MagicSignature[] = [
  { mime: "image/jpeg", bytes: [0xff, 0xd8, 0xff] },
  { mime: "image/png", bytes: [0x89, 0x50, 0x4e, 0x47] },
  { mime: "image/gif", bytes: [0x47, 0x49, 0x46, 0x38] },
  {
    mime: "image/webp",
    bytes: [0x52, 0x49, 0x46, 0x46],
    extra: { bytes: [0x57, 0x45, 0x42, 0x50], offset: 8 },
  },
];

const DOCUMENT_SIGNATURES: MagicSignature[] = [
  { mime: "application/pdf", bytes: [0x25, 0x50, 0x44, 0x46] }, // %PDF
  // DOCX/XLSX/PPTX are all ZIP-based (PK header)
  {
    mime: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    bytes: [0x50, 0x4b, 0x03, 0x04],
  },
  {
    mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    bytes: [0x50, 0x4b, 0x03, 0x04],
  },
  {
    mime: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    bytes: [0x50, 0x4b, 0x03, 0x04],
  },
];

function matchesSignature(buffer: Buffer, sig: MagicSignature): boolean {
  const offset = sig.offset ?? 0;
  if (buffer.length < offset + sig.bytes.length) return false;

  for (let i = 0; i < sig.bytes.length; i++) {
    if (buffer[offset + i] !== sig.bytes[i]) return false;
  }

  if (sig.extra) {
    const ex = sig.extra;
    if (buffer.length < ex.offset + ex.bytes.length) return false;
    for (let i = 0; i < ex.bytes.length; i++) {
      if (buffer[ex.offset + i] !== ex.bytes[i]) return false;
    }
  }

  return true;
}

export function isValidImage(buffer: Buffer): boolean {
  return IMAGE_SIGNATURES.some((sig) => matchesSignature(buffer, sig));
}

export function isValidDocument(buffer: Buffer): boolean {
  return [...DOCUMENT_SIGNATURES, ...IMAGE_SIGNATURES].some((sig) =>
    matchesSignature(buffer, sig)
  );
}

export function detectMimeFromBytes(buffer: Buffer): string | null {
  for (const sig of [...IMAGE_SIGNATURES, ...DOCUMENT_SIGNATURES]) {
    if (matchesSignature(buffer, sig)) return sig.mime;
  }
  return null;
}
