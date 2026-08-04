-- Item 1 (Fase 5): rango de fechas calendario del evento (ADR 0002).
-- Se agregan nullable primero para poder backfillear los eventos ya
-- existentes, y recién después se marcan NOT NULL.
ALTER TABLE "eventos" ADD COLUMN "rango_inicio" TIMESTAMP(3);
ALTER TABLE "eventos" ADD COLUMN "rango_fin" TIMESTAMP(3);
ALTER TABLE "eventos" ADD COLUMN "extensiones_rango" INTEGER NOT NULL DEFAULT 0;

-- Backfill: los eventos creados antes de este cambio no tenían rango; se les
-- asigna uno de 2 semanas desde su creación para no dejarlos en un estado
-- inconsistente (mejor una estimación razonable que un rango arbitrario).
UPDATE "eventos"
SET "rango_inicio" = "created_at",
    "rango_fin" = "created_at" + INTERVAL '14 days'
WHERE "rango_inicio" IS NULL;

ALTER TABLE "eventos" ALTER COLUMN "rango_inicio" SET NOT NULL;
ALTER TABLE "eventos" ALTER COLUMN "rango_fin" SET NOT NULL;
