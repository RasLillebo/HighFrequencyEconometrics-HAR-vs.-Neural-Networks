clear

path = "C:\TAQ\S\SPY\TAQ_TrCleaned"; %Where the 2 years worth of extracted data is located

data = dir(fullfile(path, '*.mat')); %What do we call the directory

for i = 1 : numel(data)'
load(data(i).name);
itsdate = data(i).name(5:12);
TT = timetable(Time, Price);
dt = minutes(5);
TT3 = retime(TT,'regular','nearest','TimeStep',dt);

data2 = dir(fullfile("C:\TAQ\S\SPY\TAQ_QuCleaned", '*mat'));
load(data2(i).name);

Cleaned = synchronize(TT3, TT2);

fdr = ['C:\TAQ\S\SPY']; %Specify directory to save file
save([fdr, '\SPY_' itsdate '-c.mat'], 'Cleaned');
end