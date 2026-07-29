import { Invitacion } from '../entities';

export interface InvitacionRepository {
  create(eventoId: string, tokenUnico: string): Promise<Invitacion>;
  findByToken(tokenUnico: string): Promise<Invitacion | null>;
}
