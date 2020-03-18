function [result ] = Basic_Eyetracker_Example_Expt(params)
% Example script for an eye tracking task. 
% Basic Prosaccades to left or right, 
% indicated as the disc that changes colour.
% 
% As an example, also shows a visual cue at fixation 
% and plays a sound at the end.
% 
% Sanjay Manohar 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ex: experiment parameters

% trial structure
ex.type            = 'Eyelink example';  % put your experiment name here.
ex.practiceTrials  = 10;            
ex.useEyelink      = 1;             % if 0, just use keyboard
ex.skipScreenCheck = 0;             % for temperamental screens, put 1.
ex.displayNumber   = 0;             % for multiple monitors

ex.blockLen        = 48;            % trials per block 
ex.blocks          = 2;             % number of blocks

% Trial variables are combined to make a factorial design.
% This means that blockLen must be a multiple of the total 
% number of factors - in this case 2 possible targetPos, and 3 possible foreperiods:
ex.trialVariables.targetPos     = [1 2];         % go left or right 
ex.trialVariables.foreperiod    = [0.5 0.6 0.7]; % possible forepreiod (seconds)
ex.blockVariables.blockType     = 1;             % between-block variables (none)

% display params 
ex.targetLocations  = [ -1 0; 1 0 ] * 400;       % left or right
ex.bgColour         = [  0   0   0];   % background colour (RGB)
ex.fgColour         = [255 255 255];   % text colour 
ex.targetColour     = [128 128 128];   % disc colour
ex.targetSize       = 70;              % disc radius (px)
ex.ITI              = 0.500;           % seconds before trial

% saccade params (millisec, pixels)
ex.fixationTolerance= 240;         % acceptable distance from target (px)
ex.saccadeTimeout   = 2;           % terminate trial if no saccade in this time (sec)
ex.saccadeMinSize   = 40;          % saccades smaller than this are ignored (px)
ex.saccadeTargetSize= 240;         % radius of saccade landing points considered to be within target (px)

% sound files get automatically read into audioplayers, scr.soundPlayer{}
ex.soundFiles = { '../../media/ping.wav' 
                  '../../media/REGISTER2.wav' };

% image files get automatically read into psychtoolbox textures, scr.imageTexture()
ex.imageFiles = { 'Fractal001.png'
                  'Fractal002.png' };

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
	src  = [0 0 scr.imageSize{i}]; % source rectangle (px)
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
