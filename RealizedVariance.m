clear
path = "C:\TAQ"; %Where the 2 years worth of extracted data is located
data = dir(fullfile(path, '*.mat')); %What do we call the directory

for i = 1 : numel(data)'
load(data(i).name);
RVol(i) = sqrt(sum(RVar));
end 
RVol = sqrt(77)*sqrt(250)*RVol;

for i = 1 : numel(data)'
load(data(i).name);

end