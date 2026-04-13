function TF = ring_simulate(f, f_ref, R, B, ng, neff, gamma)
    % RING_SIMULATE Computes the transfer function using absolute phase
    %
    % Inputs:
    % f            : Frequency vector for the simulation [Hz]
    % f_ref        : Reference frequency (usually center of your span) [Hz]
    % R            : Physical radius of the ring [m]
    % B            : Desired bandwidth (FWHM) [Hz]
    % ng           : Group index (determines FSR)
    % neff_current : Current effective index (can include thermo-optic shifts)
    % gamma        : Round-trip amplitude transmission (1 = lossless)
    %
    % Outputs:
    % TF           : Array with 2 columns -> [Through_Power, Drop_Power]
    
    c = 299792458; 
    L = 2 * pi * R; % Physical circumference
    
    % 1. Calculate the actual FSR for this specific physical ring
    FSR = c / (ng * L);
    
    % 2. Calculate coupling coefficients required to hit the target Bandwidth
    p = pi * B / FSR;
    r = (-p + sqrt(p^2 + 4)) / 2;   % field coupling coefficient
    t = sqrt(1 - r^2);
    
    % 3. Calculate Absolute Round-Trip Phase
    % Phase at the reference frequency
    phi_0 = (2 * pi * f_ref / c) * neff * L;
    
    % Phase variation across the frequency sweep
    phi_dispersion = 2 * pi * (f - f_ref) / FSR;
    
    % Total absolute phase
    phi = phi_0 + phi_dispersion;
    
    % 4. Compute Complex Transfer Functions
    E_thru = (r - r * gamma * exp(1i * phi)) ./ (1 - r^2 * gamma * exp(1i * phi));
    E_drop = (-t^2 * sqrt(gamma) * exp(1i * phi / 2)) ./ (1 - gamma * r^2 * exp(1i * phi));
    
    % 5. Return powers as a two-column matrix
    TF = [abs(E_thru(:)).^2, abs(E_drop(:)).^2];
end