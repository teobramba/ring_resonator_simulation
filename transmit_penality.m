function [TP, min_indices, ER_array] = transmit_penality(f_axis, P_RR, delta_mod)
    % TRANSMIT_PENALITY Computes the transmitter penality function given
    % the transfer function of the ring (P_RR), the frequency shift amplitude due to
    % modulation (delta_mod) and the frequency axis (f_axis)
    %
    % Inputs:
    % f_axis       : Frequency vector for the simulation [Hz]
    % P_RR         : Ring Resonator transfer function array (Through, Drop)
    % delta_mod    : Frequency shift amplitude due to modulation (how much 
    %                the Ring transfer function shifts due to applied signal) [Hz]
    %
    % Outputs:
    % TP           : Transmitter penality vector, with same dimension of f_axis
    % min_indices  : Frequency vector index corresponding to the TP minima
    %                position (index of f_axis where TP is minimized, multiple minima)
    % ER_array     : Extintion Ratio array associated to each position on
    %                the Ring transfer function (for every point on the Ring transfer function
    %                it is associated a corresponding Ext_ratio due to modulation around
    %                that point with amplitude delta_mod

    % Extracts the Through port (first column) from the transfer function matrix
    T = P_RR(:, 1); 
    
    % Initialize the arrays with zeros
    TP = zeros(size(f_axis));
    ER_array = zeros(size(f_axis)); % New array to store ER in dB
    
    % Loop through every center frequency point
    for i = 1:length(f_axis)
        f_center = f_axis(i);
        
        % The modulation states are symmetrically spaced around the bias point
        f_A = f_center - (delta_mod / 2);
        f_B = f_center + (delta_mod / 2);
        
        % Interpolate the light power at both shifted frequencies
        P_A = interp1(f_axis, T, f_A, 'linear'); 
        P_B = interp1(f_axis, T, f_B, 'linear'); 
        
        % If either shift pushes us off the edge of our data, assign Not-a-Number
        if isnan(P_A) || isnan(P_B)
            TP(i) = NaN; 
            ER_array(i) = NaN;
        else
            P1 = max(P_A, P_B);
            P0 = min(P_A, P_B);
            
            P_avg = (P1 + P0) / 2;
            IL_lin = 1 / P_avg; 
            ER_lin = P1 / P0;
            
            % Calculate TP and ER in decibels
            TP(i) = -10 * log10( (1/IL_lin) * ((ER_lin - 1) / (ER_lin + 1 + eps)) );
            ER_array(i) = 10 * log10(ER_lin); 
        end
    end
    
    % Find the indices where the TP curve has a local minimum
    min_indices = find(islocalmin(TP));
end