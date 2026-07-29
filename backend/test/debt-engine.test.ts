import {
  computeNetBalances,
  simplifyDebts,
  splitEvenlyCents,
  toCents,
  fromCents,
} from '../src/modules/debts/debt-engine';

// HU-15 — NFR#4 exige exactitud financiera, así que estos tests cubren los casos
// donde un motor mal implementado pierde o inventa centavos.

describe('toCents / fromCents', () => {
  it('convierte sin errores de punto flotante', () => {
    expect(toCents(19.99)).toBe(1999);
    expect(toCents('0.1')).toBe(10);
    expect(toCents('0.2')).toBe(20);
    expect(toCents(4500)).toBe(450000);
    expect(toCents('-12.34')).toBe(-1234);
  });

  it('completa decimales faltantes', () => {
    expect(toCents('5')).toBe(500);
    expect(toCents('5.5')).toBe(550);
  });

  it('hace ida y vuelta sin perder precisión', () => {
    for (const value of ['0.01', '19.99', '1234.56', '-7.05']) {
      expect(fromCents(toCents(value))).toBe(value);
    }
  });
});

describe('splitEvenlyCents', () => {
  it('reparte en partes iguales cuando divide exacto', () => {
    expect(splitEvenlyCents(1000, 4)).toEqual([250, 250, 250, 250]);
  });

  it('no pierde centavos cuando no divide exacto', () => {
    const parts = splitEvenlyCents(1000, 3);
    expect(parts).toEqual([334, 333, 333]);
    expect(parts.reduce((a, b) => a + b, 0)).toBe(1000);
  });

  it('mantiene la suma exacta para cualquier combinación', () => {
    for (let total = 0; total <= 200; total++) {
      for (let n = 1; n <= 7; n++) {
        const parts = splitEvenlyCents(total, n);
        expect(parts.reduce((a, b) => a + b, 0)).toBe(total);
      }
    }
  });

  it('rechaza una cantidad inválida de participantes', () => {
    expect(() => splitEvenlyCents(100, 0)).toThrow();
  });
});

describe('computeNetBalances', () => {
  it('acumula aportes y deudas por participante', () => {
    const balances = computeNetBalances([
      { participanteId: 'a', aportadoCents: 10000, adeudadoCents: 5000 },
      { participanteId: 'b', aportadoCents: 0, adeudadoCents: 5000 },
    ]);

    expect(balances.get('a')).toBe(5000);
    expect(balances.get('b')).toBe(-5000);
  });

  it('suma varias entradas del mismo participante', () => {
    const balances = computeNetBalances([
      { participanteId: 'a', aportadoCents: 3000, adeudadoCents: 1000 },
      { participanteId: 'a', aportadoCents: 2000, adeudadoCents: 500 },
    ]);

    expect(balances.get('a')).toBe(3500);
  });
});

describe('simplifyDebts', () => {
  it('resuelve el caso de 2 participantes', () => {
    const debts = simplifyDebts([
      { participanteId: 'ana', aportadoCents: 10000, adeudadoCents: 5000 },
      { participanteId: 'beto', aportadoCents: 0, adeudadoCents: 5000 },
    ]);

    expect(debts).toEqual([
      { deudorParticipanteId: 'beto', acreedorParticipanteId: 'ana', montoCents: 5000 },
    ]);
  });

  it('resuelve el asado de 3: uno paga todo', () => {
    // Marcos pone $4500 de carne, se divide entre 3 → cada uno debe $1500.
    const parts = splitEvenlyCents(450000, 3);
    const debts = simplifyDebts([
      { participanteId: 'marcos', aportadoCents: 450000, adeudadoCents: parts[0] },
      { participanteId: 'sofia', aportadoCents: 0, adeudadoCents: parts[1] },
      { participanteId: 'juan', aportadoCents: 0, adeudadoCents: parts[2] },
    ]);

    expect(debts).toHaveLength(2);
    expect(debts.every((d) => d.acreedorParticipanteId === 'marcos')).toBe(true);
    expect(debts.reduce((acc, d) => acc + d.montoCents, 0)).toBe(450000 - parts[0]);
  });

  it('no genera deudas cuando todos están saldados', () => {
    const debts = simplifyDebts([
      { participanteId: 'a', aportadoCents: 5000, adeudadoCents: 5000 },
      { participanteId: 'b', aportadoCents: 3000, adeudadoCents: 3000 },
    ]);

    expect(debts).toEqual([]);
  });

  it('simplifica una cadena circular en una sola transferencia', () => {
    // a le debe a b, b le debe a c, c le debe a a — todo por el mismo monto.
    // Un ledger crudo mostraría 3 deudas; simplificado, no queda ninguna.
    const debts = simplifyDebts([
      { participanteId: 'a', aportadoCents: 1000, adeudadoCents: 1000 },
      { participanteId: 'b', aportadoCents: 1000, adeudadoCents: 1000 },
      { participanteId: 'c', aportadoCents: 1000, adeudadoCents: 1000 },
    ]);

    expect(debts).toEqual([]);
  });

  it('usa a lo sumo N-1 transacciones con 5 participantes', () => {
    const entries = [
      { participanteId: 'a', aportadoCents: 10000, adeudadoCents: 2000 },
      { participanteId: 'b', aportadoCents: 5000, adeudadoCents: 2000 },
      { participanteId: 'c', aportadoCents: 0, adeudadoCents: 4000 },
      { participanteId: 'd', aportadoCents: 0, adeudadoCents: 4000 },
      { participanteId: 'e', aportadoCents: 0, adeudadoCents: 3000 },
    ];

    const debts = simplifyDebts(entries);

    expect(debts.length).toBeLessThanOrEqual(entries.length - 1);
    // Nadie termina pagando o cobrando de más.
    const netByParticipant = new Map<string, number>();
    for (const d of debts) {
      netByParticipant.set(
        d.deudorParticipanteId,
        (netByParticipant.get(d.deudorParticipanteId) ?? 0) - d.montoCents,
      );
      netByParticipant.set(
        d.acreedorParticipanteId,
        (netByParticipant.get(d.acreedorParticipanteId) ?? 0) + d.montoCents,
      );
    }
    // Un acreedor recibe exactamente su balance positivo; un deudor paga el suyo.
    const expected = computeNetBalances(entries);
    for (const [participanteId, balance] of expected) {
      expect(netByParticipant.get(participanteId) ?? 0).toBe(balance);
    }
  });

  it('conserva cada centavo con montos que no dividen exacto', () => {
    const parts = splitEvenlyCents(10000, 3); // 3334 / 3333 / 3333
    const debts = simplifyDebts([
      { participanteId: 'a', aportadoCents: 10000, adeudadoCents: parts[0] },
      { participanteId: 'b', aportadoCents: 0, adeudadoCents: parts[1] },
      { participanteId: 'c', aportadoCents: 0, adeudadoCents: parts[2] },
    ]);

    expect(debts.reduce((acc, d) => acc + d.montoCents, 0)).toBe(6666);
  });

  it('es determinístico ante entradas equivalentes', () => {
    const entries = [
      { participanteId: 'a', aportadoCents: 6000, adeudadoCents: 2000 },
      { participanteId: 'b', aportadoCents: 0, adeudadoCents: 2000 },
      { participanteId: 'c', aportadoCents: 0, adeudadoCents: 2000 },
    ];

    expect(simplifyDebts(entries)).toEqual(simplifyDebts([...entries].reverse()));
  });

  it('falla ruidosamente si los gastos no cierran', () => {
    expect(() =>
      simplifyDebts([
        { participanteId: 'a', aportadoCents: 10000, adeudadoCents: 0 },
        { participanteId: 'b', aportadoCents: 0, adeudadoCents: 5000 },
      ]),
    ).toThrow(/no cierran/);
  });
});
