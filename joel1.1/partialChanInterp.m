function[EEGOUT] = partialChanInterp(EEG,chans,seg)
% Usage: (In your commandline type:)
%   >> EEG = partialChanInterp(EEG,3,4);    
%        % Interpolate channel 3 in segment 4
%
%   >> EEG = partialChanInterp(EEG,[3 6 7], 6);
%        % Interpolate channel 3, 6, 7 in segment 6
%
% Function:
%   - To interpolate partial channels
%   - i.e. interpolate a channel which is only bad in a given data segment.
%   - Uses spherical interpolation method. Channel locations must be loaded.
%
% Inputs:
%   EEG       - The entire EEG structure
%   chans     - Channel number(s), can be an array as well. 
%               E.g., [3 4] to refer to both channel 3 and 4
%   seg       - Segment number. E.g., 1
%
% Outputs:
%   EEGOUT    - The entire EEG structure with interpolated data
%
% NOTE
%   - To *permanently* accept the changes to the dataset created by this
%     function, type 'EEG = EEGOUT' in MATLAB commandline.
%
% Author: Joel Frohlich
% UCLA CART
% 02/24/15

copyEEG = EEG; % Make a copy of EEG data structure
copyEEG.data = EEG.data(:,:,seg); % discard all segments except segment of interest
copyEEG.trials = 1; % change epoch number
interpEEG = eeg_interp(copyEEG, chans, 'spherical');
EEGOUT = EEG; % Make another copy of data structure
EEGOUT.data(:,:,seg) = interpEEG.data;
EEGOUT.history = [EEG.history ' NOTE: channels ',num2str(chans),  ...
    ' were interpoalted within segment number ',num2str(seg)];

