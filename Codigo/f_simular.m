function [v_t, m_pos_hist, m_vel_hist, v_tension_a, m_coord_b, ...
          v_norma_u_max, t_F] = ...
    f_simular(pos0, m_Barras, v_L0, v_k, v_masas, v_libres, v_apoyos, ...
              m_Fext, modelo, m_dir0, t_F_Max, RelTol, AbsTol, ...
              m_Triangulos, v_areas0, ind_barra_a, nodo_b, A, params_drag)

%  SIMULACION DINAMICA DEL RETICULADO 

%  se integra el sistema completo hasta t_F_Max y luego se detecta manualmente el primer instante t_F en que algun triangulo del
%  reticulado invierte su area con signo 

%  entradas:
%    pos0 ->posiciones iniciales [x, y] 
%    m_Barras -> conectividad [nodo_i, nodo_j]
%    v_L0 -> longitudes iniciales
%    v_k -> rigideces k_IJ
%    v_masas -> masa de cada nodo
%    v_libres ->vector de indices de nodos libres
%    v_apoyos -> vector de indices de nodos de apoyo
%    m_Fext -> fuerzas externas 
%    modelo ->string ('finito' o 'pequeno')
%    m_dir0 -> direcciones unitarias iniciales
%    t_F_Max -> tiempo maximo de simulacion
%    RelTol -> tol relativa para ode23
%    AbsTol -> tol absoluta para ode23
%    m_Triangulos -> triangulos para deteccion de cruce
%    v_areas0 -> areas iniciales con signo
%    ind_barra_a -> indice de la barra "a" para calcular tension
%    nodo_b -> indice del nodo "b" para registrar coordenadas
%    A -> area de seccion transversal de las barras
%    params_drag ->struct con parametros de arrastre ([] si vacio)
%  salidas:
%    v_t -> vector de tiempos de la solucion
%    m_pos_hist -> posiciones de todos los nodos en cada t
%    m_vel_hist -> velocidades de todos los nodos en cada t
%    v_tension_a -> tension normal en barra "a" en cada instante
%    m_coord_b -> coordenadas del nodo "b" en cada instante
%    v_norma_u_max -> norma maxima de desplazamiento en cada instante
%    t_F -> tiempo del primer cruce de barras (o t_F_Max)

    nNodos = size(pos0, 1);

    fprintf('  Simulando modelo "%s" con ode23...\n', modelo);

   %vector de condiciones iniciales (las velocidades inciales son cero)
    vel0 = zeros(nNodos, 2);     
    y0   = [pos0(:); vel0(:)]; % vector columna de 4*N componentes

    % configurar opciones de ode23  (chequear esto)
    opciones = odeset( ...
        'RelTol',  RelTol, ...
        'AbsTol',  AbsTol ...
    );

    f_ode = @(t, y) f_ode_reticulado(t, y, nNodos, m_Barras, v_L0, v_k, ...
                v_masas, v_libres, v_apoyos, m_Fext, modelo, m_dir0, params_drag);

    % integracion con ode23 (desde t=0 hasta t=t_F_Max)
    [v_t, m_Y] = ode23(f_ode, [0, t_F_Max], y0, opciones);

    %v_t corresponde al vector de tiempos y m_Y corresponde a una matriz de posiciones y velocidades de todos los nodos en cada instante de tiempo
    %m_Y tiene un tamanio de nPasos * 4nNodos
    %cada columna corresponde a un nodo
    %se organiza algo asi m_Y = [x1 ... xN y1 ... yN vx1 ... vxN vy1 ... vyN]
    
    nPasos = length(v_t);
    nTri   = size(m_Triangulos, 1);

    m_pos_hist    = cell(nPasos, 1);
    m_vel_hist    = cell(nPasos, 1);


    v_tension_a   = zeros(nPasos, 1);
    m_coord_b     = zeros(nPasos, 2);
    v_norma_u_max = zeros(nPasos, 1);

    t_F        = t_F_Max;
    cruce_found = false;

    for i = 1:nPasos
        % extraer posiciones y velocidades del paso i
        yi  = m_Y(i, :)';
        % extraer posiciones (primera mitad del vector)
        pos_x = yi(1 : nNodos);
        pos_y = yi(nNodos+1 : 2*nNodos);
        pos = [pos_x, pos_y];
        
        % extraer velocidades (segunda mitad del vector)
        vel_x = yi(2*nNodos+1 : 3*nNodos);
        vel_y = yi(3*nNodos+1 : 4*nNodos);
        vel = [vel_x, vel_y];

        m_pos_hist{i} = pos;
        m_vel_hist{i} = vel;

        % tension normal en barra "a"
        %numero de nodo que se encuentra en extremo izquierdo de la barra
        ni_a = m_Barras(ind_barra_a, 1);
        %numero de nodo que se encuentra en extremo derecho de la barra
        nj_a = m_Barras(ind_barra_a, 2);

        dx_a = pos(nj_a, :) - pos(ni_a, :); %pos me da la posicion de los nodos, la diferencia de posiciones me da el vector
        l_a  = sqrt(dx_a(1)^2 + dx_a(2)^2); %la norma del vector me da la longitud de la barra
        delta_a = l_a - v_L0(ind_barra_a); %esto me da cuanto se estiro la barra
        %tension normal en la barra
        v_tension_a(i) = v_k(ind_barra_a) * delta_a / A;



        % coordenadas del nodo "b" 
        m_coord_b(i, :) = pos(nodo_b, :);

        %desplazamiento de los nodos con respecto a la configuracion de ref

        % norma maxima de desplazamiento
        desplaz = pos - pos0;
        normas  = sqrt(desplaz(:,1).^2 + desplaz(:,2).^2);
        v_norma_u_max(i) = max(normas);
        
        % deteccion de cruce de barras
        % se calcula el area con signo de cada triangulo en la configuracion actual , si algun area cambio de signo respecto
        % a la configuracion de referencia , hubo cruce 
        if ~cruce_found
            for k = 1:nTri
                ni_t = m_Triangulos(k, 1);
                nj_t = m_Triangulos(k, 2);
                nk_t = m_Triangulos(k, 3);

                area_actual = 0.5 * ( ...
                    (pos(nj_t,1) - pos(ni_t,1)) * (pos(nk_t,2) - pos(ni_t,2)) ...
                  - (pos(nk_t,1) - pos(ni_t,1)) * (pos(nj_t,2) - pos(ni_t,2)) );

                % si el signo del area cambio respecto al inicial es pq hubo cruce
                if area_actual * sign(v_areas0(k)) < 0
                    t_F = v_t(i);
                    cruce_found = true;
                    break;
                end
            end
        end
    end

    %reportar resultado de cruce
    if cruce_found
        fprintf('  Cruce de barras detectado en t = %.4f s\n', t_F);
    else
        fprintf('  No se detecto cruce de barras (t_F_Max = %.1f s).\n', t_F_Max);
    end

    fprintf('  Simulacion finalizada. t_F = %.4f s  (%d pasos de ode23)\n\n', t_F, nPasos);

end


