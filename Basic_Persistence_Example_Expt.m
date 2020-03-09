function [result ] = Basic_Persistence_Example_Expt(params)
% Example script for an eye tracking task. 
% Basic Prosaccades to left or right, 
% indicated as the disc that changes colour.
% 
% As an example, also shows a visual cue at fixation 
% and plays a sound at the end.
% 
% Youssuf Saleh 2020

%% SETUP
ex.DEBUG              = false;         % debug mode - 2 trials per block, for testing.
ex.skipScreenCheck    = 1;             % should be 0, but set to 1 if you get monitor warnings.
ex.displayNumber      = 1;             % for multiple monitors
ex.channel            = 1;             % Which data channel are you using for the handle?
ex.useSqueezy         = false;          % Change to 1 to use handles! whether or not to use the squeezy devices
ex.useEyelink         = false;         % load eye tracker?
ex.xhairSize          = [5 5];
ex.xhairCoords        = [5 5];
%% STRUCTURE
ex.trialVariables.trialtype = 0;
ex.blockLen           = 48;  % number of  trials within each block.
ex.blocks             = 2;   % How many blocks are there? Note that calibration and practice phases are not blocks.
ex.blocktype          = 1;   % all blocks same =1
ex.type               = 'Persistence example';  % put your experiment name here.
ex.practiceTrials     = 3;            
ex.useEyelink         = 0;             % if 0, just use keyboard
ex.skipScreenCheck    = 1;             % for temperamental screens, put 1.
ex.displayNumber      = 1;             % for multiple monitors choose 1 else choose 0

% Trial variables are combined to make a factorial design.
% This means that blockLen must be a multiple of the total 
% number of factors - in this case 2 possible targetPos, and 3 possible foreperiods:
ex.rewardinStake                = [10 20 50];    % low or high
ex.impulseFactor                = [1 2 3 4];     % factor by which progress is reduced 
ex.blockVariables.blockType     = 1;             % between-block variables (none)

% display params 
ex.targetLocations  = [ 1 0 ] * 450;       % left or right
ex.bgColour         = [  0   0   0];   % background colour (RGB)
ex.targetPos        = [1 1];
ex.fgColour         = [255 255 255];   % text colour 
ex.targetColour     = [128 128 128];   % disc colour
ex.targetSize       = 70;              % disc radius (px)
ex.ITI              = 0.500;           % seconds before trial

% image files get automatically read into psychtoolbox textures, scr.imageTexture()
ex.imageFiles = { '20_pence.jpg'
                  '50_pence.jpg' };
%% TIMINGS (all in seconds)
ex.calibrationDuration  = 5;   % Time for calibration squeeze
% Maximum time to wait for a decision
% Change to 300 for a self paced version. 
% Previous studies limited each trial to 10 seconds.
ex.maxTimeToWait        = 10;  % Time that a participant has to accept/reject
ex.timeBeforeChoice     = 0;   % Time after options appear, before "Yes/No" appears
ex.responseDuration     = 5;   % Time allowed to obtain require force on practice and Work-phase Yes trials
ex.delayAfterResponse   = 1;   % Time after squeeze period ends, and before reward appears (practice and work)
ex.rewardDuration       = 3;   % Time from when reward appears, until screen blanks (practice and work-yes)

% this has units of SAMPLES. How many samples Need to be above the yellow line?
% currently sampling at 500 Hz, so this is 2 seconds.
ex.minimumAcceptableSqueezeTime = 1000;

%% DISPLAY
ex.bgColour      = [0 0 0];         % background
ex.fgColour      = [255 255 255];   % text colour, white
ex.fgColour2     = [  0 255   0];   % lime green to highlight Yes/No choice
ex.fgColour3     = [0 0 255];       % text colour, blue
ex.silver        = [176 196 172];   % used for rungs of ladder
ex.brown         = [160  82  45];   % brown tree trunk
ex.yellow        = [255 255   0];   % wider (current) rung
ex.size_text     = 24;              % size of text
ex.forceBarPos   = [300 150];       % location of force bars on Screen, in pixels; Original was [300 150]
ex.forceBarWidth = 50;              % width of force bars, in px
ex.forceColour   = [255 0 0];       % bar colour for force, red
ex.forceScale    = 200;             % scale of size of force bars (pixels); Original ws 200
ex.extraWidth    = 20;              % How much wider is the force-level indicator than the bar (px).

ex.imageFiles = {'50_pence.jpg'
    '20_pence.jpg'};

% these Need to be global.
global MVC totalReward


% ask the user for a file name to save the data
% show file dialog:
[savefile, savepath] = uiputfile('','Save Grit Data filename','Grit_001_01.mat');
if isequal(savefile,0) || isequal(savepath,0) % did the user press escape?
  savename = 'Grit_Temp.mat';  % use a default filename
  fprintf('User cancelled save-file dialog box\n'); % warn user
else
  savename = fullfile(savepath,savefile); % locate the selected file.
end

%%%%%%%%%%%% RUN EXPERIMENT %%%%%%%%%%%%%
if ~exist('params') params=struct(); end;  % override settings from input parameter?
result = RunExperiment( @doTrial, ex, params);
%%%%%%%%%%% END OF EXPERIMENT %%%%%%%%%%%

return


function tr=doTrial(scr, el, ex, tr)
    % This function is run once for each trial in the experiment. 
    % combine trial-wise and experiment-wise parameters.
    pa = combineStruct(ex, tr);  
    
    % calculate target location on screen, using target position index
    tr.targetLocation = scr.centre+pa.targetLocations(pa.targetPos,:);
        
    tr.key=[]; tr.R=pa.R_INCOMPLETE; % start with trial being incomplete

    % inter-trial display - crosshair - wait until fixated
    Screen('FillRect',scr.w, pa.fgColour, scr.xhairCoords(:,:,1)'); 
    Screen('Flip', scr.w);
    tr=LogEvent(pa, el, tr,'startITI'); % log event at start
    if(pa.useEyelink)                   % wait for fixation 
      r=WaitForFixation(el,scr.centre, pa.fixationTolerance,1000*pa.ITI);
    else
      KbWait;
    end
    
    % cue image, & foreperiod
    drawRings(scr,pa);                  
	    src  = [0 0 scr.imageSize{1}]; % source rectangle (px)
	tpos = scr.centre;             % location of centre of image on screen
    drc  = [tpos tpos] + ...       % destination rectangle 
	       [-0.5 -0.5 0.5 0.5].*[scr.imageSize{1} scr.imageSize{1}];
    Screen('DrawTexture',scr.w, scr.imageTexture(1), src, drc); % draw image
    Screen('Flip', scr.w);
    tr=LogEvent(pa, el, tr,'startcue');  
	
    if(pa.useEyelink)                    % ensure fixating for the foreperiod
      r=WaitForFixation(el,scr.centre, pa.fixationTolerance,1000*pa.foreperiod);
    else
      KbWait;
    end
    [z z kcode]=KbCheck;
    if kcode(pa.exitkey) tr.R=pa.R_ESCAPE; tr.key=find(kcode);end;  % exit if escape pressed

    % clear all saccades made so far from buffer: we only want to collect
    % saccades from now on, when deciding if the target has been hit.
    if(pa.useEyelink) flushEyelinkQueue(el); end;  
    
    % reveal the target
    drawRings(scr,pa);
    drawRing(scr,pa,pa.targetPos,pa.targetColour);
    Screen('Flip',scr.w);
    tr=LogEvent(pa, el, tr,'starttarget');
    
    % wait for response
    if(pa.useEyelink)             % If using eyelink
      reached=0;saccade=[];       % have the eyes reached the target yet?
      while ~reached              % if not,
        % wait for next saccade (or timeout)
        r=WaitForSaccade3(el, pa.saccadeTimeout, pa.saccadeMinSize);
        [z z kcode]=KbCheck; tr.key=find(kcode);   % check for keys too
        if ~any(kcode) & length(r)>2               % if a saccade:
          saccade = [saccade;r];                   % log saccade
          % we have reached if the distance of the endpoint to the target
          % is less than saccadeTargetSize
          reached = norm(r(2:3)-tr.targetLocation) < pa.saccadeTargetSize;
        elseif any(kcode)                          % if a key, log it and end.
          reached=1; tr.key=find(kcode);
        end;
      end
      tr.endpoint = r;
      tr.saccade=saccade;                          % store the saccade coordinates
    else  % if not using eyelink, use mouse cursor
      ShowCursor
      kcode=0; b=0; while (b(1)==0) && ~any(kcode) % wait for mouse click
        [x,y,b]=GetMouse;
        [z z kcode]=KbCheck;
        tr.key = find(kcode);
      end;
      tr.endpoint=[x,y,b];
      HideCursor;
    end;
    if(any(tr.key==pa.exitkey)) tr.R=pa.R_ESCAPE; end;   % exit if escape
    tr=LogEvent(pa, el, tr, 'saccadeaccepted');  % log that the saccade was accepted
    tr.rt=tr.saccadeaccepted-tr.starttarget;     % calculate RT from events    
    if tr.R==pa.R_INCOMPLETE                     % flag the trial as complete.
        tr.R   = tr.rt;
    end;
	
    play(scr.soundPlayer{1});                    % play sound number 1


function drawRings(scr, ex, fillColour)
    cmd='FrameOval'; col=ex.fgColour; sz=ex.targetSize;
    if exist('fillColour') cmd='FillOval'; col=fillColour; sz=ex.targetSize; end;
    for i=1:size(ex.targetLocations,1)
      c=ex.targetLocations(i,:) + scr.centre;
      Screen(cmd, scr.w, col, [c-sz c+sz]);
    end;
    
function drawRing(scr,ex,i,fillColour)
    c = ex.targetLocations(i,:) + scr.centre;
    Screen('FillOval', scr.w, fillColour, [c-ex.targetSize c+ex.targetSize]);
