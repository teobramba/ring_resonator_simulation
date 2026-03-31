%% PIC Simulation - Ring Resonator testing with Golden standard vs DUT
% Matteo Brambilla - 2026
clear; clc; close all;
c = 299792458;                % Speed of light [m/s]
enable_animation = true;

%% 1. User-Defined Parameters - Golden standard
lambda_0_gold = 1550e-9;      % Center wavelength [m]
f_0_gold = c / lambda_0_gold; % Center frequency [Hz]
FSR_gold = 100e9;             % Free Spectral Range [Hz] (100 GHz)
B_gold = 10e9;                % Full Width at Half Maximum [Hz] (10 GHz)
ng = 4.2;                     % Group index 
neff = 2.45;                  % Effective refractive index 
gamma = 1;                    % Round-trip amplitude transmission 
Ptot = 1e-3;                  % Total optical input power [1 mW]

% Heating parameters
d_neff_th = 1.86e-4;          % neff temperature sensitivity
R_heater = 100;               % Heater resistance
R_thermal = 1e3;              % Thermal resistance [K/mW]

%% 2. Design the RR
[FSR_real, R_real] = ring_design(lambda_0_gold, FSR_gold, ng, neff);
fprintf('--- Ring Parameters ---\n');
fprintf('FSR_real:     %.3f GHz\n', FSR_real/1e9);
fprintf('Real Radius:  %.3f um\n\n', R_real*1e6);

fspan = 5 * FSR_gold;
f = linspace(f_0_gold - fspan/2, f_0_gold + fspan/2, 10000);
P_gold = ring_simulate(f, f_0_gold, R_real, B_gold, ng, neff, gamma);

%% 3. Define the "LED" Source Profile 
sigma_LED = 0.5 * FSR_gold; 
PSD_LED_shape = exp(-((f - f_0_gold).^2) / (2 * sigma_LED^2));
normalization_factor = Ptot / trapz(f, PSD_LED_shape);
PSD_LED = PSD_LED_shape * normalization_factor;

%% 4. Define the DUT and Setup Full Dashboard
R_error = 10e-9;          
R_DUT = R_real + R_error;   

P_sweep = linspace(0, 30e-3, 300); 

% --- Setup Dither Parameters ---
A_dither = 0.1e-3;             % Dither amplitude: 0.1 mW
n_cycles = 3;                  % Number of full sine cycles
N_time = 180;                   % Points per dither simulation
phi_t = linspace(0, n_cycles * 2 * pi, N_time);

% Pre-compute sine and cosine waves for demodulation
sin_1f = sin(phi_t);    cos_1f = cos(phi_t);
sin_2f = sin(2*phi_t);  cos_2f = cos(2*phi_t);
sin_3f = sin(3*phi_t);  cos_3f = cos(3*phi_t);

% --- Pre-allocate Arrays ---
PSD_TT = zeros(length(f), length(P_sweep));
PSD_DD = zeros(length(f), length(P_sweep));
PSD_DT = zeros(length(f), length(P_sweep));
PSD_TD = zeros(length(f), length(P_sweep));

Power_TT = zeros(1, length(P_sweep));
Power_DD = zeros(1, length(P_sweep));
Power_DT = zeros(1, length(P_sweep));
Power_TD = zeros(1, length(P_sweep));

% Harmonics arrays [4 permutations, 3 harmonics]
H_TT = zeros(3, length(P_sweep));
H_DD = zeros(3, length(P_sweep));
H_DT = zeros(3, length(P_sweep));
H_TD = zeros(3, length(P_sweep));

P_thru_gold = P_gold(:, 1);
P_drop_gold = P_gold(:, 2);

% --- Combined Figure Setup (Now 3x4 Grid) ---
figure('Name', 'Full Port Permutation Dashboard', 'Color', 'w', 'Position', [50, 50, 1600, 900]);

% --- Helper to initialize the 3 rows ---
% Row 1: Spectra | Row 2: Average Power | Row 3: Harmonics
colors = {'b', 'r', 'g'};
harmonic_names = {'1f', '2f', '3f'};

% 1. Setup Through-Through (Column 1)
ax_TT = subplot(3, 4, 1);
plot(f/1e12, P_thru_gold, 'r', 'LineWidth', 1.5); hold on; 
h_DUT_TT = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); 
h_prod_TT = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); 
title('Through-Through'); xlabel('Freq (THz)'); grid on; ylim([0 1.1]);
subplot(3, 4, 5); h_track_TT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4); title('Power Track: TT'); ylabel('Power (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(3, 4, 9); hold on; for i=1:3, h_harm_TT(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: TT'); xlabel('Heater (mW)'); ylabel('Harmonic Amp'); grid on; xlim([0 max(P_sweep)*1000]); legend(harmonic_names);

% 2. Setup Drop-Drop (Column 2)
ax_DD = subplot(3, 4, 2);
plot(f/1e12, P_drop_gold, 'r', 'LineWidth', 1.5); hold on; 
h_DUT_DD = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); 
h_prod_DD = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); 
title('Drop-Drop'); xlabel('Freq (THz)'); grid on; ylim([0 1.1]);
subplot(3, 4, 6); h_track_DD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4); title('Power Track: DD'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(3, 4, 10); hold on; for i=1:3, h_harm_DD(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: DD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); legend(harmonic_names);

% 3. Setup Drop-Through (Column 3)
ax_DT = subplot(3, 4, 3);
plot(f/1e12, P_drop_gold, 'r', 'LineWidth', 1.5); hold on; 
h_DUT_DT = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); 
h_prod_DT = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); 
title('Drop-Through'); xlabel('Freq (THz)'); grid on; ylim([0 1.1]);
subplot(3, 4, 7); h_track_DT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4); title('Power Track: DT'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(3, 4, 11); hold on; for i=1:3, h_harm_DT(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: DT'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); legend(harmonic_names);

% 4. Setup Through-Drop (Column 4)
ax_TD = subplot(3, 4, 4);
plot(f/1e12, P_thru_gold, 'r', 'LineWidth', 1.5); hold on; 
h_DUT_TD = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); 
h_prod_TD = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); 
title('Through-Drop'); xlabel('Freq (THz)'); grid on; ylim([0 1.1]);
subplot(3, 4, 8); h_track_TD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4); title('Power Track: TD'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(3, 4, 12); hold on; for i=1:3, h_harm_TD(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: TD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); legend(harmonic_names);

%% 5. Thermo-Optic Tuning Loop with Dithering
fprintf('--- Starting Full Tuning Sweep with Dithering ---\n');

for k = 1:length(P_sweep)
    P_base = P_sweep(k);
    
    % --- Step A: Base Physics (For Rows 1 and 2) ---
    dT_base = P_base * R_thermal;           
    neff_base = neff + (d_neff_th * dT_base);
    P_DUT_base = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_base, gamma);
    
    P_thru_DUT = P_DUT_base(:, 1);
    P_drop_DUT = P_DUT_base(:, 2);
    
    % Update standard integrated powers
    PSD_TT(:, k) = (P_thru_gold .* P_thru_DUT) .* PSD_LED'; Power_TT(k) = trapz(f, PSD_TT(:, k));
    PSD_DD(:, k) = (P_drop_gold .* P_drop_DUT) .* PSD_LED'; Power_DD(k) = trapz(f, PSD_DD(:, k));
    PSD_DT(:, k) = (P_drop_gold .* P_thru_DUT) .* PSD_LED'; Power_DT(k) = trapz(f, PSD_DT(:, k));
    PSD_TD(:, k) = (P_thru_gold .* P_drop_DUT) .* PSD_LED'; Power_TD(k) = trapz(f, PSD_TD(:, k));
    
    % --- Step B: Time-Domain Dither Loop (For Row 3) ---
    P_out_TT_t = zeros(1, N_time);
    P_out_DD_t = zeros(1, N_time);
    P_out_DT_t = zeros(1, N_time);
    P_out_TD_t = zeros(1, N_time);
    
    for t_idx = 1:N_time
        % Wiggle the heater power
        P_inst = P_base + A_dither * sin_1f(t_idx);
        dT_inst = P_inst * R_thermal;
        neff_inst = neff + (d_neff_th * dT_inst);
        
        P_DUT_inst = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_inst, gamma);
        
        % Calculate instantaneous total optical power for all 4
        P_out_TT_t(t_idx) = trapz(f, (P_thru_gold .* P_DUT_inst(:, 1)) .* PSD_LED');
        P_out_DD_t(t_idx) = trapz(f, (P_drop_gold .* P_DUT_inst(:, 2)) .* PSD_LED');
        P_out_DT_t(t_idx) = trapz(f, (P_drop_gold .* P_DUT_inst(:, 1)) .* PSD_LED');
        P_out_TD_t(t_idx) = trapz(f, (P_thru_gold .* P_DUT_inst(:, 2)) .* PSD_LED');
    end
    
    % --- Step C: Demodulation (Extract 1f, 2f, 3f amplitudes) ---
    % Math: Amplitude = 2 * sqrt( mean(signal * sin)^2 + mean(signal * cos)^2 )
    
    H_TT(1, k) = 2 * sqrt(mean(P_out_TT_t .* sin_1f)^2 + mean(P_out_TT_t .* cos_1f)^2);
    H_TT(2, k) = 2 * sqrt(mean(P_out_TT_t .* sin_2f)^2 + mean(P_out_TT_t .* cos_2f)^2);
    H_TT(3, k) = 2 * sqrt(mean(P_out_TT_t .* sin_3f)^2 + mean(P_out_TT_t .* cos_3f)^2);
    
    H_DD(1, k) = 2 * sqrt(mean(P_out_DD_t .* sin_1f)^2 + mean(P_out_DD_t .* cos_1f)^2);
    H_DD(2, k) = 2 * sqrt(mean(P_out_DD_t .* sin_2f)^2 + mean(P_out_DD_t .* cos_2f)^2);
    H_DD(3, k) = 2 * sqrt(mean(P_out_DD_t .* sin_3f)^2 + mean(P_out_DD_t .* cos_3f)^2);

    H_DT(1, k) = 2 * sqrt(mean(P_out_DT_t .* sin_1f)^2 + mean(P_out_DT_t .* cos_1f)^2);
    H_DT(2, k) = 2 * sqrt(mean(P_out_DT_t .* sin_2f)^2 + mean(P_out_DT_t .* cos_2f)^2);
    H_DT(3, k) = 2 * sqrt(mean(P_out_DT_t .* sin_3f)^2 + mean(P_out_DT_t .* cos_3f)^2);

    H_TD(1, k) = 2 * sqrt(mean(P_out_TD_t .* sin_1f)^2 + mean(P_out_TD_t .* cos_1f)^2);
    H_TD(2, k) = 2 * sqrt(mean(P_out_TD_t .* sin_2f)^2 + mean(P_out_TD_t .* cos_2f)^2);
    H_TD(3, k) = 2 * sqrt(mean(P_out_TD_t .* sin_3f)^2 + mean(P_out_TD_t .* cos_3f)^2);

    % --- Step D: Update All Plots ---
    P_mw = P_sweep(1:k) * 1000; % X-axis values up to current step
    if enable_animation
        % TT Updates
        h_DUT_TT.YData = P_thru_DUT; h_prod_TT.YData = P_thru_gold .* P_thru_DUT;
        h_track_TT.XData = P_mw; h_track_TT.YData = Power_TT(1:k) * 1000;
        for i=1:3, h_harm_TT(i).XData = P_mw; h_harm_TT(i).YData = H_TT(i, 1:k) * 1000; end
        title(ax_TT, sprintf('Through-Through | \\DeltaT: %.2f °C', dT_base));

        % DD Updates
        h_DUT_DD.YData = P_drop_DUT; h_prod_DD.YData = P_drop_gold .* P_drop_DUT;
        h_track_DD.XData = P_mw; h_track_DD.YData = Power_DD(1:k) * 1000;
        for i=1:3, h_harm_DD(i).XData = P_mw; h_harm_DD(i).YData = H_DD(i, 1:k) * 1000; end
        title(ax_DD, sprintf('Drop-Drop | \\DeltaT: %.2f °C', dT_base));

        % DT Updates
        h_DUT_DT.YData = P_thru_DUT; h_prod_DT.YData = P_drop_gold .* P_thru_DUT;
        h_track_DT.XData = P_mw; h_track_DT.YData = Power_DT(1:k) * 1000;
        for i=1:3, h_harm_DT(i).XData = P_mw; h_harm_DT(i).YData = H_DT(i, 1:k) * 1000; end
        title(ax_DT, sprintf('Drop-Through | \\DeltaT: %.2f °C', dT_base));

        % TD Updates
        h_DUT_TD.YData = P_drop_DUT; h_prod_TD.YData = P_thru_gold .* P_drop_DUT;
        h_track_TD.XData = P_mw; h_track_TD.YData = Power_TD(1:k) * 1000;
        for i=1:3, h_harm_TD(i).XData = P_mw; h_harm_TD(i).YData = H_TD(i, 1:k) * 1000; end
        title(ax_TD, sprintf('Through-Drop | \\DeltaT: %.2f °C', dT_base));

        drawnow;
    end
end

fprintf('Sweep complete.\n');

%% Final Plot (If animation is disabled)
if ~enable_animation
    fprintf('Rendering final graphs...\n');
    
    P_mw = P_sweep * 1000; % The full x-axis array
    
    % 1. Update TT
    h_DUT_TT.YData = P_thru_DUT; h_prod_TT.YData = P_thru_gold .* P_thru_DUT;
    h_track_TT.XData = P_mw; h_track_TT.YData = Power_TT * 1000;
    for i=1:3, h_harm_TT(i).XData = P_mw; h_harm_TT(i).YData = H_TT(i, :) * 1000; end
    title(ax_TT, sprintf('Through-Through | \\DeltaT: %.2f °C', dT_base));

    % 2. Update DD
    h_DUT_DD.YData = P_drop_DUT; h_prod_DD.YData = P_drop_gold .* P_drop_DUT;
    h_track_DD.XData = P_mw; h_track_DD.YData = Power_DD * 1000;
    for i=1:3, h_harm_DD(i).XData = P_mw; h_harm_DD(i).YData = H_DD(i, :) * 1000; end
    title(ax_DD, sprintf('Drop-Drop | \\DeltaT: %.2f °C', dT_base));

    % 3. Update DT
    h_DUT_DT.YData = P_thru_DUT; h_prod_DT.YData = P_drop_gold .* P_thru_DUT;
    h_track_DT.XData = P_mw; h_track_DT.YData = Power_DT * 1000;
    for i=1:3, h_harm_DT(i).XData = P_mw; h_harm_DT(i).YData = H_DT(i, :) * 1000; end
    title(ax_DT, sprintf('Drop-Through | \\DeltaT: %.2f °C', dT_base));

    % 4. Update TD
    h_DUT_TD.YData = P_drop_DUT; h_prod_TD.YData = P_thru_gold .* P_drop_DUT;
    h_track_TD.XData = P_mw; h_track_TD.YData = Power_TD * 1000;
    for i=1:3, h_harm_TD(i).XData = P_mw; h_harm_TD(i).YData = H_TD(i, :) * 1000; end
    title(ax_TD, sprintf('Through-Drop | \\DeltaT: %.2f °C', dT_base));

    % draw the fully populated plots
    drawnow; 
    fprintf('Graphs rendered.\n');
end