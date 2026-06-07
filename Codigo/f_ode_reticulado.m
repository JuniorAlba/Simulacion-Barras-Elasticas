function dydt = f_ode_reticulado(t, y, nNodos, m_Barras, v_L0, v_k, ...
                                  v_masas, v_libres, v_apoyos, m_Fext, ...
                                  modelo, m_dir0, params_drag)

%  FUNCION PARA ode23 — ECUACIONES DE MOVIMIENTO DEL RETICULADO

%  se define el sistema de ecuaciones diferenciales que ode23 integra: dy/dt = f(t, y)

%  el vector de estado y contiene las posiciones y velocidades de todos los nodos del reticulado, organizados en forma de columna
%  y = [x1,...,xN, y1,...,yN | vx1,...,vxN, vy1,...,vyN]^T
% 'y' es un vector columna de tamanio 4*N x 1 , la primera mitad tiene las posiciones (x, y)
% y la segunda mitad tiene las velocidades (vx, vy)

%  las derivadas del sistema son: d(pos)/dt = vel , d(vel)/dt = acel

    pos_x = y(1 : nNodos); % posiciones X de todos los nodos
    pos_y = y(nNodos+1 : 2*nNodos);% pos Y de todos los nodos
    pos = [pos_x, pos_y];
    
    vel_x = y(2*nNodos+1 : 3*nNodos); %velocidades X de todos los nodos
    vel_y = y(3*nNodos+1 : 4*nNodos); %vels Y de todos los nodos
    vel = [vel_x, vel_y];

    % calcular aceleraciones con la funcion de fuerzas
    acc = f_calcular_aceleraciones(pos, vel, m_Barras, v_L0, v_k, ...
            v_masas, v_libres, v_apoyos, m_Fext, modelo, m_dir0, params_drag);

    % derivadas
    dpos = vel;
    dvel = acc;

    % nodos de apoyo: derivadas = 0 (estan fijos)
    dpos(v_apoyos, :) = 0;
    dvel(v_apoyos, :) = 0;

    % hay que devolverlo como vector columna pq ode23 lo espera asi
    dydt = [dpos(:); dvel(:)];

end
