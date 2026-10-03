const MAX_IMAGE_DIMENSION = 2560;
const JPEG_QUALITIES = [0.92, 0.9, 0.88];
const COMPRESSIBLE_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"];

function loadImage(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const objectUrl = URL.createObjectURL(file);
    const image = new Image();

    image.onload = () => {
      URL.revokeObjectURL(objectUrl);
      resolve(image);
    };
    image.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error(`Unable to read image "${file.name}" for compression.`));
    };
    image.src = objectUrl;
  });
}

function canvasToBlob(
  canvas: HTMLCanvasElement,
  mimeType: string,
  quality?: number,
): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (!blob) {
          reject(new Error("The selected image could not be compressed."));
          return;
        }
        resolve(blob);
      },
      mimeType,
      quality,
    );
  });
}

function fileFromBlob(blob: Blob, source: File): File {
  if (blob.type !== source.type) {
    throw new Error(
      `The browser could not preserve the image format for "${source.name}" while compressing it.`,
    );
  }

  return new File([blob], source.name, {
    type: blob.type,
    lastModified: source.lastModified,
  });
}

export async function compressImageFile(file: File): Promise<File> {
  if (!file.type.startsWith("image/")) return file;
  if (!COMPRESSIBLE_IMAGE_TYPES.includes(file.type)) {
    throw new Error(
      `The image format "${file.type}" cannot be safely compressed in this browser.`,
    );
  }

  const image = await loadImage(file);
  const longestSide = Math.max(image.naturalWidth, image.naturalHeight);
  if (!longestSide) {
    throw new Error(`The selected image "${file.name}" has invalid dimensions.`);
  }

  const scale = Math.min(1, MAX_IMAGE_DIMENSION / longestSide);
  const canvas = document.createElement("canvas");
  canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
  canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));

  const context = canvas.getContext("2d");
  if (!context) {
    throw new Error("Image compression is not supported by this browser.");
  }
  context.drawImage(image, 0, 0, canvas.width, canvas.height);

  if (file.type === "image/png") {
    const compressed = fileFromBlob(
      await canvasToBlob(canvas, file.type),
      file,
    );
    return compressed.size < file.size ? compressed : file;
  }

  for (const quality of JPEG_QUALITIES) {
    const compressed = fileFromBlob(
      await canvasToBlob(canvas, file.type, quality),
      file,
    );
    if (compressed.size < file.size) return compressed;
  }

  return file;
}
