classdef TestObjectGrapher < TestCase
    
    properties
    end
    
    methods
        function self = TestObjectGrapher(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
        end
        
        function tearDown(self)
        end
        
        function [seed, numObjects] = groupedListSeed(self)
            seed = topsGroupedList;
            numObjects = 3;
            seed.addItemToGroupWithMnemonic(1, 'a', 'one');
            seed.addItemToGroupWithMnemonic(dataset(1), 'a', 'two');
            seed.addItemToGroupWithMnemonic(1, 'b', 'one');
            seed.addItemToGroupWithMnemonic(dataset(2), 'b', 'two');
        end
        
        function [seed, numObjects] = mixedSeed(self)
            numObjects = 3;
            
            seed = containers.Map;
            seed('one') = 1;
            
            s.two = 2;
            s.map = dataset(2);
            seed('struct') = s;
            
            c{1} = 3;
            c{2} = dataset(3);
            seed('cell') = c;
            
            seed('object') = dataset(4);
        end
        
        function [seed, numObjects] = deepSeed(self)
            numObjects = 1;
            seed.next.next.next.next = dataset(1);
        end
        
        function [seed, numObjects] = stupidSeed(self)
            numObjects = 2;
            seed.empty = dataset.empty;
            seed.objArray = [topsGroupedList, topsGroupedList];
        end
        
        function testCrawlRedundant(self)
            [listSeed, n] = self.groupedListSeed;
            
            og = ObjectGrapher;
            og.addSeedObject(listSeed);
            og.addSeedObject(listSeed);
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, n, ...
                'wrong number of uniques for redunant seeds')
        end
        
        function testCrawlCyclic(self)
            [cyclicSeed, n] = self.groupedListSeed;
            cyclicSeed.addItemToGroupWithMnemonic( ...
                cyclicSeed, 'a', 'three')
            
            og = ObjectGrapher;
            og.addSeedObject(cyclicSeed);
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, n, ...
                'wrong number of uniques for cyclic seed')
        end
        
        function testCrawlOddObjects(self)
            [stupidSeed, n] = self.stupidSeed;
            
            og = ObjectGrapher;
            og.addSeedObject(stupidSeed);
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, n, ...
                'wrong number of uniques for stupid seed')
        end
        
        function testCrawlVariousTypes(self)
            [mixedSeed, n] = self.mixedSeed;
            
            og = ObjectGrapher;
            og.addSeedObject(mixedSeed);
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, n, ...
                'wrong number of uniques for cyclic seed')
        end
        
        function testCrawlSeveralSeeds(self)
            [listSeed, m] = self.groupedListSeed;
            [mixedSeed, n] = self.mixedSeed;
            [cyclicSeed, p] = self.groupedListSeed;
            cyclicSeed.addItemToGroupWithMnemonic( ...
                cyclicSeed, 'a', 'three');
            
            og = ObjectGrapher();
            og.addSeedObject(self.mixedSeed);
            og.addSeedObject(listSeed);
            og.addSeedObject(listSeed);
            og.addSeedObject(cyclicSeed);
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, m+n+p, ...
                'wrong number of uniques for cyclic seed')
        end
        
        function testCrawlLimitedElementDepth(self)
            [deepSeed, n] = self.deepSeed;
            
            og = ObjectGrapher();
            og.addSeedObject(deepSeed);
            
            og.maxElementDepth = 1;
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, 0, ...
                'should not have reached any object')
            
            og.maxElementDepth = 10;
            og.crawlForUniqueObjects;
            assertEqual(og.uniqueObjects.length, n, ...
                'should have reached one buried object')
        end
        
        function testLookupKey(self)
            og = ObjectGrapher;
            obj = topsGroupedList;
            key = og.addUniqueObject(obj);
            [containsObj, gotKey] = og.containsUniqueObject(obj);
            assertTrue(containsObj, ...
                'grapher should contain unique object just added!')
            assertEqual(key, gotKey, ...
                'grapher should return correct key for added object')
        end
    end
end