%% CSI Testing with Scope
% Author: Joe Pizzimenti
clear; clc; close all;

% Config
addpath('C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\include\'); %again... this may be different depending on install path
uri = 'ip:192.168.2.1';
fc = 1.56e9;
fs = 20e6;

% Reference Config (to match TX)
rng(42);
nSubcarriers = 64;
cpLen = 16;
active_indices = [7:32 34:59];
known_freq = zeros(nSubcarriers, 1);
known_freq(active_indices) = sign(randn(length(active_indices), 1));
ref_time = ifft(ifftshift(known_freq)) * sqrt(nSubcarriers);
ref_time_cp = [ref_time(end-cpLen+1:end); ref_time];

% Setup Receiver
disp('Setting up Receiver...');
rx = adi.AD9361.Rx;
rx.uri = uri;
rx.CenterFrequency = fc;
rx.SamplingRate = fs;
rx.EnabledChannels = [1 2];
rx.kernelBuffersCount = 4;
rx.GainControlModeChannel0 = 'manual'; rx.GainChannel0 = 55; % using manual gain to keep phase stable
rx.GainControlModeChannel1 = 'manual'; rx.GainChannel1 = 55;

%% Visulize
figure('Name', 'CSI Phase Debugger', 'Position', [100 100 1000 600]);

subplot(2,1,1);
hMag = plot(nan, nan, 'LineWidth', 2); grid on;
title('CSI Magnitude (Should be relatively flat/bumpy, NOT zero)');
ylabel('Magnitude'); xlabel('Subcarrier Index');

subplot(2,1,2);
hPhase1 = plot(nan, nan, 'b.-', 'DisplayName', 'RX1 Phase'); hold on;
hPhase2 = plot(nan, nan, 'r.-', 'DisplayName', 'RX2 Phase');
title('CSI Phase (The Critical Plot)');
ylabel('Phase (Radians)'); xlabel('Subcarrier Index');
legend; grid on; ylim([-pi pi]);

disp('Starting CSI Scope...');

while ishandle(hMag)
    data = rx();

    % Sync
    [xc, lags] = xcorr(data(:,1), ref_time_cp);
    [maxVal, maxIdx] = max(abs(xc));

    if maxVal < 0.05 % should catch relatively weak signals with this low threshold
        continue;
    end

    startIdx = lags(maxIdx) - length(ref_time_cp) + 1;
    if startIdx < 1 || (startIdx + 80) > length(data), continue; end

    % Extract Symbol
    symbol_start = startIdx + cpLen;
    rx_sym_time = data(symbol_start : symbol_start+nSubcarriers-1, :);
    rx_sym_freq = fftshift(fft(rx_sym_time));

    % Calculate Raw CSI (H)
    H = zeros(length(active_indices), 2);
    H(:,1) = rx_sym_freq(active_indices, 1) ./ known_freq(active_indices);
    H(:,2) = rx_sym_freq(active_indices, 2) ./ known_freq(active_indices);
    set(hMag, 'XData', 1:length(H), 'YData', abs(H(:,1)));

    % Plot Phase (Unwrapped)
    phase1 = angle(H(:,1));
    phase2 = angle(H(:,2));
    set(hPhase1, 'XData', 1:length(H), 'YData', phase1);
    set(hPhase2, 'XData', 1:length(H), 'YData', phase2);

    drawnow limitrate;
end
rx.release();
