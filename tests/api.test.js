'use strict';

/**
 * PRUEBAS DE INTEGRACION
 *
 * Aqui si hay HTTP: supertest levanta la aplicacion en un puerto efimero,
 * dispara peticiones reales y verifica codigo de estado, cabeceras y cuerpo.
 * Lo que se prueba es el cableado: rutas, middlewares, serializacion JSON y la
 * traduccion de errores de negocio a codigos HTTP.
 *
 * Fijese que se importa src/app.js y no src/server.js: la aplicacion, no el
 * proceso que escucha. Si se importara el servidor, el puerto quedaria ocupado
 * y Jest no terminaria nunca.
 */

const request = require('supertest');
const app = require('../src/app');

describe('GET /health', () => {
  test('responde 200 con estado ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('ok');
    expect(typeof res.body.uptimeSegundos).toBe('number');
  });
});

describe('GET /api/version', () => {
  test('expone la version y la identidad del proceso', async () => {
    const res = await request(app).get('/api/version');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('version');
    expect(res.body).toHaveProperty('node');
    // Fuera de App Service estas variables no existen y caen en 'local'.
    expect(res.body.sitio).toBeDefined();
  });
});

describe('POST /api/estudiantes', () => {
  test('crea un estudiante y devuelve 201 con el reporte calculado', async () => {
    const res = await request(app)
      .post('/api/estudiantes')
      .send({ nombre: 'Carlos Ruiz', notas: [4.0, 3.5, 4.5] })
      .set('Content-Type', 'application/json');

    expect(res.status).toBe(201);
    expect(res.body.promedio).toBe(4);
    expect(res.body.letra).toBe('B');
    expect(res.body.aprobado).toBe(true);
    expect(res.body.id).toBeGreaterThan(0);
  });

  test('devuelve 400 cuando el cuerpo es invalido', async () => {
    const res = await request(app)
      .post('/api/estudiantes')
      .send({ nombre: 'Ok', notas: [] });

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/3 caracteres/);
  });

  test('devuelve 400 cuando una nota esta fuera de rango', async () => {
    const res = await request(app)
      .post('/api/estudiantes')
      .send({ nombre: 'Laura Diaz', notas: [4, 7] });

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/Nota invalida/);
  });
});

describe('GET /api/estudiantes/:id', () => {
  test('devuelve 404 cuando el estudiante no existe', async () => {
    const res = await request(app).get('/api/estudiantes/9999');
    expect(res.status).toBe(404);
  });
});

describe('rutas desconocidas', () => {
  test('devuelven 404 en JSON', async () => {
    const res = await request(app).get('/no-existe');
    expect(res.status).toBe(404);
    expect(res.body.error).toBe('Ruta no encontrada');
  });
});
