function [FSR_real, R_real] = ring_design(lambda_0, FSR_target, ng, neff)
    % RING_DESIGN Calculates the exact physical geometry of a ring resonator
    %
    % Inputs:
    % lambda_0   : Target center wavelength [m]
    % FSR_target : Desired Free Spectral Range [Hz]
    % ng         : Group refractive index
    % neff       : Effective refractive index (nominal, unheated)
    %
    % Outputs:
    % FSR_real   : The actual FSR after adjusting to physical constraints [Hz]
    % R_real     : The physical radius of the ring [m]
    % m          : The integer mode number at the center wavelength

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
end