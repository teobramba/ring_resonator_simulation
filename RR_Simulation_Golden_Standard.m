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
Ptot = 1e-3;                  % Total input power [W]

%% 2. Derived Physical Parameters - Golden Standard
L_gold_theotical = c / (ng * FSR_gold);           % Ring circumference [m]

m = neff * L_gold_theotical / lambda_0_gold;      % Resonance harmonic
m = floor(m);                                     % Round m to integer

L_gold = lambda_0_gold * m / neff;
FSR_gold = c / (ng * L_gold);

R_gold = L_gold / (2 * pi);                       % Ring radius [m]

% Calculate the transmission and coupling coefficients
p = pi * B_gold / FSR_gold;
r = (-p + sqrt(p^2 + 4)) / 2;
t = sqrt(1 - r^2);

fprintf('--- Golden Standard ---\n');
fprintf('Gold FSR: %.3f GHz\n', FSR_gold / 1e9);
fprintf('Gold Ring Radius: %.2f um\n', R_gold * 1e6);
fprintf('Required Transmission (r): %.4f\n', r);
fprintf('Required Coupling (t): %.4f\n\n', t);

%% 3. Frequency Vector Setup
f_span = 6 * FSR_gold;
f = linspace(f_0_gold - f_span/2, f_0_gold + f_span/2, 10000); 
phi_gold = 2 * pi * (f - f_0_gold) / FSR_gold;

%% 4. Transfer Function Calculation - Golden Standard
E_thru_gold = (r - r * gamma * exp(1i * phi_gold)) ./ (1 - r^2 * gamma * exp(1i * phi_gold));
P_thru_gold = abs(E_thru_gold).^2;

E_drop_gold = (-t^2 * sqrt(gamma) * exp(1i * phi_gold / 2)) ./ (1 - gamma * r^2 * exp(1i * phi_gold));
P_drop_gold = abs(E_drop_gold).^2;


%% 5. Transfer function definition - DUT
% Define the physical fabrication error
R_error = 10e-9;                  % Lithography radius error [m] (10 nm)
R_DUT = R_gold + R_error;         % DUT Ring radius [m]
L_DUT = 2 * pi * R_DUT;           % DUT Ring circumference [m]

% 1. Compute the new Center Frequency and Wavelength based on geometry
lambda_0_DUT = lambda_0_gold * (L_DUT / L_gold);

f_0_DUT = c / lambda_0_DUT; 

% Calculate the exact wavelength shift for our own awareness
lambda_shift = lambda_0_DUT - lambda_0_gold;
f_shift = f_0_DUT - f_0_gold;

% 2. Compute the new FSR
FSR_DUT = c / (ng * L_DUT);

fprintf('--- Device Under Test (DUT) ---\n');
fprintf('DUT FSR: %.3f GHz\n', FSR_DUT / 1e9);
fprintf('DUT Ring Radius: %.2f um\n', R_DUT * 1e6);
fprintf('Calculated Wavelength Shift: %.2f nm\n', lambda_shift * 1e9);
fprintf('Calculated Frequency Shift: %.2f GHz\n\n', f_shift / 1e9);


%% 6. Transfer Function Calculation - DUT
phi_DUT = 2 * pi * (f - f_0_DUT) / FSR_DUT;

E_thru_DUT = (r - r * gamma * exp(1i * phi_DUT)) ./ (1 - r^2 * gamma * exp(1i * phi_DUT));
P_thru_DUT = abs(E_thru_DUT).^2;

E_drop_DUT = (-t^2 * sqrt(gamma) * exp(1i * phi_DUT / 2)) ./ (1 - gamma * r^2 * exp(1i * phi_DUT));
P_drop_DUT = abs(E_drop_DUT).^2;


%% 7. Cascaded Configurations & Power Integration

% Configuration 1: Through Gold + Through DUT
P_TT = P_thru_gold .* P_thru_DUT;

% Configuration 2: Drop Gold + Drop DUT
P_DD = P_drop_gold .* P_drop_DUT;

% Configuration 3: Drop Gold + Through DUT
P_DT = P_drop_gold .* P_thru_DUT;

% Configuration 4: Through Gold + Drop DUT
P_TD = P_thru_gold .* P_drop_DUT;


%% 8. Plotting
figure();

% --- Plot 1: Through-Through ---
subplot(2,2,1);
plot(f/1e12, P_thru_gold, 'b--', f/1e12, P_thru_DUT, 'r--', f/1e12, P_TT, 'k', 'LineWidth', 1.5);
title(['Through-Through']);
ylabel('Transmission'); grid on;
legend('Gold', 'DUT', 'Product');

% --- Plot 2: Drop-Drop ---
subplot(2,2,2);
plot(f/1e12, P_drop_gold, 'b--', f/1e12, P_drop_DUT, 'r--', f/1e12, P_DD, 'k', 'LineWidth', 1.5);
title(['Drop-Drop']);
grid on;
legend('Gold', 'DUT', 'Product');

% --- Plot 3: Drop-Through ---
subplot(2,2,3);
plot(f/1e12, P_drop_gold, 'b--', f/1e12, P_thru_DUT, 'r--', f/1e12, P_DT, 'k', 'LineWidth', 1.5);
title(['Drop Gold + Thru DUT']);
xlabel('Frequency (THz)'); ylabel('Transmission'); grid on;
legend('Gold Drop', 'DUT Thru', 'Product');

% --- Plot 4: Through-Drop ---
subplot(2,2,4);
plot(f/1e12, P_thru_gold, 'b--', f/1e12, P_drop_DUT, 'r--', f/1e12, P_TD, 'k', 'LineWidth', 1.5);
title(['Thru Gold + Drop DUT']);
xlabel('Frequency (THz)'); grid on;
legend('Gold Thru', 'DUT Drop', 'Product');

%% 9. Terminal Output

P_dens = Ptot / f_span;                     % Power spectral density

Power_TT = trapz(f, P_TT * P_dens);
Power_DD = trapz(f, P_DD * P_dens);
Power_DT = trapz(f, P_DT * P_dens);
Power_TD = trapz(f, P_TD * P_dens);

fprintf('--- Integrated Power Summary ---\n');
fprintf('Input Power:     %.3f mW\n', Ptot * 1e3);
fprintf('Through-Through: %.3f mW\n', Power_TT * 1e3);
fprintf('Drop-Drop:       %.3f mW\n', Power_DD * 1e3);
fprintf('Drop-Through:    %.3f mW\n', Power_DT * 1e3);
fprintf('Through-Drop:    %.3f mW\n\n', Power_TD * 1e3);