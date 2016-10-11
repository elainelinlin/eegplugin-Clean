% pop_cleaningScript()
%       - Interpolates chegments that have at least one data point 
%         above (voltBadCheg) uV.
%       - A segment with more than N bad chegments is rejected from the dataset.
%
% Usage: (In your commandline type:)
%   >> [EEG, com] = pop_cleaningScript(EEG);    % pop-up window mode
%   >> [EEG, com] = pop_cleaningScript(EEG,nChans, maxBadChans,
%   voltBadChan, voltBadCheg);
%
% Input:
%   EEG            - The EEG structure. E.g., EEG (not EEG.data)
%   nChans         - Number of channels. 129 by default
%   maxBadChans    - Maximum number of bad channels allowed. 11 by default
%   voltBadChan    - Threshold voltage to detect a bad channel throughout.
%                    * A bad channel has a mean voltage > voltBadChan (uV)
%                    throughout the entire recording.
%                    ** 200 by default
%   voltBadCheg    - Threshold voltage to detect a bad chegment.
%                    * A bad chegment has at least one data point >
%                    voltBadCheg (uV) somewhere within the segment.
%                    ** 150 by default
%   
% Output:
%   EEG      - The EEG structure.
%   com      - History string
%
% Definitions:
%   Chegment = channel-segment combination (A segment of a channel)
%   N        = Maximum number of bad chegments within a tolerable segment. 
%              A segment is rejected if it has more than N bad chegments.
%              (N = sqrt(num of channels) - (num of completely bad channels)
%
% Assumptions
%   - 129 channels in total
%   - Last 4 channels (125-128) are assumed to be eyeblink channels!
%   - Eyeblink are *not* counted towards any threshold and are not used
%   - Reference channel (129) is not used as well
%
% Notes
%   - List of all bad segments that were discarded is saved to EEG.history
%
% Author: Joel Frohlich, UCLA CART, 02/26/2015

function [EEG,com] = pop_cleaningScript(EEG, nChans, maxBadChans,...
    voltBadChan, voltBadCheg)

com = '';
if nargin < 1
    help pop_cleaningScript;
    return
end

if nargin < 2
    options = struct('Resize','on','WindowStyle','normal','Interpreter','tex');
    b = inputdlg({'Total number of channels: ','Last five channels are eyeblink channels and reference channel: [y/n]'...
    ,'What is the mean voltage threshold (in uV), above which a channel must be discarded throughout?'...
    ,'What is the voltage threshold (in uV), above which a chegment will be marked bad?',...
    'What is the maximum number of channels allowed to be discarded throughout?'},...
    'Interpolate/Discard bad segments/channels',...
    [1 100; 1 100; 1 100;1 100; 1 100], ...
    cell({'129','Y','200','150','11'}), options);
    
    if isempty(b), return;end
    NUM_CHANNELS           = str2double(b(1));
    ASSUMPTION_SATISFIED   = b(2);
    THRESHOLD_BAD_CHANNEL  = str2double(b(3));
    THRESHOLD_BAD_CHEGMENT = str2double(b(4));
    MAX_BAD_CHANNELS       = str2double(b(5));

    if ~strcmpi(ASSUMPTION_SATISFIED,'y')
        error('Assumption not satisfied. Contact Joel')
    end
elseif nargin < 5
    NUM_CHANNELS           = 129;
    THRESHOLD_BAD_CHANNEL  = 200;
    THRESHOLD_BAD_CHEGMENT = 150;
    MAX_BAD_CHANNELS       = 11;
else
    NUM_CHANNELS           = nChans;
    THRESHOLD_BAD_CHANNEL  = voltBadChan;
    THRESHOLD_BAD_CHEGMENT = voltBadCheg;
    MAX_BAD_CHANNELS       = maxBadChans;
end

% Initialization and Error Strings
% --------------------------------
S = size(EEG.data); % S = [Channel, Voltage, Segment]
badSegs = [];
errorStr = ['Number of channels greater than 129. Channels 125 - 128 are' ...
    'always treated as eyeblink channels. Channel 129 (Cz) assumed to be' ...
    'reference. If number of channels is supposed to be > 129 contact Joel' ...
    'to modify script'];

errorStr2 = ['Number of channels less than 129. Channels 125 - 128 are' ...
    'always treated as eyeblink channels. Channel 129 (Cz) assumed to be' ...
    'reference. If number of channels is supposed to be < 129 contact Joel' ...
    'to modify script'];
  
if S(1) > NUM_CHANNELS
    error(errorStr)
elseif S(1) < NUM_CHANNELS
    error(errorStr2)
end

N = floor(sqrt(S(1))); % N
display(['Using ' num2str(N) ...
    ' as bad channel threshold for discarding segments.'])


% Interpolate bad channels throughout recordings
% -----------------------------------------------
meanVolt = mean(abs(reshape(EEG.data,S(1),S(2)*S(3))),2); 
% Compute mean voltage of each channel:
% Reshape the original 3D matrix to a 2D matrix
% channel-by-voltage-by-segment  ---->  channel-by-(voltage * segment)
% Take the mean of the absolute values of voltage in each channel

[Y,I] = sort(meanVolt(1:S(1)-5));  
% Last 5 channels are not sorted (Assume 4 eyeblinks + 1 reference channel)
% I is the sorted channel numbers in order of ascending voltage mean
% Y is the sorted voltage mean in ascending order

wholeChanBad = [];

% Channels with mean voltage > THRESHOLD_ENTIRELY_BAD uV considered entirely bad
for i = length(Y):-1:1
    if Y(i) > THRESHOLD_BAD_CHANNEL
        wholeChanBad = [wholeChanBad I(i)];
    else
        break
    end
end

if length(wholeChanBad) > MAX_BAD_CHANNELS
    error(['Number of channels bad throughout recordings exceeds the maximum!'...
        ' Perhaps the data have not been filtered yet!'])
end
       
EEG = eeg_interp(EEG, wholeChanBad, 'spherical');

display(['The following channels were bad throughout the recording: ' ...
    num2str(sort(wholeChanBad))])


% Interpolate bad chegments
% --------------------------
N = N - length(wholeChanBad);
% Update threshold to account for the bad channels interpolated entirely

if N > 0
    for i = 1:S(3)       % Loop through each segment
        bad = [];
        for j = 1:S(1)-5 % Loop through each channel except eyeblinks and reference
            cheg = EEG.data(j,:,i);
            % Mark chegment bad if voltage exceeds threshold
            if max(abs(cheg)) > THRESHOLD_BAD_CHEGMENT
                bad = [bad j];
            end
        end
        % Interpolate chegment or
        % reject segment if too many channels are bad
        if length(bad) > N
            badSegs = [badSegs i];
        elseif ~isempty(bad)
            display([num2str(length(bad)) ' channels are being interpolated' ...
                ' in segment #' num2str(i)])
            EEG = partialChanInterp(EEG,bad,i);
        end
    end

    EEG.data(:,:,badSegs) = [];
    EEG.epoch(badSegs) = [];
    EEG.trials = EEG.trials - length(badSegs);

    display([num2str(length(badSegs)) ' segments were discarded'])
end

wholeChanBad

% History string
% --------------
com = sprintf('pop_cleaningScript( %s ); \n', inputname(1));
note_com1 = ['  Channels that were bad throughout the recording and discarded: ' num2str(wholeChanBad) '\n'];
note_com2 = ['  Segments that were bad and discarded: ' num2str(badSegs) '\n'];
note_com  = [note_com1, note_com2];
com = [com sprintf(note_com)];

end