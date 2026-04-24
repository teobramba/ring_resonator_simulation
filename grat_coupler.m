function [gratingCoupler] = grat_coupler(f_span, f_0, GC_BW_nm, GC_loss_dB)
    % GRAT_COUPLER computes the transfer function of grating coupler
    %
    % Inputs:
    % f_span            :  frequency array
    % f_0               :  central frequency of the coupler
    % GC_BW_nm          :  3dB coupler bandwidth expressed in nm
    % GC_loss_dB        :  coupler loss at central frequency expressed in
    %                      dB       

    % Outputs:
    % gratingCoupler    : The grating coupler transfer function
    %
    % Function:         : Outputs the linear grating coupler transfer funcion for
    %                     the given frequency span

    % Define constants
    c = 299792458;

    % Define Grating Coupler (GC) Transfer Function

    % 1. Convert Wavelength Bandwidth to Frequency Bandwidth
    % df = (c / lambda^2) * d_lambda
    GC_BW_Hz = (f_0^2 / c) * GC_BW_nm * 1e-9;

    % 2. Calculate Gaussian Parameters
    T_max_linear = 10^(-GC_loss_dB / 10);            % Convert dB to linear transmission
    sigma_GC = GC_BW_Hz / (2 * sqrt(2 * log(2)));    % Convert 3dB FWHM to standard deviation

    % 3. Create the Transfer Function for the Coupler
    gratingCoupler = T_max_linear * exp(-((f_span - f_0).^2) / (2 * sigma_GC^2)); 
    
end