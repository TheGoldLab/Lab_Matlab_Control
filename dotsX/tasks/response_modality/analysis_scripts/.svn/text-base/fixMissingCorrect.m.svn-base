function correct = fixMissingCorrect
global FIRA

eDir = strcmp(FIRA.ecodes.name, 'dot_dir');

% recode left-right
eRight = strcmp(FIRA.ecodes.name, 'right');
right = ~isnan(FIRA.ecodes.data(:,eRight)) & FIRA.ecodes.data(:,eRight)~=0;
eLeft = strcmp(FIRA.ecodes.name, 'left');
left = ~isnan(FIRA.ecodes.data(:,eLeft)) & FIRA.ecodes.data(:,eLeft)~=0;
lr = cosd(FIRA.ecodes.data(:,eDir)) > 0;

% recode down-up
eUp = strcmp(FIRA.ecodes.name, 'up');
up = ~isnan(FIRA.ecodes.data(:,eUp)) & FIRA.ecodes.data(:,eUp)~=0;
eDown = strcmp(FIRA.ecodes.name, 'down');
down = ~isnan(FIRA.ecodes.data(:,eDown)) & FIRA.ecodes.data(:,eDown)~=0;;
du = sind(FIRA.ecodes.data(:,eDir)) > 0;

correct = (right&(lr==1)) | (left&(lr==0)) ...
    | (up&(du==1)) | (down&(du==0));