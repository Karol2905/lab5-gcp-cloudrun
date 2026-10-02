'use strict';

/**
 * PRUEBAS UNITARIAS
 *
 * Prueban una funcion aislada: entra un dato, sale un dato. No hay servidor,
 * no hay red, no hay disco. Por eso corren en milisegundos y se pueden
 * ejecutar en cada guardado de archivo.
 *
 * Cada prueba sigue el patron Arrange-Act-Assert: se prepara el dato, se
 * ejecuta la funcion, se verifica el resultado.
 */

const {
  esNotaValida,
  promedio,
  aprobado,
  escalaLetra,
  construirReporte,
} = require('../src/lib/notas');

describe('esNotaValida', () => {
  test('acepta numeros dentro del rango 0 a 5', () => {
    expect(esNotaValida(0)).toBe(true);
    expect(esNotaValida(3.4)).toBe(true);
    expect(esNotaValida(5)).toBe(true);
  });

  test('rechaza valores fuera de rango, cadenas y NaN', () => {
    expect(esNotaValida(5.1)).toBe(false);
    expect(esNotaValida(-0.5)).toBe(false);
    expect(esNotaValida('4.0')).toBe(false);
    expect(esNotaValida(NaN)).toBe(false);
    expect(esNotaValida(undefined)).toBe(false);
  });
});

describe('promedio', () => {
  test('calcula el promedio y lo redondea a dos decimales', () => {
    expect(promedio([4, 5])).toBe(4.5);
    expect(promedio([3.1, 4.2, 2.8])).toBe(3.37);
    expect(promedio([5])).toBe(5);
  });

  test('falla con un mensaje claro cuando no hay notas', () => {
    expect(() => promedio([])).toThrow('Se requiere al menos una nota');
    expect(() => promedio(null)).toThrow('Se requiere al menos una nota');
  });

  test('falla cuando alguna nota es invalida', () => {
    expect(() => promedio([4, 9])).toThrow(/Nota invalida/);
  });
});

describe('aprobado', () => {
  // Las pruebas de frontera son las que de verdad valen: 2.99 y 3.0.
  test('3.0 aprueba y 2.99 no', () => {
    expect(aprobado(3)).toBe(true);
    expect(aprobado(2.99)).toBe(false);
  });
});

describe('escalaLetra', () => {
  test.each([
    [5, 'A'],
    [4.5, 'A'],
    [4.49, 'B'],
    [4, 'B'],
    [3.5, 'C'],
    [3, 'D'],
    [2.9, 'F'],
  ])('un promedio de %s corresponde a la letra %s', (valor, letra) => {
    expect(escalaLetra(valor)).toBe(letra);
  });
});

describe('construirReporte', () => {
  test('arma el reporte completo de un estudiante', () => {
    const reporte = construirReporte('  Ana Gomez ', [4.0, 4.6, 3.8]);
    expect(reporte).toEqual({
      nombre: 'Ana Gomez',
      notas: [4.0, 4.6, 3.8],
      promedio: 4.13,
      letra: 'B',
      aprobado: true,
    });
  });

  test('rechaza nombres demasiado cortos', () => {
    expect(() => construirReporte('Al', [4])).toThrow(/al menos 3 caracteres/);
  });
});
