/**
 * Tanda 6, Item 5 — subida de imágenes (ej. foto de grupo) a almacenamiento
 * de objetos. La implementación real usa un bucket de AWS S3; en local se usa
 * un endpoint S3-compatible (LocalStack) apuntado por `AWS_S3_ENDPOINT`, sin
 * que el puerto ni los servicios que lo consumen se enteren de la diferencia.
 */
export interface ImageStorageRepository {
  /**
   * Sube el archivo bajo una key derivada de `carpeta` y devuelve la URL
   * pública para acceder a él.
   */
  subir(carpeta: string, buffer: Buffer, mimeType: string): Promise<string>;
}
