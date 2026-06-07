%  (c): amortiguamiento con esfera sumergia 
%  ATENCION: hay q ejecutar primero main_TP1.m y luego inciso_a_b.m

%  nos pide modificar el modelo de a.i agregando en el nodo c una esfera de radio r_esf q esta sometida a fuerza de arrastre 
%     F_a = -(1/2) * rho_fl * C_d * A_R * |v_cy| * v_cy
%  donde AR depende del nivel de inmersion 
%  debemos de compararlo con el caso sin amort y ver la influencia del radio de la esfera y la densidad del fluido 
%  la integracion se realiza con ode23 

fprintf('\n====== INCISO (c) — AMORTIGUAMIENTO ======\n\n');

%  simulacion con amortiguamiento seria el caso base
% armamos la estructura
params_drag = struct();
params_drag.nodo_c = nodo_c;
params_drag.r_esf  = r_esf;
params_drag.rho_fl = rho_fl;
params_drag.C_d    = C_d;
params_drag.h_SL   = h_SL;

fprintf('Parámetros del amortiguador:\n');
fprintf('  Nodo c:     %d\n', nodo_c);
fprintf('  r_esf:      %.2f\n', r_esf);
fprintf('  rho_fl:     %.1f\n', rho_fl);
fprintf('  C_d:        %.2f\n', C_d);
fprintf('  h_SL:       %.1f\n', h_SL);
fprintf('\n');

% simulacion con arrastre (modelo deformaciones finitas) 
fprintf('--- Simulacion con amortiguamiento ---\n');
[t_drag, pos_hist_drag, ~, tension_a_drag, coord_b_drag,norma_u_max_drag, tF_drag] = ...
    f_simular(m_Nodos0, m_Barras, v_L0, v_k, v_masas, v_libres, v_apoyos, m_Fext, 'finito', m_dir0, t_F_Max, RelTol, AbsTol, ...
              m_Triangulos, v_areas0, ind_barra_a, nodo_b, A, params_drag);


%  hacemos la comparacion entre con y sin amortiguamiento para ello usamos los resultados del inciso a.i ya calculados en inciso_a_b

% para comaparar de manera eficiente, graficamos ambos casos hasta el t en que ocurre el primer cruce de barras entre 
%cualquiera de los dos modelos 
tF_comp = min(tF_fi, tF_drag);    % t de corte (el menor de ambos)

% hacemos indices t o f para recortar los vectores de tiempo y graficar solo hasta tF_comp
idx_fi_c   = t_fi <= tF_comp;
idx_drag_c = t_drag <= tF_comp;

fprintf('=== Comparación con vs sin amortiguamiento ===\n');
fprintf('  t_F sin amortiguamiento:  %.4f s\n', tF_fi);
fprintf('  t_F con amortiguamiento:  %.4f s\n', tF_drag);
fprintf('\n');

%agregar estas graficas al informe
% primer grafica: tension en barra a 
figure('Name', 'Inciso c - Tensión Barra a', 'Position', [100 100 800 400]);
plot(t_fi(idx_fi_c), tension_a_fi(idx_fi_c), 'b-', 'LineWidth', 1.2); hold on;
plot(t_drag(idx_drag_c), tension_a_drag(idx_drag_c), 'r--', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('\sigma');
title(sprintf('Tensión normal barra a — Con vs Sin Amortiguamiento\n(Barra %d)', ind_barra_a));
legend('Sin amortiguamiento', 'Con amortiguamiento', 'Location', 'NorthEast');
grid on; hold off;

% grafica 2
figure('Name', 'Inciso c - Coord. Nodo b', 'Position', [100 550 800 400]);
plot(t_fi(idx_fi_c), coord_b_fi(idx_fi_c,2), 'b-', 'LineWidth', 1.2); hold on;
plot(t_drag(idx_drag_c), coord_b_drag(idx_drag_c,2), 'r--', 'LineWidth', 1.2);
xlabel('Tiempo [s]'); ylabel('y');
title(sprintf('Coordenada y del nodo %d — Con vs Sin Amortiguamiento', nodo_b));
legend('Sin amortiguamiento', 'Con amortiguamiento', 'Location', 'NorthEast');
grid on; hold off;

% grafica 3: norma maxima de desplazamiento 
figure('Name', 'Inciso c - Norma Desplaz.', 'Position', [600 100 800 400]);
plot(t_fi(idx_fi_c), norma_u_max_fi(idx_fi_c), 'b-', 'LineWidth', 1.5); hold on;
plot(t_drag(idx_drag_c), norma_u_max_drag(idx_drag_c), 'r--', 'LineWidth', 1.5);
xlabel('Tiempo [s]'); ylabel('||u||_{max}');
title('Norma máxima desplazamiento — Con vs Sin Amortiguamiento');
legend('Sin amortiguamiento', 'Con amortiguamiento', 'Location', 'NorthEast');
grid on; hold off;


%  ahora variamos el radio de la esfera y la densidad del fluido 

fprintf('\n--- Variacion parametrica ---\n\n');

% valores del radio q vamos a usar
v_r_esf = [0.5, 1, 2, 4];

% valores de densidad que vamos a usar
v_rho_fl = [1, 5, 15, 50];

% variamos radio y dejamos densidad fija
figure('Name', 'Inciso c - Variación r_esf', 'Position', [100 100 800 500]);
hold on;
colores = ['b', 'r', 'g', 'm'];
leyenda = {};

for i = 1:length(v_r_esf)
    p_drag = struct();
    p_drag.nodo_c = nodo_c;
    p_drag.r_esf  = v_r_esf(i);
    p_drag.rho_fl = rho_fl;      % fijo
    p_drag.C_d    = C_d;
    p_drag.h_SL   = h_SL;

    fprintf('  Simulando r_esf = %.1f ...\n', v_r_esf(i));

    [t_var, ~, ~, ~, coord_b_var, ~, tF_var] = f_simular(m_Nodos0, m_Barras, v_L0, v_k, v_masas, v_libres, v_apoyos, ...
                  m_Fext, 'finito', m_dir0, t_F_Max, RelTol, AbsTol, ...
                  m_Triangulos, v_areas0, ind_barra_a, nodo_b, A, p_drag);
    plot(t_var, coord_b_var(:,2), [colores(i), '-'], 'LineWidth', 1.2);
    leyenda{end+1} = sprintf('r_{esf} = %.1f  (t_F = %.1f s)', v_r_esf(i), tF_var);
end

xlabel('Tiempo [s]'); ylabel('y del nodo b');
title(sprintf('Variación de r_{esf} (\\rho_{fl} = %.0f)', rho_fl));
legend(leyenda, 'Location', 'NorthEast');
grid on; hold off;

%  variamos la densidad del fluido y dejamos el radio fijo
figure('Name', 'Inciso c - Variación rho_fl', 'Position', [600 100 800 500]);
hold on;
leyenda = {};

for i = 1:length(v_rho_fl)
    p_drag = struct();
    p_drag.nodo_c = nodo_c;
    p_drag.r_esf  = r_esf;       % Fijo
    p_drag.rho_fl = v_rho_fl(i);
    p_drag.C_d    = C_d;
    p_drag.h_SL   = h_SL;

    fprintf('  Simulando rho_fl = %.0f ...\n', v_rho_fl(i));

    [t_var, ~, ~, ~, coord_b_var, ~, tF_var] = f_simular(m_Nodos0, m_Barras, v_L0, v_k, v_masas, v_libres, v_apoyos, ...
                  m_Fext, 'finito', m_dir0, t_F_Max, RelTol, AbsTol, ...
                  m_Triangulos, v_areas0, ind_barra_a, nodo_b, A, p_drag);

    plot(t_var, coord_b_var(:,2), [colores(i), '-'], 'LineWidth', 1.2);
    leyenda{end+1} = sprintf('\\rho_{fl} = %.0f  (t_F = %.1f s)', v_rho_fl(i), tF_var);
end

xlabel('Tiempo [s]'); ylabel('y del nodo b');
title(sprintf('Variacion de \\rho_{fl} (r_{esf} = %.1f)', r_esf));
legend(leyenda, 'Location', 'NorthEast');
grid on; hold off;

fprintf('\n=== Ejecutar ahora: inciso_d ===\n');
