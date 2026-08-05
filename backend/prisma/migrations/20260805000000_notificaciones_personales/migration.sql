-- F2: notificaciones que no cuelgan de ningún evento (ej. solicitud de
-- amistad recibida). Tabla separada de "log_actividad" a propósito: esa
-- sigue siendo estrictamente "actividad DENTRO de un evento".
CREATE TABLE "notificaciones_personales" (
    "id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "actor_usuario_id" TEXT NOT NULL,
    "payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "notificaciones_personales_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "notificaciones_personales_usuario_id_created_at_idx" ON "notificaciones_personales"("usuario_id", "created_at");

ALTER TABLE "notificaciones_personales" ADD CONSTRAINT "notificaciones_personales_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "notificaciones_personales" ADD CONSTRAINT "notificaciones_personales_actor_usuario_id_fkey" FOREIGN KEY ("actor_usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
