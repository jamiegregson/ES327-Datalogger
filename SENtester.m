%% prepare the data

% isolate file ending
filePattern = fullfile('.', '*.csv');

% create variable csvfiles to isolate csv files using filepattern ending
csvFiles = dir(filePattern);

% create table for all data
allData = table();

% use each file in csvfile to add its data to the table
for i = 1:length(csvFiles)

    % create variable from short filename by running through csvfiles
    baseFileName = csvFiles(i).name;

    % add filepath to basefilename for readtable use
    fullFileName = fullfile('.', baseFileName);

    % create table newData using data from current file - import and keep headings
    newData = readtable(fullFileName,'ReadVariableNames',true,'PreserveVariableNames',true);

    % add current file data newData to allData table
    allData = [allData; newData];
end

% use strings to create date and time variables for graphing
date = datetime(allData{:, 'Date DD.MM.YY'},'InputFormat','dd.MM.yyyy');
timeStr = datestr(allData{:, 'Time HH:MM:SS'}, 'HH:MM:SS');
time = datetime(timeStr,'InputFormat','HH:mm:ss');

% create new variable with date and time together (joining time and date
% strings)
myDatetime = datetime(date.Year,date.Month,date.Day,time.Hour,time.Minute,time.Second);



%% create graph for all variables against datetime (individual)
figure(1)
for i = 3:width(allData)
    
    % display in 2 columns of subplots
    subplot(ceil((width(allData)-2)/2),2,i-2)
    
    % plot datetime against all data with dots
    plot(myDatetime, allData{:,i},'.');
    
    % label axis
    xlabel('Time');
    ylabel(allData.Properties.VariableNames{i});
    title(allData.Properties.VariableNames{i});
end

%% create graph for variables together (*SEN Testing*)
figure(2)
for i = 3:width(allData)
    plot(myDatetime, allData{:,i},'.');
    hold on; 
end

xlabel('Time');
ylabel('O3 Concentration, ppb');
title('SEN0321 Ozone Sensor Comparison');
legend(allData.Properties.VariableNames(3:end)); 
hold off; 

%% correlation coeff
allData.Properties.VariableNames = {'Date', 'Time', 'Sensor 1', 'Sensor 2'};
TestData = [allData.("Sensor 1"),allData.("Sensor 2")];
Correlation_Coefficient = corrcoef(TestData)
R_pearson_corrcoef = Correlation_Coefficient(1,2)

figure(3)
diff = allData.("Sensor 1") - allData.("Sensor 2");
avg = (allData.("Sensor 1") + allData.("Sensor 2")) / 2;
scatter(avg, diff, '.', 'MarkerEdgeColor', 'black');
hold on;
line([min(avg) max(avg)], [mean(diff) mean(diff)], 'Color', 'red');
line([min(avg) max(avg)], [mean(diff) + 1.96*std(diff) mean(diff) + 1.96*std(diff)], 'Color', 'blue');
line([min(avg) max(avg)], [mean(diff) - 1.96*std(diff) mean(diff) - 1.96*std(diff)], 'Color', 'blue');
xlabel('Average ozone measurement');
ylabel('Difference between sensors');
title('Bland-Altman plot');

%% Perform  t-test assuming unequal variances
[h, p, ci, stats] = ttest2(allData.("Sensor 1"), allData.("Sensor 2"), 'Vartype', 'unequal');
% Display the results
disp(['t-statistic: ', num2str(stats.tstat)])
disp(['p-value: ', num2str(p)])