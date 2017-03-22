classdef TestMxGram < TestCase
    
    properties
        doubles;
        chars;
        logicals;
        functionHandles;
    end
    
    methods
        function self = TestMxGram(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            clear mex
            
            self.doubles = { ...
                [], -100, 0, 1e6, pi, -exp(1), ...
                eye(10), nan(3, 50), inf(4, 10)};
            
            self.chars = {'a', sprintf('\n'), char('¿'*ones(30, 31))};
            
            self.logicals = {false(0,0), true(0,1), ...
                false, true, false(2, 400), true(300, 3)};
            
            self.functionHandles = {@disp, @numel, @size, @cheese, ...
                @TestMxGram.aStaticMethod, @TestMxGram.nonexistantStaticMethod};
        end
        
        function tearDown(self)
        end
        
        function [remade, bytes] = roundTrip(self, original)
            bytes = mxGram('mxToBytes', original);
            assertEqual(class(bytes), 'uint8', ...
                'should return array of single bytes')
            assertFalse(isempty(bytes), ...
                'should return filled array')
            
            remade = mxGram('bytesToMx', bytes);
            
            assertEqual(original, remade, ...
                'should have reproduced original variable')
        end
        
        function failWithUnreasonableInput(self, unreasonable)
            [bytes, status] = mxGram('mxToBytes', unreasonable);
            assertFalse(status > 0, ...
                'should return negative status for unreasonable input')
        end
        
        function structArray = structArrayFromCellArray(self, cellArray)
            for ii = 1:length(cellArray)
                fieldname = sprintf('field_number%d', ii);
                structArray.(fieldname) = cellArray{ii};
            end
        end
        
        function testNoArgs(self)
            % should print usage examples
            mexName = 'mxGram';
            result = evalc(mexName);
            assertFalse(isempty(strfind(result, mexName)), 'no-args should print usage string')
        end
        
        function testDoublesToFromBytes(self)
            for ii = 1:length(self.doubles)
                self.roundTrip(self.doubles{ii});
            end
        end
        
        function testUnreasonablyLargeDoublemxToChars(self)
            unreasonable = eye(1000);
            self.failWithUnreasonableInput(unreasonable);
        end
        
        function testCharsToFromBytes(self)
            for ii = 1:length(self.chars)
                self.roundTrip(self.chars{ii});
            end
        end
        
        function testUnreasonablyLargeCharmxToChars(self)
            unreasonable = char('a'*eye(1000));
            self.failWithUnreasonableInput(unreasonable);
        end
        
        function testLogicalsToFromBytes(self)
            for ii = 1:length(self.logicals)
                self.roundTrip(self.logicals{ii});
            end
        end
        
        function testUnreasonablyLargeLogicalmxToChars(self)
            unreasonable = true(1000,1000);
            self.failWithUnreasonableInput(unreasonable);
        end
        
        function testCellToFromBytes(self)
            self.roundTrip({});
            self.roundTrip(self.doubles);
            self.roundTrip(self.chars);
            self.roundTrip(self.logicals);
        end
        
        function testUnreasonablyLargeCellmxToChars(self)
            unreasonable = {eye(1000)};
            self.failWithUnreasonableInput(unreasonable);
        end
        
        function testFunctionsToFromBytes(self)
            for ii = 1:length(self.functionHandles)
                self.roundTrip(self.functionHandles{ii});
            end
        end
        
        function testAnonymousFunctionsToFromBytes(self)
            % anonymous functions don't compare,
            %   instead compare string versions of them
            anons = { ...
                @(input)disp(input), ...
                @(input,chicken)disp(chicken), ...
                @()numel(4), ...
                @(cracker)cheese(cracker), ...
                @()cheese, ...
                };
            
            for ii = 1:length(anons)
                original = anons{ii};
                bytes = mxGram('mxToBytes', original);
                assertEqual(class(bytes), 'uint8', ...
                    'should return array of single bytes')
                assertFalse(isempty(bytes), ...
                    'should return filled array')
                
                remade = mxGram('bytesToMx', bytes);
                assertEqual(class(remade), 'function_handle', ...
                    'should have reproduced a function handle')
                
                assertEqual(func2str(original), func2str(remade), ...
                    'original and remade functions should have same string representations')
            end
        end
        
        function testScalarStructToFromBytes(self)
            emptyStruct = struct;
            self.roundTrip(emptyStruct);
            
            doubleStruct = self.structArrayFromCellArray(self.doubles);
            self.roundTrip(doubleStruct);
            
            charStruct = self.structArrayFromCellArray(self.chars);
            self.roundTrip(charStruct);
            
            logicalStruct = self.structArrayFromCellArray(self.logicals);
            self.roundTrip(logicalStruct);
            
            funStruct = self.structArrayFromCellArray(self.functionHandles);
            self.roundTrip(funStruct);
        end
        
        function testStructArrayToFromBytes(self)
            doubleStruct = self.structArrayFromCellArray(self.doubles);
            self.roundTrip(repmat(doubleStruct, 1, 3));
            
            charStruct = self.structArrayFromCellArray(self.chars);
            self.roundTrip(repmat(charStruct, 1, 3));
            
            logicalStruct = self.structArrayFromCellArray(self.logicals);
            self.roundTrip(repmat(logicalStruct, 1, 3));
            
            funStruct = self.structArrayFromCellArray(self.functionHandles);
            self.roundTrip(repmat(funStruct, 1, 3));
        end
        
        function testUnreasonablyLargeStructmxToChars(self)
            unreasonable.largeDouble = eye(1000);
            self.failWithUnreasonableInput(unreasonable);
        end
        
        function testNestedTypesToFromBytes(self)
            s.double = eye(3);
            s.char = 'hellpo';
            s.fun = @disp;
            s.logical = true(10);
            s.cell = {eye(4), 'goodie', false(4), @numel, {1, 2, 3}, struct('field', 5)};
            s.struct = s;
            c = struct2cell(s);
            c{end+1} = s;
            self.roundTrip(c);
        end
        
        function testEmptyCellArray(self)
            emptyCell = cell(3,3);
            self.roundTrip(emptyCell);
        end
    end
    
    methods (Static)
        function aStaticMethod
        end
    end
end