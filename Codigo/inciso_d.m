%  Inciso d: ANIMACIONES DEL RETICULADO
%  notas para el profe: ejecutar primero main_TP1.m, inciso_a_b.m e inciso_c.m
%
%  genera dos archivos .gif:
%    1 Caso a.i SIN amortiguamiento
%    2 Caso a.i CON amortiguamiento (del inciso c)
%
%  usamos la función gif.m provista por la cátedra.

fprintf('\n====== INCISO (d) — ANIMACIONES ======\n\n');

% intervalo de tiempo de simulación entre frames del gif
dt_frame = 1.0;   % [s] — cada frame avanza 1 segundo de tiempo simulado

%  animacion 1: SIN AMORTIGUAMIENTO (modelo a.i)

fprintf('Generando animación SIN amortiguamiento...\n');

% se selecciona indices donde t avanza ~dt_frame entre frames (solo hasta tF_fi)
indices_frame_fi = [1];
t_last = t_fi(1);
for k = 2:length(t_fi)
    if t_fi(k) > tF_fi
        break;
    end
    if t_fi(k) - t_last >= dt_frame
        indices_frame_fi(end+1) = k;
        t_last = t_fi(k);
    end
end

fig1 = figure('Name', 'Animación sin amortiguamiento', 'Position', [100 100 800 600]);

% calcular límites del gráfico
x_min = min(m_Nodos0(:,1)) - 5;
x_max = max(m_Nodos0(:,1)) + 5;
y_min = min(m_Nodos0(:,2)) - 15;
y_max = max(m_Nodos0(:,2)) + 15;

% primer frame
pos_frame = pos_hist_fi{1};
hold on;
for b = 1:nBarras
    ni = m_Barras(b,1); nj = m_Barras(b,2);
    h_barras(b) = plot([pos_frame(ni,1), pos_frame(nj,1)], ...
                       [pos_frame(ni,2), pos_frame(nj,2)], 'b-', 'LineWidth', 2);
end
h_nodos = plot(pos_frame(:,1), pos_frame(:,2), 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
h_titulo = title(sprintf('t = %.3f s  (Sin amortiguamiento)', t_fi(1)));
axis equal; grid on;
xlim([x_min x_max]); ylim([y_min y_max]);
xlabel('x [m]'); ylabel('y [m]');
hold off;

% inicio gif
s_NomArch = 'animacion_sin_amort';
gif([s_NomArch, '.gif'], 'overwrite', true, 'frame', gcf, ...
    'LoopCount', 0, 'DelayTime', 1/10);

% frames siguientes
for idx = indices_frame_fi(2:end)
    pos_frame = pos_hist_fi{idx};

    % actualizo barras
    for b = 1:nBarras
        ni = m_Barras(b,1); nj = m_Barras(b,2);
        set(h_barras(b), 'XData', [pos_frame(ni,1), pos_frame(nj,1)], ...
                         'YData', [pos_frame(ni,2), pos_frame(nj,2)]);
    end

    % actualizo nodos
    set(h_nodos, 'XData', pos_frame(:,1), 'YData', pos_frame(:,2));

    % actualizo titulo
    set(h_titulo, 'String', sprintf('t = %.3f s  (Sin amortiguamiento)', t_fi(idx)));

    drawnow;
    gif;
end
close(fig1);

fprintf('  Guardado: %s.gif (%d frames)\n', s_NomArch, length(indices_frame_fi));

% animacion 2: co n amortiguamiento (modelo a.i + drag)

fprintf('Generando animación CON amortiguamiento...\n');

% seleccionar indices donde t avanza ~dt_frame entre frames (solo hasta tF_drag)
indices_frame_drag = [1];
t_last = t_drag(1);
for k = 2:length(t_drag)
    if t_drag(k) > tF_drag
        break;
    end
    if t_drag(k) - t_last >= dt_frame
        indices_frame_drag(end+1) = k;
        t_last = t_drag(k);
    end
end

fig2 = figure('Name', 'Animación con amortiguamiento', 'Position', [100 100 800 600]);

% 1er frame
pos_frame = pos_hist_drag{1};
hold on;

% dibujar linea de superficie libre
h_sl = plot([x_min, x_max], [h_SL, h_SL], 'c--', 'LineWidth', 1.5);

for b = 1:nBarras
    ni = m_Barras(b,1); nj = m_Barras(b,2);
    h_barras2(b) = plot([pos_frame(ni,1), pos_frame(nj,1)], ...
                        [pos_frame(ni,2), pos_frame(nj,2)], 'b-', 'LineWidth', 2);
end
h_nodos2 = plot(pos_frame(:,1), pos_frame(:,2), 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'r');

% dibujar esfera en nodo c
theta_esf = linspace(0, 2*pi, 50);
x_esf = pos_frame(nodo_c,1) + r_esf * cos(theta_esf);
y_esf = pos_frame(nodo_c,2) + r_esf * sin(theta_esf);
h_esfera = fill(x_esf, y_esf, [0.7 0.7 1], 'EdgeColor', 'b', 'FaceAlpha', 0.3);

h_titulo2 = title(sprintf('t = %.3f s  (Con amortiguamiento, r_{esf}=%.1f m)', t_drag(1), r_esf));
axis equal; grid on;
xlim([x_min x_max]); ylim([y_min y_max]);
xlabel('x [m]'); ylabel('y [m]');
legend([h_sl, h_esfera], {'Superficie libre', 'Esfera'}, 'Location', 'NorthEast');
hold off;

% inicio gif
s_NomArch2 = 'animacion_con_amort';
gif([s_NomArch2, '.gif'], 'overwrite', true, 'frame', gcf, ...
    'LoopCount', 0, 'DelayTime', 1/10);

% frames siguientes
for idx = indices_frame_drag(2:end)
    pos_frame = pos_hist_drag{idx};

    % actualizo barras
    for b = 1:nBarras
        ni = m_Barras(b,1); nj = m_Barras(b,2);
        set(h_barras2(b), 'XData', [pos_frame(ni,1), pos_frame(nj,1)], ...
                          'YData', [pos_frame(ni,2), pos_frame(nj,2)]);
    end

    % actualizo nodos
    set(h_nodos2, 'XData', pos_frame(:,1), 'YData', pos_frame(:,2));

    % actualizo esfera
    x_esf = pos_frame(nodo_c,1) + r_esf * cos(theta_esf);
    y_esf = pos_frame(nodo_c,2) + r_esf * sin(theta_esf);
    set(h_esfera, 'XData', x_esf, 'YData', y_esf);

    % actualizo título
    set(h_titulo2, 'String', sprintf('t = %.3f s  (Con amortiguamiento, r_{esf}=%.1f m)', ...
        t_drag(idx), r_esf));

    drawnow;
    gif;
end

fprintf('  Guardado: %s.gif (%d frames)\n', s_NomArch2, length(indices_frame_drag));

fprintf('\n=== ANIMACIONES COMPLETAS ===\n');
fprintf('Archivos generados en la carpeta Codigo/:\n');
fprintf('  - %s.gif\n', s_NomArch);
fprintf('  - %s.gif\n', s_NomArch2);
