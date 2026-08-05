-- G1 (ADR 0003): PIN de sesión anónima, para poder recuperar la misma fila
-- de Participante al volver a entrar con el mismo username. Nullable: los
-- participantes registrados (es_anonimo = false) no tienen PIN.
ALTER TABLE "participantes" ADD COLUMN "pin_hash" TEXT;
