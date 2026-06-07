# Simulación Dinámica de Reticulado Elástico — GNU Octave

Simulación numérica de la respuesta dinámica de una estructura plana compuesta por barras
elásticas conectadas en nodos articulados. El sistema parte del reposo, se le aplica una
carga constante, y se observa cómo oscila, se deforma y (opcionalmente) se amortigua.

## ¿Qué hace?

Dado un reticulado de 15 nodos y 26 barras (Caso 12 de la cátedra), el programa:

1. **Simula** la respuesta dinámica resolviendo ecuaciones de movimiento con `ode23`
2. **Compara** dos modelos de deformación:
   - *Grandes desplazamientos* — recalcula la dirección de cada barra en cada paso
   - *Pequeños desplazamientos* — mantiene las direcciones iniciales fijas
3. **Incorpora amortiguamiento** mediante una esfera sumergida en un fluido, calculando
   la fuerza de arrastre según el nivel de inmersión
4. **Genera animaciones** GIF de la estructura deformándose en el tiempo
5. **Grafica** tensiones en barras, desplazamientos de nodos, y detecta inversión de
   triángulos (indicador de colapso estructural)

## Aspectos técnicos

- Integración numérica con `ode23` (Runge-Kutta de orden 2/3)
- Modelo de barras como resortes: F = k · Δl, con k = E·A/L₀
- Masa concentrada en los nodos
- Criterio de parada: detección de inversión del signo del área de triángulos
- Fuerza de arrastre: F_drag = ½ · ρ · C_d · A_R · |v| · v

## Tecnologías

| Componente | Detalle |
|---|---|
| Lenguaje | GNU Octave |
| Integración numérica | `ode23` con tolerancias configurables |
| Visualización | Gráficas 2D, animaciones GIF |
| Dominio | Mecánica del Continuo, análisis estructural |

## Estructura del proyecto

- `main_TP1.m` — Carga la geometría, propiedades y parámetros del Caso 12
- `inciso_a_b.m` — Simulación con modelos finito y de pequeños desplazamientos
- `inciso_c.m` — Simulación con amortiguamiento por esfera sumergida
- `inciso_d.m` — Generación de animaciones GIF
- `f_calcular_aceleraciones.m` — Cálculo de fuerzas internas, externas y de arrastre
- `f_ode_reticulado.m` — Función ODE para el integrador
- `f_simular.m` — Orquestador de la simulación

## Autores

Hugo J. Albarenque

*Ingeniería en Informática - FICH, UNL*
