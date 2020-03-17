clear all;
close all;

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
ex.trialVariables.rewardIndex   = [1,2,3];
ex.trialVariables.impulseFactor = [1,2,3,4];

ex.blockLen           = 48;  % number of  trials within each block.
ex.blocks             = 2;   % How many blocks are there? Note that calibration and practice phases are not blocks.
ex.blocktype          = 1;   % all blocks same =1
ex.type               = 'Grit_Task';  % put your experiment name here.
ex.practiceTrials     = 3;
ex.exitkey = KbName('Q');
% Trial variables are combined to make a factorial design.
% This means that blockLen must be a multiple of the total
% number of factors - in this case 2 possible targetPos, and 3 possible foreperiods:
ex.rewardInStake             = [10 20 50];    % low or high
ex.rewardIndex               = [1 2 3];    % low or high
ex.blockVariables.blockType  = 1;             % between-block variables (none)
ex.gain                      = 4;           % number of pixels a bar will rise per key press
% display params
ex.barPos           = [1140,225,1440,825]; % position of bar on screen
ex.bgColour         = [  0   0   0];   % background colour (RGB)
ex.fgColour         = [255 255 255];   % text colour
ex.ITI              = 0.500;           % seconds before trial
ex.RectColor        = [255 0 0];
ex.forceColour      = [255 0 0]; 
ex.yellow        = [255 255   0];   % wider (current) rung
% bar colour for force, red
% image files get automatically read into psychtoolbox textures, scr.imageTexture()
ex.imageFiles = { '10_pence.jpg'
  '20_pence.jpg'
  '50_pence.jpg' };
ex.promptPos       = [500 500];
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
ex.generateImpulseTime  = @()3+5*rand; % 10+10*rand
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

%% Start of block:
% this also controls calibraton and practice at the start of the experiment
function blockfn(scr, el, ex, tr);
global  totalReward
totalReward = 0; % start each block with zero total reward

if tr.block == 1 % display 'start of experiment' after last practice trial
  
  drawTextCentred(scr, 'When you are ready, press any key to continue',ex.fgColour);
  Screen('Flip',scr.w);
  waitForKeypress(); % wait for a key to be pressed before starting (defined at end of this script)
         

else  % starting a new block of the main experiment
  
  drawTextCentred(scr, 'End of block.', ex.fgColour, scr.centre +[0, -300])
  drawTextCentred(scr, 'When you are ready, press any key to continue', ex.fgColour)
  Screen('Flip',scr.w);
  waitForKeypress(); 

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tr=doTrial(scr, el, ex, tr)
% This function is run once for each trial in the experiment.
% combine trial-wise and experiment-wise parameters.


impulsePresent = 0; % this is the switch that is manipulated to ensure that
% each inpulse injected is only done so once per trial. see line ~ 130 for
% this. Impulses can only be applied if impulse = 0, Once an impulse is 
% applied, this switches to 1. 


counter = 0 ; % set a counter which will log the key presses and be used to
tr.pressTime = [];
tr.pressKey  = []; 
tr.releaseTime = [];
% determine the visual feedback
pa = combineStruct(ex, tr);

% drawTextCentred(scr,'Press Spacebar to start trial',pa.fgColour)
% Screen('Flip',scr.w);
% waitForKeypress();

tr.key=[]; tr.R=pa.R_INCOMPLETE; % start with trial being incomplete
tr.impulseTime = pa.generateImpulseTime(); % call function to generate random number to store
EXIT = false;

barPos = ex.barPos;
src  = [0 0 scr.imageSize{1}]; % source rectangle (px)
tpos = scr.centre;             % location of centre of image on screen
drc  = [tpos tpos] + ...       % destination rectangle
  [-0.5 -0.5 0.5 0.5].*[scr.imageSize{1} scr.imageSize{1}];
Screen('DrawTexture',scr.w, scr.imageTexture(pa.rewardIndex), src, drc); % draw image
Screen('FrameRect',scr.w,ex.forceColour,barPos); % draw bar
Screen('Flip',scr.w);
tr=LogEvent(pa, el, tr,'startStim');
WaitSecs(0.5);
tr=LogEvent(pa, el, tr,'startTime');


while  GetSecs < pa.trialTime + tr.startTime
  
  
  [ keyIsDown, timeSecs, keyCode] = KbCheck; % check the state of they keyboard


  if keyIsDown
    counter = counter + 1;
    tr.pressTime = [tr.pressTime,GetSecs-tr.startTime];
    tr.pressKey  = [tr.pressKey,keyCode];
    Screen('DrawTexture',scr.w, scr.imageTexture(pa.rewardIndex), src, drc); % draw image
    Screen('FrameRect',scr.w,ex.forceColour,barPos); % draw bar
    Screen('FillRect',scr.w,ex.forceColour,[barPos(1) barPos(2)+600-(counter*pa.gain) ...
      barPos(3) barPos(4)]);
    Screen('Flip',scr.w);


      % If the user holds down a key, KbCheck will report multiple events.
      % To condense multiple 'keyDown' events into a single event, we wait until all
      % keys have been released.
      KbReleaseWait;
     tr.releaseTime = [tr.releaseTime,GetSecs-tr.startTime]; % log time of key release
     if keyCode(pa.exitkey), EXIT = true; end   % check for ESCAPE

  end
  if GetSecs > tr.startTime+tr.impulseTime && impulsePresent == 0;
    counter = counter/pa.impulseFactor;
    impulsePresent = 1;
  end
  if impulsePresent ==1 && pa.impulseFactor ~=1 
        drawTextCentred(scr,'Whoops!',pa.yellow,scr.centre + [400,-350]);
  end
  
 if keyCode == pa.exitkey
    break;
 end
  
end
Screen('Flip',scr.w);
drawTextCentred(scr,'You won X pence',pa.fgColour)
drawTextCentred(scr,'Total reward: XXX',pa.fgColour,scr.centre + [0,100])
Screen('Flip',scr.w);
WaitSecs(2);





tr.R=1;

function EXIT = waitForKeypress()
% wait for a key to be pressed and released.
spacepressed  = false;
escapepressed = false;
exitkey  = KbName('ESCAPE');
spacekey = KbName('SPACE');

while  ~spacepressed && ~escapepressed
   [~,~,k]=KbCheck,  % get set of keys pressed
   spacepressed  = k(spacekey);
   escapepressed = k(exitkey); % is space or escape presesed?
   WaitSecs(0.1); 
end % wait for a key to be pressed before starting
if escapepressed, EXIT = true; return; else, EXIT=false; end

while KbCheck, WaitSecs(0.1); end  % (and wait for key release)
return


