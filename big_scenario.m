clear; clc; close all;

output_filename = "output/big_patches.mat";
update_figure = false;
rng(6);

% ---- PARAMETERS ----------------------------------------
N        = 100;     % Grid size (N x N)
T_steps  = 4*24*60/5;     % Number of time steps
deltaT   = 5;       % Time step (minutes)
T0       = 0;      % Start time (minutes since midnight) of the simulation
month    = 'Jan';  % Month we are running the simulation in
n_frogs  = 50;      % Number of frogs
n_seeds  = 1;     % Seeds per habitat (controls patch size)
pause_t  = 0.10;   % Pause between frames
k_const  = 0.05790; % Thermal constant of frog (1/minutes) - for update_temp
VTmax = 30; % Threshold of hot for cold
VTmin = 20; % Threshold of cold for hot
R_perc = 2;   % Perception radius (1=4 pixels, 2=12, 3=24, ...)
              % pixels within Manhattan distance R form a diamond

% ---- HABITAT PROPORTIONS (must sum to 1) ----------------
hab_proportions = [0.1, 0.20, 0.50, 0.20];
%                Rocks  DeepVeg  LightVeg  Pond
% ----------------------------------------------------------

frogs_multi_v4