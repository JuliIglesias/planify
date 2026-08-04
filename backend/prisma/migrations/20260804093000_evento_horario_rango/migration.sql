-- Item 5 (Fase 5): el horario confirmado del evento pasa a ser un rango
-- (inicio + fin), no un instante. Nullable: los eventos ya confirmados antes
-- de este cambio se leen como si solo tuvieran fijado el bloque de la hora
-- de inicio (comportamiento anterior), sin necesidad de backfill.
ALTER TABLE "eventos" ADD COLUMN "fecha_hora_fin" TIMESTAMP(3);
