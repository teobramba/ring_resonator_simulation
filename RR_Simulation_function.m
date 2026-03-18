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
gamma = 0.99;                 % Round-trip amplitude transmission (1 = lossless)
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

fspan = 3 * FSR_gold;

% Define frequency range for simulation
f = linspace(f_0_gold - fspan/2, f_0_gold + fspan/2, 10000);

P_gold = ring_simulate(f, f_0_gold, R_real, B_gold, ng, neff, gamma); % [P_thru, P_drop]

% %% 3. Plot the through and drop power (Golden Reference)
% figure;
% plot(f, P_gold(:, 1), 'b-', 'LineWidth', 1.5); hold on;
% plot(f, P_gold(:, 2), 'r-', 'LineWidth', 1.5);
% xlabel('Frequency (Hz)');
% ylabel('Power (W)');
% title('Ring Resonator Transmission and Drop Power');
% legend('Through Power', 'Drop Power');
% grid on;


% %% 4. Define the DUT and Setup Animation Dashboard
% R_error = 10e-9;            % Lithography error on ring radius (10 nm)
% R_DUT = R_real + R_error;   % Physical radius of the DUT
% 
% % Power sweep vector: 0 to 30 mW in 100 steps
% P_sweep = linspace(0, 30e-3, 100); 
% Total_Power = zeros(size(P_sweep)); % Pre-allocate array for integrated power
% 
% % --- Combined Figure Setup ---
% figure('Color', 'w', 'Position', [100, 100, 1500, 700]);
% 
% % Left Subplot: Spectral Animation
% ax1 = subplot(1, 2, 1);
% plot(f / 1e12, P_gold(:, 1), 'b', 'LineWidth', 1.5); hold on;
% plot(f / 1e12, P_gold(:, 2), 'r', 'LineWidth', 1.5);
% 
% % Initialize DUT and Product plot handles
% h_thru_DUT = plot(f / 1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5);
% h_drop_DUT = plot(f / 1e12, NaN(size(f)), 'r--', 'LineWidth', 1.5);
% h_prod_DD  = plot(f / 1e12, NaN(size(f)), 'k', 'LineWidth', 2.5); 
% 
% xlabel('Frequency (THz)'); ylabel('Transmission');
% grid on; ylim([0 1.1]); xlim([min(f)/1e12 max(f)/1e12]);
% legend('Gold Thru', 'Gold Drop', 'DUT Thru', 'DUT Drop', 'Drop-Drop Product', ...
%     'Location', 'southoutside', 'NumColumns', 2);
% 
% % Right Subplot: Integrated Power Tracker
% ax2 = subplot(1, 2, 2);
% h_power_track = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
% xlabel('Heater Power (mW)');
% ylabel('Total Cascaded Output Power (mW)');
% title('Real-Time Power Integration');
% grid on; 
% xlim([0 max(P_sweep)*1000]); 
% ylim([0 Ptot*1000]); 
% 
% %% 5. Thermo-Optic Tuning Loop
% fprintf('--- Starting Tuning Sweep ---\n');
% P_dens = Ptot / fspan; % Power spectral density for the integral
% 
% for i = 1:length(P_sweep)
%     P = P_sweep(i);
% 
%     % 1. Electrical & Thermal Physics
%     dT = P * R_thermal;           
% 
%     % 2. Index Shift
%     neff_DUT = neff + (d_neff_th * dT);
% 
%     % 3. Simulate heated DUT
%     P_DUT = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_DUT, gamma);
% 
%     % 4. Compute Cascaded Product (Drop-Drop configuration)
%     P_DD = P_gold(:, 2) .* P_DUT(:, 2);
% 
%     % 5. Compute Integral of Power Spectral Density
%     Total_Power(i) = trapz(f, P_DD * P_dens);
% 
%     % 6. Update the Spectral Animation Plot
%     h_thru_DUT.YData = P_DUT(:, 1);
%     h_drop_DUT.YData = P_DUT(:, 2);
%     h_prod_DD.YData  = P_DD;
% 
%     % Update the title of the left subplot specifically
%     title(ax1, sprintf('Heat Power: %.2f mW | \\DeltaT: %.2f °C', P * 1000, dT));
% 
%     % 7. Update the Power Tracking Plot
%     h_power_track.XData = P_sweep(1:i) * 1000;         
%     h_power_track.YData = Total_Power(1:i) * 1000;     
% 
%     drawnow;
% end
% 
% %% 6. Post-Sweep Analysis
% % Find the exact power that generated the maximum output
% [max_power_out, max_idx] = max(Total_Power);
% optimal_heater_power = P_sweep(max_idx);
% 
% fprintf('Sweep complete.\n');
% fprintf('Optimal Heater Power to compensate 10nm error: %.2f mW\n', optimal_heater_power * 1000);
% fprintf('Maximum Recovered Output Power: %.2f mW\n', max_power_out * 1000);




%% 4. Define the DUT and Setup Full Dashboard
R_error = 2e-6;%113.578e-6/3;            % Lithography error on ring radius (10 nm)
R_DUT = R_real + R_error;   % Physical radius of the DUT

% Power sweep vector: 0 to 30 mW in 100 steps
P_sweep = linspace(0, 30e-3, 100); 
Total_Power = zeros(4, length(P_sweep)); % 4 rows to store data for TT, DD, DT, TD

% --- Combined Figure Setup ---
figure('Name', 'Full Port Permutation Dashboard', 'Color', 'w', 'Position', [50, 50, 1800, 850]);

% Mapping for the 4 permutations: [Gold_Port, DUT_Port]
% 1 = Through, 2 = Drop
port_map = [1, 1;   % 1: Through-Through
            2, 2;   % 2: Drop-Drop
            2, 1;   % 3: Drop-Through
            1, 2];  % 4: Through-Drop

titles = {'Through-Through', 'Drop-Drop', 'Drop-Through', 'Through-Drop'};

% Pre-allocate plot handles and axis arrays for the loop
h_DUT = cell(1, 4);
h_prod = cell(1, 4);
h_track = cell(1, 4);
ax_spectra = zeros(1, 4);

for i = 1:4
    % --- Top Row: Spectral Plots (Indices 1 to 4) ---
    ax_spectra(i) = subplot(2, 4, i);
    
    % Plot the static Golden standard line
    if port_map(i, 1) == 1
        plot(f / 1e12, P_gold(:, 1), 'b', 'LineWidth', 1.5); hold on;
        gold_name = 'Gold Thru';
    else
        plot(f / 1e12, P_gold(:, 2), 'r', 'LineWidth', 1.5); hold on;
        gold_name = 'Gold Drop';
    end
    
    % Initialize the dynamic DUT line (Start as NaN)
    if port_map(i, 2) == 1
        h_DUT{i} = plot(f / 1e12, NaN(size(f)), 'b--', 'LineWidth', 1.5);
        dut_name = 'DUT Thru';
    else
        h_DUT{i} = plot(f / 1e12, NaN(size(f)), 'r--', 'LineWidth', 1.5);
        dut_name = 'DUT Drop';
    end
    
    % Initialize the dynamic Product line
    h_prod{i} = plot(f / 1e12, NaN(size(f)), 'k', 'LineWidth', 2);
    
    title(ax_spectra(i), titles{i});
    xlabel('Frequency (THz)'); ylabel('Transmission');
    grid on; ylim([0 1.1]); xlim([min(f)/1e12 max(f)/1e12]);
    legend(gold_name, dut_name, 'Product', 'Location', 'southoutside', 'Orientation', 'horizontal');
    
    % --- Bottom Row: Power Integrations (Indices 5 to 8) ---
    subplot(2, 4, i + 4);
    h_track{i} = plot(NaN, NaN, 'k-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 4);
    title(['Power Tracking: ', titles{i}]);
    xlabel('Heater Power (mW)'); ylabel('Output Power (mW)');
    grid on;
    xlim([0 max(P_sweep)*1000]);

    %ylim([0, 1]);       % remove for autoscale
end

%% 5. Thermo-Optic Tuning Loop
fprintf('--- Starting Full Tuning Sweep ---\n');
P_dens = Ptot / fspan; % Power spectral density for the integral

for k = 1:length(P_sweep)
    P = P_sweep(k);
    
    % 1. Electrical & Thermal Physics
    dT = P * R_thermal;           
    neff_DUT = neff + (d_neff_th * dT);
    
    % 2. Simulate heated DUT
    P_DUT = ring_simulate(f, f_0_gold, R_DUT, B_gold, ng, neff_DUT, gamma);
    
    % 3. Update all 4 permutations simultaneously
    for i = 1:4
        % Extract the correct column (1 for Thru, 2 for Drop)
        gold_sig = P_gold(:, port_map(i, 1));
        dut_sig  = P_DUT(:, port_map(i, 2));
        
        % Compute Product and Integral
        prod_sig = gold_sig .* dut_sig;
        Total_Power(i, k) = trapz(f, prod_sig) * P_dens; 
        
        % Update Spectral Plot lines
        h_DUT{i}.YData = dut_sig;
        h_prod{i}.YData = prod_sig;
        
        % Update title to show current temperature shift (only on top row)
        title(ax_spectra(i), sprintf('%s\nHeat: %.2f mW | \\DeltaT: %.2f °C', titles{i}, P*1000, dT));
        
        % Update Power Tracking Plot lines
        h_track{i}.XData = P_sweep(1:k) * 1000;
        h_track{i}.YData = Total_Power(i, 1:k) * 1000;
    end
    
    % 4. Draw frames and Pause
    drawnow;
end

fprintf('Sweep complete.\n');