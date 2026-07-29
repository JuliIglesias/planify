import { PrismaClient } from '@prisma/client';
import { Invitacion } from '../../domain/entities';
import { InvitacionRepository } from '../../domain/repositories';

export class PrismaInvitacionRepository implements InvitacionRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(eventoId: string, tokenUnico: string): Promise<Invitacion> {
    return this.prisma.invitacion.create({ data: { eventoId, tokenUnico } });
  }

  async findByToken(tokenUnico: string): Promise<Invitacion | null> {
    return this.prisma.invitacion.findUnique({ where: { tokenUnico } });
  }
}
