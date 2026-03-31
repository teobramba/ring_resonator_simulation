%% PIC Simulation - Ring Resonator testing with Golden standard vs DUT

% Matteo Brambilla - 2026

clear; clc; close all;
c = 299792458;           % Speed of light [m/s]

%% 1. User-Defined Parameters - Golden standard
lambda_0_gold = 1550e-9;      % Center wavelength [m]
f_0_gold = c / lambda_0_gold; % Center frequency [Hz]
FSR_gold = 100e9;             % Free Spectral Range [Hz] (100 GHz)
B_gold = 10e9;                % Full Width at Half Maximum [Hz] (10 GHz)
ng = 4.2;                     % Group index (typical for Silicon on Insulator)
neff = 2.45;                  % Effective refractive index (typical for 450nm guide)
gamma = 1;                    % Round-trip amplitude transmission (1 = lossless)
Ptot = 1e-3;                  % Total optical input power [1 mW]

% Heating parameters
d_neff_th = 1.86e-4;          % neff temperature sensitivity
R_heater = 100;               % Heater resistance
R_thermal = 1e3;              % Thermal resistance, [1K/mW]


%% 2. Design the RR
[FSR_real, R_real] = ring_design(lambda_0_gold, FSR_gold, ng, neff);
fprintf('--- Ring Parameters ---\n');
fprintf('FSR_real:     %.3f GHz\n', FSR_real/1e9);
fprintf('Real Radius:  %.3f um\n\n', R_real*1e6);

fspan = 5 * FSR_gold;

% Define frequency range for simulation
f = linspace(f_0_gold - fspan/2, f_0_gold + fspan/2, 10000);

P_gold = ring_simulate(f, f_0_gold, R_real, B_gold, ng, neff, gamma); % [P_thru, P_drop]


%% --- Define the "LED" Source Profile ---

% Source standard deviation (sigma) as function of gold FSR
sigma_LED = 0.5 * FSR_gold; 

% Create the unnormalized Gaussian shape centered at f_0_gold
PSD_LED_shape = exp(-((f - f_0_gold).^2) / (2 * sigma_LED^2));

% Normalize it so the total area under the LED curve equals Ptot (1 mW)
% Integrate the shape using trapz to find its current arbitrary area,
% then divide by that area and multiply by our desired total power.
normalization_factor = Ptot / trapz(f, PSD_LED_shape);
PSD_LED = PSD_LED_shape * normalization_factor;

% Plot the LED spectrum just to verify it looks correct
figure('Name', 'LED Input Spectrum', 'Color', 'w');
plot(f / 1e12, PSD_LED, 'k', 'LineWidth', 2);
title('Tapered LED Input Power Spectral Density');
xlabel('Frequency (THz)'); ylabel('Power Density (W/Hz)'); grid on;


%% 4. Define the DUT and Setup Full Dashboard
R_error = 1000e-9;            % Lithography error on ring radius
R_DUT = R_real + R_error;   % Physical radius of the DUT

% Power sweep vector: 0 to 30 mW in 100 steps
P_sweep = linspace(0, 30e-3, 100); 

% --- Pre-allocate (create empty arrays to save memory) 2D arrays for all PSDs ---
% Each matrix holds the PSD for all frequencies (rows) at every sweep step (columns)
PSD_TT = zeros(length(f), length(P_sweep));
PSD_DD = zeros(length(f), length(P_sweep));
PSD_DT = zeros(length(f), length(P_sweep));
PSD_TD = zeros(length(f), length(P_sweep));

% Pre-allocate arrays for the total integrated power
Power_TT = zeros(1, length(P_sweep));
Power_DD = zeros(1, length(P_sweep));
Power_DT = zeros(1, length(P_sweep));
Power_TD = zeros(1, length(P_sweep));

% Split Golden Standard into named variables
P_thru_gold = P_gold(:, 1);
P_drop_gold = P_gold(:, 2);

% --- Combined Figure Setup ---
figure('Name', 'Full Port Permutation Dashboard', 'Color', 'w', 'Position', [50, 50, 1400, 700]);

% 1. Setup Through-Through (Column 1)
ax_TT = subplot(2, 4, 1);
plot(f / 1e12, P_thru_gold, 'r', 'LineWidth', 1.5); hold on;
h_DUT_TT  = plot(f / 1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5);
h_prod_TT = plot(f / 1e12, NaN(size(f)), 'k', 'LineWidth', 2);
title('Through-Through'); xlabel('Frequency (THz)'); ylabel('Transmission'); grid on; ylim([0 1.1]);
legend('Gold Thru', 'DUT Thru', 'Product', 'Location', 'southoutside', 'Orientation', 'horizontal');

subplot(2, 4, 5);
h_track_TT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4);
title('Power Tracking: TT'); xlabel('Heater Power (mW)'); ylabel('Output Power (mW)'); grid on; xlim([0 max(P_sweep)*1000]);

% 2. Setup Drop-Drop (Column 2)
ax_DD = subplot(2, 4, 2);
plot(f / 1e12, P_drop_gold, 'r', 'LineWidth', 1.5); hold on;
h_DUT_DD  = plot(f / 1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5);
h_prod_DD = plot(f / 1e12, NaN(size(f)), 'k', 'LineWidth', 2);
title('Drop-Drop'); xlabel('Frequency (THz)'); ylabel('Transmission'); grid on; ylim([0 1.1]);
legend('Gold Drop', 'DUT Drop', 'Product', 'Location', 'southoutside', 'Orientation', 'horizontal');

subplot(2, 4, 6);
h_track_DD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4);
title('Power Tracking: DD'); xlabel('Heater Power (mW)'); ylabel('Output Power (mW)'); grid on; xlim([0 max(P_sweep)*1000]);

% 3. Setup Drop-Through (Column 3)
ax_DT = subplot(2, 4, 3);
plot(f / 1e12, P_drop_gold, 'r', 'LineWidth', 1.5); hold on;
h_DUT_DT  = plot(f / 1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5);
h_prod_DT = plot(f / 1e12, NaN(size(f)), 'k', 'LineWidth', 2);
title('Drop-Through'); xlabel('Frequency (THz)'); ylabel('Transmission'); grid on; ylim([0 1.1]);
legend('Gold Drop', 'DUT Thru', 'Product', 'Location', 'southoutside', 'Orientation', 'horizontal');

subplot(2, 4, 7);
h_track_DT = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4);
title('Power Tracking: DT'); xlabel('Heater Power (mW)'); ylabel('Output Power (mW)'); grid on; xlim([0 max(P_sweep)*1000]);

% 4. Setup Through-Drop (Column 4)
ax_TD = subplot(2, 4, 4);
plot(f / 1e12, P_thru_gold, 'r', 'LineWidth', 1.5); hold on;
h_DUT_TD  = plot(f / 1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5);
h_prod_TD = plot(f / 1e12, NaN(size(f)), 'k', 'LineWidth', 2);
title('Through-Drop'); xlabel('Frequency (THz)'); ylabel('Transmission'); grid on; ylim([0 1.1]);
legend('Gold Thru', 'DUT Drop', 'Product', 'Location', 'southoutside', 'Orientation', 'horizontal');

subplot(2, 4, 8);
h_track_TD = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4);
title('Power Tracking: TD'); xlabel('Heater Power (mW)'); ylabel('Output Power (mW)'); grid on; xlim([0 max(P_sweep)*1000]);

%% 5. Thermo-Optic Tuning Loop
fprintf('--- Starting Full Tuning Sweep ---\n');
P_dens = Ptot / fspan; % Base Power Spectral Density (W/Hz)

for k = 1:length(P_sweep)
    P = P_sweep(k);
    
    % --- Physics Calculation ---
    dT = P * R_thermal;           
    neff_DUT = neff + (d_neff_th * dT);
    P_DUT = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_DUT, 0.9);
    
    % Split DUT into named variables
    P_thru_DUT = P_DUT(:, 1);
    P_drop_DUT = P_DUT(:, 2);
    
    % ==========================================
    % 1. Compute Through-Through (TT)
    % ==========================================
    prod_TT = P_thru_gold .* P_thru_DUT;
    % PSD_TT(:, k) = prod_TT * P_dens;
     PSD_TT(:, k) = prod_TT .* PSD_LED';
    Power_TT(k) = trapz(f, PSD_TT(:, k));
    
    h_DUT_TT.YData  = P_thru_DUT;
    h_prod_TT.YData = prod_TT;
    h_track_TT.XData = P_sweep(1:k) * 1000;
    h_track_TT.YData = Power_TT(1:k) * 1000;
    title(ax_TT, sprintf('Through-Through\nHeat: %.2f mW | \\DeltaT: %.2f °C', P*1000, dT));

    % ==========================================
    % 2. Compute Drop-Drop (DD)
    % ==========================================
    prod_DD = P_drop_gold .* P_drop_DUT;
    % PSD_DD(:, k) = prod_DD * P_dens;
     PSD_DD(:, k) = prod_DD .* PSD_LED';
    Power_DD(k) = trapz(f, PSD_DD(:, k));
    
    h_DUT_DD.YData  = P_drop_DUT;
    h_prod_DD.YData = prod_DD;
    h_track_DD.XData = P_sweep(1:k) * 1000;
    h_track_DD.YData = Power_DD(1:k) * 1000;
    title(ax_DD, sprintf('Drop-Drop\nHeat: %.2f mW | \\DeltaT: %.2f °C', P*1000, dT));

    % ==========================================
    % 3. Compute Drop-Through (DT)
    % ==========================================
    prod_DT = P_drop_gold .* P_thru_DUT;
    % PSD_DT(:, k) = prod_DT * P_dens;
     PSD_DT(:, k) = prod_DT .* PSD_LED';
    Power_DT(k) = trapz(f, PSD_DT(:, k));
    
    h_DUT_DT.YData  = P_thru_DUT;
    h_prod_DT.YData = prod_DT;
    h_track_DT.XData = P_sweep(1:k) * 1000;
    h_track_DT.YData = Power_DT(1:k) * 1000;
    title(ax_DT, sprintf('Drop-Through\nHeat: %.2f mW | \\DeltaT: %.2f °C', P*1000, dT));

    % ==========================================
    % 4. Compute Through-Drop (TD)
    % ==========================================
    prod_TD = P_thru_gold .* P_drop_DUT;
    %PSD_TD(:, k) = prod_TD * P_dens;
     PSD_TD(:, k) = prod_TD .* PSD_LED';
    Power_TD(k) = trapz(f, PSD_TD(:, k));
    
    h_DUT_TD.YData  = P_drop_DUT;
    h_prod_TD.YData = prod_TD;
    h_track_TD.XData = P_sweep(1:k) * 1000;
    h_track_TD.YData = Power_TD(1:k) * 1000;
    title(ax_TD, sprintf('Through-Drop\nHeat: %.2f mW | \\DeltaT: %.2f °C', P*1000, dT));

    % --- Update Animation ---
    drawnow;
end

fprintf('Sweep complete.\n');
