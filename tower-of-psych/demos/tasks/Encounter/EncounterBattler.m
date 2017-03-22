classdef EncounterBattler < handle
    % @class EncounterBattler
    % Class to represent character or monster in the "Encounter" demo game.

    properties
        % string name to display for this battler
        name = 'nameless';
        
        % interval between attacks for this battler
        attackInterval = 5;
        
        % average damage dealt by this battler
        attackMean = 1;
        
        % the hit points left for this battler
        HP = 1;
        
        % the hit points of this battler when new
        maxHP = 1;
    end
    
    properties (SetAccess = protected)
        % true or false, whether this battler is a monser
        isMonster = false;
        
        % true or false, whether this battler is already dead
        isDead = false;
        
        % [rgb] in [0 1] display color for this battler
        color;
        
        % [rgb] in [0 1] display outline color for this battler
        lineColor;
        
        % [rgb] in [0 1] display selection color for this battler
        highlightColor;
        
        % [rgb] in [0 1] display color for this battler when dead
        deadColor = [1 1 1];
        
        % [rgb] in [0 1] display outline color for this battler when dead
        deadLineColor = [1 1 1]*0.5;
        
        % vector of x-points for the polygon to display for this battler
        xPoints;
        
        % vector of y-points for the polygon to display for this battler
        yPoints;
        
        % handle graphics handle for displaying this batler
        bodyHandle;
        
        % handle graphics handle for displaying this batler's name
        nameHandle;
        
        % handle graphics handle for displaying damage dealt to this
        % battler
        damageHandle;
    end
    
    methods
        % Make a new battler object.
        function self = EncounterBattler(isMonster)
            if nargin >= 1
                self.isMonster = isMonster;
            end
            
            % choose some random, different colors
            n = 9;
            colors = puebloColors(9);
            shuffle = randperm(n);
            self.color = colors(shuffle(1), :);
            self.highlightColor = colors(shuffle(2), :);
            self.lineColor = colors(shuffle(3), :);
            
            if self.isMonster
                % results in a funky shape for monsters
                n = 5;
                self.xPoints = rand(1,n);
                self.yPoints = rand(1,n);
            end
        end
        
        % Refresh this battler as though new.
        function restoreHP(self)
            self.isDead = false;
            self.HP = self.maxHP;
        end
        
        % Create handle graphics objects for displaying this battler.
        function makeGraphicsForAxesAtPositionWithCallback( ...
                self, ax, position, callback)
            
            xIn = 0.15*position(3);
            yIn = 0.15*position(4);
            inpos = position + [xIn, yIn, -2*xIn, -2*yIn];
            
            if self.isMonster
                % create funky shape for monsters
                self.bodyHandle = patch( ...
                    'Parent', ax, ...
                    'XData', inpos(1) + self.xPoints*inpos(3), ...
                    'YData', inpos(2) + self.yPoints*inpos(4), ...
                    'DisplayName', self.name, ...
                    'FaceColor', self.color, ...
                    'EdgeColor', self.lineColor, ...
                    'LineStyle', ':', ...
                    'LineWidth', 1, ...
                    'ButtonDownFcn', callback, ...
                    'Selected', 'off', ...
                    'SelectionHighlight', 'off', ...
                    'UserData', self, ...
                    'Visible', 'on');
                
            else
                % create rounded rectangle for characters
                self.bodyHandle = rectangle( ...
                    'Parent', ax, ...
                    'Curvature', [.5 .9], ...
                    'DisplayName', self.name, ...
                    'FaceColor', self.color, ...
                    'EdgeColor', self.lineColor, ...
                    'LineStyle', '-', ...
                    'LineWidth', 3, ...
                    'Position', inpos, ...
                    'ButtonDownFcn', callback, ...
                    'Selected', 'off', ...
                    'SelectionHighlight', 'off', ...
                    'UserData', self, ...
                    'Visible', 'on');
            end
            
            self.nameHandle = text( ...
                'Parent', ax, ...
                'BackgroundColor', self.color, ...
                'Color', [0 0 0], ...
                'Position', [inpos(1:2), 0], ...
                'String', self.summarizeNameAndHP(), ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'UserData', self, ...
                'Visible', 'on');
            
            self.damageHandle = text( ...
                'Parent', ax, ...
                'BackgroundColor', [0 0 0], ...
                'Color', self.highlightColor, ...
                'Position', [inpos(1), inpos(2)+inpos(4)/2, 0], ...
                'String', '0', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'UserData', self, ...
                'Visible', 'off');
        end
        
        % Display a selection highlight for this battler.
        function showHighlight(self)
            if ~self.isDead
                set (self.bodyHandle, ...
                    'FaceColor', self.highlightColor, ...
                    'EdgeColor', self.highlightColor);
            end
        end
        
        % Un-display a selection highlight for this battler.
        function hideHighlight(self)
            if ~self.isDead
                set (self.bodyHandle, ...
                    'FaceColor', self.color, ...
                    'EdgeColor', self.lineColor);
            end
        end
        
        % Deal random damage to another battler.
        function attackOpponent(self, opponent)
            if ~self.isDead
                % do clipped-normal damage
                damage = max(0, normrnd(self.attackMean, self.attackMean/2));
                opponent.takeDamageAndShow(damage);
            end
        end
        
        % Take damage from another battler and display it.
        function takeDamageAndShow(self, damage)
            self.HP = self.HP - damage;
            if self.HP <=0
                self.dieAndShow();
            end
            set(self.damageHandle, ...
                'String', sprintf('%.1f', damage), ...
                'Visible', 'on');
            
            set(self.nameHandle, ...
                'String', self.summarizeNameAndHP());
        end
        
        % Un-display damage taken.
        function hideDamage(self)
            set(self.damageHandle, ...
                'String', '0', ...
                'Visible', 'off');
        end
        
        % Let this battler be isDead and display it.
        function dieAndShow(self)
            self.isDead = true;
            
            set(self.bodyHandle, ...
                'FaceColor', self.deadColor, ...
                'EdgeColor', self.deadLineColor, ...
                'ButtonDownFcn', [], ...
                'Selected', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
            set(self.nameHandle, ...
                'BackgroundColor', self.deadColor, ...
                'Color', self.deadLineColor, ...
                'Visible', 'on');
            set(self.damageHandle, ...
                'BackgroundColor', self.deadColor, ...
                'Color', self.deadLineColor, ...
                'Visible', 'on');
        end
        
        % Get a string with Battler name and hit points.
        function summary = summarizeNameAndHP(self)
            if self.isMonster
                summary = self.name;
            else
                summary = sprintf('%s (%d / %d)', ...
                    self.name, floor(self.HP), floor(self.maxHP));
            end
        end
        
        % Delete the handle graphics for displaying this battler.
        function deleteGraphics(self)
            if ishandle(self.bodyHandle)
                delete(self.bodyHandle);
            end
            self.bodyHandle = [];
            
            if ishandle(self.nameHandle)
                delete(self.nameHandle);
            end
            self.nameHandle = [];
            
            if ishandle(self.damageHandle)
                delete(self.damageHandle);
            end
            self.damageHandle = [];
        end
        
        % Make a new battler with the same properties as this battler.
        function newCopy = copy(self)
            % copy all fields into a new object
            newCopy = EncounterBattler();
            props = properties(self);
            for ii = 1:numel(props)
                prop = props{ii};
                value = self.(prop);
                if numel(value) == 1 && ishandle(value)
                    newCopy.(prop) = copyobj(value, get(value, 'Parent'));
                else
                    newCopy.(prop) = value;
                end
            end
        end
    end
end