
%    1) ejecutar este script para cargar datos
%    2) luego ejecutar: inciso_a_b   (modelos a.i y a.ii + gráficas)
%    3) luego ejecutar: inciso_c     (amortiguamiento con esfera)
%    4) luego ejecutar: inciso_d     (animaciones .gif)

clear; close all; clc;
addpath('../Consigna e instrucciones');   % Para f_LectDxf.m y gif.m

fprintf('=== TP1 - Mecánica del Continuo — CASO 12 ===\n');

%  primero definimos la geometria de la estructura
%  se definen las coordenadas iniciales (posicion de referencia, t=0)
%  de todos los nodos del reticulado. A partir de estas posiciones
%  se mediran los desplazamientos durante la simulación.

% definimos coordenadas iniciales de los nodos [x, y] 
m_Nodos0 = [
     0,  0;    % Nodo 1  — apoyo izquierdo
    10,  0;    % Nodo 2
     5,  5;    % Nodo 3
    20,  0;    % Nodo 4
    15, 15;    % Nodo 5
    25, 15;    % Nodo 6
    20, 20;    % Nodo 7  — se aplica carga P
    30, 30;    % Nodo 8  — nodo c: esfera
    35, 15;    % Nodo 9
    40, 20;    % Nodo 10 — se aplica carga P
    45, 15;    % Nodo 11
    40,  0;    % Nodo 12
    50,  0;    % Nodo 13
    55,  5;    % Nodo 14
    60,  0;    % Nodo 15 — apoyo derecho
];

nNodos = size(m_Nodos0, 1);

% conectividad de las barras [Ni, Nj]
% el orden Ni→Nj.

m_Barras = [
     1,  2;    % barra 1
     1,  3;    % barra 2
     2,  4;    % barra 3
     4,  6;    % barra 4
     4,  5;    % barra 5  esta es la barra a
     5,  2;    % barra 6
     2,  3;    % barra 7
     5,  6;    % barra 8
     6,  7;    % barra 9
     3,  5;    % barra 10
     5,  7;    % barra 11
     7,  8;    % barra 12
    15, 13;    % barra 13
    15, 14;    % barra 14
    14, 11;    % barra 15
    11, 10;    % barra 16
    10,  8;    % barra 17
    13, 12;    % barra 18
    12,  9;    % barra 19
    12, 11;    % barra 20
    11, 13;    % barra 21
    13, 14;    % barra 22
    11,  9;    % barra 23
     9, 10;    % barra 24
     6,  8;    % barra 25
     9,  8;    % barra 26
];

nBarras = size(m_Barras, 1);

% apoyos articulados fijos (desplazamiento = 0)
v_apoyos = [1; 15];

% nodos donde se aplica la carga P (hacia abajo)
v_nodos_carga = [7; 10];

%  definimos las propiedades del material y cargas
%  se definen las constantes del material y la carga aplicada.
%  la rigidez de cada barra se calcula como k = E*A/L0 (ley de Hooke para un resorte elástico). La tension normal es sigma = F/A.

E   = 600;       % modulo de elasticidad longitudinal
A   = 0.25;      % area de sección transversal de las barras
rho = 1;         % densidad de barra
P   = 3.2;       % carga uniforme P(t) = cte

% nodos y barras de interes 
ind_barra_a = 5;    % barra "a" = barra 5 (conecta nodos 4 y 5)
nodo_b      = 4;    % nodo "b"  = nodo 4
nodo_c      = 8;    % nodo "c"  = nodo 8 (donde va la esfera)

% parametros de la simulacion, usando ode23 para integrar las ecuaciones de movimiento.
t_F_Max = 50;     % t max de simulacion  
RelTol  = 1e-4;   % tol rel. para ode23 
AbsTol  = 1e-6;   % tol abs para ode 23 

% parametros del amortiguador (es inciso c) 
r_esf   = 1.5;     % radio esfera amortiguadora
rho_fl  = 3.0;     % densidad del fluido
C_d     = 0.47;    % coef de arrastre  
h_SL    = 30.0;    % cota de la sup libre del fluido 

% procedemos a hacer los calculos
%  para las longitudes inciiales de las barras 
% calculamos el vector unitario (versor) de cada barra en la posicion de referencia. En el modelo de pequeños desplazamientos (a.ii),
% estas direcciones se mantienen fijas durante toda la simulacion (asumimos que la geometria cambia muy poco respecto a la referencia).

% para los vectores directores unitarios iniciales (a.ii)
% calculamos la longitud L0 de cada barra en la posicion de referencia.El alargamiento de cada barra se calcula como: 
%delta = L_actual - L0.
v_L0 = zeros(nBarras, 1);
for b = 1:nBarras
    ni = m_Barras(b, 1);
    nj = m_Barras(b, 2);
    dx = m_Nodos0(nj, :) - m_Nodos0(ni, :);
    v_L0(b) = sqrt(dx(1)^2 + dx(2)^2);
    m_dir0(b, :) = (m_Nodos0(nj, :) - m_Nodos0(ni, :)) / v_L0(b);
end

% rigidez de cada barra: k_ij = E * A / L0
% la fuerza interna en cada barra se calcula como |F| = k * delta, con k = E*A/L0.
v_k = E * A ./ v_L0;

% para la masa de cada nodo hacemos m_I = sum( (1/2) * rho * A * L0_IJ )  para cada barra conectada al nodo I
v_masas = zeros(nNodos, 1);
for b = 1:nBarras
    masa_barra = rho * A * v_L0(b);
    ni = m_Barras(b, 1);
    nj = m_Barras(b, 2);
    v_masas(ni) = v_masas(ni) + masa_barra / 2;
    v_masas(nj) = v_masas(nj) + masa_barra / 2;
end

% nodos libres, osea los q no son apyos 
v_libres = setdiff(1:nNodos, v_apoyos)';

% vector de fuerzas externas cte en el tiempo
m_Fext = zeros(nNodos, 2);
for i = 1:length(v_nodos_carga)
    m_Fext(v_nodos_carga(i), 2) = -P;   % fuerza hacia abajo x eso hacemos y negativo
end

% identificamos los triangulos para el criterio de paradada 

% construimos matriz de adyacencia
m_adj = zeros(nNodos, nNodos);
for b = 1:nBarras
    ni = m_Barras(b, 1);
    nj = m_Barras(b, 2);
    m_adj(ni, nj) = 1;
    m_adj(nj, ni) = 1;
end

% buscamos todos los triangulos para eso buscamos 3 nodos q esten conectados entre si
m_Triangulos = [];
for i = 1:nNodos
    for j = i+1:nNodos
        if m_adj(i, j)
            for k = j+1:nNodos
                if m_adj(i, k) && m_adj(j, k)
                    m_Triangulos = [m_Triangulos; i, j, k];
                end
            end
        end
    end
end
nTriangulos = size(m_Triangulos, 1);

% calculamos las areas con signo iniciales de cada triangulo 
% a esto lo hacemos para tener los signgos de las areas de referencia q necesitamos para q a la hora de calcular el area del triangulo
%cuando ejecutamos podamos comaprar los signos con el area de referencia y si este cambio entonces el triang se dio vuelta 
v_areas0 = zeros(nTriangulos, 1);
for t = 1:nTriangulos
    ni = m_Triangulos(t, 1);
    nj = m_Triangulos(t, 2);
    nk = m_Triangulos(t, 3);
    v_areas0(t) = 0.5 * ( (m_Nodos0(nj,1) - m_Nodos0(ni,1)) * (m_Nodos0(nk,2) - m_Nodos0(ni,2)) ...
                         - (m_Nodos0(nk,1) - m_Nodos0(ni,1)) * (m_Nodos0(nj,2) - m_Nodos0(ni,2)) );
end


% visualizamos la estructura de nuestro caso
figure('Name', 'Estructura Inicial - Caso 12', 'Position', [100 100 800 600]);
hold on;

for b = 1:nBarras
    ni = m_Barras(b, 1);  nj = m_Barras(b, 2);
    plot([m_Nodos0(ni,1), m_Nodos0(nj,1)], ...
         [m_Nodos0(ni,2), m_Nodos0(nj,2)], 'b-', 'LineWidth', 1.5);
end

plot(m_Nodos0(:,1), m_Nodos0(:,2), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

for i = 1:nNodos
    text(m_Nodos0(i,1) + 0.8, m_Nodos0(i,2) + 0.8, num2str(i), ...
         'FontSize', 10, 'FontWeight', 'bold');
end

plot(m_Nodos0(v_apoyos,1), m_Nodos0(v_apoyos,2), ...
     'g^', 'MarkerSize', 14, 'MarkerFaceColor', 'g');

for i = 1:length(v_nodos_carga)
    nc = v_nodos_carga(i);
    quiver(m_Nodos0(nc,1), m_Nodos0(nc,2) + 4, 0, -3, 'r', ...
           'LineWidth', 2, 'MaxHeadSize', 0.8);
    text(m_Nodos0(nc,1) + 0.5, m_Nodos0(nc,2) + 5, 'P', ...
         'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');
end

% hacemos la linea de sup libre para tenerla de referencia 
plot([-5, 65], [h_SL, h_SL], 'c--', 'LineWidth', 1);
text(62, h_SL + 1, 'h_{SL}', 'Color', 'c', 'FontSize', 10);

axis equal; grid on;
title('Estructura Inicial — Caso 12', 'FontSize', 14);
xlabel('x'); ylabel('y');
hold off;

%  printeamos los datos
fprintf('--- Estructura ---\n');
fprintf('  Nodos:      %d\n', nNodos);
fprintf('  Barras:     %d\n', nBarras);
fprintf('  Triángulos: %d\n', nTriangulos);
fprintf('  Apoyos:     nodos %s\n', mat2str(v_apoyos'));
fprintf('  Cargas P:   nodos %s (P = %.1f)\n', mat2str(v_nodos_carga'), P);
fprintf('  Barra a:    %d (nodos %d-%d)\n', ind_barra_a, m_Barras(ind_barra_a,1), m_Barras(ind_barra_a,2));
fprintf('  Nodo b:     %d\n', nodo_b);
fprintf('  Nodo c:     %d\n', nodo_c);
fprintf('\n--- Propiedades ---\n');
fprintf('  E   = %.0f\n', E);
fprintf('  A   = %.2f\n', A);
fprintf('  rho = %.0f\n', rho);
fprintf('\n--- Amortiguador ---\n');
fprintf('  r_esf  = %.1f\n', r_esf);
fprintf('  rho_fl = %.1f\n', rho_fl);
fprintf('  h_SL   = %.1f\n', h_SL);
fprintf('  RelTol: %.0e\n', RelTol);
fprintf('  AbsTol: %.0e\n', AbsTol);
fprintf('\n=== Datos cargados. Ejecutar ahora: inciso_a_b ===\n');

