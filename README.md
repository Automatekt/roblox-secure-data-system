# Sistema de guardado de datos seguro para Roblox (monedas e inventario)

Pieza de portafolio: guarda las monedas y el inventario de cada jugador sin perder datos, y los muestra en pantalla solo a su dueño. Usa ProfileStore (bloqueo de sesión y guardado automático).

**Cómo se hizo:** el código se desarrolló dirigiendo a Claude (IA) y se verificó con pruebas en Roblox Studio. No está escrito a mano.

## Qué hace

- Al entrar un jugador se cargan sus datos y quedan bloqueados para que ningún otro servidor los use a la vez.
- Al salir (o al cerrar el servidor) se guardan y se liberan.
- Si los datos no se pueden cargar, el jugador es expulsado con un mensaje claro. Nunca juega con datos vacíos que pisarían su guardado real.
- Las monedas y el inventario solo se cambian a través de funciones del servidor que validan todo.
- Cada jugador ve su propio panel con monedas e inventario. Los demás jugadores no pueden ver esos datos.
- Hay un cofre de demostración que da 100 monedas y, si cabe, una poción, con un cooldown de 5 segundos por jugador.

## Decisión de diseño: los datos solo los ve su dueño

El servidor copia los datos como atributos en el `PlayerGui` de cada jugador. Roblox solo envía el `PlayerGui` de un jugador a ese mismo jugador, así que nadie más puede ver sus monedas ni su inventario.

- No hay ningún `RemoteEvent` ni `RemoteFunction`: el cliente no tiene ningún canal para pedir cambios.
- Poner los atributos en el `Player` (la primera versión) mostraba los datos a todos los jugadores. Se cambió por esto.
- Lo que el cliente haga a esos atributos en su equipo no llega al servidor.

## Archivos y para qué sirve cada uno

**Servidor** (`src/server`)
- `init.server.luau`: punto de entrada, arranca todo en orden.
- `DataTemplate.luau`: los datos con los que empieza un jugador nuevo (0 monedas, inventario vacío). Si se añade un campo nuevo, los jugadores antiguos lo reciben sin perder nada.
- `DataService.luau`: carga y libera los datos de cada jugador, con bloqueo de sesión. Expulsa al jugador si no hay datos.
- `CurrencyService.luau`: sumar y gastar monedas. Rechaza negativos, texto, NaN, infinito y decimales, no deja gastar más de lo que hay y tiene un tope de 1.000.000.000.
- `InventoryService.luau`: añadir y quitar objetos. Solo acepta objetos del catálogo, cantidades válidas y respeta el máximo de cada objeto.
- `Validation.luau`: la comprobación de cantidades que usan las monedas y el inventario.
- `DataReplicator.luau`: copia los datos al `PlayerGui` del dueño para que su pantalla los muestre.
- `DemoRewardService.luau`: el cofre de demostración, con cooldown validado en el servidor. Si el saldo está al tope no da nada; si la poción está al máximo, da solo las monedas.
- `Packages/ProfileStore.luau`: librería de terceros (ver Licencias).
- `ColorPartService.luau`: una Part que cambia de color al tocarla. Es una prueba aparte de una etapa anterior y no forma parte del sistema de datos.

**Compartido** (`src/shared`)
- `ItemCatalog.luau`: la lista de objetos que existen (Espada, Poción de vida, Gema, Llave) con su máximo. Está congelada para que nadie la cambie por accidente.
- `DataAttributes.luau`: los nombres de los atributos con los que el servidor y la pantalla se entienden.
- `ColorPartConfig.luau`: ajustes de la prueba de la Part de colores.

**Cliente** (`src/client`)
- `init.client.luau`: punto de entrada del cliente.
- `HudController.luau`: dibuja el panel de monedas e inventario. Solo lee, no tiene botones.

## Cómo instalarlo y probarlo

1. Instala [Rokit](https://github.com/rojo-rbx/rokit) y, dentro de esta carpeta, ejecuta `rokit install` (instala Rojo 7.7.1).
2. En esta carpeta ejecuta `rojo serve` y déjalo abierto.
3. En Roblox Studio abre un lugar Baseplate, ve a Plugins > Rojo y pulsa **Connect**. (Si el botón dice Disconnect, ya está conectado.)
4. Pulsa **Play**. Arriba a la izquierda verás el panel con `Monedas: 0` e `Inventario: Vacío`.
5. Camina hasta el cofre marrón, mantén pulsado el botón que aparece y recibirás 100 monedas y una poción de vida. Si lo repites antes de 5 segundos no pasa nada.
6. Para probar con 2 jugadores: pestaña Prueba, Clientes y servidores, Jugadores: 2, Iniciar. Cada jugador debe ver solo sus datos.
7. Para probar en celular: pestaña Prueba, emulador de dispositivos, elige un celular.

Para usar el sistema desde otro script del servidor (por ejemplo una tienda):

```lua
local result = CurrencyService.spendCoins(player, 50) -- "Ok", "NotEnoughCoins", "InvalidAmount", "NoData"
if result == "Ok" then
	InventoryService.addItem(player, "Sword", 1)
end
```

## Qué está probado y qué no

**Probado** (en Roblox Studio, con el guardado de prueba):
- Cargar y liberar datos al entrar y salir.
- Monedas: sumar, gastar, valores inválidos (negativos, texto, NaN, infinito, decimales, nil), gastar de más y el tope.
- Inventario: añadir y quitar, objetos inventados, ids raros, cantidades inválidas, máximos por objeto.
- El panel con el saldo máximo y los 4 objetos, sin textos cortados.
- 2 jugadores: cada uno ve solo sus datos y ninguno puede ver los del otro. Probado también tras reaparecer.
- El cofre de demostración con el prompt real: cooldown y spam.
- Un cliente que se pone monedas en su propio equipo no cambia nada en el servidor.
- Emulador de celular (Samsung Galaxy S25 Ultra simulado): el panel no se superpone con el botón de salto.

**Sin probar todavía** (necesitan el lugar publicado y una cuenta con acceso a DataStore):
- Guardado real entre sesiones: los datos de prueba se borran al detener Studio.
- Expulsión por fallo de carga de datos.
- Choque entre dos servidores que quieren el mismo jugador.
- Tablet, consola y un celular real.

## Límites conocidos

Salieron de la revisión de seguridad (un revisor de solo lectura leyó todo el código y no encontró fallos críticos ni altos):

- **El cofre solo tiene cooldown, sin límite total.** Alguien que dispare el prompt sin parar podría sacar 100 monedas cada 5 segundos hasta el tope. Es una demo. En una tienda o misión real hay que añadir un límite por día o de un solo uso, guardado en los datos del jugador.
- **El cofre no avisa al jugador** si recibió la recompensa, si está en cooldown o si el saldo está lleno.
- **Si algún día se quita un objeto del catálogo**, los jugadores que ya lo tengan lo conservan en su guardado sin poder verlo. Habría que hacer una migración usando `SchemaVersion`.
- **El panel se redibuja entero** en cada cambio. Con 4 objetos no importa; con cientos habría que actualizar solo la fila que cambió.

## Licencias

ProfileStore, de MAD STUDIO (loleris), se usa bajo licencia Apache 2.0. La copia completa está en `licenses/ProfileStore-LICENSE.txt` y el origen en `THIRD_PARTY.md`.
