function TF = ring_simulate_K(f, f_ref, R, K1, K2, ng, neff, alpha_dB_cm)
    % RING_SIMULATE_K Computes the MRR transfer function using power coupling coefficients
    %
    % Inputs:
    % f           : Frequency vector for the simulation [Hz]
    % f_ref       : Reference frequency (usually center of your span) [Hz]
    % R           : Physical radius of the ring [m]
    % K1          : Power coupling coefficient of the input coupler (0 to 1)
    % K2          : Power coupling coefficient of the output coupler (0 to 1)
    % ng          : Group index (determines FSR)
    % neff        : Effective index at f_ref (determines absolute resonance position)
    % alpha_dB_cm : Propagation loss in the ring [dB/cm]
    %
    % Outputs:
    % TF          : Array with 2 columns -> [Through_Power, Drop_Power]
    
    % Constants and Geometry
    c = 299792458;          % Speed of light [m/s]
    L = 2 * pi * R;         % Physical circumference of the ring [m]
    
    % 1. Calculate the actual FSR for this specific physical ring
    FSR = c / (ng * L);     % Free Spectral Range [Hz]
    
    % 2. Derive Field Coupling Coefficients
    % Assuming lossless point-couplers, |t|^2 + |kappa|^2 = 1
    t1 = sqrt(1 - K1);      % Self-coupling field coefficient (input)
    t2 = sqrt(1 - K2);      % Self-coupling field coefficient (output)
    kappa1 = sqrt(K1);      % Cross-coupling field coefficient (input)
    kappa2 = sqrt(K2);      % Cross-coupling field coefficient (output)
    
    % 3. Loss Calculation
    % Convert loss from dB/cm to a round-trip field amplitude transmission factor (alpha_coeff)
    % L * 100 converts the length from meters to centimeters
    alpha_coeff = 10^(-(alpha_dB_cm * (L * 100)) / 20); 
    
    % 4. Calculate Absolute Round-Trip Phase
    % Phase at the reference frequency
    phi_0 = (2 * pi * f_ref / c) * neff * L;
    
    % Phase variation across the frequency sweep using the group index (via FSR)
    phi_dispersion = 2 * pi * (f - f_ref) / FSR;
    
    % Total absolute phase
    phi = phi_0 + phi_dispersion;
    
    % 5. Compute Complex Transfer Functions
    % Common denominator for add-drop configuration
    den = 1 - t1 * t2 * alpha_coeff * exp(1i * phi);
    
    % Through port (Notch response)
    num_thru = t1 - t2 * alpha_coeff * exp(1i * phi);
    E_thru = num_thru ./ den;
    
    % Drop port (Bandpass response)
    num_drop = -kappa1 * kappa2 * sqrt(alpha_coeff) * exp(1i * phi / 2);
    E_drop = num_drop ./ den;
    
    % 6. Return powers as a two-column matrix
    % Using (:) ensures the output is strictly column-oriented
    TF = [abs(E_thru(:)).^2, abs(E_drop(:)).^2];
end