D = transpIndex(result.data);
plot(squeeze(D.pressTime)');
% visually represent the number of key presses over time with the impulse
% time demonstrated 
times=squeeze(D.pressTime)';
impulseTime=squeeze(D.impulseTime)';
RewardInd = D.rewardIndex;
for i = 1:size(D.pressTime,2)
% subplot(2,3,i);
hold on
switch(RewardInd(i))
case 1
 G =  plot(times(:,i)','color','k');
case 2
  G=  plot(times(:,i)','color','b');
case 3
   G= plot(times(:,i)','color','g');
end
 x1=min(find(G.YData>impulseTime(i)));
 x2=max(find(G.YData<impulseTime(i)));
plot(mean([x1 x2]),impulseTime(i),'r*');
hold off
end