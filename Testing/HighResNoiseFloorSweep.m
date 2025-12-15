%% Pluto+ High-Res Frequency Sweep
% Author: Joe Pizzimenti

%% Scans 100 MHz - 3 GHz with high resolution (2 MHz steps). Takes a minute or two to fully sweep through
% This is how I found the optimal frequency for my environment was 1.56 GHz

clear; clc; close all;

uri = 'ip:192.168.2.1';
startFreq = 100e6;
stopFreq  = 3000e6;

stepSize  = 2e6;
bandwidth = 3e6;

% Create the frequency list
scanFreqs = startFreq:stepSize:stopFreq;
numSteps = length(scanFreqs);

rx1_power_db = zeros(1, numSteps);
rx2_power_db = zeros(1, numSteps);

% Config PLUTO+
addpath('C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\include\'); % THIS WAS THE PATH FROM MY INSTALLER!!! May change for other systems, see PLUTO+ with MATLAB installation report
disp(['Initializing High-Res Receiver (' num2str(stepSize/1e6) ' MHz steps)...']);
rx = adi.AD9361.Rx;
rx.uri = uri;
rx.SamplingRate = bandwidth;
rx.kernelBuffersCount = 2;
rx.EnabledChannels = [1 2];

% Manual gain set to what is used in experiment
rx.GainControlModeChannel0 = 'manual';
rx.GainControlModeChannel1 = 'manual';
rx.GainChannel0 = 55;
rx.GainChannel1 = 55;


disp(['Starting Sweep...']);
figure('Name', 'High-Res Spectrum Sweep');
hLine1 = plot(nan, nan, 'b', 'LineWidth', 1, 'DisplayName', 'RX1 Power'); hold on;
hLine2 = plot(nan, nan, 'r', 'LineWidth', 1, 'DisplayName', 'RX2 Power');
xlabel('Frequency (MHz)'); ylabel('Relative Power (dB)');
title('High-Resolution Noise Floor Sweep');
grid on; legend;
xlim([startFreq/1e6 stopFreq/1e6]);

for i = 1:numSteps
    currentF = scanFreqs(i);

    rx.CenterFrequency = currentF;
    % Small pause for LO lock
    pause(0.02);

    data = rx();
    p1 = mean(abs(data(:,1)).^2);
    p2 = mean(abs(data(:,2)).^2);
    rx1_power_db(i) = 10*log10(p1);
    rx2_power_db(i) = 10*log10(p2);

    % Update Plot
    set(hLine1, 'XData', scanFreqs(1:i)/1e6, 'YData', rx1_power_db(1:i));
    set(hLine2, 'XData', scanFreqs(1:i)/1e6, 'YData', rx2_power_db(1:i));

    if mod(i, 20) == 0
        drawnow limitrate; %this makes my CPU run a bit less so it doesn't overheat... not sure why MATLAB wants to use ALL of my CPU if I don't limit it...
    end
end

rx.release();
disp('Sweep Complete!');

% Find the Deepest Valley (also filters the data slightly to ignore little blips downward)
smooth_power = movmean(rx1_power_db, 5);
[minPower, minIdx] = min(smooth_power);
bestFreq = scanFreqs(minIdx);

disp('------------------------------------------------');
disp(['Quietest Frequency Found: ' num2str(bestFreq/1e6) ' MHz']);
disp('Use this frequency for the SpotFi experiments!');
