function [u_, attributes_, batchMethods_] = dXudp(num_objects)
% function [u_, attributes_, batchMethods_] = dXudp(num_objects)
%
% Creates a dXudp object
%
% Arguments:
%   num_objects    ... ignored
%
% Returns:
%   u_             ... created dXudp object
%   attributes_    ... default object attributes
%   batchMethods_  ... methods that can be run in a batch (e.g., done)

% Copyright 2006 by Ben Heasly
%   University of Pennsylvania

% discover the local host IP address
host = java.net.InetAddress.getLocalHost;
hostName = host.getHostName.toCharArray';
if strncmp(hostName, 'quadMaster', 10) || strncmp(hostName, 'humdinger', 9)
    % force client connection using built in ethernet #2
    localIP = '1.1.1.2';
else
    % autodetect ip address on main ethernet connection
    localIP = host.getHostAddress.toCharArray';
end

% default object attributes
attributes = { ...
    % name              type		ranges  default
    'localIP',      'string',       [],     localIP;        ...
    'remoteIP',     'string',       [],		'192.168.16.250';      ...
    'port',         'scalar',       [],		6665;           ...
    'socketIndex',  'scalar',       [],     -1;             ...
    'sendDoneFlag', 'boolean',      [],     false;          ...
    'messageIn',    'string',       [],     '';             ...
    'messageOut',   'string',       [],     '';             ...
    'retry',        'scalar',       [],     10;             ...
    'initialized',  'auto',         [],     [];             ...
    };

% make an array of objects from structs made from the attributes
u_ = class(cell2struct(attributes(:,4), attributes(:,1), 1), 'dXudp');

% return the attributes, if necessary
if nargout > 1
    attributes_ = attributes;
end

% return list of batch methods
if nargout > 2
    batchMethods_ = {'root', 'reset'};
end
