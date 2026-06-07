%  INCISO a y b: simulacion con ambos modelos y graficas.
fprintf('\n====== INCISO (a) y (b) ======\n\n');

% a.i modelo de deformacones finitas
% las direcciones de las fuerzas internas las recalculo en cada paso
% usando las posiciones actuales de los nodos Esto permite capturar los cambios de orientacion 
%de las barras.

fprintf('--- Inciso (a.i): Deformaciones Finitas ---\n');

params_drag_off = [];  % sin amortiguamiento para los incisos a y b

[t_fi, pos_hist_fi, vel_hist_fi, tension_a_fi, coord_b_fi, norma_u_max_fi, tF_fi] = f_simular(...
m_Nodos0, m_Barras, v_L0, v_k, v_masas, v_libres, v_apoyos,m_Fext, 'finito', m_dir0, t_F_Max, RelTol,...
 AbsTol, m_Triangulos, v_areas0, ind_barra_a, nodo_b, A, params_drag_off);


%  a.ii modelo de pequeños desplazamientos
%  las direcciones de las fuerzas internas se mantienen fijas en la
%  posicion inicial durante toda la simulacion. Asumimos 
%  que los desplazamientos son pequeños respecto a las dimensiones
%  de la estructura.

fprintf('--- Inciso (a.ii): Pequeños Desplazamientos ---\n');

[t_pd, pos_hist_pd, vel_hist_pd, tension_a_pd, coord_b_pd, norma_u_max_pd, tF_pd] = f_simular(...
m_Nodos0, m_Barras, v_L0, v_k, v_masas, v_libres, v_apoyos, m_Fext, 'pequeno', m_dir0, t_F_Max,...
RelTol, AbsTol, m_Triangulos, v_areas0, ind_barra_a, nodo_b, A, params_drag_off);

%  b.i primer instante de cruce de barras

fprintf('=== Resultados del inciso (b.i) ===\n');
fprintf('  t_F (deformaciones finitas):       %.4f s\n', tF_fi);
fprintf('  t_F (pequeños desplazamientos):    %.4f s\n', tF_pd);
fprintf('\n');

%  b.ii graficas hasta t_f de cada modelo

% filtrar datos hasta t_F de cada modelo (descartamos datos post-cruce)
idx_fi_full = t_fi <= tF_fi; 
idx_pd_full = t_pd <= tF_pd;

% grafica 1: tension normal en barra "a"
%se calcula sigma = F/A, que es la tension puramente axial de la barra.
figure('Name', 'Inciso b.ii - Tensión Barra a', 'Position', [100 100 900 400]);

subplot(1, 2, 1);
plot(t_fi(idx_fi_full), tension_a_fi(idx_fi_full), 'b-', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('\sigma');
title(sprintf('Tensión normal barra a — Def. Finitas\n(Barra %d: nodos %d-%d)', ...
      ind_barra_a, m_Barras(ind_barra_a,1), m_Barras(ind_barra_a,2)));
grid on;

subplot(1, 2, 2);
plot(t_pd(idx_pd_full), tension_a_pd(idx_pd_full), 'r-', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('\sigma');
title(sprintf('Tensión normal barra a — Peq. Desplaz.\n(Barra %d: nodos %d-%d)', ...
      ind_barra_a, m_Barras(ind_barra_a,1), m_Barras(ind_barra_a,2)));
grid on;

%  grafica 2:
figure('Name', 'Inciso b.ii - Tensión Tangencial', 'Position', [100 550 600 350]);

tau = zeros(sum(idx_fi_full), 1);
plot(t_fi(idx_fi_full), tau, 'b-', 'LineWidth', 1.5);
xlabel('Tiempo [s]'); ylabel('\tau');
title('Tensión tangencial barra a — \tau = 0 siempre');
grid on;
ylim([-1 1]);

% agrego texto explicativo.
text(tF_fi*0.1, 0.5, ...
    {'\tau = 0 porque:', ...
     '- Barras articuladas (rótulas)', ...
     '- Sin peso propio distribuido', ...
     '- Cargas solo en nodos', ...
     '→ Solo hay fuerzas axiales'}, ...
    'FontSize', 9, 'BackgroundColor', 'w', 'EdgeColor', 'k');

% grafica 3: coordenadas actuales del nodo b
figure('Name', 'Inciso b.ii - Coordenadas Nodo b', 'Position', [600 100 900 600]);

subplot(2, 2, 1);
plot(t_fi(idx_fi_full), coord_b_fi(idx_fi_full,1), 'b-', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('x');
title(sprintf('Coord. x del nodo %d — Def. Finitas', nodo_b));
grid on;

subplot(2, 2, 2);
plot(t_fi(idx_fi_full), coord_b_fi(idx_fi_full,2), 'b-', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('y');
title(sprintf('Coord. y del nodo %d — Def. Finitas', nodo_b));
grid on;

subplot(2, 2, 3);
plot(t_pd(idx_pd_full), coord_b_pd(idx_pd_full,1), 'r-', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('x');
title(sprintf('Coord. x del nodo %d — Peq. Desplaz.', nodo_b));
grid on;

subplot(2, 2, 4);
plot(t_pd(idx_pd_full), coord_b_pd(idx_pd_full,2), 'r-', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('y');
title(sprintf('Coord. y del nodo %d — Peq. Desplaz.', nodo_b));
grid on;

%  b.iii comparacion de norma maxima de desplazamiento
%  se compara cuanto se desplazaron los nodos en cada modelo, tomando
%  el intervalo común [0, min(t_F_a.i, t_F_a.ii)] para que la comparación sea justa

tF_comun = min(tF_fi, tF_pd);

% filtro datos hasta t_F_comun
idx_fi = t_fi <= tF_comun;
idx_pd = t_pd <= tF_comun;

figure('Name', 'Inciso b.iii - Comparación', 'Position', [100 100 800 500]);

plot(t_fi(idx_fi), norma_u_max_fi(idx_fi), 'b-', 'LineWidth', 1.5); hold on;
plot(t_pd(idx_pd), norma_u_max_pd(idx_pd), 'r--', 'LineWidth', 1.5);
xlabel('Tiempo [s]'); ylabel('||u||_{max}');
title('Norma máxima del desplazamiento — Comparación de modelos');
legend('Def. Finitas (a.i)', 'Peq. Desplaz. (a.ii)', 'Location', 'NorthWest');
grid on;
hold off;

% encontrar el máximo de cada modelo en el intervalo común
[max_u_fi, idx_max_fi] = max(norma_u_max_fi(idx_fi));
t_fi_filtrado = t_fi(idx_fi);
t_max_fi = t_fi_filtrado(idx_max_fi);

[max_u_pd, idx_max_pd] = max(norma_u_max_pd(idx_pd));
t_pd_filtrado = t_pd(idx_pd);
t_max_pd = t_pd_filtrado(idx_max_pd);

%printeo resultados 
fprintf('=== Resultados del inciso (b.iii) ===\n');
fprintf('  Intervalo de comparación: [0, %.4f] s\n', tF_comun);
fprintf('\n  Modelo Deformaciones Finitas (a.i):\n');
fprintf('    ||u||_max = %.4f  en t = %.4f s\n', max_u_fi, t_max_fi);
fprintf('\n  Modelo Pequeños Desplazamientos (a.ii):\n');
fprintf('    ||u||_max = %.4f  en t = %.4f s\n', max_u_pd, t_max_pd);

fprintf('\n=== Ejecutar ahora: inciso_c ===\n');
