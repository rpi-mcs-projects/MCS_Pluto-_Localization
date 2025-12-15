%% Generate OFDM Signal for ADALM-PLUTO Transmitter
% Creates a custom OFDM signal with 64 subcarriers.
% It saves the I/Q samples to a binary file for use in GNU Radio.

clear; clc;

rng(42); %FIXED SEED - used for randn() used in signal generator
filename = 'custom_ofdm_signal.bin';
nSubcarriers = 64;
scSpacing = 312.5e3; % Standard WiFi spacing (312.5 kHz)
cpLen = 16; % Cyclic Prefix length (16 samples)

%% Create Frequency Domain Symbols
% Using the known preamble 52 subcarriers (standard for WiFi) are used and
% I zeroed out the edges/DC
known_symbol = zeros(nSubcarriers, 1);
active_indices = [7:32 34:59]; % Skip DC (33) and guard bands
known_symbol(active_indices) = sign(randn(length(active_indices), 1));

%% OFDM Modulation
tx_time = ifft(ifftshift(known_symbol)) * sqrt(nSubcarriers);
tx_cp = [tx_time(end-cpLen+1:end); tx_time]; % Add CP
tx_packet = repmat(tx_cp, 10, 1); % Repeat the symbol 10 times to make a "packet"
silence = zeros(100, 1); % Add a little silence (gap) between packets
final_signal = [tx_packet; silence];
final_signal = final_signal / max(abs(final_signal)) * 0.5; % Normalized to prevent clipping

%% Save to Binary File for use in GNU Radio on other computer (with standard ADALM-PLUTO)
interleaved = [real(final_signal) imag(final_signal)].';
interleaved = interleaved(:);

fileID = fopen(filename, 'w');
fwrite(fileID, interleaved, 'float32');
fclose(fileID);

disp(['Successfully saved ' filename]);
