classdef topsTaskHelper < topsFoundation
   % Class topsTaskHelper
   %
   % Standard interface for adding snow-dots "helper" objects to a
   % topsTreeNode
   
   properties (SetObservable)
      
      % The helper object
      theObject;
      
      % Flag to remove copy from treeNode (see start)
      removeCopy = true;
      
      % Keep track of the names of the objects in the ensemble
      ensembleObjectNames;
      
      % Keep track of the classes of objects in the ensemble
      ensembleObjectClasses;
      
      % For time synchronization
      sync = struct( ...
         'clockFevalable', {{}}, ...   % Function to get time from helper object
         'timeout',        0.5,  ...   % Timeout to get synchronization time, in sec
         'minRoundTrip',   0.02, ...   % Minimum round trip time, in sec
         'results',        struct( ...
         'referenceTime',  0, ...      % Time of local trial start
         'deviceTime',     0, ...      % Device time at synchronize event
         'offset',         0, ...      % Local time - device time
         'roundTrip',      0));
      
      % Below are properties used to bind the helper to a topsTreeNode
      %  Defaults are defined in the constructor method
      topsBindings = struct( ...
         'start',          [], ...     % Fevalables for task start
         'finish',         [], ...     % Fevalables for task finish
         'prepare',        [], ...     % Fevalables to prepare for trial
         'bindingNames',   [], ...     % Cell array of helper names to bind to this helper
         'copySpecs',      []);        % Specs to use when looking for a copy
   end
   
   methods
      
      % Construct the helper with standard specs
      %
      %
      % Arguments:
      %
      % helperName            ... string name
      % theObject             ... the helper object, or specs for parse
      % varargin is list of optional property/value pairs:
      %     'fevalable'       ... Fevalable ({<fcn> <args>}) used to
      %                                   create the helper
      %     'settings'        ... Struct of property values to set to
      %                                   this helper
      %     'commonSettings'  ... Struct of property values to set to
      %                                   all sub-helpers
      %     'prepare'         ... Cell arrray of fevalables for the prepare call list
      %     'synchronize'     ... fevalable to get helper time
      %     'start',          ... Cell array of fevalables to add to the
      %                                   topsTreeNode's start call list.
      %                                   Automatically adds the helper as
      %                                   the first arg to each fevalable.
      %     'finish'          ... like start, but for the finish call list
      %     'type'            ... 'ensemble', 'copy', or 'default'
      %     'bindingNames'    ... Cell array of names of struct fields
      %                                   to find helpers to share with the
      %                                   given helper object via its
      %                                   "bindHelpers" method
      %     OTHERWISE         ... other name/spec pairs
      function self = topsTaskHelper(name, theObject, varargin)
         
         % parse inputs
         p = inputParser;
         p.StructExpand = false;
         p.KeepUnmatched = true;
         p.addRequired( 'name');
         p.addRequired( 'theObject');
         p.addParameter('fevalable',        {});
         p.addParameter('settings',         struct());
         p.addParameter('commonSettings',   struct());
         p.addParameter('synchronize',      {});
         p.addParameter('prepare',          {});
         p.addParameter('start',            {});
         p.addParameter('finish',           {});
         p.addParameter('bindingNames',     {});
         p.addParameter('copySpecs',        struct());
         p.parse(name, theObject, varargin{:});
         
         % check name
         if isempty(p.Results.name) && isobject(p.Results.theObject)
            name = class(p.Results.theObject);
         end
         
         % Create the helper
         self = self@topsFoundation(name);
         
         % create & save the object. Send unmatched params in given order.
         self.theObject = self.parse(name, theObject, p.Results.fevalable, ...
            p.Results.settings, p.Results.commonSettings, ...
            orderParams(p.Unmatched, varargin));
         
         % Set up synchronization in the prepare call list
         if ~isempty(p.Results.synchronize)
            self.sync.clockFevalable = p.Results.synchronize;
            self.prepareCallList.addCall({@synchronize, self}, 'synchronize');
         end

         % Use default snow-dots clock
         if exist('dotsTheMachineConfiguration', 'file')
            self.clockFunction=dotsTheMachineConfiguration.getDefaultValue('clockFunction');
         end
         
         % BINDINGS: update from inputs
         for ff = fieldnames(self.topsBindings)'
            self.topsBindings.(ff{:}) = p.Results.(ff{:});
         end
      end
      
      % Parse constructor specs to make theObject -- possibly recursive if
      % making multiple objects and putting them into an ensemble
      %
      % Arguments:
      %  name           ... string name of the helper object
      %  theObject      ... the actual object, or spects to build (see below)
      %  fevalable      ... optional fevalable to make the object
      %  settings       ... struct of property/value pairs
      %  commonSettings ... struct of property/value pairs common to all objects
      %  unmatched      ... structs of settings for ensemble objects
      %
      % Returns:
      %  theObject   ... a helper object
      function theObject = parse(self, name, theObject, fevalable, ...
            settings, commonSettings, unmatched)
         
         % Make the object
         if ischar(fevalable) || isa(fevalable, 'function_handle')
            
            % Create from given function name/handle
            theObject = feval(fevalable);
            
         elseif iscell(fevalable) && ~isempty(fevalable)
            
            % Create from given fevalable
            theObject = feval(fevalable{:});
            
         elseif (ischar(theObject) && exist(theObject, 'file')==2) || ...
               isa(theObject, 'function_handle')
            
            % Create from function name/handle given as theObject
            theObject = feval(theObject);
        
         elseif ~isempty(unmatched)
            
            % Make objects from "unmatched" specs
            names      = fieldnames(unmatched);
            numObjects = length(names);
            if numObjects == 0
               return
            end
            specs = struct( ...
               'object',      cell(numObjects, 1), ...
               'names',       names, ...
               'settings',    []);
            
            % Loop through the objects
            for nn = 1:numObjects
               
               % Get the specs, fill in extras
               if isfield(unmatched.(names{nn}), 'fevalable')
                  specs(nn).fevalable = unmatched.(names{nn}).fevalable;
               end
               if isfield(unmatched.(names{nn}), 'settings')
                  specs(nn).settings = unmatched.(names{nn}).settings;
               end
                              
               % Recursively parse
               specs(nn).object = self.parse(names{nn}, [], ...
                  specs(nn).fevalable, specs(nn).settings, commonSettings, []);               
            end
            
            % Possibly make the ensemble
            if numObjects == 1 && ~isa(specs(nn).object, 'dotsDrawable')
               
               % Just take the single non-drawable object
               theObject = specs(nn).object;
               
            else
               
               % Making ensemble!               
               theObject = topsEnsemble.makeEnsemble(name, {specs.object});
               
               % Save the names, classes
               self.ensembleObjectNames = names;
               self.ensembleObjectClasses = cellfun(@(x) class(x), ...
                  {specs.object}, 'UniformOutput', false);               
               
               % Apply settings               
               for nn = 1:numObjects
                  topsSetObjectProperties(theObject, nn, commonSettings)
                  topsSetObjectProperties(theObject, nn, settings)
               end
               
               % Done!
               return
            end
         end
         
         % Apply settings to the object (NOT ENSEMBLE)
         if isobject(theObject)
            topsSetObjectProperties(theObject, [], commonSettings)
            topsSetObjectProperties(theObject, [], settings)
         else
            theObject = [];
         end
      end
      
      % start
      %
      % Called at task start
      function start(self, treeNode)
         
         % Check wehether we are getting a copy of theObject from another
         %  helper.. this is typically used for dotsReadables -- we make one
         %  set of readables (or just one readable) for the whole
         %  experiment, then in each task use a copy of them/it
         if isempty(self.theObject) && ~isempty(self.topsBindings.copySpecs)
            
            % Try to copy from a matching helper
            helpers = struct2cell(treeNode.helpers);
            
            % Check all given specs
            for ff = fieldnames(self.topsBindings.copySpecs)'
               if ~isempty(self.topsBindings.copySpecs.(ff{:}))
                  
                  % Check whether any of the objects are of the class indicated
                  %  by the name of the unmatched spec
                  Lmatch = cellfun(@(x) isa(x.theObject, ff{:}), helpers);
                  if any(Lmatch)
                     
                     % Got it!
                     theHelper = helpers{find(Lmatch,1)};
                     
                     % Get the copy specs
                     specs = self.topsBindings.copySpecs.(ff{:});
                     
                     % Copy everything
                     for pp = properties(theHelper)'
                        self.(pp{:}) = theHelper.(pp{:});
                     end
                     
                     % Copy new bindings from specs
                     for ss = fieldnames(specs)'
                        self.topsBindings.(ss{:}) = specs.(ss{:});
                     end
                     
                     % Possibly remove old copy
                     if self.removeCopy
                         treeNode.helpers = rmfield(treeNode.helpers, ...
                             class(theHelper.theObject));
                     end
                         
                     % Just need/want one
                     break
                  end
               end
            end
         end
         
         % Need the object to continue
         if isempty(self.theObject)
            return
         end

         % Set helperBindings (cell array of string names of helpers)
         for bb = makeCellString(self.topsBindings.bindingNames)
            self.theObject.helpers.(bb{:}) = treeNode.helpers.(bb{:}).theObject;
         end
         
         % Call start fevalables
         self.callFevalables(self.topsBindings.start);
      end
      
      % finish
      %
      % Called at task finish
      function finish(self, treeNode)
         
         % Call finish fevalables
         self.callFevalables(self.topsBindings.finish);
      end
      
      % Function to prepare for use, called before each trial
      %
      %  Just runs through the call list added using "prepare"
      function startTrial(self, treeNode)
         
         % Call prepare fevalables
         self.callFevalables(self.topsBindings.prepare);
         
         % Synchronize the time
         if ~isempty(self.sync.clockFevalable)
                        
            % Get the device time
            roundTrip  = inf;
            started    = feval(self.clockFunction);
            after      = started;
            while (roundTrip > self.sync.minRoundTrip) && ...
                  ((after-started) < self.sync.timeout);
               before      = feval(self.clockFunction);
               deviceTime  = feval(self.sync.clockFevalable{:});
               after       = feval(self.clockFunction);
               roundTrip   = after - before;
            end
            if (after-started) >= self.sync.timeout
               error(sprintf('Helper <%s>: Could not synchronize', self.name))
            end
            
            % offset is local - remote, then offset relative to topNode sync time
            self.sync.results.deviceTime = deviceTime;
            self.sync.results.offset = mean([before after])-deviceTime;            
            self.sync.results.roundTrip = roundTrip;
            
            % Store sync data in data log
            topsDataLog.logDataInGroup(self.sync.results, ['synchronize ' self.name]);
         end
      end
      
      % Finish trial method -- should overload in subclass if needed
      %
      function finishTrial(self, treeNode)          
      end
      
      % Set property
      %
      % Args are:
      %     for ensemble: property, value, index
      %     otherwise: property, value
      function setProperty(self, varargin)
         
         if isempty(self.theObject)
            return;
         end
         
         if isa(self.theObject, 'topsEnsemble')
            self.theObject.setObjectProperty(varargin{:});
         else
            self.theObject.(varargin{1}) = varargin{2};
         end
      end
   end
   
   methods (Access = protected)
      
      % Utility to call a list of fevalables
      %
      function callFevalables(self, fevalables)
         
         if isempty(fevalables)
            return
         end
         
         if iscell(fevalables{1})
            for ii = 1:length(fevalables)
               feval(fevalables{ii}{1}, self.theObject, fevalables{ii}{2:end});
            end
         else
            feval(fevalables{1}, self.theObject, fevalables{2:end});
         end
      end
   end
   
   methods (Static)
      
      % Get synchroniztion data from the current topsDataLog and make
      %  a maxtrix with columns:
      %        referenceTime
      %        offset
      %
      % Arguments:
      %  helperName ... string name of the helper object being synchronized
      %  varargin   ... (optional) string name of topsDataFile
      function synchronizationData = getSynchronizationData(helperName, varargin)
      
         % Get the synchronization data from the topsDataLog
         dataTub = topsDataLog.getTaggedData(['synchronize ' helperName], varargin{:});
         
         % Convert the synchronization tubs into structs
         %
         % NOTE: copying a helper results in two sets of
         % synchronization data logs ... clean them up here by always
         % taking the second one (the copy)
         tmpData = [dataTub.item];
         diffs = diff([tmpData.referenceTime]);
         diffi = find(diffs==0 & (diffs+1)<=size(tmpData,2));
         if any(diffi)
            tmpData = tmpData(1,diffi+1);
         end
         
         % Create matrix of referenceTime, deviceTime, offset
         synchronizationData = cat(2, ...
            [tmpData.referenceTime]', ...
            [tmpData.offset]');         
      end
      
      % Utility to make helpers
      %
      % Arguments:
      %  constructor ... string name that might be a topsTaskHelper<name>
      %  varargin    ... args sent to topsTaskHelper constructor
      %
      % Returns:
      %  struct with fields named for the created helpers
      %
      function helpers = makeHelpers(constructor, varargin)
         
         % Set up return struct
         helpers = struct();
         
         % Get args
         if nargin > 1 && isstruct(varargin{1})
            
            % ARG 1 IS A STRUCT TO UNPACK
            %
            % Recursively make a helper from each field, which should hold 
            %  a struct that is unpacked as arguments to the constructor
            theStruct = varargin{1};
            varargin(1) = [];
            for ff = fieldnames(theStruct)'
               
               % Get constructor args
               if isstruct(theStruct.(ff{:}))
                  % args are also a struct
                  structArgs = struct2args(theStruct.(ff{:}));
               else
                  % args are a cell
                  structArgs = theStruct.(ff{:});
               end
                  
               helperStruct = topsTaskHelper.makeHelpers(constructor, ...
                  ff{:}, structArgs{:}, varargin{:});
               for nn = fieldnames(helperStruct)'
                  helpers.(nn{:}) = helperStruct.(nn{:});
               end
            end
            
         else            
            
            % ARGS are property-value pairs
            %
            % Just make the helper from the constructor with the args
            if nargin >= 1 && ischar(constructor) && length(constructor)>1 && ...
                  exist(['topsTaskHelper' upper(constructor(1)) constructor(2:end)], 'file')
               % named helper, check case
               constructor = ['topsTaskHelper' upper(constructor(1)) constructor(2:end)];
            else
               % generic helper
               constructor = 'topsTaskHelper';
            end
            helper = feval(constructor, varargin{:});
            helpers.(helper.name) = helper;
         end
      end
   end
end
