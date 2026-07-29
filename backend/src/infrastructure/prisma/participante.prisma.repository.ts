import { PrismaClient } from '@prisma/client';
import { AsistenciaEstado, Participante } from '../../domain/entities';
import {
  CrearParticipanteAnonimoData,
  ParticipanteRepository,
} from '../../domain/repositories';
import { toParticipante } from './mappers';

export class PrismaParticipanteRepository implements ParticipanteRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Participante | null> {
    const row = await this.prisma.participante.findUnique({ where: { id } });
    return row ? toParticipante(row) : null;
  }

  async findByTokenSesion(token: string): Promise<Participante | null> {
    const row = await this.prisma.participante.findUnique({ where: { tokenSesion: token } });
    return row ? toParticipante(row) : null;
  }

  async findByEventoAndUsuario(
    eventoId: string,
    usuarioId: string,
  ): Promise<Participante | null> {
    const row = await this.prisma.participante.findFirst({ where: { eventoId, usuarioId } });
    return row ? toParticipante(row) : null;
  }

  async findOrganizador(eventoId: string): Promise<Participante | null> {
    const row = await this.prisma.participante.findFirst({
      where: { eventoId, esOrganizador: true },
    });
    return row ? toParticipante(row) : null;
  }

  async listByEvento(eventoId: string): Promise<Participante[]> {
    const rows = await this.prisma.participante.findMany({ where: { eventoId } });
    return rows.map(toParticipante);
  }

  async listByUsuario(usuarioId: string): Promise<Participante[]> {
    const rows = await this.prisma.participante.findMany({ where: { usuarioId } });
    return rows.map(toParticipante);
  }

  async createAnonimo(data: CrearParticipanteAnonimoData): Promise<Participante> {
    const row = await this.prisma.participante.create({
      data: {
        eventoId: data.eventoId,
        nombreDisplay: data.nombreDisplay,
        esAnonimo: true,
        tokenSesion: data.tokenSesion,
      },
    });
    return toParticipante(row);
  }

  async updateAsistencia(id: string, estado: AsistenciaEstado): Promise<Participante> {
    const row = await this.prisma.participante.update({
      where: { id },
      data: { estadoAsistencia: estado },
    });
    return toParticipante(row);
  }

  async marcarLeido(id: string, cuando: Date): Promise<Participante> {
    const row = await this.prisma.participante.update({
      where: { id },
      data: { ultimaLecturaAt: cuando },
    });
    return toParticipante(row);
  }

  async invalidarSesionesAnonimas(eventoId: string): Promise<void> {
    await this.prisma.participante.updateMany({
      where: { eventoId, esAnonimo: true },
      data: { tokenSesion: null },
    });
  }
}
