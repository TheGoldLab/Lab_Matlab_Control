classdef dotsSocketPnet < dotsAllSocketObjects
    % @class dotsSocketPnet
    % Implement socket behavior using the pnet mex function.
    % @details
    % pnet is from the "tcp/udp/ip-toolbox" by Peter Rydester, Sweden, and
    % released under the GNU General Public License.
    %
    % See http://www.rydesater.com or search for "tcp/udp/ip-toolbox" on
    % the Matlab Central File Exchange.
    methods
        % Open a pnet "udpsocket", "udpconnect" it, and make it
        % non-blocking.
        function id = open(self, localIP, localPort, remoteIP, remotePort)
            id = pnet('udpsocket', localPort);
            if id >= 0
                status = pnet(id, 'udpconnect', remoteIP, remotePort);
                if status < 0
                    id = -2;
                    self.close(id);
                    warning('%s cannot connect to remote host (%d)', ...
                        mfilename, status);
                    return
                end
                
                % disable blocking when writing
                pnet(id ,'setwritetimeout', 0);

            else
                sprintf('%s cannot open UDP socket (%d)', ...
                    mfilename, id);
            end
        end
        
        % Close the given pnet socket.
        function status = close(self, id)
            status = 0;
            try
                pnet(id, 'close');
            catch
                status = -1;
            end
        end
        
        % Close all pnet sockets.
        function status = closeAll(self)
            status = 0;
            try
                pnet('closeall');
            catch
                status = -1;
            end
        end
        
        % Attempt to read from the given pnet socket without consuming
        % available data.
        function hasData = check(self, id, timeoutSecs)
            if nargin < 3 || isempty(timeoutSecs)
                timeoutSecs = 0;
            end
            pnet(id ,'setreadtimeout', timeoutSecs);
            
            data = pnet(id, 'read', 65536, 'uint8', 'view');
            if isempty(data)
                hasData = pnet(id, 'readpacket') > 0;
            else
                hasData = true;
            end
        end
        
        % Read any avalable data from the given pnet socket.
        function data = readBytes(self, id)
            pnet(id ,'setreadtimeout', 0);
            data = pnet(id, 'read', 65536, 'uint8');
            if isempty(data)
                nBytes = pnet(id, 'readpacket');
                if nBytes > 0
                    data = pnet(id, 'read', 65536, 'uint8');
                end
            end
        end
        
        % Write data to the given pnet socket.
        function status = writeBytes(self, id, data)
            pnet(id, 'write', data);
            status = pnet(id, 'writepacket');
        end
    end
end