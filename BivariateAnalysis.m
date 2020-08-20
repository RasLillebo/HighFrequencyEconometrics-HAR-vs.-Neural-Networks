clear
path = "C:\TAQ\S\SPY"; %Where the 2 years worth of extracted data is located

data = dir(fullfile(path, '*.mat')); %What do we call the directory

for i = 1 : numel(data)'
load(data(i).name);
itsdate = data(i).name(5:13);
LowerBound = Cleaned.Bid*1.5;
UpperBound = Cleaned.Ask*1.5;
BiVa = LowerBound <= Cleaned.Price <= UpperBound;
BiVa = find(BiVa);
BiVa = unique(BiVa);
Cleaned = Cleaned([BiVa],:);
Returns = diff(log(Cleaned.Price));
fdr = ['C:\TAQ']; %Specify directory to save file
save([fdr, '\SPY_' itsdate 'cc.mat'], 'Cleaned', 'Returns', 'RVar');
end

