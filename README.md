# Silicon Photonics Ring Resonator Simulator

**Author:** Matteo Brambilla | **Year:** 2026  
**Language:** MATLAB

## Overview
This repository contains a comprehensive MATLAB simulation environment for designing, testing, and analyzing Silicon-on-Insulator (SOI) Add-Drop Ring Resonators. 

The project bridges the gap between theoretical "Golden Standard" optical designs and real-world foundry manufacturing variations. It allows users to simulate the degradation of optical performance due to lithography errors and implements realistic active control schemes (such as thermo-optic tuning and lock-in demodulation) to dynamically track and analyze resonances.

## Core Features & Physics Modeled

*   **Geometrical Design & Critical Coupling:** Automatically calculates the physical circumference, radius, and ideal power coupling coefficients (K1, K2) required to hit a target Free Spectral Range (FSR) and Bandwidth. Includes All-Pass critical coupling attenuation analysis.
*   **Lithography Tolerance Modeling:** Simulates foundry gap errors by modeling the exponential decay of the evanescent field (κ_DUT = κ_gold * exp(-γ * Δg)). Accurately demonstrates the trade-off between Q-factor, Insertion Loss, and Extinction Ratio when critical coupling is broken.
*   **Thermo-Optic Tuning & Dithering:** Models local micro-heaters to shift the effective refractive index (n_eff) of the silicon core. Implements a time-domain sinusoidal dither to the heater power.
*   **Lock-In Demodulation:** Uses a simulated lock-in amplifier approach to extract in-phase harmonic signatures. Accurately maps the 1f harmonic to the 1st derivative (slope) and the 2f harmonic to the 2nd derivative (curvature) of the optical transfer function.
*   **Advanced WDM Source Modeling:** 
    *   Simulates broadband LED power spectral densities (PSD).
    *   Implements **Super-Gaussian flat-top optical filters** to convert broad Gaussian light sources into steep-sloped, rectangular optical channels.
*   **Fiber-to-Chip Grating Couplers:** Overlays realistic Gaussian insertion loss profiles and 3dB bandwidth constraints inherent to standard vertical grating couplers.
*   **Automated Dashboard Rendering:** Generates real-time, animated 4x4 plotting dashboards tracking spectral shifts, integrated power, and harmonic responses, complete with automated high-resolution `.png` exports with metadata footers.

## Repository Structure
Executable codes:
*   `RR_Simulation_dithering_HarmonicRatio.m` - Simulation of DUT (with heater) and Golden sample (fixed) structures. Handles source definition, thermo-optic sweeps, time-domain dithering, demodulation, harmonic ratio computation and UI generation.
*   `RR_Simulation_HarmonicRatio_HeaterGold.m` - Simulation of DUT (fixed) and Golden sample (with heaters) structures. Gold and DUT rings with indipendent characteristics, source definition with super-gaussian filtering, thermo-optic sweeps, time-domain dithering, demodulation, harmonic ratio and UI generation.

External functions:
*   `ring_design.m` - Calculates the exact physical geometry and golden coupling parameters based on target FSR and Bandwidth using cavity finesse math.
*   `ring_simulate.m` - Computes the complex transfer functions (Through and Drop ports) of the Add-Drop ring using phase theoretical transfer function.
*   `ring_simulate_K.m` - Computes the complex transfer functions (Through and Drop ports) of the Add-Drop ring taking into account propagation losses and power coupling coefficients.
*   `grat_coupler.m` - Generates the wavelength-dependent Gaussian transfer function of standard grating couplers based on a specified 3dB bandwidth.
*   `ext_ratio.m` - Computes the true Extinction Ratio (ER) in decibels by comparing out-of-band maximum transmission to on-resonance minimum transmission.
*   `transmit_penality.m` - Computes the Transmitter penality (TP) function given the transfer function of the Ring and the frequency shift amplitude due to modulation. Comuputes also the corresponding local Extintion Ratio

## Usage

1.  Clone the repository to your local machine.
2.  Open MATLAB and navigate to the repository directory.
3.  Open the `main.m` script.
4.  Adjust the **User-Defined Parameters** in Section 1 (e.g., target wavelength, FSR, Bandwidth, waveguide losses, and dither amplitude).
5.  Set `enable_animation = true;` to watch the thermo-optic sweep happen in real-time, or `false` to jump straight to the final high-resolution render.
6.  Run the script. The final dashboard will automatically export as a 300-DPI `.png` file to your working directory.

## License
MIT License. Feel free to use and modify this code for your own academic or engineering simulations.
