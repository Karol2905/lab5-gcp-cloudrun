'use strict';

const path = require('path');
const express = require('express');
const { construirReporte } = require('./lib/notas');
const { version } = require('../package.json');

/**
 * Aqui se construye la aplicacion, pero NO se pone a escuchar.
 * app.listen() vive en src/server.js.
 *
 * Esta separacion es la que permite que supertest levante la aplicacion en
 * memoria, en un puerto efimero, sin chocar con el servidor de desarrollo ni
 * dejar procesos colgados al terminar las pruebas.
 */
const app = express();

app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

// Almacen en memoria. Se pierde en cada reinicio del proceso, y eso esta bien:
// el laboratorio trata sobre despliegue, no sobre persistencia. En App Service
// el contenedor se recicla, asi que cualquier estado real iria en una base de
// datos externa.
const estudiantes = [];
let siguienteId = 1;

const arranque = Date.now();

/**
 * Sonda de salud. La usan tres actores distintos:
 *  - usted, para verificar a mano despues de desplegar;
 *  - el paso de smoke test del pipeline de GitHub Actions;
 *  - App Service, si se configura Health check en el portal.
 * Por eso responde rapido y no consulta nada externo.
 */
app.get('/health', (_req, res) => {
  res.json({
    estado: 'ok',
    version,
    uptimeSegundos: Math.round((Date.now() - arranque) / 1000),
  });
});

/**
 * Identidad del proceso que esta respondiendo.
 * WEBSITE_SITE_NAME y WEBSITE_INSTANCE_ID los inyecta App Service; en la
 * maquina virtual salen como 'local', y esa diferencia es justamente la
 * evidencia de que la aplicacion esta corriendo en la nube.
 */
app.get('/api/version', (_req, res) => {
  res.json({
    version,
    node: process.version,
    entorno: process.env.NODE_ENV || 'development',
    sitio: process.env.WEBSITE_SITE_NAME || 'local',
    instancia: (process.env.WEBSITE_INSTANCE_ID || 'local').substring(0, 12),
    region: process.env.REGION_NAME || 'local',
  });
});

app.get('/api/estudiantes', (_req, res) => {
  res.json({ total: estudiantes.length, datos: estudiantes });
});

/**
 * Alta de un estudiante. La validacion vive en la capa de negocio: aqui solo
 * se traduce la excepcion a un codigo HTTP. Un error del cliente es 400, no 500.
 */
app.post('/api/estudiantes', (req, res) => {
  const { nombre, notas } = req.body || {};
  try {
    const reporte = construirReporte(nombre, notas);
    const registro = { id: siguienteId++, ...reporte };
    estudiantes.push(registro);
    res.status(201).json(registro);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.get('/api/estudiantes/:id', (req, res) => {
  const registro = estudiantes.find((e) => e.id === Number(req.params.id));
  if (!registro) {
    return res.status(404).json({ error: 'Estudiante no encontrado' });
  }
  res.json(registro);
});

// Cualquier ruta que no coincida con las anteriores.
app.use((_req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

module.exports = app;
