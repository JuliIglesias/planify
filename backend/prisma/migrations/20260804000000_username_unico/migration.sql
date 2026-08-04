-- Username único, reemplaza a "nombre" (Usuario) y "nombre_display" (Participante).
-- Ver docs/05-fixes.md — Item "Username único para logueados y anónimos".

-- 1) Usuario: renombrar nombre -> username.
ALTER TABLE "usuarios" RENAME COLUMN "nombre" TO "username";

-- 2) Normalizar (minúsculas, espacios -> guion bajo) y desambiguar los que
--    queden duplicados antes de poder agregar la constraint única: los
--    usuarios ya existentes tenían "nombre" libre, sin ninguna unicidad.
UPDATE "usuarios"
SET "username" = lower(regexp_replace(trim("username"), '\s+', '_', 'g'));

WITH duplicados AS (
  SELECT "id", "username",
         ROW_NUMBER() OVER (PARTITION BY "username" ORDER BY "created_at", "id") AS rn
  FROM "usuarios"
)
UPDATE "usuarios" u
SET "username" = u."username" || '_' || d.rn
FROM duplicados d
WHERE u."id" = d."id" AND d.rn > 1;

ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_username_key" UNIQUE ("username");

-- 3) Participante: renombrar nombre_display -> username. Sin constraint
--    única a nivel de tabla (ver comentario en schema.prisma) — la
--    unicidad para anónimos se valida en la aplicación.
ALTER TABLE "participantes" RENAME COLUMN "nombre_display" TO "username";
