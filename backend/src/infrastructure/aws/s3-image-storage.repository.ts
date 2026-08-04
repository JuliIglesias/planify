import { randomUUID } from 'crypto';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';

import { ImageStorageRepository } from '../../domain/repositories';

export interface S3ImageStorageConfig {
  bucket: string;
  region: string;
  /**
   * Endpoint S3-compatible. Vacío/undefined en AWS real; en local apunta a
   * LocalStack (`http://localhost:4566`) — es el "homónimo" de desarrollo del
   * mismo bucket real, sin que este adapter note la diferencia.
   */
  endpoint?: string;
  /** LocalStack (y otros S3-compatibles) necesitan path-style en vez de virtual-hosted-style. */
  forcePathStyle?: boolean;
  /** Si se define, se usa tal cual como base de la URL pública devuelta (ej. un dominio de CDN). */
  publicBaseUrl?: string;
  accessKeyId?: string;
  secretAccessKey?: string;
}

/**
 * Tanda 6, Item 5 — sube imágenes (hoy: foto de grupo) a un bucket S3.
 *
 * Misma clase para AWS real y para LocalStack en desarrollo: lo único que
 * cambia entre ambos es la config (`endpoint` + `forcePathStyle`), inyectada
 * desde `container.ts` a partir de variables de entorno.
 *
 * No fija ACL en el `PutObject`: muchos buckets modernos tienen las ACLs
 * deshabilitadas por default (Object Ownership = Bucket owner enforced), así
 * que el acceso público se resuelve con una bucket policy configurada fuera
 * de este código (ver docs/05-fixes.md).
 */
export class S3ImageStorageRepository implements ImageStorageRepository {
  private readonly client: S3Client;

  constructor(private readonly config: S3ImageStorageConfig) {
    this.client = new S3Client({
      region: config.region,
      endpoint: config.endpoint,
      forcePathStyle: config.forcePathStyle,
      credentials:
        config.accessKeyId && config.secretAccessKey
          ? { accessKeyId: config.accessKeyId, secretAccessKey: config.secretAccessKey }
          : undefined,
    });
  }

  async subir(carpeta: string, buffer: Buffer, mimeType: string): Promise<string> {
    const extension = mimeType.split('/')[1]?.split('+')[0] ?? 'bin';
    const key = `${carpeta}/${randomUUID()}.${extension}`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: this.config.bucket,
        Key: key,
        Body: buffer,
        ContentType: mimeType,
      }),
    );

    return this.urlPublica(key);
  }

  private urlPublica(key: string): string {
    if (this.config.publicBaseUrl) return `${this.config.publicBaseUrl}/${key}`;
    if (this.config.forcePathStyle && this.config.endpoint) {
      return `${this.config.endpoint}/${this.config.bucket}/${key}`;
    }
    return `https://${this.config.bucket}.s3.${this.config.region}.amazonaws.com/${key}`;
  }
}
