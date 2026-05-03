%% PIC Simulation - Single Ring Resonator Analisys
% Matteo Brambilla - 2026

clear; clc; close all;
c = 299792458;                % Speed of light [m/s]

%% 1. User-Defined Parameters 
lambda_0 = 1310e-9;        f_0 = c / lambda_0;
FSR = 1000e9;              B = 1e9;
ng = 4.2;                  neff = 2.45;
alpha_db_cm = 2;

%% 2. Design the RR
% Ring Resonator parameters
[FSR_real, R_real, K1, K2] = ring_design(lambda_0, FSR, ng, neff, B);
K1 = K1 + 0.8*K1;
fprintf('--- Ring characteristics ---\n');
fprintf('FSR:               %.2f GHz\n', FSR_real/1e9);
fprintf('BW:                %.2f GHz\n', B/1e9);
fprintf('Radius:            %.2f um\n', R_real*1e6);
fprintf('Coupling:          %.3f \n\n', K1);
fspan = FSR_real;
f_plot = linspace(f_0 - fspan/2, f_0 + fspan/2, 10000);

% Simulate the ring 
P_RR = ring_simulate_K(f_plot, f_0, R_real, K1, K2, ng, neff, alpha_db_cm);

%% 3. Plot RR transfer function
figure;
subplot(2, 1, 1);
plot(f_plot/1e12, P_RR(:, 1), "Color", 'r', "LineWidth", 2); hold on; grid on
plot(f_plot/1e12, P_RR(:, 2), "Color", 'b', "LineWidth", 2);
legend({'Through', 'Drop'}, 'Location', 'northwest', 'FontSize', 14);
xlabel('Frequency [THz]', 'FontSize', 14);
title('Ring Resonator Transfer Function', 'FontSize', 15);

xlim([(f_0 - 5*B)/1e12, (f_0 + 5*B)/1e12]); % limit the plot frtequency span

%% 4. Transmitter Penalty (TP) Calculation and Plotting
delta_mod = 1e9;

% Call the custom function
[TP, min_indices, ER_array] = transmit_penality(f_plot, P_RR, delta_mod);

% Switch to right Y-axis for the decibel scale
yyaxis right; 

%% Plot the TP function
plot(f_plot/1e12, TP, "Color", 'g', "LineWidth", 1);
ylabel('Transmitter Penalty [dB]', 'FontSize', 14);
ylim([0 20]); 

fprintf('--- Transmitter Penalty Minima ---\n');
fprintf('Frequency shift:  %.2f GHz\n', delta_mod/1e9);

% Loop through the found minima to plot the lines and print the values
for k = 1:length(min_indices)
    idx = min_indices(k);
    
    % Get the precise frequency, TP, and ER values directly from the arrays
    min_freq = f_plot(idx); 
    min_TP_val = TP(idx);
    min_ER_val = ER_array(idx); % Extract the ER exactly at the optimum point
    
    % Print the values
    fprintf('Minimum %d:        %.4f THz (TP = %.2f dB, ER = %.2f dB)\n', k, min_freq/1e12, min_TP_val, min_ER_val);
    
    % Draw a vertical line where minimum ER is
    xline(min_freq/1e12, "Color", "#7E2F8E", "LineWidth", 1.5, "LineStyle", "--");
end
fprintf('\n');

% Update the legend
legend({'Through', 'Drop', 'TP', 'TP Minima'}, 'Location', 'northwest', 'FontSize', 14);

subplot(2, 1, 2);
plot(f_plot/1e12, P_RR(:, 1), "Color", 'r', "LineWidth", 2); hold on; grid on       % Plot the Through port
% plot(f_plot/1e12, ER_array/20, "Color", 'b', "LineWidth", 2);                     % Plot the Extintion Ratio

% Draw a vertical dashed line where minimum ER is
min_freq = f_plot(min_indices(1));          % Find the frequency of the first Transmission Penality minima
xline(min_freq/1e12, "Color", "#7E2F8E", "LineWidth", 1.5, "LineStyle", "--");                      % Transmission Penality Minima
xline(min_freq/1e12 - (delta_mod/1e12)/2, "Color", "g", "LineWidth", 1.5, "LineStyle", "--");       % Minimum modulation freq
xline(min_freq/1e12 + (delta_mod/1e12)/2, "Color", "g", "LineWidth", 1.5, "LineStyle", "--");       % Maximum modulation freq
xlim([(f_0 - 3*B)/1e12, (f_0 + 3*B)/1e12]);
legend({'Through', 'TP Minima', 'Lower Freq', 'Upper Freq'}, 'Location', 'northwest', 'FontSize', 14);
xlabel('Frequency [THz]', 'FontSize', 14);
title('Ring Resonator Transfer Function', 'FontSize', 15);
