function [FSR_real, R_real, K1, K2, alpha_crit_dB_cm] = ring_design(lambda_0, FSR_target, ng, neff, B)
    % RING_DESIGN Calculates the exact physical geometry and coupling 
    % parameters of a symmetric add-drop ring resonator.
    %
    % Inputs:
    % lambda_0   : Target center wavelength [m]
    % FSR_target : Desired Free Spectral Range [Hz]
    % ng         : Group refractive index
    % neff       : Effective refractive index (nominal, unheated)
    % B          : Desired bandwidth (FWHM) [Hz]
    %
    % Outputs:
    % FSR_real         : The actual FSR after adjusting to physical constraints [Hz]
    % R_real           : The physical radius of the ring [m]
    % K1               : Power coupling coefficient of the input coupler
    % K2               : Power coupling coefficient of the output coupler
    % alpha_crit_dB_cm : The ideal waveguide loss (dB/cm) required to critically 
    %                    couple K1, assuming an All-Pass configuration.
    
    c = 299792458; % Speed of light [m/s]
    
    % 1. Calculate approximate circumference based on target FSR
    L_approx = c / (ng * FSR_target);
    
    % 2. Calculate the theoretical mode number and force it to an integer
    m_theoretical = (neff * L_approx) / lambda_0;
    m = round(m_theoretical);
    
    % 3. Calculate the true physical circumference and radius
    L_real = (m * lambda_0) / neff;
    R_real = L_real / (2 * pi);
    
    % 4. Calculate the true FSR based on the physical length
    FSR_real = c / (ng * L_real);
    
    % 5. Calculate Power Coupling Coefficients (K1, K2)
    p = pi * B / FSR_real; % Dimensionless bandwidth parameter
    
    % Solve quadratic equation for field transmission coefficient (t)
    t = (-p + sqrt(p^2 + 4)) / 2;
    
    % Convert field transmission (t) to power coupling (K)
    K = 1 - t^2;
    
    % Assign to symmetric couplers
    K1 = K;
    K2 = K;
    
    % 6. Calculate Critical Coupling Attenuation (All-Pass Assumption, modulators only)
    L_cm = L_real * 100;
    
    % Calculate required loss in dB/cm
    alpha_crit_dB_cm = -20 * log10(t) / L_cm;
    
end