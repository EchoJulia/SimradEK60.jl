%Test output from matlab echolab against echoview
%
rawFile = 'D:\JR16003_Rob\ek60-sample.raw';
%
%
[header, rawData] = readEKRaw(rawFile);
%
%
% Check calibration inputs
calParms = readEKRaw_GetCalParms(header, rawData);
%
% Want Sv data to compare with echoview
data = readEKRaw_Power2Sv(rawData, calParms, KeepPower=TRUE);
%
%
% Read in echoview data
%
% 
EV_data = importdata('EK60_example2.sv.csv');
%
%% Compare EKrawreadin and echoview output. Some ambiguity on the number of samples - but other than that seems okay
%
subset_pings = data.pings(1).Sv(:,1:5)
plot(subset_pings(2:200,1),EV_data.data(1,9:207)')
plot(subset_pings(2:200,5),EV_data.data(5,9:207)')
%
% What about more data
plot(data.pings(1).Sv(2:200,1:20),EV_data.data(1:20,9:207)');
plot(data.pings(1).Sv(2:2000,1:20),EV_data.data(1:2000,9:207)');
plot(data.pings(1).Sv(2:500,1:20),EV_data.data(1:20,9:507)');
%
% calculations from matlab
%
% from readEKRaw_Power2Sv header
%
%   Sv is calculated as follows:
%
%       Sv = recvPower + 20 log10(Range) + (2 *  alpha * Range) - (10 * ...
%           log10((xmitPower * (10^(gain/10))^2 * lambda^2 * ...
%            c * tau * 10^(psi/10)) / (32 * pi^2)) - (2 * SaCorrection)
