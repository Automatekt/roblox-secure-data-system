# Código de terceros

## ProfileStore

- Qué es: librería para guardar datos de jugadores con bloqueo de sesión (un jugador no puede estar cargado en dos servidores a la vez) y guardado automático.
- Autor: MAD STUDIO (loleris)
- Fuente: https://github.com/MadStudioRoblox/ProfileStore (archivo `ProfileStore.luau`, versión 1.0.3)
- Licencia: Apache 2.0 (permite uso comercial). Copia completa en `licenses/ProfileStore-LICENSE.txt`.
- Ubicación: `src/server/Packages/ProfileStore.luau` (solo servidor).
- Revisión: leído completo el 2026-11-03. Solo usa servicios oficiales (DataStoreService, MessagingService, HttpService para generar identificadores, RunService). Sin `loadstring`, sin `require` externos y sin llamadas HTTP a internet.
- Regla: el archivo no se edita. Para actualizarlo, descargar la versión nueva y repetir la revisión.
