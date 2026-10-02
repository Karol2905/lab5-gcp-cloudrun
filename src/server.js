'use strict';

const app = require('./app');

/**
 * EL DETALLE MAS IMPORTANTE DEL LABORATORIO.
 *
 * App Service no deja escoger el puerto: arranca el contenedor, le inyecta la
 * variable PORT y espera que el proceso escuche ahi. Si el codigo fija 3000 a
 * la fuerza, el sitio responde "Application Error" aunque el despliegue haya
 * terminado sin un solo mensaje de error.
 *
 * En la maquina virtual PORT no existe, asi que cae en 3000 y todo funciona
 * igual. Un solo codigo, dos entornos.
 */
const PUERTO = process.env.PORT || 3000;

const servidor = app.listen(PUERTO, () => {
  console.log(`Portal de notas escuchando en el puerto ${PUERTO}`);
});

// App Service envia SIGTERM antes de reciclar el contenedor. Cerrar bien evita
// cortar peticiones a mitad de camino durante un despliegue.
process.on('SIGTERM', () => {
  console.log('SIGTERM recibido: cerrando el servidor');
  servidor.close(() => process.exit(0));
});

module.exports = servidor;
