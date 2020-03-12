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
ex.displayNumber      = 0;             % for multiple monitors
ex.channel            = 0;             % Which data channel are you using for the handle?
ex.useSqueezy         = false;          % Change to 1 to use handles! whether or not to use the squeezy devices
ex.useEyelink         = false;         % load eye tracker?

%% STRUCTURE
ex.trialVariables.trialtype = 0;
ex.blockLen           = 48;  % number of  trials within each block.
ex.blocks             = 2;   % How many blocks are there? Note that calibration and practice phases are not blocks.
ex.blocktype          = 1;   % all blocks same =1
ex.type               = 'Grit_Task';  % put your experiment name here.
ex.practiceTrials     = 3;

% Trial variables are combined to make a factorial design.
% This means that blockLen must be a multiple of the total
% number of factors - in this case 2 possible targetPos, and 3 possible foreperiods:
ex.rewardInStake             = [10 20 50];    % low or high
ex.rewardIndex               = [1 2 3];    % low or high
ex.impulseFactor                = [1 2 3 4];     % factor by which progress is reduced
ex.blockVariables.blockType     = 1;             % between-block variables (none)

% display params
ex.barPos           = [1140,225,1440,825]; % position of bar on screen
ex.bgColour         = [  0   0   0];   % background colour (RGB)
ex.fgColour         = [255 255 255];   % text colour
ex.ITI              = 0.500;           % seconds before trial
ex.RectColor        = [255 0 0];
ex.forceColour      = [255 0 0];       % bar colour for force, red
% image files get automatically read into psychtoolbox textures, scr.imageTexture()
ex.imageFiles = { '10_pence.jpg'
  '20_pence.jpg'
  '50_pence.jpg' };
%% TIMINGS (all in seconds)
ex.calibrationDuration  = 5;   % Time for calibration squeeze
% Maximum time to wait for a decision
% Change to 300 for a self paced version.
% Previous studies limited each trial to 10 seconds.
ex.maxTimeToWait        = 10;  % Time that a participant has to act
ex.responseDuration     = 5;   % Time allowed to obtain require force on practice and Work-phase Yes trials
ex.delayAfterResponse   = 1;   % Time after squeeze period ends, and before reward appears (practice and work)
ex.rewardDuration       = 3;   % Time from when reward appears, until screen blanks (practice and work-yes)
ex.trialTime            = 10;
% this has units of SAMPLES. How many samples Need to be above the yellow line?
% currently sampling at 500 Hz, so this is 2 seconds.
ex.minimumAcceptableSqueezeTime = 1000;

%% Prompt to save file
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

counter = 0 ; % set a counter which will log the key presses and be used to 
% determine the visual feedback
  trialTime = GetSecs+ ex.trialTime; % how long will each trial be
  pa = combineStruct(ex, tr);
  tr=LogEvent(pa, el, tr,'starttime');
  tr.key=[]; tr.R=pa.R_INCOMPLETE; % start with trial being incomplete

  
  while  GetSecs<trialTime
    
    while KbCheck; end %
    [ keyIsDown, timeSecs, keyCode] = KbCheck; % check the state of they keyboard
    keyCode = find(keyCode, 1); % what is the key code and can we store this?
    if keyIsDown 
      counter = counter + 1;
    
    
    barPos = ex.barPos;
    src  = [0 0 scr.imageSize{1}]; % source rectangle (px)
    tpos = scr.centre;             % location of centre of image on screen
    drc  = [tpos tpos] + ...       % destination rectangle
      [-0.5 -0.5 0.5 0.5].*[scr.imageSize{1} scr.imageSize{1}];
    Screen('DrawTexture',scr.w, scr.imageTexture(1), src, drc); % draw image
    Screen('FrameRect',scr.w,ex.forceColour,barPos); % draw bar
    Screen('FillRect',scr.w,ex.forceColour,[barPos(1) barPos(2)+600-(counter*1.5) ...
      barPos(3) barPos(4)]);
    
    
    
    % clear all saccades made so far from buffer: we only want to collect
    % saccades from now on, when deciding if the target has been hit.
    % if(pa.useEyelink) flushEyelinkQueue(el); end;
    
    % reveal the target
    % drawRects(scr,pa);
    % drawRect(scr,pa,pa.targetPos,pa.forceColour);
    % tr=LogEvent(pa, el, tr,'starttarget');
    if GetSecs==trialTime
    
    tr=LogEvent(pa, el, tr, 'endResponse');  % log that the saccade was accepted
    Screen('Flip', scr.w);WaitSecs(ex.ITI)
    end

    
    % tr.rt=tr.saccadeaccepted-tr.starttarget;     % calculate RT from events
    if tr.R==pa.R_INCOMPLETE                     % flag the trial as complete.
      %   tr.R   = tr.rt;
      
      escapeKey = KbName('ESCAPE');
      
      if keyCode == escapeKey
        break;
      end
      
      % If the user holds down a key, KbCheck will report multiple events.
      % To condense multiple 'keyDown' events into a single event, we wait until all
      % keys have been released.
      KbReleaseWait;
      
    end
  end
  
end
  Screen('Flip', scr.w);

%
% function buttonpress
%
% while KbCheck; end % wait for all the keys to be released
% while 1
%   % Check the state of the keyboard.
%   [ keyIsDown, timeSecs, keyCode] = KbCheck;
%    % if Key is down then counter = counter + 1
%   counter = 0
%   keyCode = find(keyCode, 1);
%   counter = counter + 1;