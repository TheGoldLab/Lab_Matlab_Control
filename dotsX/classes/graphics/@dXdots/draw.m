function d_ = draw(d_)
%draw method for class dXdots: prepare graphics for display
%   d_ = draw(d_)
%
%   All DotsX graphics classes have draw methods.  These prepare class
%   instances for displaying graphics upon the next dXscreen 'flip'.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded draw method for class dXdots
%-% note: this routine always returns the object
%-% in case it was changed
%-%
%-% 12/08/05 jig modified so that all loops
%-%   are computed at once
%-% 04/22/08 BSH modified wrapping behavior so
%-%   dots don't form stripes
%-% 04/30/08 BSH adding case for arbitrary direction distribution
%----------Special comments-----------------------------------------------
%
%   See also draw dXdots

% Copyright 2004 by Joshua I. Gold
%   University of Pennsylvania

% get real
if d_(1).windowNumber <=0
    return
end

% get loop index (same for all dots)
li = d_(1).loopIndex + 1;
if li > d_(1).loops
    li = 1;
end

% loop through the visible objects
for ii = find([d_.visible])

    % check loop pointer
    if li == 1

        %%%
        % get saved pts_
        %%%
        p1 = d_(ii).pts(1:2, :);
        p2 = d_(ii).pts(3, :);

        %%%
        % select coherent dots
        %%%
        %
        % depends on 'lifetimeMode'
        %   if 'random', use rand to pick based on coh (no limit)
        %   if 'limit', sort lifetime array and pick
        %       dots with the longest lifetimes (limit)
        % First just get the coherent dots
        L  = rand(size(p2)) < d_(ii).dotCoh;

        if strcmp(d_(ii).lifetimeMode, 'limit')

            % use the hits to select from the sorted array of
            % lifetimes (pick the shortest)
            num = sum(L);
            if num
                [y,I]           = sort(p2);
                L(I(1:num))     = true;
                L(I(num+1:end)) = false;
            end

            % update lifetimes
            p2( L) = p2(L) + 1;
            p2(~L) = 0;
        end

        %%%
        % offset positions
        %%%
        % Coherent dots move by the same, constant dx and dy
        %   -unless deltaDir is non-zero, in which case we randomize
        %   dot direction with a small uniform distribution.
        %   -unless dirDomain is non-empty, in which case we randomize
        %   dot direction with an arbitrary distribution of dX and dy.
        %
        % Either random case can pick a single direction for all dots, or
        %   pick a new direction for each dot indivudially.  Uses the same
        %   distribution in either case.

        if d_(ii).deltaDir

            % "deltaDir" is the width of a uniform distribution of directions
            % centered on "direction".  Pick direction(s) and, given
            % jumpSize, compute new dxdy.
            if d_(ii).groupMotion

                % one direction for all dots
                dir = pi/180*(d_(ii).direction + ...
                    2*d_(ii).deltaDir*rand - d_(ii).deltaDir);
                p1(1,L) = p1(1,L) + cos(dir) * d_(ii).jumpSize;
                p1(2,L) = p1(2,L) - sin(dir) * d_(ii).jumpSize;
            else

                % new direction for each dot
                dir = pi/180*(d_(ii).direction + ...
                    2*d_(ii).deltaDir*rand(1,sum(L)) - d_(ii).deltaDir);
                p1(:,L) = p1(:,L) +  [cos(dir); -sin(dir)] * d_(ii).jumpSize;
            end

        elseif ~isempty(d_(ii).dirDomain)

            % pick random direction(s) in which to offset
            %   this is just random lookup into a table of dx and dy

            if d_(ii).groupMotion

                % one direction for all dots
                randInd = floor(1-eps+rand*d_(ii).nP);
                p1(1,L) = p1(1,L) + d_(ii).dxdyDomain(1,randInd);
                p1(2,L) = p1(2,L) + d_(ii).dxdyDomain(2,randInd);
            else

                % new direction for each dot
                randInd = floor(1-eps+rand(1,sum(L))*d_(ii).nP);
                p1(:,L) = p1(:,L) + d_(ii).dxdyDomain(:,randInd);
            end

        else

            % offset the selected (coherent) dots by dxdy
            p1(:,L) = p1(:,L) + d_(ii).dxdy(:,L);
        end

        % non-coherent dots behavior depends on 'flickerMode'
        if any(~L)

            Ln = ~L;

            if strcmp(d_(ii).flickerMode, 'random')

                % in random mode
                p1(:, Ln) = rand(2, sum(Ln));
            else

                % in move mode, draw at random location for given jumpSize
                dirs      = 2*pi*rand(1, sum(Ln));
                p1(:, Ln) = p1(:, Ln) + [cos(dirs); -sin(dirs)] * d_(ii).jumpSize;
            end
        end

        %%%
        % wrap around
        %%%
        % behavior depends on 'wrapMode'
        Llo = p1 < 0;
        Lhi = p1 > 1;
        Lany = any(Llo|Lhi, 1);
        if any(Lany)

            if strcmp(d_(ii).wrapMode, 'random')

                % in random mode, redraw totally at random
                p1(:, Lany) = rand(2, sum(Lany));

            else

                % in wrap mode, redraw at random position on far edge
                % p1(Llo) = 1.0; % -0.1*rand(1,sum(Llo(:)));
                % p1(Lhi) = 0.0; %  0.1*rand(1,sum(Lhi(:)));

                % wrap the dimension that overran
                % but don't restart *on* the opposite edge,
                %   carry the overrun to prevent striping of dots
                p1(Llo) = 1.0 + p1(Llo);
                p1(Lhi) = p1(Lhi) - 1;

                % randomize the non-wrapped dimension
                p1([Llo(2,:)|Lhi(2,:); Llo(1,:)|Lhi(1,:)]) = ...
                    rand(1, sum(sum(Llo|Lhi)));

                % slowwwww....
                % pts_(flipdim(Llo|Lhi,2)) = rand(sum(sum(Llo|Lhi)),1);
            end
        end

        % save pts
        d_(ii).pts = [p1; p2];
        
        % save debugging data
        if d_(ii).debugSavePts
            d_(ii).ptsHistory = cat(3, d_(ii).ptsHistory, [p1;p2]);
        end
    end


    % call Screen('Dots') to do the work
    %     Screen('Dots', d_(1).windowNumber, ...
    %         d_(ii).pts(1:2, d_(ii).Lpts(li, :)), ...
    %         d_(ii).drawRect,  d_(ii).apRect, ...
    %         d_(ii).size, clutX(d_(ii).color), d_(ii).smooth);

    % no longer need Screen('Dots').  Now we use PTB builtin 'DrawDots'
    %   and a texture mask
    Screen('DrawDots', d_(1).windowNumber, ...
        d_(ii).pts(1:2, d_(ii).Lpts(li, :))*d_(ii).drawSizePix, ...
        d_(ii).size, ...
        clutX(d_(ii).color), ...
        d_(ii).drawRect(1:2));

    Screen('DrawTexture', d_(1).windowNumber, ...
        d_(ii).maskTexindex, ...
        d_(ii).maskSource, ...
        d_(ii).maskRect, ...
        [], [], []);
end

% update all loop pointers
[d_.loopIndex] = deal(li);

%%%% FOR TEXTURES ... NOT IMPLEMENTED %%%%%%
%
%     if isempty(d_(ii).textures)
%
%     else
%
%         % draw the texture
%         Screen('DrawTexture', d_(1).windowNumber, ...
%             d_(ii).textures(d_(ii).textureIndex), ...
%             d_(ii).sourceRect, d_(ii).destRect);
%
%         % update the texture pointer
%         d_(ii).textureIndex = d_(ii).textureIndex + 1;
%         if d_(ii).textureIndex > length(d_(ii).textures)
%             d_(ii).textureIndex = 1;
%         end
%     end