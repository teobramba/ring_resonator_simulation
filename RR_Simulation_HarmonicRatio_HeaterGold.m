%% PIC Simulation - Ring Resonator testing, Gold standard heater + DUT + grating coupler
% Matteo Brambilla - 2026

clear; clc; close all;
c = 299792458;                % Speed of light [m/s]

%% 1. User-Defined Parameters 
lambda_0_gold = 1549.7e-9;      f_0_gold = c / lambda_0_gold;
lambda_0_DUT = 1550e-9;       f_0_DUT = c / lambda_0_DUT;
lambda_0_LED = 1550.5e-9;     f_0_LED = c / lambda_0_LED;
FSR_gold = 300e9;             B_gold = 2e9;
FSR_DUT = 100e9;              B_DUT = 30e9;
ng = 4.2;                     neff = 2.45;
Ptot = 1e-3;
alpha_db_cm = 2;

% Heating parameters
d_neff_th = 1.86e-4;          R_heater = 100;
R_thermal = 1e3;

%% 2. Design the RR
% Gold standard parameters
[FSR_real_gold, R_real_gold, K1_gold, K2_gold] = ring_design(lambda_0_gold, FSR_gold, ng, neff, B_gold);
K1_gold = K1_gold + K1_gold*0.5;
% K1_gold = 0.291;     % Tuned value for best coupling and maximum Extintion Ratio FSR100G, B10G
fprintf('--- Gold characteristics ---\n');
fprintf('FSR_gold:          %.2f GHz\n', FSR_real_gold/1e9);
fprintf('BW_gold:           %.2f GHz\n', B_gold/1e9);
fprintf('Radius_gold:       %.2f um\n', R_real_gold*1e6);
fprintf('Coupling gold:     %.3f \n\n', K1_gold);

% DUT parameters
[FSR_real_DUT, R_real_DUT, K1_DUT_ideal, K2_DUT_ideal] = ring_design(lambda_0_DUT, FSR_DUT, ng, neff, B_DUT);
fprintf('--- DUT characteristics ---\n');
fprintf('FSR_DUT:           %.2f GHz\n', FSR_real_DUT/1e9);
fprintf('BW_DUT:            %.2f GHz\n', B_DUT/1e9);
fprintf('Radius_DUT:        %.2f um\n', R_real_DUT*1e6);
fprintf('Coupling DUT:      %.3f \n\n', K1_DUT_ideal);

%% Define the Grating Coupler transfer function
% GC Parameters
GC_BW_nm = 35;      % 35 nm GC Bandwidth
GC_loss_dB = 0;     % 3dB GC loss at central frequency

fspan_simul = 3 * FSR_gold;
f = linspace(f_0_DUT - fspan_simul/2, f_0_DUT + fspan_simul/2, 5000);
gratingCoupler = grat_coupler(f, f_0_gold, GC_BW_nm, GC_loss_dB);

% % Plot the grating transfer function
% figure;
% plot(f/1e12, 10*log10(gratingCoupler), 'LineWidth', 2);
% title('Grating Coupler Transfer Function', 'FontSize', 18);
% xlabel('Frequency [THz]', 'FontSize', 16);
% ylabel('Loss [dB]', 'FontSize', 16);
% grid on;

%% 3. Define the Broad LED and Apply Flat-Top Filter
% wide raw LED 
sigma_raw_LED = 5 * FSR_gold; 
PSD_raw_shape = exp(-((f - f_0_LED).^2) / (2 * sigma_raw_LED^2));
norm_factor = Ptot / trapz(f, PSD_raw_shape);
PSD_LED_raw = PSD_raw_shape * norm_factor;

% Flat-Top Filter Parameters
filter_BW = FSR_gold;    % Bandwidth of the rectangle
filter_order = 7;                 % Steepness (1 = rounded, 4 = flat-top, 10 = rectangle)
filter_IL_dB = 2;                 % Insertion Loss of the filter [dB]

% Convert dB loss to a linear transmission multiplier
T_max_filter = 10^(-filter_IL_dB / 10);

% Super-Gaussian Transfer Function
% The formula: T * exp( -0.5 * | (f - f_0) / (BW / 2) | ^ (2 * order) )
T_flat_top = T_max_filter * exp(-0.5 * (abs(f - f_0_LED) / (filter_BW / 2)).^(2 * filter_order));

% Apply filtering (Multiply LED and filter)
PSD_LED = PSD_LED_raw .* T_flat_top;

% Plot LED PSD and Filtering process
figure('Name', 'LED Filtering Process', 'Color', 'w', 'Position', [100, 100, 800, 500]);
plot(f/1e12, PSD_LED_raw / max(PSD_LED_raw), 'k--', 'LineWidth', 1.5); hold on;
plot(f/1e12, T_flat_top, 'b', 'LineWidth', 1.5);
plot(f/1e12, PSD_LED / max(PSD_LED_raw), 'r', 'LineWidth', 2);
title('Creating a Flat-Top LED Source', 'FontSize', 15);
xlabel('Frequency [THz]', 'FontSize', 14);
ylabel('Normalized Power / Transmission', 'FontSize', 14);
legend({'1. Raw Broad LED', '2. Super-Gaussian Filter', '3. Final Filtered LED'}, 'Location', 'northeast');
grid on;

% %% Plot LED Power Spectrum Density
% PSD_LED_fig = figure('Position', [20, 30, 700, 700]);
% plot(f/1e12, PSD_LED, 'LineWidth', 2, 'Color', 'g');
% title('LED Power Spectrum Density Profile', 'FontSize', 18);
% xlabel('Frequency [THz]', 'FontSize', 16);
% ylabel('PSD [mW/Hz]', 'FontSize', 16);
% grid on;

% %% Export PSD graph
% % Define the file name
% PSD_filename = 'LED PSD.png';
% exportgraphics(PSD_LED_fig, PSD_filename , 'Resolution', 300);
% fprintf('Image saved successfully as: %s\n', PSD_filename);
%% Setup Dither Parameters
P_heater_max = 20e-3;
P_sweep = linspace(0, P_heater_max, 400);
A_dither = 0.5e-3;             % dither amplitude has major role
n_cycles = 3;                  
N_time = 180;                   
phi_t = linspace(0, n_cycles * 2 * pi, N_time);

sin_1f = sin(phi_t);    cos_1f = cos(phi_t);
sin_2f = sin(2*phi_t);  cos_2f = cos(2*phi_t);
sin_3f = sin(3*phi_t);  cos_3f = cos(3*phi_t);

% %% plot the sin(phi_t) signal
% figure
% plot(phi_t, A_dither*1000*sin_1f, 'LineWidth', 2);
% xlabel('Phase (rad)', 'FontSize', 14);
% ylabel('Power (mW)', 'FontSize', 14);
% ylim([-0.53, 0.53]);
% grid on
% title('Dither Signal (sine)', 'FontSize', 16);

%% DUT Coupling coefficient dependance on Gap
evan_gamma = 0.02;                  % evanescent decay constant gamma for SOI [nm^-1]
gap1 = 10;                          % gap distance error for coupler 1 [nm], best -4nm
gap2 = -10;                         % gap distance error for coupler 2 [nm]
K1_DUT = K1_DUT_ideal*exp(-evan_gamma*gap1);   % DUT coupling coefficient 1
K2_DUT = K2_DUT_ideal*exp(-evan_gamma*gap2);   % DUT coupling coefficient 2

% %% Plot coupling dependance on gap distance
% gap = linspace(0, 30, 100);
% K1_plot = K1 * exp(-evan_gamma * gap);   % DUT coupling coefficient for varying gap
% K2_plot = K2 * exp(evan_gamma * gap);   % DUT coupling coefficient for varying gap
% 
% figure;
% plot(gap, K1_plot, "LineWidth", 2, "Color", 'r');   hold on;
% plot(gap, K2_plot, "LineWidth", 2, "Color", 'b');
% xlabel('Gap distance (nm)', 'FontSize', 14);
% ylabel('Power Coupling Coefficient', 'FontSize', 14);
% 
% legend({'K1', 'K2'}, 'Location', 'northwest', 'FontSize', 14);
% % ylim([-0.13, 0.13]);
% grid on
% title('Power Coupling coefficient dependance on gap distance', 'FontSize', 16);

%% Comparison Gold-DUT Transfer functions
fspan_gold = FSR_gold;
fspan_DUT = FSR_DUT;
f_plot_gold = linspace(f_0_gold - fspan_gold/2, f_0_gold + fspan_gold/2, 10000);
f_plot_DUT = linspace(f_0_DUT - fspan_DUT/2, f_0_DUT + fspan_DUT/2, 10000);

P_gold_plot = ring_simulate_K(f_plot_gold, f_0_gold, R_real_gold, K1_gold, K2_gold, ng, neff, alpha_db_cm);
P_DUT_plot = ring_simulate_K(f_plot_DUT, f_0_DUT, R_real_DUT, K1_DUT, K2_DUT, ng, neff, alpha_db_cm);

ER_gold = ext_ratio(P_gold_plot);
ER_DUT = ext_ratio(P_DUT_plot);

% %% Plot Extintion Ratio Explanation
% figure;
% plot(f_plot/1e12, P_DUT_plot(:, 1), "Color", 'r', "LineWidth", 2); grid on;
% title('DUT Through Port', 'FontSize', 15);
% legend({'Through'}, 'Location', 'southeast', 'FontSize', 14);
% xlabel('Frequency [THz]', 'FontSize', 14);

%% Plot Gold vs DUT
figure;
% Gold standart transfer function plot
subplot(1, 2, 1);
plot(f_plot_gold/1e12, P_gold_plot(:, 1), "Color", 'r', "LineWidth", 2); hold on; grid on
plot(f_plot_gold/1e12, P_gold_plot(:, 2), "Color", 'b', "LineWidth", 2);
legend({'Through', 'Drop'}, 'Location', 'northwest', 'FontSize', 14);
xlabel('Frequency [THz]', 'FontSize', 14);
title('Gold Reference Transfer Function', 'FontSize', 15);

% DUT transfer function plot
subplot(1, 2, 2);
plot(f_plot_DUT/1e12, P_DUT_plot(:, 1), "Color", 'r', "LineWidth", 2); hold on; grid on;
plot(f_plot_DUT/1e12, P_DUT_plot(:, 2), "Color", 'b', "LineWidth", 2);
legend({'Through', 'Drop'}, 'Location', 'northwest', 'FontSize', 14);
xlabel('Frequency [THz]', 'FontSize', 14);
title('DUT Transfer Function', 'FontSize', 15);

%% --- Pre-allocate Arrays ---
Power_TT = zeros(1, length(P_sweep)); Power_DD = zeros(1, length(P_sweep));
Power_DT = zeros(1, length(P_sweep)); Power_TD = zeros(1, length(P_sweep));
H_TT = zeros(3, length(P_sweep));     H_DD = zeros(3, length(P_sweep));
H_DT = zeros(3, length(P_sweep));     H_TD = zeros(3, length(P_sweep));

P_DUT = ring_simulate_K(f, f_0_DUT, R_real_DUT, K1_DUT, K2_DUT, ng, neff, alpha_db_cm);       % P DUT

P_thru_DUT_coup = P_DUT(:, 1) .* gratingCoupler';
P_drop_DUT_coup = P_DUT(:, 2) .* gratingCoupler';

colors = {'b', 'r', 'g'};
harmonic_names = {'1f', '2f', '3f'};

% =========================================================================
% FIGURE 1: SPECTRA POWER TRACKING AND HARMONIC
% =========================================================================
fig_dashboard = figure('Name', 'Spectra, Power Dashboard and Harmonic analisys', 'Color', 'w', 'Position', [0, 20, 1920, 1000]);
% Row 1: Spectrums
ax_TT = subplot(4, 4, 1); plot(f/1e12, P_thru_DUT_coup, 'b', 'LineWidth', 1.5); hold on; plot(f/1e12, PSD_LED/max(PSD_LED), 'LineWidth', 2, 'Color', 'g'); h_DUT_TT = plot(f/1e12, NaN(size(f)), 'r', 'LineWidth', 1.5); h_prod_TT = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Through-Through'); grid on; ylim([0 1.1]); ylabel('Transmission');
ax_DD = subplot(4, 4, 2); plot(f/1e12, P_drop_DUT_coup, 'b', 'LineWidth', 1.5); hold on; plot(f/1e12, PSD_LED/max(PSD_LED), 'LineWidth', 2, 'Color', 'g'); h_DUT_DD = plot(f/1e12, NaN(size(f)), 'r', 'LineWidth', 1.5); h_prod_DD = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Drop-Drop'); grid on; ylim([0 1.1]);
ax_DT = subplot(4, 4, 3); plot(f/1e12, P_thru_DUT_coup, 'b', 'LineWidth', 1.5); hold on; plot(f/1e12, PSD_LED/max(PSD_LED), 'LineWidth', 2, 'Color', 'g'); h_DUT_DT = plot(f/1e12, NaN(size(f)), 'r', 'LineWidth', 1.5); h_prod_DT = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Drop-Through'); grid on; ylim([0 1.1]);
ax_TD = subplot(4, 4, 4); plot(f/1e12, P_drop_DUT_coup, 'b', 'LineWidth', 1.5); hold on; plot(f/1e12, PSD_LED/max(PSD_LED), 'LineWidth', 2, 'Color', 'g'); h_DUT_TD = plot(f/1e12, NaN(size(f)), 'r', 'LineWidth', 1.5); h_prod_TD = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Through-Drop'); grid on; ylim([0 1.1]);

% Row 2: Power Tracking
subplot(4, 4, 5); h_track_TT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: TT'); xlabel('Heater (mW)'); ylabel('Output (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(4, 4, 6); h_track_DD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: DD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(4, 4, 7); h_track_DT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: DT'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(4, 4, 8); h_track_TD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: TD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]);

% Row 3: Harmonics
subplot(4, 4, 9); hold on; for i=1:3, h_harm_TT(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: TT'); ylabel('Amp (mW)'); grid on; xlim([0 max(P_sweep)*1000]); legend(harmonic_names, 'Location', 'northwest');
subplot(4, 4, 10); hold on; for i=1:3, h_harm_DD(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: DD'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(4, 4, 11); hold on; for i=1:3, h_harm_DT(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: DT'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(4, 4, 12); hold on; for i=1:3, h_harm_TD(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: TD'); grid on; xlim([0 max(P_sweep)*1000]);

% Row 4: Ratios
ratio_limit = [-0.1 1.5]; 
subplot(4, 4, 13); h_ratio_TT = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: TT'); xlabel('Heater (mW)'); ylabel('Ratio'); grid on; xlim([0 max(P_sweep)*1000]); % ylim(ratio_limit);
subplot(4, 4, 14); h_ratio_DD = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: DD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); % ylim(ratio_limit);
subplot(4, 4, 15); h_ratio_DT = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: DT'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); % ylim(ratio_limit);
subplot(4, 4, 16); h_ratio_TD = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: TD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); % ylim(ratio_limit);


%% 5. Thermo-Optic Tuning Loop
fprintf('--- Starting Full Tuning Sweep ---\n');

for k = 1:length(P_sweep)
    P_base = P_sweep(k);
    
    dT_base = P_base * R_thermal;           
    neff_base = neff + (d_neff_th * dT_base);
    P_gold_base = ring_simulate_K(f, f_0_gold, R_real_gold, K1_gold, K2_gold, ng, neff_base, alpha_db_cm);
    
    P_thru_gold_coup = P_gold_base(:, 1) .* gratingCoupler';                % P GOLD
    P_drop_gold_coup = P_gold_base(:, 2) .* gratingCoupler';
    
    % Integrated powers
    Power_TT(k) = trapz(f, (P_thru_gold_coup .* P_thru_DUT_coup) .* PSD_LED');
    Power_DD(k) = trapz(f, (P_drop_gold_coup .* P_drop_DUT_coup) .* PSD_LED');
    Power_DT(k) = trapz(f, (P_drop_gold_coup .* P_thru_DUT_coup) .* PSD_LED');
    Power_TD(k) = trapz(f, (P_thru_gold_coup .* P_drop_DUT_coup) .* PSD_LED');
    
    % --- Time-Domain Dither Loop ---
    P_out_TT_dith = zeros(1, N_time); P_out_DD_dith = zeros(1, N_time);
    P_out_DT_dith = zeros(1, N_time); P_out_TD_dith = zeros(1, N_time);
    
    for t_idx = 1:N_time
        P_inst = P_base + A_dither * sin_1f(t_idx);
        dT_inst = P_inst * R_thermal;
        neff_inst = neff + (d_neff_th * dT_inst);
        P_gold_inst = ring_simulate_K(f, f_0_gold, R_real_gold, K1_gold, K2_gold, ng, neff_inst, alpha_db_cm);

        P_gold_inst_thru_coup = P_gold_inst(:, 1) .* gratingCoupler';       % P GOLD DITHER
        P_gold_inst_drop_coup = P_gold_inst(:, 2) .* gratingCoupler';
        
        P_out_TT_dith(t_idx) = trapz(f, (P_thru_DUT_coup .* P_gold_inst_thru_coup) .* PSD_LED');
        P_out_DD_dith(t_idx) = trapz(f, (P_drop_DUT_coup .* P_gold_inst_drop_coup) .* PSD_LED');
        P_out_DT_dith(t_idx) = trapz(f, (P_drop_DUT_coup .* P_gold_inst_thru_coup) .* PSD_LED');
        P_out_TD_dith(t_idx) = trapz(f, (P_thru_DUT_coup .* P_gold_inst_drop_coup) .* PSD_LED');
    end
    
    % % --- Demodulation Amplitude ---
    % H_TT(1, k) = 2 * sqrt(mean(P_out_TT_dith .* sin_1f)^2 + mean(P_out_TT_dith .* cos_1f)^2);
    % H_TT(2, k) = 2 * sqrt(mean(P_out_TT_dith .* sin_2f)^2 + mean(P_out_TT_dith .* cos_2f)^2);
    % H_TT(3, k) = 2 * sqrt(mean(P_out_TT_dith .* sin_3f)^2 + mean(P_out_TT_dith .* cos_3f)^2);
    % 
    % H_DD(1, k) = 2 * sqrt(mean(P_out_DD_dith .* sin_1f)^2 + mean(P_out_DD_dith .* cos_1f)^2);
    % H_DD(2, k) = 2 * sqrt(mean(P_out_DD_dith .* sin_2f)^2 + mean(P_out_DD_dith .* cos_2f)^2);
    % H_DD(3, k) = 2 * sqrt(mean(P_out_DD_dith .* sin_3f)^2 + mean(P_out_DD_dith .* cos_3f)^2);
    % 
    % H_DT(1, k) = 2 * sqrt(mean(P_out_DT_dith .* sin_1f)^2 + mean(P_out_DT_dith .* cos_1f)^2);
    % H_DT(2, k) = 2 * sqrt(mean(P_out_DT_dith .* sin_2f)^2 + mean(P_out_DT_dith .* cos_2f)^2);
    % H_DT(3, k) = 2 * sqrt(mean(P_out_DT_dith .* sin_3f)^2 + mean(P_out_DT_dith .* cos_3f)^2);
    % 
    % H_TD(1, k) = 2 * sqrt(mean(P_out_TD_dith .* sin_1f)^2 + mean(P_out_TD_dith .* cos_1f)^2);
    % H_TD(2, k) = 2 * sqrt(mean(P_out_TD_dith .* sin_2f)^2 + mean(P_out_TD_dith .* cos_2f)^2);
    % H_TD(3, k) = 2 * sqrt(mean(P_out_TD_dith .* sin_3f)^2 + mean(P_out_TD_dith .* cos_3f)^2);

    % --- Demodulation (In-Phase / Signed Amplitude) ---
    % 1f is in-phase with sin(wt) -> Proportional to 1st Derivative
    H_TT(1, k) = 2 * mean(P_out_TT_dith .* sin_1f);
    H_DD(1, k) = 2 * mean(P_out_DD_dith .* sin_1f);
    H_DT(1, k) = 2 * mean(P_out_DT_dith .* sin_1f);
    H_TD(1, k) = 2 * mean(P_out_TD_dith .* sin_1f);

    % 2f is in-phase with -cos(2wt) -> Proportional to 2nd Derivative
    H_TT(2, k) = -2 * mean(P_out_TT_dith .* cos_2f);
    H_DD(2, k) = -2 * mean(P_out_DD_dith .* cos_2f);
    H_DT(2, k) = -2 * mean(P_out_DT_dith .* cos_2f);
    H_TD(2, k) = -2 * mean(P_out_TD_dith .* cos_2f);

    % 3f is in-phase with -sin(3wt) -> Proportional to 3rd Derivative
    H_TT(3, k) = -2 * mean(P_out_TT_dith .* sin_3f);
    H_DD(3, k) = -2 * mean(P_out_DD_dith .* sin_3f);
    H_DT(3, k) = -2 * mean(P_out_DT_dith .* sin_3f);
    H_TD(3, k) = -2 * mean(P_out_TD_dith .* sin_3f);

    % --- Update Animation (Only if enabled) ---
    P_mw = P_sweep(1:k) * 1000; 
        
    % Update Figure 1
    h_DUT_TT.YData = P_thru_gold_coup; h_prod_TT.YData = P_thru_gold_coup .* P_thru_DUT_coup;
    h_track_TT.XData = P_mw; h_track_TT.YData = Power_TT(1:k) * 1000;
    title(ax_TT, sprintf('Through-Through | \\DeltaT: %.2f °C', dT_base));

    h_DUT_DD.YData = P_drop_gold_coup; h_prod_DD.YData = P_drop_gold_coup .* P_drop_DUT_coup;
    h_track_DD.XData = P_mw; h_track_DD.YData = Power_DD(1:k) * 1000;
    title(ax_DD, sprintf('Drop-Drop | \\DeltaT: %.2f °C', dT_base));

    % DT = Drop gold + Through DUT
    h_DUT_DT.YData = P_drop_gold_coup; h_prod_DT.YData = P_drop_gold_coup .* P_thru_DUT_coup; 
    h_track_DT.XData = P_mw; h_track_DT.YData = Power_DT(1:k) * 1000;
    title(ax_DT, sprintf('Drop-Through | \\DeltaT: %.2f °C', dT_base));

    % TD = Through gold + Drop DUT
    h_DUT_TD.YData = P_thru_gold_coup; h_prod_TD.YData = P_thru_gold_coup .* P_drop_DUT_coup;
    h_track_TD.XData = P_mw; h_track_TD.YData = Power_TD(1:k) * 1000;
    title(ax_TD, sprintf('Through-Drop | \\DeltaT: %.2f °C', dT_base));

    % Update Figure 2 (Harmonics and Ratios)
    for i=1:3
        h_harm_TT(i).XData = P_mw; h_harm_TT(i).YData = H_TT(i, 1:k) * 1000;
        h_harm_DD(i).XData = P_mw; h_harm_DD(i).YData = H_DD(i, 1:k) * 1000;
        h_harm_DT(i).XData = P_mw; h_harm_DT(i).YData = H_DT(i, 1:k) * 1000;
        h_harm_TD(i).XData = P_mw; h_harm_TD(i).YData = H_TD(i, 1:k) * 1000;
    end

    % Calculate Ratios safely (add eps to avoid exact 0 division)
    h_ratio_TT.XData = P_mw; h_ratio_TT.YData = H_TT(2, 1:k) ./ (H_TT(1, 1:k) + eps);
    h_ratio_DD.XData = P_mw; h_ratio_DD.YData = H_DD(2, 1:k) ./ (H_DD(1, 1:k) + eps);
    h_ratio_DT.XData = P_mw; h_ratio_DT.YData = H_DT(2, 1:k) ./ (H_DT(1, 1:k) + eps);
    h_ratio_TD.XData = P_mw; h_ratio_TD.YData = H_TD(2, 1:k) ./ (H_TD(1, 1:k) + eps);

    drawnow;
end

fprintf('Sweep complete.\n');

%% 6.5 Add Footer Text to Figure
% Construct the string with all simulation parameters
footer_str = sprintf(['\\lambda_0: %.0f nm, FSR_g: %.1f GHz, B_g: %.1f GHz, ' ...
    '\\alpha: %.1f dB/cm, R_{DUT}: %.1f um, A_{dith}: %.2f mW, ' ...
    '\\filterBW: %.1f GHz, \\gamma_{evan}: %.3f nm^{-1}, gap1: %.1f nm, gap2: %.1f nm'], ...
    lambda_0_DUT*1e9, ...           % lambda_0 in nm
    FSR_gold/1e9, ...                % FSR in GHz
    B_gold/1e9, ...                  % B in GHz
    alpha_db_cm, ...                 % Loss
    R_real_DUT*1e6, ...              % DUT Radius in um
    A_dither*1000, ...               % Dither in mW
    filter_BW/1e9, ...               % LED Sigma in GHz
    evan_gamma, ...                  % Evanescent gamma
    gap1, ...                        % Gap 1 error
    gap2);                           % Gap 2 error

% Add the annotation to the bottom of the figure
annotation(fig_dashboard, 'textbox', [0, 0.005, 1, 0.045], ...
    'String', footer_str, ...
    'Interpreter', 'tex', ...        % Forces Greek symbol rendering
    'EdgeColor', 'none', ...
    'BackgroundColor', 'w', ...      % White background blocks overlapping axes
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 12, ...              % Made slightly larger for 1920px width
    'FontWeight', 'bold', ...
    'Color', [0.2 0.2 0.2]);

%% 7. Export Dashboard Image
fprintf('Saving final dashboard image...\n');

% Define the file name (it will save in whatever folder you are currently running the script from)
image_filename = 'Full Dashboard (1550nm, FSR100G, B10G, alpha0, A_dith0.5m, sigma2FSR, 0nm, radius_err0nm).png';

% Use exportgraphics to save the figure handle we defined earlier.
% 'Resolution', 300 makes it high-definition (300 Dots Per Inch).
exportgraphics(fig_dashboard, image_filename, 'Resolution', 300);

fprintf('Image saved successfully as: %s\n', image_filename);

%% 8. Verify the Extintion Ratio

simPower = [Power_DT' , zeros(size(Power_DT'))];
ER_gold_DUT_conv = ext_ratio(simPower);

% Stamp the Extintion ratio values
fprintf('--- Extinction Ratio ---\n');
fprintf('Extinction Ratio - Gold:     %.2f dB\n', ER_gold);
fprintf('Extinction Ratio - DUT:      %.2f dB\n', ER_DUT);
fprintf('Extinction Ratio - Series:   %.2f dB\n', ER_gold_DUT_conv);

% Compute the convolution of the 2 ring transfer functions
fspan_gold = FSR_gold;
% Rename to f_plot_gold to match the rest of the script consistently
f_plot_gold = linspace(f_0_gold - fspan_gold/2, f_0_gold + fspan_gold/2, 10000); 

% Calculate frequency step (df) to scale the convolution properly
df = f_plot_gold(2) - f_plot_gold(1);

P_gold_plot = ring_simulate_K(f_plot_gold, f_0_gold, R_real_gold, K1_gold, K2_gold, ng, neff, alpha_db_cm);

% Assuming f_0_DUT and FSR_DUT are defined earlier in your code
P_DUT_plot = ring_simulate_K(f_plot_gold, f_0_DUT, R_real_DUT, K1_DUT, K2_DUT, ng, neff, alpha_db_cm);

%% --- NEW CONVOLUTION LOGIC ---
% 1. Limit the transfer function of the DUT to only one FSR_DUT around its center
% Create a logical mask (1 inside the window, 0 outside)
DUT_mask = (f_plot_gold >= (f_0_DUT - FSR_DUT)) & (f_plot_gold <= (f_0_DUT + FSR_DUT));

% Apply the mask (transpose DUT_mask to column vector if necessary)
P_DUT_limited_thru = P_DUT_plot(:, 1) .* DUT_mask'; 
P_DUT_limited_drop = P_DUT_plot(:, 2) .* DUT_mask';

% 2. Convolve the Drop port of Gold with Through and Drop of DUT
% Use 'same' to keep the output array exactly 10000 points long for plotting
conv_thru = conv(P_gold_plot(:, 2), P_DUT_limited_thru, 'same') * df;
conv_drop = conv(P_gold_plot(:, 2), P_DUT_limited_drop, 'same') * df;

% Create the new variable containing both
P_gold_DUT = [conv_thru, conv_drop];

% Optional: Normalize the convolution to a max of 1 so it plots nicely on the same Y-axis
P_gold_DUT(:, 1) = P_gold_DUT(:, 1) / max(P_gold_DUT(:, 1)) * 0.804;
P_gold_DUT(:, 2) = P_gold_DUT(:, 2) / max(P_gold_DUT(:, 2)) * 0.804;

%% Plot Gold vs DUT with Convolution
figure('Name', 'Ring Resonator Convolution Analysis', 'Color', 'w', 'Position', [100, 100, 1200, 500]);

% --- Gold Standard Transfer Function Plot ---
subplot(1, 2, 1);
plot(f_plot_gold/1e12, P_gold_plot(:, 1), "Color", 'r', "LineWidth", 2); hold on; grid on
plot(f_plot_gold/1e12, P_gold_plot(:, 2), "Color", 'b', "LineWidth", 2);
legend({'Through', 'Drop'}, 'Location', 'northwest', 'FontSize', 12);
xlabel('Frequency [THz]', 'FontSize', 14);
ylabel('Transmission', 'FontSize', 14);
title('Gold Reference Transfer Function', 'FontSize', 15);
ylim([0 1.1]);

% --- DUT Transfer Function Plot (+ Convolution) ---
subplot(1, 2, 2);
% Original DUT
plot(f_plot_gold/1e12, P_DUT_plot(:, 1), "Color", 'r', "LineWidth", 1.5, "LineStyle", "--"); hold on; grid on;
plot(f_plot_gold/1e12, P_DUT_plot(:, 2), "Color", 'b', "LineWidth", 1.5, "LineStyle", "--");

% Convolution Results (Plotted in Green)
plot(f_plot_gold/1e12, P_gold_DUT(:, 1), "Color", [0 0.8 0], "LineWidth", 2); % Darker green for visibility
plot(f_plot_gold/1e12, P_gold_DUT(:, 2), "Color", [0 1 0], "LineWidth", 2);   % Bright green

legend({'DUT Through', 'DUT Drop', 'Conv (Gold Drop * DUT Thru)', 'Conv (Gold Drop * DUT Drop)'}, ...
    'Location', 'northwest', 'FontSize', 11);
xlabel('Frequency [THz]', 'FontSize', 14);
title('DUT Transfer Function & Convolutions', 'FontSize', 15);
ylim([0 1.1]);