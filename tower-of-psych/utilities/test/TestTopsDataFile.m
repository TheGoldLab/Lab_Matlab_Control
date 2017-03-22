classdef TestTopsDataFile < TestCase
    
    properties
        fileWithPath;
    end
    
    methods
        function self = TestTopsDataFile(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            [p,n,e] = fileparts(mfilename('fullpath'));
            self.fileWithPath = fullfile(p, 'topsDataFileTest.mat');
        end
        
        function tearDown(self)
            if exist(self.fileWithPath)
                delete(self.fileWithPath);
            end
        end
        
        function testCreate(self)
            fHeader = topsDataFile.newHeader( ...
                'fileWithPath', self.fileWithPath);
            assertTrue(isstruct(fHeader), ...
                'should get topsDataFile header metadata struct')
            assertEqual(self.fileWithPath, fHeader.fileWithPath, ...
                'should topsDataFile use supplied file name')
        end
        
        function testWriteReadIncrements(self)
            fHeader = topsDataFile.newHeader( ...
                'fileWithPath', self.fileWithPath);
            
            for ii = 1:10
                fHeader = topsDataFile.write(fHeader, ii);
                fHeader = topsDataFile.write(fHeader, -ii);
                [fHeader, increments] = topsDataFile.read(fHeader);
                assertEqual(numel(increments), 2, ...
                    'should read increments that were written')
                assertEqual(increments{1}, ii, ...
                    'should get first written increment, first')
                assertEqual(increments{2}, -ii, ...
                    'should get last written increment, last')
                
                [fHeader, increments] = topsDataFile.read(fHeader);
                assertTrue(isempty(increments), ...
                    'should not reread increments that were already read')
            end
        end
        
        function testRereadData(self)
            fHeader = topsDataFile.newHeader( ...
                'fileWithPath', self.fileWithPath);
            
            n = 10;
            for ii = 1:n
                fHeader = topsDataFile.write(fHeader, ii);
            end
            [fHeader, increments] = topsDataFile.read(fHeader);
            assertEqual(numel(increments), n, ...
                'should read all increments that were written')
            
            [fHeader, increments] = topsDataFile.read(fHeader);
            assertTrue(isempty(increments), ...
                'should not reread increments that were already read')
            
            [fHeader, increments] = topsDataFile.read( ...
                fHeader, fHeader.readIncrements);
            assertEqual(numel(increments), n, ...
                'should reread specified increments')
        end
    end
end