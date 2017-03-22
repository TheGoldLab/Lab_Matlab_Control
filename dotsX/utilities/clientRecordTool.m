global ROOT_STRUCT

drawTimes = [ROOT_STRUCT.clientRecord{:,1}];
preflipTimes = [ROOT_STRUCT.clientRecord{:,2}];
postflipTimes = [ROOT_STRUCT.clientRecord{:,3}];


mft = mode(postflipTimes);

slowInds = find(postflipTimes > 1.5*mft);

figure(4)

subplot(2,1,1)
plot([0,preflipTimes(2:end)], 'g');
ylabel(gca,'pre-flip times (s)');
set(gca,'Ytick',[(0:.002:mft),mft,(10*mft:10*mft:200*mft)],'YGrid','on')
text(slowInds,preflipTimes(slowInds),'*','Color','r');

subplot(2,1,2)
plot([0,postflipTimes(2:end)], 'g');
ylabel(gca,'post-flip times (s)');
set(gca,'Ytick',[(mft:mft:3*mft),(4*mft:10*mft:200*mft)],'YGrid','on','YMinorTick','on')
text(slowInds,postflipTimes(slowInds),'*','Color','r');


for si = slowInds
    mess = char(ROOT_STRUCT.clientRecord{si,4});
    if isempty(mess)
        tim = [];
    else
        tim = ROOT_STRUCT.clientRecord{si,5};
    end
    disp(sprintf('At frame %i after %0.4fs',si,sum(postflipTimes(1:si-1))))
    disp(sprintf('     draw time was %0.4f',drawTimes(si)))
    disp(sprintf(' pre-flip time was %0.4f',preflipTimes(si)))
    disp(sprintf('post-flip time was %0.4f',postflipTimes(si)))
    disp(sprintf('%0.4f : total messages eval time',sum(tim)))
    for m = 1:size(mess,1)
        disp(sprintf('%0.4f for "%s',tim(m),mess(m,:)));
    end
    disp('------------------------------------')
end