%% Part 2: Time of Flight (ToF) Simulation
% Author: Joe Pizzimenti

%% This script treats the 64 subcarriers as a 64-element virtual antenna array

clear; clc; close all;

% Config
nSubcarriers = 64;
scSpacing = 312.5e3; % 312.5 kHz "distance" between the simulated antennas
snr = -20;
nSnapshots = 1000;

% Define "Ground Truth" Multipath Channel
c = 3e8;
trueDelays_ns = [50; 120]; % GROUND TRUTH PATHS: 50 ns and 120 ns
trueDelays_s = trueDelays_ns * 1e-9; % Convert to seconds
trueGains = [1; 0.7]; % Linear gains
nPaths = length(trueDelays_s);

% Generate Ground Truth CSI
% Create the steering vector for the virtual antenna array
% (I was inspired by https://www.antenna-theory.com/definitions/steering.php)
freqs = (0:nSubcarriers-1)' * scSpacing;
steeringMatrix = exp(-1j * 2 * pi * freqs * trueDelays_s'); % 64x2
csi_ideal = steeringMatrix * trueGains; % 64x1
csi_matrix = repmat(csi_ideal, 1, nSnapshots);
csi_noisy_matrix = awgn(csi_matrix, snr, 'measured'); % 64x1000

% Create the 64-element simulated antenna array
virtualArray = phased.ULA(...
    'NumElements', nSubcarriers,...
    'ElementSpacing', scSpacing);

% Define scan range for time delays.
scanDelays_ns = 0:0.5:250; % Scan from 0 to 250 ns
scanDelays_s = scanDelays_ns * 1e-9; % Convert to seconds
scanAngles_deg = asind(scanDelays_s); % Convert to "angles" in degrees

% Create the MUSIC estimator
musicEstimator = phased.MUSICEstimator(...
    'SensorArray', virtualArray,...
    'PropagationSpeed', 1, ...
    'OperatingFrequency', 1, ...
    'ScanAngles', scanAngles_deg);

spectrum = musicEstimator(csi_noisy_matrix');

% Plot Result
figure;
plot(scanDelays_ns, 10*log10(spectrum));
hold on;
% Plot lines at ground truth paths to see if MUSIC worked well enough
xline(trueDelays_ns(1), '--r', 'Path 1 (50 ns)', 'LineWidth', 2);
xline(trueDelays_ns(2), '--g', 'Path 2 (120 ns)', 'LineWidth', 2);
hold off;

title('Time of Flight (ToF) - MUSIC Pseudospectrum');
xlabel('Time of Flight (nanoseconds)');
ylabel('Pseudospectrum (dB)');
grid on;
legend('MUSIC Spectrum', 'Actual Path 1', 'Actual Path 2');
xlim([0 250]);
