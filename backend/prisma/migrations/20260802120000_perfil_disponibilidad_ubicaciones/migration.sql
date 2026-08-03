-- H-14: disponibilidad semanal de perfil (por usuario)
CREATE TABLE "disponibilidad_perfil" (
    "id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "dia_semana" INTEGER NOT NULL,
    "bloque_hora" INTEGER NOT NULL,
    CONSTRAINT "disponibilidad_perfil_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "disponibilidad_perfil_usuario_id_dia_semana_bloque_hora_key" ON "disponibilidad_perfil"("usuario_id", "dia_semana", "bloque_hora");

ALTER TABLE "disponibilidad_perfil" ADD CONSTRAINT "disponibilidad_perfil_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- HU-B5: ubicaciones favoritas
CREATE TABLE "ubicaciones_favoritas" (
    "id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "etiqueta" TEXT NOT NULL,
    "texto" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ubicaciones_favoritas_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "ubicaciones_favoritas" ADD CONSTRAINT "ubicaciones_favoritas_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
