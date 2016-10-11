% pop_changeTag()
%     - Remove qEEG tags outside of start-stop target tags.
%     - qEEG tags in bad coded segments are also removed.
%     - If use the provided usage example (by typing 'EEG = ' on the left
%       hand side, the results are updated in the variable, 'EEG'.
%
% Usage: (In your commandline type:)
%   >> [EEG, com] = pop_changeTag(EEG);         % pop-up window mode
%   >> [EEG, com] = pop_changeTag(EEG,tag);     % any tag name
%
% Inputs:
%   EEG          - The EEG data structure. This is the entire structure, not
%                  just the data field! E.g., EEG
%   tag          - The name of the tag in single quotes without the plus or 
%                  minus sign. E.g., 'Bub' for bubbles start/stop. This is case 
%                  insensitive. Enter 'NA' if you just wish to clean the
%                  tags within bad segments.
%
% Outputs:
%   EEG     - The new EEG data structure after removal of qEEG tags that are
%             outside of start-stop or within bad start-stop tags.
%   com     - History string
%
% Author: Joel Frohlich, UCLA CART, 08/09/2016

function[EEG, com] = pop_changeTag(EEG,tag)
    
com = '';
if nargin < 1
    help pop_changeTag;
    return
end

if nargin < 2
    options = struct('Resize','on','WindowStyle','normal','Interpreter','tex');
    a       = inputdlg({'What is the tag name? This is case insensitive. Input ''NA'' if you just want to clean the tags within bad segments.'},...
        'Change Tag',[1 60],cell({'Bub'}),options);
    if isempty(a), return; end
    tag     = a{1};
end

% Check if input parameters are valid
% ------------------------------------
if ~strcmpi(tag,'NA')
    message = ['Searching for ', tag, '+ and ', tag,'-'];
else
    message = ['Changing all event tags to ''X'' within bad segments.'];
end

if ~ischar(tag)
    error('The tag must be a string. Please enter tag name')
else
    display(message)
end


% Variable Initialization
% -----------------------
if ~strcmpi(tag,'NA')
    tagStart = strcat(tag,'+');
    tagStop  = strcat(tag,'-');
    count    = 0;
    start    = [];
    stop     = [];
end

N = max(size(EEG.event));

badStart = [];
badStop = [];

fs = EEG.srate;


% Find latencies of all start and stop tags
% ------------------------------------------
if ~strcmpi(tag,'NA')
    display('     ')
    display('Removing all qEEG tags outside the start/stop brackets')
    display('     ')
end

for i = 1:N
    if strcmpi(EEG.event(i).type,'Bad+')
        t         = EEG.event(i).latency; % time bad tag is dropped
        t_before  = t - fs*1.024; % time 1.024 seconds (period of qEEG tags)
                     % before bad tag is dropped. This makes
                     % sure that the segment in which the bad tag was
                     % dropped is ALSO marked bad.
        badStart  = [badStart t_before];
    elseif strcmpi(EEG.event(i).type,'Bad-')
        badStop   = [badStop EEG.event(i).latency];
    elseif ~strcmpi(tag,'NA')
        if strcmpi(EEG.event(i).type,tagStart) 
            start = [start EEG.event(i).latency];
        elseif strcmpi(EEG.event(i).type,tagStop) 
            stop  = [stop EEG.event(i).latency];
        end
    end
end

if ~strcmpi(tag,'NA')
    start = sort(start);
    stop = sort(stop);
end

badStart = sort(badStart);
badStop = sort(badStop);


% Make sure number of start and stop tags matches
% -----------------------------------------------

if ~strcmpi(tag,'NA')
    if length(start) ~= length(stop)
        display('The start tags are located at these time points: ')
        start
        display('The stop tags are located at these time points: ')
        stop
        if length(start) > length(stop)
            error('Error: at least one stop tag is missing')
        elseif length(start) < length(stop) 
            error('Error: at least one start tag is missing')
        end
    end
end

if length(badStart) ~= length(badStop)
    display('The bad start tags are located at these time points: ')
    badStart
    display('The bad stop tags are located at these time points: ')
    badStop
    if length(badStart) > length(badStop)
        error('Error: at least one bad stop tag is missing')
    elseif length(badStart) < length(badStop) 
        error('Error: at least one bad start tag is missing')
    end
    
elseif ~isempty(badStop) && ~isempty(badStart)
    if badStop(1) < badStart(1) && badStop(length(badStop)) ...
        < badStart(length(badStart))
        disp(['Warning: Although the number of bad start tags and the number'...
        ' of bad stop tags are the same, it appears the EEG data were' ...
        ' bad-coded with a ''Bad-'' at the beginning of the file and a ''Bad+'''...
        ' at the end of the file. Will deleted the first Bad- tag and last Bad+ tag.'])
        badStop(1) = [];
        badStart(length(badStart)) = [];
    end
end

% Make sure if a start tag proceeds a stop tag for each bracket
% -------------------------------------------------------------
if ~strcmpi(tag,'NA')
    L = length(start);

    for i = 2:L
        if stop(i-1) > start(i) 
            error(['Error: Stop tag from the previous bracket comes after start',...
            'tag for next bracket'])
        end
    end
end

bL = length(badStart);

for i = 2:bL
    if badStop(i-1) > badStart(i) 
        error(['Error: bad stop tag from the previous bracket comes after',...
            'bad start tag for next bracket'])
    end
end

% If a qEEG tag is not bracketed by start/stop tags,
% change this qEEG tag to 'X'
% ---------------------------------------------------
if ~strcmpi(tag,'NA')
    qEEGcount = 0;
    for i = 1:N
        if strcmpi(EEG.event(i).type,'qEEG')
            qEEGcount = qEEGcount + 1;  % Keep track of total number of qEEG
            lat = EEG.event(i).latency;
            tally = 0;
            for j = 1:L
                % Check to see if bracketed by video start-stop tags
                if start(j) < lat && lat < stop(j) 
                    break
                else
                    tally = tally + 1;
                end
            end
            % If not inside any start-stop brackets, remove qEEG tag
            if tally == L
                EEG.event(i).type  = 'X';
                EEG.event(i).value = 'X';
                count = count + 1;
            end
        end
    end
end

% Clearing all event tags within bad+/bad-
% ----------------------------------------
badCount = 0;
if bL > 0   % Only proceed if there are bad segments
    isBad = 0;
    j = 1;
    i = 1;
    while i <= N
        if EEG.event(i).latency >= badStart(j) && EEG.event(i).latency <= badStop(j)
            isBad = 1;  % In bad segment
        elseif j < bL
            if EEG.event(i).latency > badStop(j) && EEG.event(i).latency < badStart(j+1) % in between bad segments
                isBad = 0;
            elseif EEG.event(i).latency >= badStart(j+1) % In the next bad segment
                j = j + 1;
                continue
            end
        else    % j == bL, out of the last bad segment
            isBad = 0;
        end
        if isBad
            if strcmpi(EEG.event(i).type,'qEEG') || strcmpi(EEG.event(i).type,'Bub+')
                badCount = badCount + 1;
            end
            EEG.event(i).type  = 'X';
            EEG.event(i).value = 'X';
        end
        i = i + 1;
    end
end

if ~strcmpi(tag,'NA')
    qEEG_left = qEEGcount - count - badCount;
    note_com_1  = ['  Number of qEEG tags outside of ' tag ': ' num2str(count) '\n'];
    note_com_3  = ['  Original number of qEEG tags: ' num2str(qEEGcount) '\n'];
    note_com_4  = ['  Total number of qEEG tags preserved: ' num2str(qEEG_left) '\n\n'];
    note_com_2  = ['  Number of qEEG or Bub+ tags inside bad segments: ' num2str(badCount) '\n'];
    note_com    = [note_com_1,note_com_2,note_com_3,note_com_4];   
else
    note_com    = ['  Number of qEEG or Bub+ tags inside bad segments: ' num2str(badCount) '\n'];
end    
fprintf(note_com)

noteStr = ['  Note: this script detected ', num2str(fs),'Hz as the sampling rate.\n If this is incorrect, bad segment removal might have been done wrong \n'];
fprintf(noteStr)

% History string
% ---------------
com = sprintf('%s = pop_changeTag(%s, ''%s''); \n', inputname(1), inputname(1), tag);
com = [com sprintf(note_com)];


end
