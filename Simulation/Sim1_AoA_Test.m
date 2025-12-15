%% Part 1: Angle of Arrival (AoA) Simulation
% Author: Joe Pizzimenti

%% This script simulates a 2-antenna array (Emulating the hardware setup for the Pluto+)
% and uses the MUSIC algorithm to estimate the angle of a single source.

clear; clc; close all;

% Config
c = 3e8;
fc = 1.56e9;
lambda = c/fc;
trueAngle = 30; % GROUND TRUTH ANGLE of the transmitter (degrees)
snr = -10;

% Create Antenna Array (2*RX Pluto+ Antennas) with the Phased Array Antenna Toolbox
array = phased.ULA(...
    'NumElements', 2,...
    'ElementSpacing', lambda/2,...
    'Element', phased.IsotropicAntennaElement);

% Create the Transmitted Signal
nSamples = 1000;
txSignal = exp(1j*2*pi*0.1*(1:nSamples)'); % just a simple complex sinusoid

% Simulate Signal Collection at the Array
collector = phased.Collector(...
    'Sensor', array,...
    'PropagationSpeed', c,...
    'OperatingFrequency', fc);

% Collect Signal from Specified Angle
rxSignal = collector(txSignal, trueAngle);
rxSignal = awgn(rxSignal, snr, 'measured'); % Add White Noise

% Apply MUSIC for AoA Estimation
musicEstimator = phased.MUSICEstimator(...
    'SensorArray', array,...
    'OperatingFrequency', fc,...
    'NumSignalsSource', 'Property',...
    'NumSignals', 1,...
    'ScanAngles', -90:0.1:90);

spectrum = musicEstimator(rxSignal);

% Visualize AoA Results
figure;
plot(musicEstimator.ScanAngles, 10*log10(spectrum));
hold on;

% Plot a line at the ground truth angle to see if MUSIC worked well enough
xline(trueAngle, '--r', 'Actual Angle', 'LineWidth', 2);
hold off;

title('Angle of Arrival (AoA) - MUSIC Pseudospectrum');
xlabel('Angle (degrees)');
ylabel('Pseudospectrum (dB)');
grid on;
legend('MUSIC Spectrum', 'Actual Angle');
