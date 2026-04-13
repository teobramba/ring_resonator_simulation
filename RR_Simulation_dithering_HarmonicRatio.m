%% PIC Simulation - Ring Resonator testing with Dithering & Ratio Analysis
% Matteo Brambilla - 2026
clear; clc; close all;
c = 299792458;                % Speed of light [m/s]

% --- Set to 'true' to watch animation, 'false' for max speed ---
enable_animation = true;

%% 1. User-Defined Parameters 
lambda_0_gold = 1550e-9;      f_0_gold = c / lambda_0_gold; 
FSR_gold = 100e9;             B_gold = 10e9;                
ng = 4.2;                     neff = 2.45;                  
gamma = 1;                    Ptot = 1e-3;                  

% Heating parameters
d_neff_th = 1.86e-4;          R_heater = 100;               
R_thermal = 1e3;              

%% 2. Design the RR
[FSR_real, R_real] = ring_design(lambda_0_gold, FSR_gold, ng, neff, B_gold);
fspan = 5 * FSR_gold;
f = linspace(f_0_gold - fspan/2, f_0_gold + fspan/2, 10000);
P_gold = ring_simulate(f, f_0_gold, R_real, B_gold, ng, neff, gamma);

%% 3. Define the "LED" Source Profile 
sigma_LED = 0.5 * FSR_gold; 
PSD_LED_shape = exp(-((f - f_0_gold).^2) / (2 * sigma_LED^2));
normalization_factor = Ptot / trapz(f, PSD_LED_shape);
PSD_LED = PSD_LED_shape * normalization_factor;

%% 4. Define the DUT and Setup Dashboards
R_error = 1e-6;          
R_DUT = R_real + R_error;   
P_sweep = linspace(0, 30e-3, 400); 

% --- Setup Dither Parameters ---
A_dither = 0.1e-3;             
n_cycles = 3;                  
N_time = 180;                   
phi_t = linspace(0, n_cycles * 2 * pi, N_time);

sin_1f = sin(phi_t);    cos_1f = cos(phi_t);
sin_2f = sin(2*phi_t);  cos_2f = cos(2*phi_t);
sin_3f = sin(3*phi_t);  cos_3f = cos(3*phi_t);


%% plot the sin(phi_t) signal
figure
plot(phi_t, A_dither*1000*sin_1f, 'LineWidth', 2);
xlabel('Phase (rad)', 'FontSize', 14);
ylabel('Power (mW)', 'FontSize', 14);
ylim([-0.13, 0.13]);
grid on
title('Dither Signal (sine)', 'FontSize', 16);

%%

% --- Pre-allocate Arrays ---
Power_TT = zeros(1, length(P_sweep)); Power_DD = zeros(1, length(P_sweep));
Power_DT = zeros(1, length(P_sweep)); Power_TD = zeros(1, length(P_sweep));
H_TT = zeros(3, length(P_sweep));     H_DD = zeros(3, length(P_sweep));
H_DT = zeros(3, length(P_sweep));     H_TD = zeros(3, length(P_sweep));

P_thru_gold = P_gold(:, 1); P_drop_gold = P_gold(:, 2);

colors = {'b', 'r', 'g'};
harmonic_names = {'1f', '2f', '3f'};

% =========================================================================
% FIGURE 1: SPECTRA AND POWER TRACKING
% =========================================================================
figure('Name', 'Spectra & Power Dashboard', 'Color', 'w', 'Position', [50, 450, 1600, 500]);
ax_TT = subplot(2, 4, 1); plot(f/1e12, P_thru_gold, 'r', 'LineWidth', 1.5); hold on; h_DUT_TT = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); h_prod_TT = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Through-Through'); grid on; ylim([0 1.1]); ylabel('Transmission');
ax_DD = subplot(2, 4, 2); plot(f/1e12, P_drop_gold, 'r', 'LineWidth', 1.5); hold on; h_DUT_DD = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); h_prod_DD = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Drop-Drop'); grid on; ylim([0 1.1]);
ax_DT = subplot(2, 4, 3); plot(f/1e12, P_drop_gold, 'r', 'LineWidth', 1.5); hold on; h_DUT_DT = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); h_prod_DT = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Drop-Through'); grid on; ylim([0 1.1]);
ax_TD = subplot(2, 4, 4); plot(f/1e12, P_thru_gold, 'r', 'LineWidth', 1.5); hold on; h_DUT_TD = plot(f/1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5); h_prod_TD = plot(f/1e12, NaN(size(f)), 'k', 'LineWidth', 2); title('Through-Drop'); grid on; ylim([0 1.1]);

subplot(2, 4, 5); h_track_TT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: TT'); xlabel('Heater (mW)'); ylabel('Output (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(2, 4, 6); h_track_DD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: DD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(2, 4, 7); h_track_DT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: DT'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(2, 4, 8); h_track_TD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); title('Power Track: TD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]);

% =========================================================================
% FIGURE 2: HARMONICS AND RATIOS (2x4 Grid)
% =========================================================================
figure('Name', 'Harmonic Ratio Analysis', 'Color', 'w', 'Position', [50, 50, 1600, 500]);
% Row 1: Harmonics
subplot(2, 4, 1); hold on; for i=1:3, h_harm_TT(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: TT'); ylabel('Amp (mW)'); grid on; xlim([0 max(P_sweep)*1000]); legend(harmonic_names, 'Location', 'northwest');
subplot(2, 4, 2); hold on; for i=1:3, h_harm_DD(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: DD'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(2, 4, 3); hold on; for i=1:3, h_harm_DT(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: DT'); grid on; xlim([0 max(P_sweep)*1000]);
subplot(2, 4, 4); hold on; for i=1:3, h_harm_TD(i) = plot(NaN, NaN, colors{i}, 'LineWidth', 1.5); end; title('Harmonics: TD'); grid on; xlim([0 max(P_sweep)*1000]);

% Row 2: Ratios
ratio_limit = [-0.1 1.5]; 
subplot(2, 4, 5); h_ratio_TT = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: TT'); xlabel('Heater (mW)'); ylabel('Ratio'); grid on; xlim([0 max(P_sweep)*1000]); ylim(ratio_limit);
subplot(2, 4, 6); h_ratio_DD = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: DD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); ylim(ratio_limit);
subplot(2, 4, 7); h_ratio_DT = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: DT'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); ylim(ratio_limit);
subplot(2, 4, 8); h_ratio_TD = plot(NaN, NaN, 'k', 'LineWidth', 1.5); title('Ratio 2f/1f: TD'); xlabel('Heater (mW)'); grid on; xlim([0 max(P_sweep)*1000]); ylim(ratio_limit);


%% 5. Thermo-Optic Tuning Loop
fprintf('--- Starting Full Tuning Sweep ---\n');

for k = 1:length(P_sweep)
    P_base = P_sweep(k);
    
    dT_base = P_base * R_thermal;           
    neff_base = neff + (d_neff_th * dT_base);
    P_DUT_base = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_base, gamma);
    
    P_thru_DUT = P_DUT_base(:, 1);
    P_drop_DUT = P_DUT_base(:, 2);
    
    % Standard integrated powers
    Power_TT(k) = trapz(f, (P_thru_gold .* P_thru_DUT) .* PSD_LED');
    Power_DD(k) = trapz(f, (P_drop_gold .* P_drop_DUT) .* PSD_LED');
    Power_DT(k) = trapz(f, (P_drop_gold .* P_thru_DUT) .* PSD_LED');
    Power_TD(k) = trapz(f, (P_thru_gold .* P_drop_DUT) .* PSD_LED');
    
    % --- Time-Domain Dither Loop ---
    P_out_TT_t = zeros(1, N_time); P_out_DD_t = zeros(1, N_time);
    P_out_DT_t = zeros(1, N_time); P_out_TD_t = zeros(1, N_time);
    
    for t_idx = 1:N_time
        P_inst = P_base + A_dither * sin_1f(t_idx);
        dT_inst = P_inst * R_thermal;
        neff_inst = neff + (d_neff_th * dT_inst);
        P_DUT_inst = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_inst, gamma);
        
        P_out_TT_t(t_idx) = trapz(f, (P_thru_gold .* P_DUT_inst(:, 1)) .* PSD_LED');
        P_out_DD_t(t_idx) = trapz(f, (P_drop_gold .* P_DUT_inst(:, 2)) .* PSD_LED');
        P_out_DT_t(t_idx) = trapz(f, (P_drop_gold .* P_DUT_inst(:, 1)) .* PSD_LED');
        P_out_TD_t(t_idx) = trapz(f, (P_thru_gold .* P_DUT_inst(:, 2)) .* PSD_LED');
    end
    
    % --- Demodulation ---
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

    % --- Update Animation (Only if enabled) ---
    if enable_animation
        P_mw = P_sweep(1:k) * 1000; 
        
        % Update Figure 1
        h_DUT_TT.YData = P_thru_DUT; h_prod_TT.YData = P_thru_gold .* P_thru_DUT;
        h_track_TT.XData = P_mw; h_track_TT.YData = Power_TT(1:k) * 1000;
        title(ax_TT, sprintf('Through-Through | \\DeltaT: %.2f °C', dT_base));

        h_DUT_DD.YData = P_drop_DUT; h_prod_DD.YData = P_drop_gold .* P_drop_DUT;
        h_track_DD.XData = P_mw; h_track_DD.YData = Power_DD(1:k) * 1000;
        title(ax_DD, sprintf('Drop-Drop | \\DeltaT: %.2f °C', dT_base));

        h_DUT_DT.YData = P_thru_DUT; h_prod_DT.YData = P_drop_gold .* P_thru_DUT;
        h_track_DT.XData = P_mw; h_track_DT.YData = Power_DT(1:k) * 1000;
        title(ax_DT, sprintf('Drop-Through | \\DeltaT: %.2f °C', dT_base));

        h_DUT_TD.YData = P_drop_DUT; h_prod_TD.YData = P_thru_gold .* P_drop_DUT;
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
end

fprintf('Sweep complete.\n');

%% 6. Final Plot Render (If animation was disabled)
if ~enable_animation
    fprintf('Rendering final graphs...\n');
    P_mw = P_sweep * 1000;
    
    % [Same assignment logic as Step D, applied to full arrays]
    h_DUT_TT.YData = P_thru_DUT; h_prod_TT.YData = P_thru_gold .* P_thru_DUT;
    h_track_TT.XData = P_mw; h_track_TT.YData = Power_TT * 1000;
    
    h_DUT_DD.YData = P_drop_DUT; h_prod_DD.YData = P_drop_gold .* P_drop_DUT;
    h_track_DD.XData = P_mw; h_track_DD.YData = Power_DD * 1000;
    
    h_DUT_DT.YData = P_thru_DUT; h_prod_DT.YData = P_drop_gold .* P_thru_DUT;
    h_track_DT.XData = P_mw; h_track_DT.YData = Power_DT * 1000;
    
    h_DUT_TD.YData = P_drop_DUT; h_prod_TD.YData = P_thru_gold .* P_drop_DUT;
    h_track_TD.XData = P_mw; h_track_TD.YData = Power_TD * 1000;
    
    for i=1:3
        h_harm_TT(i).XData = P_mw; h_harm_TT(i).YData = H_TT(i, :) * 1000;
        h_harm_DD(i).XData = P_mw; h_harm_DD(i).YData = H_DD(i, :) * 1000;
        h_harm_DT(i).XData = P_mw; h_harm_DT(i).YData = H_DT(i, :) * 1000;
        h_harm_TD(i).XData = P_mw; h_harm_TD(i).YData = H_TD(i, :) * 1000;
    end

    h_ratio_TT.XData = P_mw; h_ratio_TT.YData = H_TT(2, :) ./ (H_TT(1, :) + eps);
    h_ratio_DD.XData = P_mw; h_ratio_DD.YData = H_DD(2, :) ./ (H_DD(1, :) + eps);
    h_ratio_DT.XData = P_mw; h_ratio_DT.YData = H_DT(2, :) ./ (H_DT(1, :) + eps);
    h_ratio_TD.XData = P_mw; h_ratio_TD.YData = H_TD(2, :) ./ (H_TD(1, :) + eps);

    drawnow; 
    fprintf('Graphs rendered.\n');
end