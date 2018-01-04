function texturePointer = textureMakerCheckers(textureObject, checkHeight, checkWid, totH, totW, color1, color2)
% Make a checkerboard texture of size totH X totW where each texture is
% checkHeight X checkWid and the checker in the top left is color1, and the
% other checker is color2
% Matt Nassar, 2010
% University of Pennsylvania

if isempty(totH)|isempty(totW)
    totW=textureObject.windowRect(3);
    totH=textureObject.windowRect(4);
end

if length(color1)>size(color1,1)
    color1=color1';
end

if length(color2)>size(color2,1)
    color2=color2';
end
    
checker1 = repmat(reshape(color1, 1,1,3), checkHeight, checkWid);
checker2 = repmat(reshape(color2, 1,1,3), checkHeight, checkWid);

%% make first column of checkers;
vertBlock=cat(1, checker1, checker2);
image1=vertBlock;
while size(image1, 1)<totH
    image1=cat(1, image1, vertBlock);
end
image1=image1(1:totH, :,:);

%% make second column of checkers

vertBlock=cat(1,  checker2,  checker1);
image2=vertBlock;
while size(image2, 1)<totH
    image2=cat(1, image2, vertBlock);
end
image2=image2(1:totH, :,:);

%% alternate first and second column across total width

horBlock=[image1 image2];
image=horBlock;
while size(image,2)<totW
    image = [image horBlock];
end
image = image(:, 1:totW,:);

%% return texture pointer
    
texturePointer = Screen('MakeTexture', textureObject.windowNumber, image);