clear
path = "C:\TAQ\S\SPY\TAQ_TrRaw"; %Where the 2 years worth of extracted data is located

data = dir(fullfile(path, '*.mat')); %What do we call the directory

for i = 1 : numel(data)'
load(data(i).name);
itsdate = data(i).name(8:16);
  Time = double(TAQdata.utcsec)*1e-9; %Extract the data and format as double & alter nano-format
  Price = TAQdata.price;
  Corr = TAQdata.corr;
  Exchange = TAQdata.ex;

%Delete all data where EX != NYSE or NASDAQ
idy =  Exchange == 'T' & 'N'; 
delRows1 = find(idy);
delRows1 = unique(delRows1);
ExchangeC = delRows1;
Time = Time([ExchangeC],:);
Price = Price([ExchangeC],:);
Corr = Corr([ExchangeC],:);
Exchange = Exchange([ExchangeC],:);
%Delete all data that is not wihin 09:30 (34200) & 16:00 (56000)

idx = Time>=34200 & Time<=56000;
idx = find(idx);
idx = unique(idx);
Exchange = Exchange([idx],:);
Price = Price([idx],:);
Corr = Corr([idx],:);
Time = Time([idx],:);
%Delete all data that correlates
idz = Corr;
if idz ~= '00';
    idz = find(idz);
    idz = unique(idz);
    Corr = Corr([idz],:);
    Exchange = Exchange([idz],:);
    Price = Price([idz],:);
    Time = Time([idz],:);
    fprintf("Correlation")
end 
%Format Time as Time variable
Time = duration(0, 0, Time);

fdr = ['C:\TAQ\S\SPY\TAQ_TrCleaned']; %Specify directory to save file
save([fdr, '\SPY_' itsdate '-c.mat'], 'Time', 'Price', 'Corr', 'Exchange');

end