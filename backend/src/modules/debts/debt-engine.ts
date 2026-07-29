/**
 * HU-15 — Motor de simplificación de deudas (SCRUM-11).
 *
 * NFR#4 exige exactitud financiera. Por eso este módulo trabaja SIEMPRE en
 * enteros (centavos): nunca usa punto flotante para acumular montos, porque
 * 0.1 + 0.2 !== 0.3 en IEEE-754 y esos errores se acumulan en eventos con
 * muchos gastos.
 *
 * Estrategia (decisión: Duda #3, opción B — simplificación tipo Splitwise):
 *   1. Calcular el balance neto de cada participante: aportado - adeudado.
 *   2. Emparejar codiciosamente al mayor acreedor con el mayor deudor.
 * Esto produce a lo sumo N-1 transacciones para N participantes con saldo,
 * que es óptimo en el caso general y siempre mejor que el ledger crudo.
 */

export interface ParticipantAmountCents {
  participanteId: string;
  /** Lo que esta persona puso de su bolsillo, en centavos. */
  aportadoCents: number;
  /** Lo que a esta persona le corresponde pagar, en centavos. */
  adeudadoCents: number;
}

export interface SimplifiedDebt {
  deudorParticipanteId: string;
  acreedorParticipanteId: string;
  montoCents: number;
}

/** Balance neto por participante. Positivo = le deben; negativo = debe. */
export function computeNetBalances(
  entries: ParticipantAmountCents[],
): Map<string, number> {
  const balances = new Map<string, number>();

  for (const entry of entries) {
    const current = balances.get(entry.participanteId) ?? 0;
    balances.set(entry.participanteId, current + entry.aportadoCents - entry.adeudadoCents);
  }

  return balances;
}

/**
 * Reduce los balances netos al mínimo conjunto de transferencias.
 * Precondición: la suma de todos los balances debe ser 0 (lo que alguien puso,
 * otro lo debe). Si no lo es, los gastos están mal cargados y preferimos fallar
 * ruidosamente antes que generar deudas silenciosamente incorrectas.
 */
export function simplifyDebts(entries: ParticipantAmountCents[]): SimplifiedDebt[] {
  const balances = computeNetBalances(entries);

  const total = [...balances.values()].reduce((acc, v) => acc + v, 0);
  if (total !== 0) {
    throw new Error(
      `Los gastos no cierran: la suma de balances es ${total} centavos, debería ser 0. ` +
        'Revisar que el total aportado coincida con el total adeudado en cada gasto.',
    );
  }

  // Orden determinístico: por monto y, ante empate, por id. Sin esto el
  // resultado podría variar entre corridas y los tests serían inestables.
  const creditors = [...balances.entries()]
    .filter(([, amount]) => amount > 0)
    .map(([participanteId, amount]) => ({ participanteId, amount }))
    .sort((a, b) => b.amount - a.amount || a.participanteId.localeCompare(b.participanteId));

  const debtors = [...balances.entries()]
    .filter(([, amount]) => amount < 0)
    .map(([participanteId, amount]) => ({ participanteId, amount: -amount }))
    .sort((a, b) => b.amount - a.amount || a.participanteId.localeCompare(b.participanteId));

  const result: SimplifiedDebt[] = [];
  let i = 0;
  let j = 0;

  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    const amount = Math.min(debtor.amount, creditor.amount);

    if (amount > 0) {
      result.push({
        deudorParticipanteId: debtor.participanteId,
        acreedorParticipanteId: creditor.participanteId,
        montoCents: amount,
      });
    }

    debtor.amount -= amount;
    creditor.amount -= amount;

    if (debtor.amount === 0) i++;
    if (creditor.amount === 0) j++;
  }

  return result;
}

/**
 * Reparte un monto en partes iguales sin perder ni inventar centavos.
 * Los centavos de resto se asignan de a uno a los primeros participantes, así
 * la suma de las partes siempre es exactamente igual al total (NFR#4).
 */
export function splitEvenlyCents(totalCents: number, participantCount: number): number[] {
  if (participantCount <= 0) throw new Error('participantCount debe ser mayor a 0');

  const base = Math.trunc(totalCents / participantCount);
  const remainder = totalCents - base * participantCount;

  return Array.from({ length: participantCount }, (_, index) =>
    index < Math.abs(remainder) ? base + Math.sign(remainder) : base,
  );
}

export function toCents(amount: number | string): number {
  // Se pasa por string para evitar el redondeo binario de los float
  // (ej. 19.99 * 100 === 1998.9999999999998).
  const [intPart, decPart = ''] = String(amount).split('.');
  const decimals = (decPart + '00').slice(0, 2);
  const sign = intPart.trim().startsWith('-') ? -1 : 1;
  const absInt = Math.abs(Number(intPart));
  return sign * (absInt * 100 + Number(decimals));
}

export function fromCents(cents: number): string {
  const sign = cents < 0 ? '-' : '';
  const abs = Math.abs(cents);
  return `${sign}${Math.trunc(abs / 100)}.${String(abs % 100).padStart(2, '0')}`;
}
