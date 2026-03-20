# OpenClaw — Instalación manual en contenedor Docker

**OpenClaw** es un asistente personal de IA (TypeScript/Node.js) que se conecta a WhatsApp, Telegram, Slack, Discord, y más. Corre un Gateway local que sirve como plano de control para sesiones, canales y herramientas.

- Repo: https://github.com/openclaw/openclaw
- Docs: https://docs.openclaw.ai
- Docker: https://docs.openclaw.ai/install/docker
- WebChat: https://docs.openclaw.ai/web/webchat
- Gateway config: https://docs.openclaw.ai/gateway/configuration

---

## Requisitos previos

### Docker
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) con **mínimo 6 GB de RAM** asignados
  - Docker Desktop → Settings → Resources → Memory → 6 GB → Apply & Restart
- Node 24 está incluido en la imagen Docker, no necesitas instalarlo en tu Mac

### Proveedor de IA (elige uno)
- **GitHub Copilot** (usado en esta guía): cuenta de GitHub con suscripción a Copilot activa. El onboarding hace el login OAuth automáticamente.
- **Anthropic**: API key (`sk-ant-...`) desde https://console.anthropic.com
- **OpenAI**: API key (`sk-...`) desde https://platform.openai.com

### Canal de mensajería (elige uno o más)
- **Telegram** (usado en esta guía):
  1. Crea un bot con [@BotFather](https://t.me/BotFather) → `/newbot` → copia el **bot token** (`123456:ABC-DEF...`)
  2. Ten a mano tu **Telegram user ID** — se obtiene enviando un DM al bot y leyéndolo en los logs (ver paso 3.5)
- **WhatsApp**: teléfono con WhatsApp activo para escanear el QR de vinculación
- **Discord**: bot token desde https://discord.com/developers
- **Slack**: bot token + app token desde https://api.slack.com

### Opcional
- **Google API key** (para web search con Gemini): https://aistudio.google.com/app/apikey

---

## 1. Construir la imagen y levantar el contenedor

```bash
cd /ruta/a/openclaw-manual

docker compose build
docker compose up -d
```

---

## 2. Conectarse al contenedor

```bash
docker compose exec openclaw bash
# — o bien —
docker exec -it openclaw-dev bash
```

---

## 3. Instalación manual de OpenClaw (dentro del contenedor)

### 3.1 Clonar el repositorio

```bash
cd /openclaw
git clone https://github.com/openclaw/openclaw.git source
cd source
```

### 3.2 Instalar dependencias

```bash
pnpm install
```

### 3.3 Compilar

```bash
pnpm build        # compila TypeScript → dist/
pnpm ui:build     # compila los assets del Control UI → dist/control-ui/
```

> `pnpm ui:build` debe ejecutarse **después** de `pnpm build`. Si el Control UI muestra
> *"assets not found"*, vuelve a correr `pnpm ui:build`.

### 3.4 Crear symlink global del binario

```bash
ln -sf /openclaw/source/openclaw.mjs /usr/local/bin/openclaw
```

Esto permite usar `openclaw` como comando directo en cualquier path dentro del contenedor.

### 3.5 Onboarding interactivo

```bash
openclaw onboard
```

El wizard guía paso a paso:
- Selección del modelo y proveedor (GitHub Copilot, Anthropic, OpenAI, etc.)
- Configuración de canales (Telegram, WhatsApp, Discord, etc.)
- Para obtener tu `from.id` de Telegram: abre los logs con `openclaw logs --follow` en otra terminal y envía un DM a tu bot; el ID aparecerá en los logs.

### 3.6 Levantar el Gateway

```bash
openclaw gateway --port 18789 --verbose
```

El Control UI queda disponible en: **http://localhost:18789**

---

## 4. Configuración de `~/.openclaw/openclaw.json`

Cambios necesarios respecto a la config generada por el onboarding para funcionar correctamente en Docker:

```json
"gateway": {
  "port": 18789,
  "mode": "local",
  "bind": "lan",
  "controlUi": {
    "dangerouslyAllowHostHeaderOriginFallback": true,
    "allowInsecureAuth": true
  },
  "auth": {
    "mode": "password",
    "password": "tu-password-aqui",
    "token": "token-generado-por-onboarding"
  }
}
```

| Clave | Valor | Motivo |
|-------|-------|--------|
| `bind` | `lan` | Expone el gateway en todas las interfaces (necesario para llegar desde el Mac al contenedor) |
| `dangerouslyAllowHostHeaderOriginFallback` | `true` | Permite acceso al Control UI sin configurar `allowedOrigins` explícitamente |
| `allowInsecureAuth` | `true` | Permite auth por password sobre HTTP (sin TLS) |
| `auth.mode` | `password` | La UI muestra un campo de contraseña; con `token` el Control UI mostraba "pairing required" |

---

## 5. Volúmenes compartidos con el Mac

| Ruta en el contenedor | Ruta en el Mac | Descripción |
|---|---|---|
| `/root/.openclaw/` | `~/.openclaw/` | Config, credenciales, sesiones |
| `/root/.openclaw/workspace/` | `~/.openclaw/workspace/` | Workspace del agente, skills |
| `/openclaw/` | volumen Docker `openclaw-source` | Código fuente (solo en Docker, persiste entre reinicios) |

Cualquier cambio en `~/.openclaw/openclaw.json` en el Mac se refleja inmediatamente en el contenedor.

---

## 6. Puertos

| Puerto | Uso |
|--------|-----|
| `18789` | Gateway WebSocket + Control UI |
| `18791` | Browser tool (Chromium interno, no accesible externamente) |

---

## Comandos útiles de Docker

```bash
# Levantar en background
docker compose up -d

# Conectarse al contenedor
docker compose exec openclaw bash

# Ver logs del contenedor
docker compose logs -f

# Parar el contenedor
docker compose stop

# Eliminar contenedor + red
docker compose down

# Eliminar también volúmenes (borra el código fuente)
docker compose down -v

# Reiniciar
docker compose restart
```

---

## Comandos de OpenClaw (dentro del contenedor)

```bash
# Ver versión
openclaw --version

# Onboarding interactivo
openclaw onboard

# Levantar el Gateway
openclaw gateway --port 18789 --verbose

# Ver logs en tiempo real
openclaw logs --follow

# Ver estado de salud
openclaw doctor

# Listar solicitudes de pairing pendientes (canales tipo Telegram)
openclaw pairing list

# Aprobar pairing de un canal
openclaw pairing approve <código>

# Actualizar a la última versión estable
openclaw update --channel stable
```

---

## Problemas encontrados y soluciones

### ❌ `c++: fatal error: Killed signal terminated program cc1plus`
**Causa:** Falta de RAM al compilar con múltiples jobs (era el repo equivocado, C++).
**Solución:** No aplica — el repo correcto es TypeScript/Node.js.

---

### ❌ `FATAL ERROR: Ineffective mark-compacts near heap limit — JavaScript heap out of memory`
**Causa:** Node.js se queda sin heap al correr `openclaw onboard` con la configuración por defecto de memoria.
**Solución:** Aumentar la RAM del contenedor a 6 GB en Docker Desktop y configurar `NODE_OPTIONS`:
```yaml
# docker-compose.yaml
environment:
  - NODE_OPTIONS=--max-old-space-size=4096
mem_limit: 6g
```

---

### ❌ `Gateway failed to start: non-loopback Control UI requires gateway.controlUi.allowedOrigins`
**Causa:** Al usar `--bind lan` (o `bind: "lan"` en config), el gateway exige que se definan orígenes permitidos para el Control UI.
**Solución:** Añadir en `~/.openclaw/openclaw.json`:
```json
"controlUi": {
  "dangerouslyAllowHostHeaderOriginFallback": true
}
```

---

### ❌ Control UI muestra `"Control UI assets not found"`
**Causa:** La UI no fue compilada o se perdió al recrear el contenedor (el volumen `openclaw-source` fue eliminado).
**Solución:**
```bash
cd /openclaw/source
pnpm ui:build
```

---

### ❌ Control UI muestra `"pairing required"` (alert rojo, sin campo de entrada)
**Causa:** El gateway con `auth.mode: "token"` no expone un formulario en la UI — muestra el alert de pairing sin input.
**Solución:** Cambiar a `auth.mode: "password"` en `~/.openclaw/openclaw.json` y añadir `allowInsecureAuth: true`:
```json
"auth": {
  "mode": "password",
  "password": "tu-password",
  "token": "token-original"
},
"controlUi": {
  "allowInsecureAuth": true
}
```

---

### ❌ El comando `openclaw` no se encuentra tras reiniciar el contenedor
**Causa:** El symlink en `/usr/local/bin/openclaw` se pierde al recrear el contenedor (no forma parte del volumen persistente).
**Solución:** Volver a crearlo:
```bash
ln -sf /openclaw/source/openclaw.mjs /usr/local/bin/openclaw
```
O automatizarlo en el `command` del `docker-compose.yaml`.

---

### ❌ `Invalid --bind (use "loopback", "lan", "tailnet", "auto", or "custom")`
**Causa:** El flag `--bind` no acepta IPs directas como `0.0.0.0`.
**Solución:** Usar `--bind lan` o configurar `bind: "lan"` en el JSON.

---

## Notas de seguridad

- Los flags `dangerouslyAllowHostHeaderOriginFallback` y `allowInsecureAuth` son **solo para uso local**. No expongas el gateway en redes públicas con esta configuración.
- El `botToken` de Telegram y las API keys en `openclaw.json` son credenciales reales — no las comitees al repositorio.
- Corre `openclaw security audit` periódicamente para detectar configuraciones riesgosas.
