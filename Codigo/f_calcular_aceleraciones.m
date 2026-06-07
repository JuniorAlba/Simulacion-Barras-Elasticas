function acc = f_calcular_aceleraciones(pos, vel, m_Barras, v_L0, v_k, ...
                                       v_masas, v_libres, v_apoyos, m_Fext, ...
                                       modelo, m_dir0, params_drag)

%  CALCULO DE ACELERACIONES PARA CADA NODO

%  para cada nodo libre del reticulado se suman todas las fuerzas que actuan sobre el y se calcula su aceleracion usando 
% la 2da ley de Newton

%  las fuerzas internas F_IJ provienen de las barras conectadas al nodo cada barra actua como un resorte la magnitud de la fuerza es
%  F=k*delta ,  la direccion depende del modelo elegido (finito o pequenos desplazamientos).

%  las barras articuladas solo transmiten fuerzas axiales (a lo largo de su eje) por lo que la tension tangencial es siempre cero.

%  entradas:
%    pos -> posiciones actuales [x, y] de todos los nodos
%    vel -> velocidades actuales [vx, vy] de todos los nodos
%    m_Barras -> conectividad [nodo_i, nodo_j]
%    v_L0 -> longitudes iniciales
%    v_k -> rigideces k_IJ 
%    v_masas -> masa de cada nodo
%    v_libres -> vector de indices de nodos libres
%    v_apoyos -> vector de indices de nodos de apoyo
%    m_Fext -> fuerzas externas en cada nodo        
%    modelo -> string 'finito' o 'pequeno'
%    m_dir0 -> direcciones unitarias iniciales de las barras
%    params_drag -> struct con campos nodo_c, r_esf, rho_fl, C_d, h_SL
%  salida:
%    acc -> aceleracion de cada nodo


    nNodos  = size(pos, 1);
    nBarras = size(m_Barras, 1);

    % inicializar vector de fuerzas resultantes
    F_total = zeros(nNodos, 2);

    %fuerzas internas de las barras 
    %para cada barra hay que calcular su longitud actual con las coordenadas deformadas 
    for b = 1:nBarras
        ni = m_Barras(b, 1);   
        nj = m_Barras(b, 2);   

        % vector diferencia de posiciones actuales
        dx = pos(nj, :) - pos(ni, :);

        % longitud actual de la barra
        l_actual = sqrt(dx(1)^2 + dx(2)^2);

        % alargamiento
        delta = l_actual - v_L0(b);

        % magnitud de la fuerza interna
        F_mag = v_k(b) * delta;

        % direccion segun el modelo
        if strcmp(modelo, 'finito')
            % se calcula con las posiciones actuales
            e_ij = dx / l_actual;
        else
            % se usa la direccion inicial como referencia durante toda la simulación
            e_ij = m_dir0(b, :);
        end

        % fuerza sobre nodo i desde la barra b
        %  si delta > 0 traccion , si delta < 0 compresion
        F_barra = F_mag * e_ij;

        % 3ra ley de nwton
        F_total(ni, :) = F_total(ni, :) + F_barra;   
        F_total(nj, :) = F_total(nj, :) - F_barra;   
    end

    %sumamos fuerzas externas
    F_total = F_total + m_Fext;

    %calculamos fuerza de arrastre (drag)
    % primero se determina el A_R segun cuanto de la esfera esta sumergida y luego se aplica la formula de drag
    if ~isempty(params_drag)
        nc    = params_drag.nodo_c;
        r_esf = params_drag.r_esf;
        rho_f = params_drag.rho_fl;
        C_d   = params_drag.C_d;
        h_SL  = params_drag.h_SL;

        % coordenada vertical nodo c
        y_c = pos(nc, 2);

        % velocidad vertical nodo c
        vy_c = vel(nc, 2);

        % area de referencia A_R segun nivel de inmersion
        if (y_c - r_esf) >= h_SL
            % 1er caso esfera fuera del liquido
            A_R = 0;
        elseif h_SL <= y_c
            % 2d caso parcialmente sumergida
            A_R = pi * (r_esf^2 - (y_c - h_SL)^2);
        else
            % 3er caso sumergida hasta inmersión total
            A_R = pi * r_esf^2;
        end

        % fuerza de arrastre
        F_drag_y = -0.5 * rho_f * C_d * A_R * abs(vy_c) * vy_c;

        % sumamos la fuerza de arrastre al nodo c
        F_total(nc, 2) = F_total(nc, 2) + F_drag_y;
    end

    % calculo de aceleraciones: a = F / m
    acc = zeros(nNodos, 2);
    for i = v_libres'
        acc(i, :) = F_total(i, :) / v_masas(i);
    end
end
