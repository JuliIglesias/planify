-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "EventoEstado" AS ENUM ('planificacion', 'confirmado', 'cancelado', 'finalizado');

-- CreateEnum
CREATE TYPE "AsistenciaEstado" AS ENUM ('sin_confirmar', 'confirmado', 'rechazado');

-- CreateEnum
CREATE TYPE "TareaEstado" AS ENUM ('no_asignado', 'pendiente', 'completado');

-- CreateEnum
CREATE TYPE "DeudaEstado" AS ENUM ('pagar', 'pendiente', 'saldado');

-- CreateEnum
CREATE TYPE "AmistadEstado" AS ENUM ('pendiente', 'aceptada');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "avatar_url" TEXT,
    "idioma_preferido" TEXT NOT NULL DEFAULT 'es',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "grupos" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "avatar_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "grupos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "miembros_grupo" (
    "id" TEXT NOT NULL,
    "grupo_id" TEXT NOT NULL,
    "usuario_id" TEXT NOT NULL,
    "fecha_union" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "miembros_grupo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "eventos" (
    "id" TEXT NOT NULL,
    "grupo_id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "lugar_texto" TEXT NOT NULL,
    "estado" "EventoEstado" NOT NULL DEFAULT 'planificacion',
    "fecha_hora_inicio" TIMESTAMP(3),
    "creado_por" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "eventos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "participantes" (
    "id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "usuario_id" TEXT,
    "nombre_display" TEXT NOT NULL,
    "es_anonimo" BOOLEAN NOT NULL DEFAULT false,
    "es_organizador" BOOLEAN NOT NULL DEFAULT false,
    "token_sesion" TEXT,
    "estado_asistencia" "AsistenciaEstado" NOT NULL DEFAULT 'sin_confirmar',
    "ultima_lectura_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "participantes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invitaciones" (
    "id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "token_unico" TEXT NOT NULL,
    "expira_en" TIMESTAMP(3),
    "usos_maximos" INTEGER,

    CONSTRAINT "invitaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "disponibilidad_slots" (
    "id" TEXT NOT NULL,
    "participante_id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "dia_semana" INTEGER NOT NULL,
    "bloque_hora" INTEGER NOT NULL,

    CONSTRAINT "disponibilidad_slots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tareas" (
    "id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "estado" "TareaEstado" NOT NULL DEFAULT 'no_asignado',
    "asignado_a" TEXT,
    "creado_por" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tareas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gastos" (
    "id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "descripcion" TEXT NOT NULL,
    "monto_total" DECIMAL(12,2) NOT NULL,
    "creado_por" TEXT NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gastos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gasto_acreedores" (
    "id" TEXT NOT NULL,
    "gasto_id" TEXT NOT NULL,
    "participante_id" TEXT NOT NULL,
    "monto_aportado" DECIMAL(12,2) NOT NULL,

    CONSTRAINT "gasto_acreedores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gasto_deudores" (
    "id" TEXT NOT NULL,
    "gasto_id" TEXT NOT NULL,
    "participante_id" TEXT NOT NULL,
    "monto_adeudado" DECIMAL(12,2) NOT NULL,

    CONSTRAINT "gasto_deudores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deudas_simplificadas" (
    "id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "deudor_participante_id" TEXT NOT NULL,
    "acreedor_participante_id" TEXT NOT NULL,
    "monto" DECIMAL(12,2) NOT NULL,
    "estado" "DeudaEstado" NOT NULL DEFAULT 'pendiente',
    "saldado_en" TIMESTAMP(3),

    CONSTRAINT "deudas_simplificadas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "log_actividad" (
    "id" TEXT NOT NULL,
    "evento_id" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "actor_participante_id" TEXT NOT NULL,
    "payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "log_actividad_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "amistades" (
    "id" TEXT NOT NULL,
    "usuario_id_1" TEXT NOT NULL,
    "usuario_id_2" TEXT NOT NULL,
    "estado" "AmistadEstado" NOT NULL DEFAULT 'pendiente',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "amistades_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_email_key" ON "usuarios"("email");

-- CreateIndex
CREATE UNIQUE INDEX "miembros_grupo_grupo_id_usuario_id_key" ON "miembros_grupo"("grupo_id", "usuario_id");

-- CreateIndex
CREATE UNIQUE INDEX "participantes_token_sesion_key" ON "participantes"("token_sesion");

-- CreateIndex
CREATE UNIQUE INDEX "invitaciones_token_unico_key" ON "invitaciones"("token_unico");

-- CreateIndex
CREATE UNIQUE INDEX "disponibilidad_slots_participante_id_evento_id_dia_semana_b_key" ON "disponibilidad_slots"("participante_id", "evento_id", "dia_semana", "bloque_hora");

-- CreateIndex
CREATE UNIQUE INDEX "amistades_usuario_id_1_usuario_id_2_key" ON "amistades"("usuario_id_1", "usuario_id_2");

-- AddForeignKey
ALTER TABLE "miembros_grupo" ADD CONSTRAINT "miembros_grupo_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "miembros_grupo" ADD CONSTRAINT "miembros_grupo_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "eventos" ADD CONSTRAINT "eventos_grupo_id_fkey" FOREIGN KEY ("grupo_id") REFERENCES "grupos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participantes" ADD CONSTRAINT "participantes_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participantes" ADD CONSTRAINT "participantes_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitaciones" ADD CONSTRAINT "invitaciones_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disponibilidad_slots" ADD CONSTRAINT "disponibilidad_slots_participante_id_fkey" FOREIGN KEY ("participante_id") REFERENCES "participantes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disponibilidad_slots" ADD CONSTRAINT "disponibilidad_slots_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tareas" ADD CONSTRAINT "tareas_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tareas" ADD CONSTRAINT "tareas_asignado_a_fkey" FOREIGN KEY ("asignado_a") REFERENCES "participantes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tareas" ADD CONSTRAINT "tareas_creado_por_fkey" FOREIGN KEY ("creado_por") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gastos" ADD CONSTRAINT "gastos_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gastos" ADD CONSTRAINT "gastos_creado_por_fkey" FOREIGN KEY ("creado_por") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gasto_acreedores" ADD CONSTRAINT "gasto_acreedores_gasto_id_fkey" FOREIGN KEY ("gasto_id") REFERENCES "gastos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gasto_acreedores" ADD CONSTRAINT "gasto_acreedores_participante_id_fkey" FOREIGN KEY ("participante_id") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gasto_deudores" ADD CONSTRAINT "gasto_deudores_gasto_id_fkey" FOREIGN KEY ("gasto_id") REFERENCES "gastos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gasto_deudores" ADD CONSTRAINT "gasto_deudores_participante_id_fkey" FOREIGN KEY ("participante_id") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deudas_simplificadas" ADD CONSTRAINT "deudas_simplificadas_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deudas_simplificadas" ADD CONSTRAINT "deudas_simplificadas_deudor_participante_id_fkey" FOREIGN KEY ("deudor_participante_id") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deudas_simplificadas" ADD CONSTRAINT "deudas_simplificadas_acreedor_participante_id_fkey" FOREIGN KEY ("acreedor_participante_id") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "log_actividad" ADD CONSTRAINT "log_actividad_evento_id_fkey" FOREIGN KEY ("evento_id") REFERENCES "eventos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "log_actividad" ADD CONSTRAINT "log_actividad_actor_participante_id_fkey" FOREIGN KEY ("actor_participante_id") REFERENCES "participantes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amistades" ADD CONSTRAINT "amistades_usuario_id_1_fkey" FOREIGN KEY ("usuario_id_1") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amistades" ADD CONSTRAINT "amistades_usuario_id_2_fkey" FOREIGN KEY ("usuario_id_2") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

