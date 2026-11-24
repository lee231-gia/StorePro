const CLOUDINARY_CLOUD = 'dn3rmoaq8';
const CLOUDINARY_PRESET = 'storepro_preset';

export async function uploadProductImage(file, folder) {
  const body = new FormData();
  body.append('file', file);
  body.append('upload_preset', CLOUDINARY_PRESET);
  body.append('folder', `storepro/${folder}`);
  const controller = new AbortController();
  const timer = window.setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/image/upload`, {
      method: 'POST',
      body,
      signal: controller.signal,
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || !result.secure_url) throw new Error(result.error?.message || 'Image upload failed. Check your connection and try again.');
    return result.secure_url;
  } finally {
    window.clearTimeout(timer);
  }
}
