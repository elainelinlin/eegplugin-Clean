% pop_changeSingleTag() - Helps find the first target event tag within a 
%                         given time range and replace with user input
% 
% Usage: (In your commandline type:)
%   >> [EEG, com] = pop_changeSingleTag(EEG);   % pop-up window mode
%   >> [EEG, com] = pop_changeSingleTag(EEG, targetTag, changeTagTo,
%                   startT, endT);
% Inputs:
%   EEG         - The EEG data structure. E.g. 'EEG'
%   targetTag   - Name of tag to search for. Case insensitive. E.g. 'Bub+'
%   changeTagTo - Name of tag to replace targetTag with. E.g. 'XX'
%   startT      - Start time from which function will start looking for
%                 target tag.
%   endT        - End time until which function will stop looking for
%                 target tag.
% 
% Outputs:
%   EEG     - The new EEG data structure after replacement of target tag
%   com     - History string
%
% Note: EEG should not have been epoched!
% Author: Elaine Lin, UCLA, 08/23/2016

function [EEG,com]=pop_changeSingleTag(EEG, targetTag, changeTagTo, startT,...
    endT)

com = '';
if nargin < 1
    help pop_changeSingleTag;
    return;
end

if nargin < 2
    options = struct('Resize','on','WindowStyle','normal','Interpreter','tex');
    a = inputdlg({'Target tag?','Replace target tag with?', ...
        'Start time (s)? [From when should I start looking? Input a number or leave blank]','End time (s)? [After when should I stop looking? Input a number or leave blank]'},...
        'Replace or search for the first target tag within a time range',[1 100; 1 100; 1 100; 1 100], cell({'Bub+','X','',''}), options);

    if isempty(a), return; end
    targetTag = a{1};
    changeTagTo = a{2};
    startT = a(3);
    endT = a(4);
    
    if strcmp(startT,'')
        startT = 0;
    else
        startT = str2double(startT) * EEG.srate;   % Conversion to latency
    end

    if strcmp(endT,'')
        endT = EEG.pnts;    % Conversion to latency: total number of data points
    else
        endT = str2double(endT) * EEG.srate;    % Conversion to latency
    end
    
else
    if nargin < 3
        changeTagTo = 'Deleted';
    end

    if nargin < 4
        startT = 0;
    end

    if nargin < 5
        endT = EEG.pnts;    % Conversion to latency
    end
end

[~,numEvent] = size(EEG.event);

if startT >= endT
    error('Start time cannot be earlier than end time!')
end
% Find the first index which is within the time range
% ----------------------------------------------------
j = 1;
while j <= numEvent
    if EEG.event(j).latency >= startT
        break
    end
    j = j + 1;
end
startIndex = j;

% Find the last index within the specified time range
% ----------------------------------------------------
endIndex = numEvent - 1;
if endT ~= EEG.pnts     % User specified an end time
    while j <= numEvent
        if EEG.event(j).latency > endT
            break
        end
        j = j + 1;
    end
    endIndex = j - 1;
end

% Start pruning to find the first target tag
% -------------------------------------------
i = startIndex;
while i < endIndex
    if strcmpi(EEG.event(i).type,targetTag)
        break;
    end
    i = i + 1;
end

if i > numEvent || ~strcmpi(EEG.event(i).type,targetTag)
    error('Target tag not found within given time range')
else
    targetTime = EEG.event(i).latency / EEG.srate;
    targetTime = num2str(targetTime);
    strQ = strcat('Would you like to replace the event tag',{' '}, targetTag,{' '},'to',{' '}, changeTagTo,{' '},' at time point ',{' '}, targetTime,{' '},'s ?');
    choice = questdlg(strQ, ...
        'Double checking', ...
        'Yes','No','No');
% Handle response
    switch choice
        case 'Yes'
            disp([choice ', event tag will be replaced after clicking save.'])
            EEG.event(i).type  = changeTagTo;
            EEG.event(i).value = changeTagTo;
        case 'No'
            disp([choice ', Nothing was changed'])
            return;
    end
end

% History string
% --------------
noteStr = ['  Event tag ''', targetTag,''' was replaced with ''', ...
    changeTagTo, ''' at time point ' num2str(targetTime) 's.'];
com = sprintf('%s = pop_changeSingleTag(%s); \n', changeTagTo, targetTag);
com = [com sprintf(noteStr)];

end
