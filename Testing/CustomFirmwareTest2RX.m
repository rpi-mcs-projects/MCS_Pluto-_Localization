%% Hardware Test: OFDM Reception at 1.56 GHz
% Author: Joe Pizzimenti

%% Does nothing else other than testing if the OFDM signal is received, displays signal in time domain.

clear; clc; close all;

% Config
addpath('C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\include\');
uri = 'ip:192.168.2.1';
fc = 1.56e9;
fs = 20e6;

% Setup PLUTO+ Reciever
disp(['Setting up Receiver at ' num2str(fc/1e9) ' GHz...']);
rx = adi.AD9361.Rx;
rx.uri = uri;
rx.CenterFrequency = fc;
rx.SamplingRate = fs;
rx.EnabledChannels = [1 2];
rx.kernelBuffersCount = 2;

rx.GainControlModeChannel0 = 'manual';
rx.GainControlModeChannel1 = 'manual';
rx.GainChannel0 = 55;
rx.GainChannel1 = 55;

% Visualization
disp('Starting Live View...');
figure('Name', 'Live Signal Check (1.56 GHz)');

subplot(2,1,1);
hLine1 = plot(nan, nan, 'b'); hold on;
hLine2 = plot(nan, nan, 'r');
title('Time Domain (Look for Packets)');
ylim([0 2048]); grid on;

subplot(2,1,2);
hSpec = plot(nan, nan, 'k');
title('Spectrum (Should look like a tabletop)');
grid on; xlim([-10 10]); ylim([-80 0]);
xlabel('Frequency Offset (MHz)');


while ishandle(hLine1)
    data = rx();

    % Time Domain Magnitude
    mag1 = abs(data(:,1));
    mag2 = abs(data(:,2));

    set(hLine1, 'YData', mag1, 'XData', 1:length(mag1));
    set(hLine2, 'YData', mag2, 'XData', 1:length(mag2));

    % Frequency Domain
    L = length(data);
    Y = fftshift(fft(data(:,1)));
    f = (-L/2:L/2-1)*(fs/L)/1e6;
    power = 20*log10(abs(Y)/L) + 20;
    set(hSpec, 'XData', f, 'YData', power);

    drawnow limitrate;
end

rx.release();
