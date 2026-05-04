% =========================================================
%  MULTIPLE FROGS – Random movement over habitat map
%
%  Habitats (fixed temperature):
%    1 = Rocks            -> 30 C
%    2 = Light Vegetation -> 28 C
%    3 = Deep Vegetation  -> 18 C
%    4 = Pond             -> 12 C
%
%  Each frog has an INTERNAL TEMPERATURE (frog_temp) that
%  currently matches the temperature of its current habitat.
%  To change this logic in the future, only modify the
%  function: update_frog_temp() at the bottom of this file.
%
%  Each frog moves with probability p_move to one of its
%  4 neighbours (Von Neumann), chosen at random (uniform).
%  Each frog has its own colour and trail.
% =========================================================

clear; clc; close all;

%% ---- PARAMETERS ----------------------------------------
N        = 40;     % Grid size (N x N)
T_steps  = 300;     % Number of time steps
deltaT   = 5;       % Time step (minutes)
T0       = 0;      % Start time (minutes since midnight) of the simulation
month    = "Jan";  % Month we are running the simulation in
n_frogs  = 3;      % Number of frogs
initial_temp = 10;    % Initial frog body temperature
p_move   = 0.7;    % Probability of moving each step [0-1]
n_seeds  = 20;     % Seeds per habitat (controls patch size)
pause_t  = 0.10;   % Pause between frames

k_const  = 0.05790; % Thermal constant of frog (1/minutes) - for update_temp
% --------------------------------------------------------

%% ---- MICROCLIMATE -----------------------------------------
% Temperature profile using nichemapr given a location and month
% latitude = -36.686844; longitude = 145.223311; month = "Jan";
% [T_hab, ~, ~] = get_microclimate_nichemapr(latitude, longitude, month);

% Temperature profile from a pre-processed file
temperature_file = "data/microclimate_data-" + month + ".txt";
T_hab = read_microclimate_file(temperature_file);

%% ---- HABITATS -----------------------------------------
hab_names = {'Rocks','Light Veg','Deep Veg','Pond'};
C_hab     = [0.52 0.32 0.18;             % Rocks  - brown
             0.72 0.88 0.28;             % Light Veg   - yellow-green
             0.08 0.45 0.12;             % Deep Veg    - dark green
             0.12 0.42 0.82];            % Pond        - blue

%% ---- FROG COLOURS --------------------------------------
frog_colors = [
    0.95 0.92 0.10;   % yellow
    0.95 0.35 0.15;   % orange
    0.85 0.15 0.85;   % magenta
    0.15 0.90 0.90;   % cyan
    1.00 1.00 1.00;   % white
    0.60 0.95 0.20;   % lime
    0.95 0.60 0.80;   % pink
    0.55 0.80 1.00;   % light blue
    0.95 0.70 0.10;   % gold
    0.70 0.40 1.00;   % violet
];
% Cycle through colours if n_frogs > number of defined colours
frog_colors = frog_colors(mod((1:n_frogs)-1, size(frog_colors,1))+1, :);

%% ---- BUILD HABITAT MAP ---------------------------------
habitat = build_habitat(N, n_seeds);

% Build RGB image of the habitat (used as background)
hab_rgb = zeros(N, N, 3);
for ch = 1:3
    layer = zeros(N,N);
    for h = 1:4
        layer(habitat == h) = C_hab(h, ch);
    end
    hab_rgb(:,:,ch) = layer;
end

%% ---- INITIAL POSITIONS (random) ------------------------
fi = randi(N, 1, n_frogs);   % row of each frog
fj = randi(N, 1, n_frogs);   % column of each frog
frog_hab = arrayfun(@(i,j) habitat(i,j), fi, fj); % Get the habitats

%% ---- INITIAL INTERNAL TEMPERATURE ----------------------
frog_temp = get_habitat_temp(T_hab, frog_hab, T0);

%% ---- FIGURE (3 panels) ---------------------------------
fig = figure('Name','Multiple Frogs – Internal Temperature', ...
             'NumberTitle','off', ...
             'Color',[0.09 0.09 0.13], ...
             'Position',[40 60 1420 650]);

% ---- Panel 1: habitat map + frogs ----------------------
ax1 = subplot(1,4,[1 2]);
image(ax1, hab_rgb);
axis(ax1,'equal','tight','off');
hold(ax1,'on');
% Habitat legend
for h = 1:4
    plot(ax1, nan, nan, 's', ...
        'MarkerFaceColor', C_hab(h,:), 'MarkerEdgeColor','none', ...
        'MarkerSize',12, ...
        'DisplayName', sprintf('%s', hab_names{h}));
end
legend(ax1,'Location','southoutside','TextColor','w', ...
       'Color',[0.18 0.18 0.22],'EdgeColor','none', ...
       'FontSize',8,'NumColumns',2);
title(ax1,'Habitat map','Color','w','FontSize',12,'FontWeight','bold');

% Trails and markers
h_trail  = gobjects(n_frogs, 1);
h_frog   = gobjects(n_frogs, 1);
h_tlabel = gobjects(n_frogs, 1);   % internal temperature label above each frog
trail_r  = num2cell(fi');          % row history per frog
trail_c  = num2cell(fj');          % column history per frog

%%
for k = 1:n_frogs
    col = frog_colors(k,:);
    h_trail(k) = plot(ax1, fj(k), fi(k), '-', ...
        'Color', [col 0.35], 'LineWidth', 1.0);
    % h_frog(k) = plot(ax1, fj(k), fi(k), 'o', ...
    %     'MarkerFaceColor', col, 'MarkerEdgeColor', col*0.4, ...
    %     'MarkerSize', 13, 'LineWidth', 1.2);
    h_frog(k) = text(ax1, fj(k), fi(k), '🐸', ...
        'FontSize', 14, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle');

    % Internal temperature label floating above each frog
    h_tlabel(k) = text(ax1, fj(k), fi(k)-1.3, ...
        sprintf('%.0fC', frog_temp(k)), ...
        'Color', col, 'FontSize', 7, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
end

% Step counter label
txt_paso = text(ax1, 1, 0.3, '', ...
    'Color','w','FontSize',9,'FontWeight','bold', ...
    'VerticalAlignment','bottom','BackgroundColor',[0 0 0 0.55]);

% ---- Panel 2: frogs per habitat ------------------------
ax2 = subplot(1,4,3);
hold(ax2,'on');
ln_hab = gobjects(4,1);
for h = 1:4
    ln_hab(h) = animatedline(ax2,'Color',C_hab(h,:),'LineWidth',2.2);
end
xlim(ax2,[1 T_steps]); ylim(ax2,[0 n_frogs]);
xlabel(ax2,'Time step','Color','w','FontSize',10);
ylabel(ax2,'Number of frogs','Color','w','FontSize',10);
title(ax2,'Frogs per habitat','Color','w','FontSize',12,'FontWeight','bold');
ax2.Color  = [0.13 0.13 0.17];
ax2.XColor = 'w'; ax2.YColor = 'w';
ax2.YTick  = 0:n_frogs;
grid(ax2,'on'); ax2.GridColor = [0.35 0.35 0.35];
legend(ax2, hab_names,'TextColor','w','Color',[0.18 0.18 0.22], ...
       'EdgeColor','none','Location','northeast','FontSize',9);

% ---- Panel 3: internal temperature per frog ------------
ax3 = subplot(1,4,4);
hold(ax3,'on');
ln_temp = gobjects(n_frogs,1);
for k = 1:n_frogs
    ln_temp(k) = animatedline(ax3,'Color',frog_colors(k,:),'LineWidth',1.8);
end
xlim(ax3,[1 T_steps]);
% ylim(ax3,[min(T_hab)-3, max(T_hab)+3]);
xlabel(ax3,'Time step','Color','w','FontSize',10);
ylabel(ax3,'Internal temperature (C)','Color','w','FontSize',10);
title(ax3,'Internal temperature per frog', ...
    'Color','w','FontSize',12,'FontWeight','bold');
ax3.Color  = [0.13 0.13 0.17];
ax3.XColor = 'w'; ax3.YColor = 'w';
grid(ax3,'on'); ax3.GridColor = [0.35 0.35 0.35];
% Reference lines for each habitat temperature
for h = 1:4
    habitat_temp_profile = get_habitat_temp(T_hab, h, (1:T_steps).*5);
    plot(ax3, 1:T_steps, habitat_temp_profile, '--', ...%hab_names{h}, ...
        'Color', [C_hab(h,:) 0.6] )%'FontSize', 7, ...
        % 'LabelHorizontalAlignment','left', ...
        % 'LabelVerticalAlignment','bottom');
end
frog_leg = arrayfun(@(k) sprintf('Frog %d',k), 1:n_frogs, 'UniformOutput',false);
legend(ax3, frog_leg,'TextColor','w','Color',[0.18 0.18 0.22], ...
       'EdgeColor','none','Location','northeast','FontSize',7,'NumColumns',2);

%% ---- SIMULATION LOOP ----------------------------------
fprintf('\nStarting simulation: %d frogs, %d steps\n\n', ...
        n_frogs, T_steps);

K = 0.5;
for t = 1:T_steps
    time_mins = T0 + t*deltaT;
    % -- Move each frog independently --
    for k = 1:n_frogs
        % 1. Identify the habitat and actual temperture of frog
        hab_actual = frog_hab(k);
        T_actual = frog_temp(k);
        
        % 2. Probability of movement depending on the habitat
        if hab_actual == 1 || hab_actual == 2
            p_move_k = 1 / (1 + exp(-K*(T_actual - 30)));
        elseif hab_actual == 3
            p_move_k = 1 - 1 / (1 + exp(-K* (T_actual - 20)));
        else
            % For habitat 4, we use random probability
            p_move_k = p_move;
        end
        
        % 3. Decidir si se mueve
        if rand() < p_move_k
           % Valid Von Neumann neighbours (inside limits)
            vi = [fi(k)-1, fi(k)+1, fi(k),   fi(k)  ];
            vj = [fj(k),   fj(k),   fj(k)-1, fj(k)+1];
            ok = vi>=1 & vi<=N & vj>=1 & vj<=N;
            vi = vi(ok); vj = vj(ok);
            
            % 4. Preference direction
            % Neighbors
            vecinos_hab = arrayfun(@(r, c) habitat(r, c), vi, vj);
            
            % Assign weights to each pixel neighbor (1 para todos)
            weight = ones(1, length(vi)); 
            weight_pref = 10; % <--- Cambia este valor para hacer la preferencia más o menos fuerte
            
            % Modificar weight según las preferencias de dirección
            if hab_actual == 1 || hab_actual == 2
                % In rocks or light veg, preference for hab 3 o 4
                pref = (vecinos_hab == 3) | (vecinos_hab == 4);
                weight(pref) = weight_pref;
            elseif hab_actual == 3 
                % In deep veg, preference for hab 1 o 2
                pref = (vecinos_hab == 1) | (vecinos_hab == 2);
                weight(pref) = weight_pref;               
            end
            
            % Selección aleatoria ponderada (Ruleta)
            probabilities = weight / sum(weight);
            cum_prob = cumsum(probabilities);
            r = rand();
            idx = find(cum_prob >= r, 1);
            
            % Actualizar posición
            fi(k) = vi(idx);
            fj(k) = vj(idx);
            
            % Guardar rastro
            trail_r{k}(end+1) = fi(k);
            trail_c{k}(end+1) = fj(k);
        end
    
    % -- Update habitat --
    frog_hab = arrayfun(@(i,j) habitat(i,j), fi, fj);

    % -- Update internal temperature --
    % All temperature logic is encapsulated in this function
    frog_temp = update_temp(T_hab, frog_hab, frog_temp, k_const, time_mins, deltaT);

    % -- Count frogs per habitat --
    pop = arrayfun(@(h) sum(frog_hab==h), 1:4);

    % -- Update figure --
    for k = 1:n_frogs
        %set(h_frog(k),  'XData', fj(k), 'YData', fi(k));
        set(h_frog(k), 'Position', [fj(k), fi(k), 0])
        set(h_trail(k), 'XData', trail_c{k}, 'YData', trail_r{k});
        set(h_tlabel(k), 'Position', [fj(k), fi(k)-1.3, 0], ...
            'String', sprintf('%.0fC', frog_temp(k)));
        addpoints(ln_temp(k), t, frog_temp(k));
    end

    set(txt_paso,'String', ...
        sprintf('Step %d/%d  |  p_move=%.2f', t, T_steps, p_move));

    for h = 1:4
        addpoints(ln_hab(h), t, pop(h));
    end

    drawnow;
    pause(pause_t);
    end
end

%% ---- FINAL RESULTS -------------------------------------
fprintf('=== FINAL DISTRIBUTION ===\n');
hab_final = arrayfun(@(r,c) habitat(r,c), fi, fj);
fprintf('%-6s  %-16s  %8s\n','Frog','Habitat','Int. Temp');
fprintf('%s\n', repmat('-',1,35));
for k = 1:n_frogs
    fprintf('  %2d    %-16s   %.1f C\n', k, hab_names{hab_final(k)}, frog_temp(k));
end


%% =========================================================
%  INTERNAL TEMPERATURE OF EACH FROG
%  -------------------------------------------------------
%  MODIFY THIS FUNCTION to change the internal temperature
%
% Inputs:
%    fi, fj    - current positions (vectors 1 x n_frogs)
%   H_frog     - 1 x n_frogs vector with habitat type of each frog (1-4)
%   T_frog     - 1 x n_frogs vector with temperature of each frog
%
% Output:
%   temp      - vector 1 x n_frogs with internal temperature
%
% =========================================================
function body_temp = update_temp(T_hab, H_frog, T_frog, k, time_mins, dt)
    Te = get_habitat_temp(T_hab, H_frog, time_mins);
    assert(isequal(size(Te), size(T_frog)), "Mismatched vectors in update_temp");
    body_temp = Te + (T_frog-Te).*exp(-k*dt);
    % n = length(fi);
    % body_temp = zeros(1,n);
    % for i = 1:n
    %     h       = habitat(fi(i), fj(i));   % habitat type of frog i
    %     Te = get_habitat_temp(T_hab, h, time_mins);
    %     body_temp(i) = Te + (T_frog(i)-Te)*exp(-k*dt);
    % end
end

%% =========================================================
%  EXTERNAL TEMPERATURE OF HABITAT(S)
%  -------------------------------------------------------
%
% Inputs:
%   T_hab      - Table with a row of hourly temperatures per habitat type
%   H_frog     - 1 x n_frogs vector with habitat type of each frog (1-4)
%   time_mins  - The time in minutes (from midnight)
%
% Output:
%   env_temp   - vector 1 x n_frogs with the external temperature for each
%   frog
%
% =========================================================

function env_temp = get_habitat_temp(T_hab, H_frog, time_mins)
    time_24hour = mod(floor(time_mins/60), 24); % We want the hour of the day
    env_temp = T_hab{string(H_frog), string(time_24hour)}'; % Return as row if array
end




%% =========================================================
%  LOCAL FUNCTION – Build habitat map
%  Uses random seeds + nearest-neighbour assignment
%  to create natural, irregular habitat patches.
% =========================================================
function habitat = build_habitat(N, n_seeds)
    seeds  = [randi(N, n_seeds*4, 1), randi(N, n_seeds*4, 1)];
    labels = repelem(1:4, n_seeds)';
    habitat = zeros(N,N);
    for i = 1:N
        for j = 1:N
            [~, best]    = min((seeds(:,1)-i).^2 + (seeds(:,2)-j).^2);
            habitat(i,j) = labels(best);
        end
    end
end
