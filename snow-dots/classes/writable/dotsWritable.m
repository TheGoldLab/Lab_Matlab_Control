classdef dotsWritable < handle
   %> @class dotsWritable
   %> Superclass for objects that write data.
   %> @details
   %> The dotsWritable superclass provides a uniform way to write data,
   %> such as TTL pulses.
   
   properties
      
      %> whether or not the object is ready to read() from
      isAvailable = false;
      
      %> any function that returns the current time as a number
      clockFunction;            
   end
   
   properties (SetAccess = protected)
   end
   
   methods
      
      %> Constructor takes no arguments.
      function self = dotsWritable()
         mc = dotsTheMachineConfiguration.theObject();
         mc.applyClassDefaults(self, mc.defaultGroup);
      end
      
      %> Locate, acquire, configure, etc. device and component resources.
      function initialize(self, varargin)
         
         %> Protection from redundant initializations
         self.closeDevice();
         
         %> Try to open device and components from scratch
         self.openDevice(varargin{:});
      end
      
      %> Get the current time from clockFunction.
      function time = getDeviceTime(self)
         time = feval(self.clockFunction);
      end
      
      %> Release any resources acquired by initialize().
      function close(self)
         self.closeDevice();
      end
      
      %> Automatically close when Matlab is done with this object.
      function delete(self)
         self.close();
      end
   end
   
   methods (Access = protected)
      %> Locate and acquire input device resources (for subclasses).
      %> @details
      %> Subclasses must redefine openDevice().  They should expect
      %> openDevice() to be called during initialize() and when an object
      %> is constructed.  openDevice() should locate, acquire, configure,
      %> etc. major device resources required for reading data.  Specific
      %> resources relating to device components, like individual buttons
      %> of a gamepad, should be handled in openComponents().
      %> @details
      %> openDevice() should return true if resources were successfully
      %> acquired and individual components are ready to be opened.
      %> Otherwise, openDevice() should return false.
      function openDevice(self)
         self.isAvailable = false;
      end
      
      %> Release input device resources (for subclasses).
      %> @details
      %> Subclasses must redefine closedevice().  Any resources that
      %> were acquired by openDevice() should be released.  It should
      %> be safe to call closeDevice() multiple times in a row.
      function closeDevice(self)
         self.isAvailable = false;
      end
   end
end