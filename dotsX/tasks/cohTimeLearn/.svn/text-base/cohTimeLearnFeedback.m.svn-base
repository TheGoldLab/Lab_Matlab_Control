function feedback = cohTimeLearnFeedback(dXp)
% generate a string which previews the upcoming cohTimeLearn task
%
%   feedback = cohTimeLearnFeedback(dXp)

% copyright 2008 Benjamin Heasly
%   University of Pennsylvania
global FIRA



    if dXp.repeatAllTasks < 0
                trialnum = strcmp(FIRA.ecodes.name, 'trial_num');
                dotcoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
                dotdir = strcmp(FIRA.ecodes.name, 'dot_dir');
                viewingtime = strcmp(FIRA.ecodes.name, 'viewing_time');
                task = strcmp(FIRA.ecodes.name, 'task_index');
                eGood = strcmp(FIRA.ecodes.name, 'good_trial');
                eCorrect = strcmp(FIRA.ecodes.name, 'correct');
                taskID = strcmp(FIRA.ecodes.name, 'taskNameID');
                timequesttime = strcmp(FIRA.ecodes.name, 'timeQ81_used');
                
                % Get final coherence data
                taskdataA= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==2),:);
                coherencedataA = taskdataA(:,dotcoherence);
                finalcohA= coherencedataA(end)
                feedbacktimeA = taskdataA(:,viewingtime);

                taskdataB= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==3),:);
                coherencedataB = taskdataB(:,dotcoherence);
                finalcohB= coherencedataB(end)
                feedbacktimeB = taskdataB(:,viewingtime);
               
                taskdataC= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==4),:);
                coherencedataC = taskdataC(:,dotcoherence);
                finalcohC= coherencedataC(end)
                feedbacktimeC = taskdataC(:,viewingtime);
                
                taskdataD= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==5),:);
                coherencedataD = taskdataD(:,dotcoherence);
                finalcohD= coherencedataD(end)
                feedbacktimeD = taskdataD(:,viewingtime);
                                 
                if feedbacktimeA(1) == 100 | feedbacktimeA(1) == 126
                    if finalcohA > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 159 | feedbacktimeA(1) == 200
                    if finalcohA > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 252 | feedbacktimeA(1) == 317
                    if finalcohA > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 400 | feedbacktimeA(1) == 502
                    if finalcohA > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                end
                
                if feedbacktimeB(1) == 100 | feedbacktimeB(1) == 126
                    if finalcohB > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 159 | feedbacktimeB(1) == 200
                    if finalcohB > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 252 | feedbacktimeB(1) == 317
                    if finalcohB > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 400 | feedbacktimeB(1) == 502
                    if finalcohB > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                end
                
                if feedbacktimeC(1) == 100 | feedbacktimeC(1) == 126
                    if finalcohC > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                
                elseif feedbacktimeC(1) == 159 | feedbacktimeC(1) == 200
                    if finalcohC > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                
                elseif feedbacktimeC(1) == 252 | feedbacktimeC(1) == 317
                    if finalcohC > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                
                elseif feedbacktimeC(1) == 400 | feedbacktimeC(1) == 502
                    if finalcohC > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                end

                if feedbacktimeD(1) == 100 | feedbacktimeD(1) == 126
                    if finalcohD > 60
                        feedback = 'Task Performance: Poor :-(  All Done.'
                        ROOTSTRUCT.payoutd = 2.25+ROOTSTRUCT.payoutc
                    elseif finalcohD > 40
                        feedback = 'Task Performance: Good :-)  All Done.'
                        ROOTSTRUCT.payoutd = 3+ROOTSTRUCT.payoutc
                    else
                        feedback = 'Task Performance: Excellent :-D  All Done.'
                        ROOTSTRUCT.payoutd = 3.75+ROOTSTRUCT.payoutc
                    end
                
                elseif feedbacktimeD(1) == 159 | feedbacktimeD(1) == 200
                    if finalcohD > 55
                        feedback = 'Task Performance: Poor :-(  All Done.'
                        ROOTSTRUCT.payoutd = 2.25+ROOTSTRUCT.payoutc
                    elseif finalcohD > 35
                        feedback = 'Task Performance: Good :-)  All Done.'
                        ROOTSTRUCT.payoutd = 3+ROOTSTRUCT.payoutc
                    else
                        feedback = 'Task Performance: Excellent :-D  All Done.'
                        ROOTSTRUCT.payoutd = 3.75+ROOTSTRUCT.payoutc
                    end
                
                elseif feedbacktimeD(1) == 252 | feedbacktimeD(1) == 317
                    if finalcohD > 45
                        feedback = 'Task Performance: Poor :-(  All Done.'
                        ROOTSTRUCT.payoutd = 2.25+ROOTSTRUCT.payoutc
                    elseif finalcohD > 30
                        feedback = 'Task Performance: Good :-)  All Done.'
                        ROOTSTRUCT.payoutd = 3+ROOTSTRUCT.payoutc
                    else
                        feedback = 'Task Performance: Excellent :-D  All Done.'
                        ROOTSTRUCT.payoutd = 3.75+ROOTSTRUCT.payoutc
                    end
                
                elseif feedbacktimeD(1) == 400 | feedbacktimeD(1) == 502
                    if finalcohD > 35
                        feedback = 'Task Performance: Poor :-(  All Done.'
                        ROOTSTRUCT.payoutd = 2.25+ROOTSTRUCT.payoutc
                    elseif finalcohD > 20
                        feedback = 'Task Performance: Good :-)  All Done.'
                        ROOTSTRUCT.payoutd = 3+ROOTSTRUCT.payoutc
                    else
                        feedback = 'Task Performance: Excellent :-D  All Done.'
                        ROOTSTRUCT.payoutd = 3.75+ROOTSTRUCT.payoutc
                    end
                end

    else

        switch rGet('dXtask', dXp.taski, 'name')


            case {'CohTimeLearn_Practice', 'CohTimeLearn_interleaved_Practice'}
                feedback = 'Practice: pick left or right motion (should be easy)';

            case {'CohTimeLearn_cohQuestA'}
                                
                feedback = 'Practice Done.  (Pull lever to initiate Coherence Quest)';

            case {'CohTimeLearn_cohQuestB'}
                
                trialnum = strcmp(FIRA.ecodes.name, 'trial_num');
                dotcoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
                dotdir = strcmp(FIRA.ecodes.name, 'dot_dir');
                viewingtime = strcmp(FIRA.ecodes.name, 'viewing_time');
                task = strcmp(FIRA.ecodes.name, 'task_index');
                eGood = strcmp(FIRA.ecodes.name, 'good_trial');
                eCorrect = strcmp(FIRA.ecodes.name, 'correct');
                taskID = strcmp(FIRA.ecodes.name, 'taskNameID');
                timequesttime = strcmp(FIRA.ecodes.name, 'timeQ81_used');
    
                % Coherence's equivalent to the above time data stuff               
                taskdataA= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==2),:);
                coherencedataA = taskdataA(:,dotcoherence);
                finalcohA= coherencedataA(end);
                feedbacktimeA = taskdataA(:,viewingtime);
                
                if feedbacktimeA(1) == 100 | feedbacktimeA(1) == 126
                    if finalcohA > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 159 | feedbacktimeA(1) == 200
                    if finalcohA > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 252 | feedbacktimeA(1) == 317
                    if finalcohA > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 400 | feedbacktimeA(1) == 502
                    if finalcohA > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                end

            case {'CohTimeLearn_cohQuestC'}
                
                trialnum = strcmp(FIRA.ecodes.name, 'trial_num');
                dotcoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
                dotdir = strcmp(FIRA.ecodes.name, 'dot_dir');
                viewingtime = strcmp(FIRA.ecodes.name, 'viewing_time');
                task = strcmp(FIRA.ecodes.name, 'task_index');
                eGood = strcmp(FIRA.ecodes.name, 'good_trial');
                eCorrect = strcmp(FIRA.ecodes.name, 'correct');
                taskID = strcmp(FIRA.ecodes.name, 'taskNameID');
                timequesttime = strcmp(FIRA.ecodes.name, 'timeQ81_used');
    
                % Coherence's equivalent to the above time data stuff
                taskdataA= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==2),:);
                coherencedataA = taskdataA(:,dotcoherence);
                finalcohA= coherencedataA(end);
                feedbacktimeA = taskdataA(:,viewingtime);

                taskdataB= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==3),:);
                coherencedataB = taskdataB(:,dotcoherence);
                finalcohB= coherencedataB(end);
                feedbacktimeB = taskdataB(:,viewingtime);
                
                if feedbacktimeA(1) == 100 | feedbacktimeA(1) == 126
                    if finalcohA > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 159 | feedbacktimeA(1) == 200
                    if finalcohA > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 252 | feedbacktimeA(1) == 317
                    if finalcohA > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 400 | feedbacktimeA(1) == 502
                    if finalcohA > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                end
                
                if feedbacktimeB(1) == 100 | feedbacktimeB(1) == 126
                    if finalcohB > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 159 | feedbacktimeB(1) == 200
                    if finalcohB > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 252 | feedbacktimeB(1) == 317
                    if finalcohB > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 400 | feedbacktimeB(1) == 502
                    if finalcohB > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                end
                
            case {'CohTimeLearn_cohQuestD'}
                
                trialnum = strcmp(FIRA.ecodes.name, 'trial_num');
                dotcoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
                dotdir = strcmp(FIRA.ecodes.name, 'dot_dir');
                viewingtime = strcmp(FIRA.ecodes.name, 'viewing_time');
                task = strcmp(FIRA.ecodes.name, 'task_index');
                eGood = strcmp(FIRA.ecodes.name, 'good_trial');
                eCorrect = strcmp(FIRA.ecodes.name, 'correct');
                taskID = strcmp(FIRA.ecodes.name, 'taskNameID');
                timequesttime = strcmp(FIRA.ecodes.name, 'timeQ81_used');
    
                % Coherence's equivalent to the above time data stuff
                taskdataA= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==2),:);
                coherencedataA = taskdataA(:,dotcoherence);
                finalcohA= coherencedataA(end);
                feedbacktimeA = taskdataA(:,viewingtime);

                taskdataB= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==3),:);
                coherencedataB = taskdataB(:,dotcoherence);
                finalcohB= coherencedataB(end);
                feedbacktimeB = taskdataB(:,viewingtime);
               
                taskdataC= FIRA.ecodes.data(find(FIRA.ecodes.data(:,task)==4),:);
                coherencedataC = taskdataC(:,dotcoherence);
                finalcohC= coherencedataC(end);
                feedbacktimeC = taskdataC(:,viewingtime);
                
                if feedbacktimeA(1) == 100 | feedbacktimeA(1) == 126
                    if finalcohA > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 159 | feedbacktimeA(1) == 200
                    if finalcohA > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 252 | feedbacktimeA(1) == 317
                    if finalcohA > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                
                elseif feedbacktimeA(1) == 400 | feedbacktimeA(1) == 502
                    if finalcohA > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 2.25
                    elseif finalcohA > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payouta = 3.75
                    end
                end
                
                if feedbacktimeB(1) == 100 | feedbacktimeB(1) == 126
                    if finalcohB > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 159 | feedbacktimeB(1) == 200
                    if finalcohB > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 252 | feedbacktimeB(1) == 317
                    if finalcohB > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                
                elseif feedbacktimeB(1) == 400 | feedbacktimeB(1) == 502
                    if finalcohB > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 2.25+ROOTSTRUCT.payouta
                    elseif finalcohB > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3+ROOTSTRUCT.payouta
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutb = 3.75+ROOTSTRUCT.payouta
                    end
                end
                
                if feedbacktimeC(1) == 100 | feedbacktimeC(1) == 126
                    if finalcohC > 60
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 40
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                
                elseif feedbacktimeC(1) == 159 | feedbacktimeC(1) == 200
                    if finalcohC > 55
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 35
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                
                elseif feedbacktimeC(1) == 252 | feedbacktimeC(1) == 317
                    if finalcohC > 45
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 30
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                
                elseif feedbacktimeC(1) == 400 | feedbacktimeC(1) == 502
                    if finalcohC > 35
                        feedback = 'Task Performance: Poor :-(  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 2.25+ROOTSTRUCT.payoutb
                    elseif finalcohC > 20
                        feedback = 'Task Performance: Good :-)  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3+ROOTSTRUCT.payoutb
                    else
                        feedback = 'Task Performance: Excellent :-D  (Pull lever to initiate next task)'
                        ROOTSTRUCT.payoutc = 3.75+ROOTSTRUCT.payoutb
                    end
                end
                
        otherwise
            feedback = 'Next: Unknown Task';
        end
    end



