
function KbDemo

KbName('UnifyKeyNames');


%% Run KbCheck script
KbDemoPart1;

return

%% Part 1sc
function KbDemoPart1


% Clear the workspace and the screen
sca;
close all;
clearvars;
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
% ensure you bypass mac bugs
Screen('Preference','SkipSyncTests',2)
% How many screens are there
screens = Screen('Screens');
% use the external one if more than one
ex.displayNumber = min(screens);
% define black
black = BlackIndex(ex.displayNumber);
% Open up a window
[window windowRect] = PsychImaging('OpenWindow',ex.displayNumber,black);

% image files get automatically read into psychtoolbox textures, scr.imageTexture()
ex.imageFiles = { '50_pence.jpg'
                  '20_pence.jpg' };
while KbCheck; end % Wait until all keys are released.


% Displays the key number when the user presses a key.
counter = 0;
fprintf('Press any key as many times as you can for 30 seconds');
fprintf('Press the escape key to exit');
escapeKey = KbName('ESCAPE');
startSecs = GetSecs;
while 1
  %DRAW CURRENT BAR
  % start with frame in the centre of the screen which is red.
  % what is the size of the onscreen window in pixels?
  [screenXpixels, screenYpixels] = Screen('WindowSize',window);
  % where is the centre of the screen?
  [xCenter, yCenter] = RectCenter(windowRect);
  % define a rectangle based on its co-ordinates
  baseRect = [0 0 300 600];
  % centre this rectangle in the middle of the screen
  RedCentre = CenterRectOnPointd(baseRect,xCenter+450,yCenter);
  twenty_pence=imread(ex.imageFiles{2});
  RectColor = [1 0 0];

  

  % set up counter to calculate total number of presses
  % Check the state of the keyboard.
  [ keyIsDown, timeSecs, keyCode] = KbCheck;
  % if Key is down then counter = counter + 1
  
  keyCode = find(keyCode, 1);
  % If the user is pressing a key, then display its code number and name.
  if keyIsDown
    
    % Note that we use find(keyCode) because keyCode is an array.
    % See 'help KbCheck'
    counter = counter + 1;
    test = ['Press the keyboard to advance in the race!'];
    
    % draw the square onto the screen
    Screen(window, 'TextSize', 42);        % default text font size
    Screen(window, 'TextFont',  'Arial');  % and
    DrawFormattedText(window,test,'center',100,[0,200,255]);
       
    FillRed = [590 350 200 100];
    Screen('FillRect',window,RectColor,[RedCentre(1) RedCentre(2)+600-counter ...
      RedCentre(3) RedCentre(4)]);

  if counter ==30 
    
  DrawFormattedText(window,'not bad, keep going!','center',100,[0,200,255]);
  Screen('FrameRect',window,RectColor,RedCentre);    
    ImTexture=Screen('MakeTexture',window,twenty_pence);
    Screen('DrawTexture',window,ImTexture,[],[]);
    Screen('Flip',window);
    FillRed = [590 350 200 100];
    Screen('FillRect',window,RectColor,[RedCentre(1) RedCentre(2)+600-counter ...
    RedCentre(3) RedCentre(4)]);

  end
    if keyCode == escapeKey
      break;
    end
    
    % If the user holds down a key, KbCheck will report multiple events.
    % To condense multiple 'keyDown' events into a single event, we wait until all
    % keys have been released.
    KbReleaseWait;
  end
  
end

return


