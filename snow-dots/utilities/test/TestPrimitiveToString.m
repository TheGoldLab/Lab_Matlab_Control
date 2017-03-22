classdef TestPrimitiveToString < TestCase
    
    properties
        numerics;
        nonNumerics;
        functionHandles;
        numericTolerance;
    end
    
    methods
        function self = TestPrimitiveToString(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.numericTolerance = 1e-6;
            
            self.numerics = {uint8(3), 44.65, pi, ...
                nan, inf, -inf, [], ...
                1:10, (-100:10)*exp(1), int16(0:5), ...
                eye(10), [1 2 3;4 5 6], single(eps*ones(100,4))};
            
            self.nonNumerics = {true, false, '', 'a', char(42:126), ...
                logical([0 1 1 0; 1 1 0 1]), ...
                ['aaaaaaa';'zzzzzzz';'ggggggg']};
            
            self.functionHandles = {@disp, @()disp('things'), ...
                @self.setUp, @(str)disp(str), @(stuff)self.setUp(stuff)};
        end
        
        function tearDown(self)
        end
        
        function assertEqualCheckType(self, a, b)
            if isnumeric(a) && isnumeric(b)
                message = sprintf( ...
                    'number %f should almost equal number %f', a, b);
                assertElementsAlmostEqual(double(a), double(b), ...
                    'absolute', self.numericTolerance, message);
                
            elseif isa(a, 'function_handle')
                assertTrue(isa(b, 'function_handle'), ...
                    'should be function handle')
                aStr = func2str(a);
                bStr = func2str(b);
                assertEqual(aStr, bStr, ...
                    'function %s should equal function %s')
                
            else
                assertEqual(a, b, 'values should be equal');
                
            end
        end
        
        function testNumericsToString(self)
            for ii = 1:length(self.numerics)
                string = primitiveToString(self.numerics{ii});
                regenerated = eval(string);
                self.assertEqualCheckType(self.numerics{ii}, regenerated);
            end
        end
        
        function testNonNumericsToString(self)
            for ii = 1:length(self.nonNumerics)
                string = primitiveToString(self.nonNumerics{ii});
                regenerated = eval(string);
                self.assertEqualCheckType( ...
                    self.nonNumerics{ii}, regenerated);
            end
        end
        
        function testFunctionHandles(self)
            for ii = 1:length(self.functionHandles)
                string = primitiveToString(self.functionHandles{ii});
                regenerated = eval(string);
                regenerated = eval(string);
                self.assertEqualCheckType( ...
                    self.functionHandles{ii}, regenerated);
            end
        end
        
        function testQuoteSubstitution(self)
            s = 'regular string';
            substitute = '"';
            
            inner = primitiveToString(s, substitute);
            outer = primitiveToString(inner);
            regeneratedInner = eval(outer);
            regeneratedInner(regeneratedInner==substitute) = '''';
            regenerated = eval(regeneratedInner);
            assertEqual(s, regenerated, ...
                'should have got back regular string')
        end
        
        function testFlatCell(self)
            c = cat(2, ...
                self.numerics, self.nonNumerics, self.functionHandles);
            string = primitiveToString(c);
            regenerated = eval(string);
            assertEqual(size(c), size(regenerated), ...
                'should regenerate cell array of same size')
            
            for ii = 1:numel(c)
                self.assertEqualCheckType(c{ii}, regenerated{ii});
            end
        end
        
        function testFlatStruct(self)
            c = cat(2, ...
                self.numerics, self.nonNumerics, self.functionHandles);
            fn = cell(numel(c), 1);
            for ii = 1:numel(c)
                fn{ii} = sprintf('field_%d', ii);
            end
            s = cell2struct(c, fn, 2);
            
            string = primitiveToString(s);
            regenerated = eval(string);
            
            regeneratedFn = fieldnames(regenerated);
            assertEqual(fn, regeneratedFn, ...
                'regenerated struct should have same fields as original')
            for ii = 1:length(fn);
                self.assertEqualCheckType( ...
                    s.(fn{ii}), regenerated.(fn{ii}));
            end
        end
    end
end