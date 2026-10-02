# Laboratorio 5 — Azure App Service, IaC y CI/CD

Repositorio **plantilla** del laboratorio de Azure App Service del curso de Cloud Computing
y DevOps (PEMU 2026) — Escuela Colombiana de Ingeniería Julio Garavito.

Contiene una aplicación Node.js completa con pruebas, la infraestructura declarada con
Terraform y un pipeline de CI/CD en GitHub Actions que despliega en la capa gratuita **F1**
de App Service, **sin Service Principal** (usa el publish profile del sitio), para que
funcione con una suscripción Azure for Students.

---

## Cómo empezar (estudiantes)

1. Pulse **Use this template → Create a new repository** en esta página.
   Nombre sugerido: `lab5-app-service`. Visibilidad: **Private**.
   No haga fork: un fork queda atado a este repositorio y trae Actions deshabilitado.
2. Agregue a su profesor como colaborador en **Settings → Collaborators**.
3. Siga la guía del laboratorio (`Laboratorio_AppService_CICD.docx`), que entrega el profesor.

En la máquina de trabajo:

```bash
gh repo clone <su-usuario>/lab5-app-service
cd lab5-app-service
npm ci
npm test
npm start          # http://localhost:3000
```

> Personalice las **dos líneas marcadas con `► SU NOMBRE`** en `public/index.html`:
> es lo que identifica su entrega.

---

## La aplicación

Un portal de notas en Node.js 22 + Express 5. Registra estudiantes con sus calificaciones
en la escala colombiana (0.0 a 5.0), calcula el promedio, lo traduce a una escala de letras
y dice si aprobó. La página que sirve en `/` no es un «hola mundo»: explica la arquitectura,
el empaquetado y el pipeline, y muestra en vivo qué instancia de Azure respondió.

### Estructura

```
src/lib/notas.js          Lógica de negocio pura (sin HTTP) — pruebas unitarias
src/app.js                Aplicación Express — se exporta, NO escucha
src/server.js             El proceso — escucha en process.env.PORT
public/index.html         La página del portal y material de estudio
tests/notas.test.js       Pruebas unitarias (Jest)
tests/api.test.js         Pruebas de integración (Supertest)
scripts/empaquetar.sh     Construye deploy.zip con solo lo que se ejecuta
infra/                    Terraform: resource group, App Service Plan F1, Linux Web App
.github/workflows/        Pipeline: construir-y-probar → desplegar
```

### Comandos

| Comando | Qué hace |
|---|---|
| `npm ci` | Instala las versiones exactas de `package-lock.json` |
| `npm start` | Levanta el servidor en `http://localhost:3000` |
| `npm test` | Ejecuta las 22 pruebas unitarias y de integración |
| `npm run test:cov` | Las mismas, con reporte de cobertura |
| `bash scripts/empaquetar.sh` | Genera `deploy.zip` listo para App Service |

### Endpoints

| Método y ruta | Respuesta |
|---|---|
| `GET /` | La página del portal |
| `GET /health` | `{ estado, version, uptimeSegundos }` — sonda usada por el pipeline |
| `GET /api/version` | Versión, Node, sitio, instancia y región que respondieron |
| `GET /api/estudiantes` | Lista registrada en memoria |
| `POST /api/estudiantes` | `201` con el reporte, o `400` si los datos no son válidos |
| `GET /api/estudiantes/:id` | Un estudiante, o `404` |

---

## Despliegue

### 1. Infraestructura (desde su máquina, con `az login`)

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # complete subscription_id y usuario
terraform init
terraform plan
terraform apply
terraform output
```

Terraform crea el grupo de recursos, un App Service Plan **F1** y la Web App con Node 22,
`always_on = false`, `use_32_bit_worker = true` y la autenticación básica del endpoint SCM
habilitada (sin ella no hay publish profile).

### 2. Credenciales del pipeline

```bash
RG_TF=$(terraform output -raw grupo_recursos)
APP_TF=$(terraform output -raw nombre_app)

az webapp deployment list-publishing-profiles -g $RG_TF -n $APP_TF --xml \
  | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE

gh variable set AZURE_WEBAPP_NAME --body "$APP_TF"
```

| Tipo | Nombre | Contenido |
|---|---|---|
| Secret | `AZURE_WEBAPP_PUBLISH_PROFILE` | El XML completo del publish profile |
| Variable | `AZURE_WEBAPP_NAME` | El nombre de la Web App |

### 3. Aplicación

Automática en cada `push` a `main`. Un pull request se construye y se prueba, pero no
despliega.

---

## Limpieza

```bash
cd infra && terraform destroy
az group delete -n rg-vm-lab5-<usuario> --yes --no-wait   # la máquina de trabajo
```

Los recursos de Azure siguen consumiendo crédito aunque no se usen. Verifique con
`az group list -o table` que no queda nada del laboratorio.

---

## Notas de diseño

- **`process.env.PORT`**: App Service inyecta el puerto. Fijar `3000` a la fuerza es la causa
  número uno de «Application Error» con un despliegue en verde.
- **`app.js` separado de `server.js`**: permite que Supertest levante la aplicación en memoria
  sin abrir un puerto real en cada ejecución de las pruebas.
- **`SCM_DO_BUILD_DURING_DEPLOYMENT=false`**: se despliega el artefacto ya construido y
  probado, no el código fuente; Oryx no vuelve a instalar dependencias dentro del sitio.
- **Publish profile en vez de Service Principal**: una cuenta de estudiante no suele poder
  crear registros de aplicación en Entra ID. En un entorno corporativo la opción correcta es
  OIDC con credencial federada, sin secretos que rotar.

## Licencia

MIT — ver [LICENSE](LICENSE). Material docente; úselo y adáptelo libremente.
