function [extintionRatio] = ext_ratio(P_ring)
    % EXT_RATIO computes the extintion watio from the transfer function of
    % the ring resonator
    %
    % Inputs:
    % P_ring:           : The transfer function composed of:
    %
    % P_ring(:, 1)      : Through power
    % P_ring(:, 2)      : Drop power
    %
    % Outputs:
    % extintionRatio    : The value of extintion ratio expressed in dB
    %
    % Function: computes the ratio between the maximum and the minimum 
    % values of the Trough port

    extintionRatio = 10*log10(max(P_ring(:, 1))/min(P_ring(:, 1)));
    
end