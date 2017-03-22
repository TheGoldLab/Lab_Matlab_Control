classdef dotsSocketMexUDP < dotsAllSocketObjects
    % @class dotsSocketMexUDP
    % Implement socket behavior using the mexUDP mex function, which is a
    % part of Snow Dots.
    methods
        % Open a BSD-style socket with mexUDP().
        function id = open(self, localIP, localPort, remoteIP, remotePort)
            id = mexUDP('open', localIP, remoteIP, localPort, remotePort);
        end
        
        % Close the given BSD-style socket with mexUDP().
        function status = close(self, id)
            status = mexUDP('close', id);
        end
        
        % Close all mexUDP() sockets.
        function status = closeAll(self)
            status = mexUDP('closeAll');
        end
        
        % Check whether the given mexUDP() socket is ready to read, using
        % BSD select().
        function hasData = check(self, id, timeoutSecs)
            if nargin < 3 || isempty(timeoutSecs)
                timeoutSecs = 0;
            end
            hasData = mexUDP('check', id, timeoutSecs) ~= 0;
        end
        
        % Read the next available packet from the given mexUDP() socket.
        function data = readBytes(self, id)
            data = mexUDP('receiveBytes', id);
        end
        
        % Write a packet to the given mexUDP() socket.
        function status = writeBytes(self, id, data)
            status = mexUDP('sendBytes', id, data);
        end
    end
end