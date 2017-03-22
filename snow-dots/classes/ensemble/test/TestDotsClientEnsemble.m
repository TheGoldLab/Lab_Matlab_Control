classdef TestDotsClientEnsemble < TestTopsEnsemble
    % Test the client version of tops ensemble
    
    methods
        function self = TestDotsClientEnsemble(name)
            self = self@TestTopsEnsemble(name);
        end
        
        % test subclass may override to produce subclass
        function ensemble = getEnsemble(self, name)
            ensemble = dotsClientEnsemble(name);
            
            % fall back on a vanilla ensemble,
            %   so the test runner doesn't get all ornery.
            if ~ensemble.isConnected
                id = sprintf('%s:%s', mfilename(), 'getEnsemble');
                warning(id, 'Not Connected.  Fallback on topsEnsemble')
                ensemble = topsEnsemble(name);
            end
        end
        
        function testReset(self)
            [status, txn] = dotsClientEnsemble.resetServer();
            % only bother to check transaction if connected status OK
            if status >= 0
                assertFalse(isempty(txn.serverStartTime), ...
                    'server did not fill in transaction start time')
                assertFalse(isempty(txn.serverFinishTime), ...
                    'server did not fill in transaction start time')
            end
        end
    end
end