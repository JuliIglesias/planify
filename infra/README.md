# Infraestructura — Planify

Decisión de arquitectura: **AWS EC2 + RDS Postgres**, encendidos únicamente para testing del equipo y demos a los profesores (ver [`docs/02-decisiones.md`](../docs/02-decisiones.md), Duda #8 revisada). No hay compromiso de disponibilidad 24/7 — es un proyecto académico donde "producción" es una demo.

> ⚠️ Nada de lo que sigue está provisionado todavía. Requiere una cuenta de AWS y credenciales que no están disponibles en el entorno de desarrollo — lo ejecuta el equipo manualmente.

## Desarrollo local (sin AWS)

Levanta Postgres + backend en Docker:

```bash
docker compose -f infra/docker-compose.yml up --build
```

Luego, la primera vez:

```bash
cd backend
npx prisma migrate dev
npm run seed
```

El `seed` crea el usuario organizador semilla (T-07): `organizador@planify.test` / `planify-mvp-2026`. Es el único que puede crear eventos en el MVP (ver Duda #19) — los anónimos solo se unen por link de invitación.

## Provisioning de AWS (T-01)

Objetivo: mantenerse dentro del **Free Tier de 12 meses**, que cubre los 4 meses del proyecto.

### 1. Cuenta y usuario IAM
1. Crear cuenta AWS nueva (para tener el Free Tier disponible).
2. Crear un usuario IAM para el equipo con acceso programático — **no usar la cuenta root** para el día a día.
3. Habilitar MFA en la cuenta root.

### 2. RDS Postgres
1. RDS → Create database → PostgreSQL.
2. Template: **Free tier**, instancia `db.t3.micro`, 20 GB gp2.
3. Anotar endpoint, usuario y contraseña → van a `DATABASE_URL` del backend.
4. Security group: permitir el puerto 5432 solo desde el security group del EC2 (no abrir a `0.0.0.0/0`).

> Nota operativa: una instancia RDS detenida **se reinicia sola después de 7 días**. Si el ambiente va a quedar apagado más tiempo, conviene tomar un snapshot y borrar la instancia, restaurándola antes de la próxima demo.

### 3. EC2
1. EC2 → Launch instance → Amazon Linux 2023, tipo `t2.micro`/`t3.micro` (Free Tier).
2. Crear key pair y guardarlo (va como secret `EC2_SSH_KEY` en GitHub).
3. Security group: puerto 22 (SSH) solo desde las IPs del equipo, y 3000 (o 80/443 detrás de un reverse proxy) para la app.
4. Instalar Docker y docker-compose en la instancia.

### 4. Cognito (para SCRUM-14 — auth completa, no se usa en el MVP)
1. Crear un User Pool con login por email.
2. Crear un App Client sin secret (para la app mobile).
3. Anotar `COGNITO_USER_POOL_ID` y `COGNITO_CLIENT_ID`.

### 5. SNS / Pinpoint (para SCRUM-15 — notificaciones)
Configurar recién cuando se aborde esa épica (15/10–28/10).

## Encendido y apagado del ambiente

El ambiente vive apagado por defecto. Antes de cada sesión de testing o demo:

1. Iniciar la instancia RDS (consola AWS o `aws rds start-db-instance`).
2. Iniciar la instancia EC2 (`aws ec2 start-instances`).
3. Verificar que la API responde: `curl http://<EC2_HOST>:3000/health`.

Al terminar, detener ambas en orden inverso. Los datos persisten en los volúmenes EBS/RDS entre apagados.

> Automatizar esto con EventBridge + Lambda (o AWS Instance Scheduler) es un objetivo deseable pero **no bloqueante** — arrancar con arranque manual documentado.

## Secrets de GitHub Actions (T-05)

Para que el workflow `deploy-ec2.yml` funcione, configurar en Settings → Secrets del repo:

- `EC2_HOST` — IP pública o DNS de la instancia
- `EC2_USER` — usuario SSH (`ec2-user` en Amazon Linux)
- `EC2_SSH_KEY` — contenido del `.pem` del key pair

El deploy es de **disparo manual** (`workflow_dispatch`), nunca automático, para no encender/modificar el ambiente sin querer.
