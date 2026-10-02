'use strict';

/**
 * Logica de negocio del portal de notas.
 *
 * Este modulo no sabe nada de HTTP, de Express ni de Azure: recibe datos y
 * devuelve datos. Esa separacion es deliberada y es lo que hace posible
 * probarlo con pruebas unitarias rapidas, sin levantar un servidor.
 *
 * Escala colombiana: las notas van de 0.0 a 5.0 y se aprueba con 3.0.
 */

const NOTA_MINIMA = 0;
const NOTA_MAXIMA = 5;
const NOTA_APROBATORIA = 3;

/**
 * Una nota valida es un numero (no NaN) dentro del rango [0, 5].
 * Se rechazan cadenas a proposito: "4.5" no es un numero, y aceptarlo
 * escondería errores de quien consume la API.
 */
function esNotaValida(valor) {
  return typeof valor === 'number' && Number.isFinite(valor) &&
    valor >= NOTA_MINIMA && valor <= NOTA_MAXIMA;
}

/**
 * Promedio aritmetico redondeado a dos decimales.
 * Lanza un error si el arreglo esta vacio o si alguna nota es invalida:
 * es preferible fallar con un mensaje claro que devolver NaN silenciosamente.
 */
function promedio(notas) {
  if (!Array.isArray(notas) || notas.length === 0) {
    throw new Error('Se requiere al menos una nota');
  }
  const invalida = notas.find((n) => !esNotaValida(n));
  if (invalida !== undefined) {
    throw new Error(`Nota invalida: ${invalida}. Debe ser un numero entre 0 y 5`);
  }
  const suma = notas.reduce((acc, n) => acc + n, 0);
  return Math.round((suma / notas.length) * 100) / 100;
}

/** Un promedio aprueba a partir de 3.0 inclusive. */
function aprobado(valor) {
  return esNotaValida(valor) && valor >= NOTA_APROBATORIA;
}

/**
 * Traduce un promedio a la escala de letras que usa el reporte.
 * El orden de las comparaciones importa: se evalua de mayor a menor.
 */
function escalaLetra(valor) {
  if (!esNotaValida(valor)) {
    throw new Error('El promedio debe ser un numero entre 0 y 5');
  }
  if (valor >= 4.5) return 'A';
  if (valor >= 4.0) return 'B';
  if (valor >= 3.5) return 'C';
  if (valor >= 3.0) return 'D';
  return 'F';
}

/**
 * Arma el reporte completo de un estudiante a partir de su nombre y sus notas.
 * Es la funcion que usa la capa HTTP: una sola llamada, un solo objeto.
 */
function construirReporte(nombre, notas) {
  if (typeof nombre !== 'string' || nombre.trim().length < 3) {
    throw new Error('El nombre debe tener al menos 3 caracteres');
  }
  const prom = promedio(notas);
  return {
    nombre: nombre.trim(),
    notas,
    promedio: prom,
    letra: escalaLetra(prom),
    aprobado: aprobado(prom),
  };
}

module.exports = {
  NOTA_MINIMA,
  NOTA_MAXIMA,
  NOTA_APROBATORIA,
  esNotaValida,
  promedio,
  aprobado,
  escalaLetra,
  construirReporte,
};
