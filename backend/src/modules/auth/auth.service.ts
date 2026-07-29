import bcrypt from 'bcryptjs';
import { prisma } from '../../common/prisma';
import { UnauthorizedError } from '../../common/errors';
import { signOrganizerToken } from '../../common/jwt';

// HU-41 — login del organizador semilla (T-07). Sin Cognito todavía (ver Duda #19).
export async function loginOrganizer(email: string, password: string) {
  const usuario = await prisma.usuario.findUnique({ where: { email } });
  if (!usuario) throw new UnauthorizedError('Credenciales inválidas');

  const valid = await bcrypt.compare(password, usuario.passwordHash);
  if (!valid) throw new UnauthorizedError('Credenciales inválidas');

  const token = signOrganizerToken({ usuarioId: usuario.id, email: usuario.email });
  return { token, usuario: { id: usuario.id, nombre: usuario.nombre, email: usuario.email } };
}
