% pop_calculatePower() -  Compute relative power for each ROI defined in ...
%                         Kevin McEvoy's BIB paper (resting EEG)
% 
% Usage: (In your commandline type:)
%   >> [studyPowerVals, com] = pop_calculatePower(EEG) % pop-up window mode
%
%   >> [studyPowerVals, com] = pop_calculatePower(EEG, windowSize, whoAmI,...
%                              studyPowerVals, plotMe, export_csv,
%                              filename);
% Inputs:
%   EEG            - The entire EEG structure
%   windowSize     - Window size for Welch's method in seconds. 
%                    * 1 sec windows cannot be used to estimate spectral power 
%                    of oscillations slower than 2 Hz (e.g., delta), but 2 sec 
%                    windows may include temporal discontinuties between 
%                    concatenated segments which affect the high end of the 
%                    frequency spectrum. 
%   whoAmI         - File name for matrix of PSD values. E.g. 'allPSDs.mat'
%                    (will save to your current folder, usually MATLAB 
%                     folder in Documents)
%   studyPowerVals - Matrix of power values for study.
%                    Should be 45 columns (5 freq bands x 9 ROIs)
%   plotMe         - Boolean variable to indicate if ROI PSDs should be
%                    plotted. (1 for yes, 0 for no)
%   export_csv     - Boolean variable that specifies whether studyPowerVals
%                    should be exported as CSV. (1 for yes, 0 for no)
%   filename       - Name to save CSV as. E.g. 'ROI_power_values.csv'
%                    (will save to your current folder, usually MATLAB
%                    folder in Documents)
%
% Outputs:
%   studyPowerVals - Matrix of power values, cancatenated with a new row of
%                    newly run data.
%   com            - History string. Always empty because no changes are
%                    made to data by this function.
%
% Notes: Version 3
%   - Edited 08/17/16 to output one beta band (12-30 Hz), create menu if 
%     fewer than 1 input argument fed to function
%   - Edited 08/10/16 fixed PSD ROI plots
%
% Author: Joel Frohlich, UCLA CART, 09/30/15

function[studyPowerVals, com] = pop_calculatePower(EEG, windowSize, whoAmI, studyPowerVals, plotMe, export_csv, filename)

com = '';
studyPowerVals = 0;
if nargin < 2
    options = struct('Resize','on','WindowStyle','normal','Interpreter','tex');
    a = inputdlg({'Window size in data segments?', ...
        'Matlab file name (w/extension)?',...
        'Name of existing variable with last output? (IF none write ''NA'')',...
        'Plot ROI PSDs? (y/n)','Save CSV file? (y/n)','CSV file name (w/extension)?'},...
        'Calculate Power',[1 100; 1 100; 1 100; 1 100; 1 100; 1 100],...
        cell({'2','allPSDs.mat','NA','y','y','ROIpower.csv'}), options);
    
    if isempty(a), return; end
    
    % Get params from menu input 
    
    windowSize = str2double(a{1});
    
    whoAmI = a{2};
    if isempty(strfind(whoAmI,'.mat'))
        whoAmI = [whoAmI '.mat'];
    end
    
    varName = a{3};
    if strcmpi(varName, 'NA') 
        studyPowerVals = [];
    else
        try 
            studyPowerVals = evalin('base',varName); 
            % Extract data from varName to studyPowerVals
        catch
            error('Variable not existent')
        end
    end
    
     if strcmpi(a{4},'y')
         plotMe = 1;
     else
         plotMe = 0;
     end

     if strcmpi(a{5},'y')
         export_csv = 1;
         filename = a{6};
     else
         export_csv = 0;
     end
     
else
    if nargin < 3
        whoAmI = 'allPSDs.mat';
    end

    if nargin < 4
        studyPowerVals = [];
    else
        [~,n] = size(studyPowerVals);
        if n > 54
            error('Number of power values per subject is too large in the study matrix!')
        end
    end

    if nargin < 5
        plotMe = 0;
    end

    if nargin < 6
        export_csv = 0;
    end

    if nargin < 7
        filename = 'Study_power_values.csv';
    end

end

if plotMe ~= 0
    h1 = figure;
end
if export_csv == 1
    if ~ischar(filename)
        error('You must specify the filename as a string!')
    end
    if isempty(strfind(filename,'.csv'))
        filename = [filename '.csv'];
    end
end

    
sRate = EEG.srate;
dataset = EEG.data;
howBig = size(dataset);
columns = howBig(2); % Number of samples (data points) per segment
window = columns * windowSize; % window size 
NFFT = 2^( round( log2( sRate ) ) ); % closest power of 2

% All channels in ROIs
leftFrontal = [23 24 27 28]; % CORRECTED!
leftCentral = [35 36 41 42];
leftPosterior = [51 52 59 60];
midFrontal = [5 11 12 16];
midCentral = [7 31 80 106];
midPosterior = [62 71 72 76];
rightFrontal = [3 117 123 124];
rightCentral = [93 103 104 110];
rightPosterior = [85 91 92 97]; 

ROIstr = {'leftFrontal';
'leftCentral';
'leftPosterior'; 
'midFrontal ';
'midCentral';
'midPosterior ';
'rightFrontal'; 
'rightCentral ';
'rightPosterior'};

% Matrix of ROI electrodes, each row is a region, each ...
% column is an electrode
ROI = [leftFrontal;
leftCentral ;
leftPosterior ;
midFrontal ;
midCentral ;
midPosterior ;
rightFrontal ;
rightCentral ;
rightPosterior];

f = linspace(0,sRate/2,NFFT/2+1); % frequency bins
rf = floor(f); % rounded frequency bins

powerAllChans = zeros(130,length(f)); % blank vector to hold PSDs for all channels

for i = 1:(NFFT/2+1)
    if rf(i) == 48 % Frequency cut off ... 
        gStop = i; % last gamma frequency index
    elseif rf(i) == 30
        gStart = i; % First gamma freq index
        b2Stop = i - 1; % last beta2 frequency index
    elseif rf(i) == 20
        b2Start = i;
        b1Stop = i - 1;
    elseif rf(i) == 12 
        b1Start = i; % first beta1 freq index .. you get the idea :)
        aStop = i - 1;
    elseif rf(i) == 8 
        aStart = i;
        tStop = i - 1;
    elseif rf(i) == 4 
        tStart = i;
        dStop = i - 1;
    elseif rf(i) == 1 
        dStart = i;
    end
end

% Empty matrices to hold power values 

AD = zeros(9,4);
RD = zeros(9,4);
AT = zeros(9,4);
RT = zeros(9,4);
AA= zeros(9,4); 
RA = zeros(9,4); 
AB1 = zeros(9,4); 
RB1 = zeros(9,4); 
AB2 = zeros(9,4);
RB2 = zeros(9,4);
AG = zeros(9,4);
RG = zeros(9,4);

panels = [1 4 7 2 5 8 3 6 9]; % Vector of subpanels for plotting, in order

h = waitbar(0,'Caclulating power ...');
step = 0;

for i = 1:9
    % High and low values for plotting PSDs
    HI = zeros(1,4);
    LOW = zeros(1,4);
    for j = 1:4
        [Pxx,F] = pwelch(dataset(ROI(i,j),:),window,[],NFFT,sRate); % calculate power Welch's method
        step = step + 1; % number of channels processed
        progress = step/129;
        waitbar(progress) % Progress bar
        NDX = ROI(i,j);
        powerAllChans(NDX,:) = Pxx; % Add to matrix
        if plotMe 
            figure(h1)
            subplot(3,3,panels(i)) % Select subpanel
            hold on
            plot(F(dStart:gStop),log(Pxx(dStart:gStop)),'linewidth',1,'color','blue');% changed rand(1,3) to blue
            xlabel('frequency (Hz)')
            ylabel('log power density (uV^{2}/Hz)')
            LOW(j) = min(log(Pxx(dStart:gStop))) - std(log(Pxx(dStart:gStop))); % Lower boundary
            HI(j) = max(log(Pxx(dStart:gStop))) + std(log(Pxx(dStart:gStop))); % Upper boundary
            axis([1 50 min(LOW) max(HI)]) % Set axes
            title(ROIstr(i)) % Set title
            grid on
        end
        
        % Sum across frequency bins
        AD(i,j) = sum(Pxx(dStart:dStop));
        AT(i,j) = sum(Pxx(tStart:tStop));
        AA(i,j) = sum(Pxx(aStart:aStop));
        AB1(i,j) = sum(Pxx(b1Start:b1Stop));
        AB2(i,j) = sum(Pxx(b2Start:b2Stop));
        AG(i,j) = sum(Pxx(gStart:gStop));
        
        % Total bandpass power
        tot = sum(Pxx(dStart:gStop)); % EDITED TO exlcude spectral power outside bandpass
        
        % Divide by total power to get relative power 
        RD(i,j) = AD(i,j)/tot;
        RT(i,j) = AT(i,j)/tot;
        RA(i,j) = AA(i,j)/tot; 
        RB1(i,j) = AB1(i,j)/tot; 
        RB2(i,j) = AB2(i,j)/tot;
        RG(i,j) = AG(i,j)/tot;       
    end
end

% Build new row of matrix containing ROI power values
studyPowerVals = [studyPowerVals; mean(RD,2)', mean(RT,2)', mean(RA,2)', mean(RB1,2)', mean(RB2,2)', mean(RG,2)']; %added

if export_csv
    csvwrite(filename,studyPowerVals) % export the matrix as a CSV
end

regions = ROI(1:36);
chanNDX = 1:129;
everyoneElse = setdiff(chanNDX,regions); % Which channels have we NOT calculated power for yet?

% Calculate power for remaining channels
for i = everyoneElse
    [Pxx,~] = pwelch(dataset(i,:),window,[],NFFT,sRate); % Calculate power using Welch's method
    step = step + 1; % Count number of chans that have been processed
    progress = step/129;
    waitbar(progress) % Update progress bar
    powerAllChans(i,:) = Pxx;
end

% Make the 130th row a vector of frequency values (NOT power values)
powerAllChans(130,:) = F;

try
    load(whoAmI) % Attempt to load the .mat mile
    display('Loading matrix ...')
    [~,~,c] = size(allPSDs); % Count number of layers
    allPSDs(:,:,c+1) = powerAllChans; % Add new layer
    save(whoAmI, 'allPSDs') % Save the 3D matrix
    display('Saving matrix.')
catch
    allPSDs = zeros(130,length(f),1); % Create new matrix if we couldn't load it
    display('Creating new matrix from scratch ...')
    allPSDs(:,:,1) = powerAllChans; % Build the first layer
    save(whoAmI, 'allPSDs') % save it
    display('Saving matrix.')
end

if ndims(allPSDs) == 3 % IF there is more than 1 layer, check for redundancy (important if you accidently run same subject twice)
    matSize = size(allPSDs);
    N = matSize(3);

    for i = 1:N % For each layer ...
        for j = i+1:N % ... check every other layer
            identity = allPSDs(:,:,i) == allPSDs(:,:,j); % See which elements are the same
            identity = sum(sum(identity));
            if identity == matSize(1)*matSize(2) % IF every element is the same
                message = strcat('Duplicate detected in PSD array! Layers_',num2str(i),'_and_',num2str(j),' are identical!');
                display(message)
            end
        end
    end
end

close(h) % Close progress bar

end



