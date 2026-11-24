const CLOUDINARY_CLOUD = 'dn3rmoaq8';
const CLOUDINARY_PRESET = 'storepro_preset';

export async function uploadProductImage(asset, folder) {
  if (!asset?.uri) throw new Error('Choose an image before uploading.');
  const formData = new FormData();
  formData.append('file', {
    uri: asset.uri,
    name: asset.fileName || `storepro-${Date.now()}.jpg`,
    type: asset.mimeType || 'image/jpeg',
  });
  formData.append('upload_preset', CLOUDINARY_PRESET);
  formData.append('folder', `storepro/${folder}`);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/image/upload`, {
      method: 'POST',
      body: formData,
      signal: controller.signal,
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || !result.secure_url) throw new Error(result.error?.message || 'Image upload failed. Check your connection and try again.');
    return result.secure_url;
  } finally {
    clearTimeout(timeout);
  }
}
