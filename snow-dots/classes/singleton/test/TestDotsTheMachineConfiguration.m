classdef TestDotsTheMachineConfiguration < dotsTestCase
    
    properties
        checkList;
        tempFile;
        numericTolerance;
    end
    
    methods
        function self = TestDotsTheMachineConfiguration(name)
            self = self@dotsTestCase(name);
        end
        
        function setUp(self)
            self.setUp@dotsTestCase;
            
            self.numericTolerance = 1e-6;
            self.tempFile = 'TestDotsTheMachineConfigurationTemp.xml';
            self.checkList = topsGroupedList();
            
            mc = dotsTheMachineConfiguration.theObject();
            groups = mc.settings.groups;
            for ii = 1:length(groups)
                [items, mnemonics] = ...
                    mc.settings.getAllItemsFromGroup(groups{ii});
                for jj = 1:length(mnemonics)
                    self.checkList.addItemToGroupWithMnemonic( ...
                        items{jj}, groups{ii}, mnemonics{jj});
                end
            end
        end
        
        function tearDown(self)
            self.tearDown@dotsTestCase();
            
            self.checkList.removeAllGroups();
            if exist(self.tempFile, 'file')
                delete(self.tempFile)
            end
        end
        
        function checkSettingsAgainstList(self)
            mc = dotsTheMachineConfiguration.theObject();
            
            assertEqual(self.checkList.length, mc.settings.length, ...
                'settings length does not match checkList length')
            
            checkGroups = self.checkList.groups;
            settingsGroups = mc.settings.groups;
            assertEqual(checkGroups, settingsGroups, ...
                'settings groups do not match checkList groups')
            
            for ii = 1:length(checkGroups)
                [checkItems, checkMnemonics] = ...
                    self.checkList.getAllItemsFromGroup(checkGroups{ii});
                [settingsItems, settingsMnemonics] = ...
                    mc.settings.getAllItemsFromGroup(checkGroups{ii});
                
                assertEqual(length(checkItems), length(settingsItems), ...
                    'settings and cheklist have different number of items')
                assertEqual(checkMnemonics, settingsMnemonics, ...
                    'settings and cheklist have different mnemonics')
                
                for jj = 1:length(checkItems)
                    if isa(checkItems{jj}, 'function_handle')
                        assertEqual(func2str(checkItems{jj}), ...
                            func2str(settingsItems{jj}), ...
                            'function handle setting does not check out')
                        
                    elseif isnumeric(checkItems{jj})
                        assertElementsAlmostEqual(checkItems{jj}, ...
                            settingsItems{jj}, ...
                            'absolute', self.numericTolerance, ...
                            'numeric setting does not check out')
                        
                    else
                        assertEqual(checkItems{jj}, settingsItems{jj}, ...
                            'setting does not check out')
                    end
                end
            end
        end
        
        function testToFromXmlFile(self)
            dotsTheMachineConfiguration.writeUserSettingsFile( ...
                self.tempFile);
            assertTrue(exist(self.tempFile, 'file')>0, ...
                'should have written temp settings file')
            dotsTheMachineConfiguration.reset();
            dotsTheMachineConfiguration.readUserSettingsFile( ...
                self.tempFile);
            self.checkSettingsAgainstList();
        end
        
        function testToFromXmlDocument(self)
            mc = dotsTheMachineConfiguration.theObject();
            xDoc = mc.settingsToXmlDocument();
            dotsTheMachineConfiguration.reset();
            mc.settingsFromXmlDocument(xDoc);
            self.checkSettingsAgainstList();
        end
        
        function testCheckListWorks(self)
            self.checkSettingsAgainstList();
        end
    end
end