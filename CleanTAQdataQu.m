clear
path = "C:\TAQ\S\SPY\TAQ_QuRaw"; %Where the 2 years worth of extracted data is located

data = dir(fullfile(path, '*.mat')); %What do we call the directory

for i = 1 : numel(data)'
load(data(i).name);
itsdate = data(i).name(8:15);
 Time = double(TAQdata.utcsec)*1e-9; %Extract the data and format as double & alter nano-format
 Bid = TAQdata.bid;
 Ask = TAQdata.ofr;
 Exchange = TAQdata.ex;
 
idy =  Exchange == 'T' & 'N'; 
delRows1 = find(idy);
delRows1 = unique(delRows1);
ExchangeC = delRows1;
Time = Time([ExchangeC],:);
Bid = Bid([ExchangeC],:);
Ask = Ask([ExchangeC],:);
Exchange = Exchange([ExchangeC],:);

idx = Time>=34200 & Time<=56000;
idx = find(idx);
idx = unique(idx);
Exchange = Exchange([idx],:);
Bid = Bid([idx],:);
Ask = Ask([idx],:);
Time = Time([idx],:);
Time = duration(0, 0, Time);
TT1 = timetable(Time, Bid, Ask);
dt = minutes(5);
TT2 = retime(TT1,'regular','nearest','TimeStep',dt);


fdr = ['C:\TAQ\S\SPY\TAQ_QuCleaned']; %Specify directory to save file
save([fdr, '\SPY_' itsdate '-c.mat'], 'Time', 'Bid', 'Ask', 'Exchange', 'TT2');
end
