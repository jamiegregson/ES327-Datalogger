%% process LEFT sensor data

cd('LData');

% define file types
filePattern = fullfile('.', '*.csv');

% create variable csvfiles to isolate csv files using filepattern ending
csvFiles = dir(filePattern);

% create table for all data
allDataL = table();

% use each file in csvfile to add its data to the table
for i = 1:length(csvFiles)

    % create variable filename by running through csvfiles
    baseFileName = csvFiles(i).name;
    fullFileName = fullfile('.', baseFileName);

    % create table newData using data from current file
    newData = readtable(fullFileName,'ReadVariableNames',true,'PreserveVariableNames',true);

    % add current file data newData to allData table
    allDataL = [allDataL; newData];
end

% use strings to create date and time variables for graphing
date = datetime(allDataL{:, 'Date'},'InputFormat','dd.MM.yyyy');
timeStr = datestr(allDataL{:, 'Time'}, 'HH:MM:SS');
time = datetime(timeStr,'InputFormat','HH:mm:ss');

% create new variable with date and time together (joining time and date strings)
myDatetime = datetime(date.Year,date.Month,date.Day,time.Hour,time.Minute,time.Second);

% Create empty datetime type table
myDatetimetable = datetime('now') + hours(1:1336)';

% Convert datetime array to table for use with other tables
myDatetimetable = array2table(myDatetime, 'VariableNames', {'DateTime'});

% replace in allData for one column datetime
allDataL.Date = myDatetimetable.DateTime;

% remove time column
allDataL(:, 2) = [];

% remove indoor air quality (debug only)
allDataL(:, 10) = [];
allDataL.Properties.VariableNames = {'Date', 'Temperature *C', 'Humidity %','Pressure hPa','Gas Resistance KOhm','Ozone ppb','Battery V','Soil Conductivity mS/m','Soil Temperature *C','CO2 Equivalent ppm','VOC equivalent ppm'};

cd('..');

%% process RIGHT sensor data

cd('RData');

% define file types
filePattern = fullfile('.', '*.csv');

% create variable csvfiles to isolate csv files using filepattern ending
csvFiles = dir(filePattern);

% create table for all data
allDataR = table();

% use each file in csvfile to add its data to the table
for i = 1:length(csvFiles)

    % create variable filename by running through csvfiles
    baseFileName = csvFiles(i).name;
    fullFileName = fullfile('.', baseFileName);

    % create table newData using data from current file
    newData = readtable(fullFileName,'ReadVariableNames',true,'PreserveVariableNames',true);

    % add current file data newData to allData table
    allDataR = [allDataR; newData];
end

% use strings to create date and time variables for graphing
date = datetime(allDataR{:, 'Date'},'InputFormat','dd.MM.yyyy');
timeStr = datestr(allDataR{:, 'Time'}, 'HH:MM:SS');
time = datetime(timeStr,'InputFormat','HH:mm:ss');

% create new variable with date and time together (joining time and date strings)
myDatetime = datetime(date.Year,date.Month,date.Day,time.Hour,time.Minute,time.Second);

% Create empty datetime type table
myDatetimetable = datetime('now') + hours(1:1336)';

% Convert datetime array to table for use with other tables
myDatetimetable = array2table(myDatetime, 'VariableNames', {'DateTime'});

% replace in allData for one column datetime
allDataR.Date = myDatetimetable.DateTime;

% remove time column
allDataR(:, 2) = [];


% remove indoor air quality (debug only)
allDataR(:, 10) = [];
allDataR.Properties.VariableNames = {'Date', 'Temperature *C', 'Humidity','Pressure hPa','Gas Resistance KOhm','Ozone ppb','Battery V','Soil Conductivity mS/m','Soil Temperature *C','CO2 Equivalent ppm','VOC equivalent ppm'};


cd('..');

%% process real data

cd('RealData');

%import real data 
realData = readtable('realdata.csv');
dendrometer = readtable('dendrometer.csv');
hourlyDataLC = readtable('hourlyDataL.csv');
hourlyDataRC = readtable('hourlyDataR.csv');

cd('..');

%% Remove Outliers using Z-Score Method (Left)
figure(3)
set(gcf, 'name', 'Data with Outliers Removed using Z-Score Method (Left)');

% Set z-score threshold
z_thresholdL = 3;

% Create a new table 
cleanDataL = allDataL;

% Remove rows with NaN values
cleanDataL = cleanDataL(~any(isnan(cleanDataL{:,2:end}),2),:);

% Loop through all columns of the table
numeric_cols = cleanDataL(:,2:end);
for i = 1:width(numeric_cols)
    
    % Calculate z-scores for each data point 
    z_scoresL = abs(zscore(numeric_cols{:,i}));
    
    % Remove data points with z-scores > threshold
    cleanDataL{z_scoresL > z_thresholdL, i+1} = NaN;
end

% Plot datetime against cleaned data
numeric_cols = cleanDataL(:,2:end);
for i = 1:width(numeric_cols)
    subplot(ceil((width(numeric_cols)-1)/2),2,i)
    plot(cleanDataL{:,1}, numeric_cols{:,i},'.');
    
    % Label axis and add title
    xlabel('Time');
    ylabel(numeric_cols.Properties.VariableNames{i});
    title(sprintf('%s', numeric_cols.Properties.VariableNames{i}));
end
sgtitle('Data with Outliers Removed using Z-Score Method (System 1)');

%% Remove Outliers using Z-Score Method (RIGHT)
figure(4)
set(gcf, 'name', 'Data with Outliers Removed using Z-Score Method (Right)');

% Set z-score threshold
z_thresholdR = 3;

% Create a new table
cleanDataR = allDataR;

% Remove rows with NaN values
cleanDataR = cleanDataR(~any(isnan(cleanDataR{:,2:end}),2),:);

% Loop through all columns of the tablenumeric_cols = cleanDataR(:,2:end);
for i = 1:width(numeric_cols)
    
    % Calculate z-scores for each data point 
    z_scoresR = abs(zscore(numeric_cols{:,i}));
    
    % Remove data points with z-scores > threshold
    cleanDataR{z_scoresR > z_thresholdR, i+1} = NaN;
end


% Plot datetime against cleaned data
numeric_cols = cleanDataR(:,2:end);
for i = 1:width(numeric_cols)
    subplot(ceil((width(numeric_cols)-1)/2),2,i)
    plot(cleanDataR{:,1}, numeric_cols{:,i},'.');
    
    % Label axis and add title
    xlabel('Time');
    ylabel(numeric_cols.Properties.VariableNames{i});
    title(sprintf('%s', numeric_cols.Properties.VariableNames{i}));
end
sgtitle('Data with Outliers Removed using Z-Score Method (System 2)');

%% process hourly averages of data (Left)
% Create a copy of cleanDataL
hourlyDataL = cleanDataL;

% Convert datetime to hourly datetime
hourlyDataL.Date = dateshift(hourlyDataL.Date, 'start', 'hour');

% Group data by hourly datetime
hourlyDataL = varfun(@mean, hourlyDataL, 'GroupingVariables', 'Date');

% Rename  variables
hourlyDataL.Properties.VariableNames{1} = 'HourlyDateTime';
hourlyDataL(:, 2) = [];
for i = width(hourlyDataL)
    hourlyDataL.Properties.VariableNames{i} = [cleanDataL.Properties.VariableNames{i}, '_mean'];
end

% Copy hourlyDataL to hourlyDataLC for correlation
hourlyDataLC = hourlyDataL;

% Duplicate the bottom row of hourlyDataL to make the total number of rows up to 360
while height(hourlyDataL) < 360
    hourlyDataL(end+1,:) = hourlyDataL(end,:);
end




%% process hourly averages of data (Right)
% Create a copy of cleanDataR
hourlyDataR = cleanDataR;

% Convert datetime to hourly datetime
hourlyDataR.Date = dateshift(hourlyDataR.Date, 'start', 'hour');

% Group data by hourly datetime
hourlyDataR = varfun(@mean, hourlyDataR, 'GroupingVariables', 'Date');

% Rename  variables
hourlyDataR.Properties.VariableNames{1} = 'HourlyDateTime';
hourlyDataR(:, 2) = [];
for i = width(hourlyDataR)
    hourlyDataR.Properties.VariableNames{i} = [cleanDataR.Properties.VariableNames{i}, '_mean'];
end

% Copy hourlyDataL to hourlyDataRC for correlation
hourlyDataRC = hourlyDataR;

% Duplicate the bottom row of hourlyDataR to make the total number of rows up to 360
while height(hourlyDataR) < 360
    hourlyDataR(end+1,:) = hourlyDataR(end,:);
end





%% create 12 hourly averages (LEFT)
% Duplicate hourlyDataL
twhourlyDataL = hourlyDataL;

% Keep the first row and delete every 11th row thereafter
keep = [1:12:height(twhourlyDataL)];
twhourlyDataL = twhourlyDataL(keep, :);

%% create 12 hourly averages (RIGHT)
% Duplicate hourlyDataL
twhourlyDataR = hourlyDataR;

% Keep the first row and delete every 11th row thereafter
keep = [1:12:height(twhourlyDataR)];
twhourlyDataR = twhourlyDataR(keep, :);

%% create 12 hourly averages (REAL)
% Duplicate hourlyDataL
twrealData = realData;

% Keep the first row and delete every 11th row thereafter
keep = [1:12:height(twrealData)];
twrealData = twrealData(keep, :);

%% process daily max temp (RIGHT)
% Create a copy of allData
dailymaxtempR = cleanDataR;

% Convert datetime to daily datetime
dailymaxtempR.Date = dateshift(dailymaxtempR.Date, 'start', 'day');

% Group data by daily datetime and find maximum temperature for each day
dailymaxtempR = varfun(@max, dailymaxtempR, 'GroupingVariables', 'Date', 'InputVariables', 'Temperature *C');

% Rename the variables
dailymaxtempR.Properties.VariableNames{1} = 'DailyDateTime';
dailymaxtempR.Properties.VariableNames{2} = 'MaxTemperature';
dailymaxtempR(:, 2) = [];

%% process daily max temp (LEFT)
% Create a copy of allData
dailymaxtempL = cleanDataL;

% Convert datetime to daily datetime
dailymaxtempL.Date = dateshift(dailymaxtempL.Date, 'start', 'day');

% Group data by daily datetime and find maximum temperature for each day
dailymaxtempL = varfun(@max, dailymaxtempL, 'GroupingVariables', 'Date', 'InputVariables', 'Temperature *C');

% Rename the variables
dailymaxtempL.Properties.VariableNames{1} = 'DailyDateTime';
dailymaxtempL.Properties.VariableNames{2} = 'MaxTemperature';
dailymaxtempL(:, 2) = [];

%% process daily means for all sensor variables L
% Create a copy of allDataR
dailyDataL = allDataL;
dailyDataL = rmmissing(dailyDataL);


% Convert datetime to daily datetime
dailyDataL.Date = dateshift(dailyDataL.Date, 'start', 'day');

% Group data by daily datetime and find @mean for each day
dailyDataL = varfun(@mean, dailyDataL, 'GroupingVariables', 'Date');

% Rename the variables
dailyDataL.Properties.VariableNames{1} = 'DailyDateTime';
for i = 2:width(dailyDataL)
    dailyDataL.Properties.VariableNames{i} = [allDataL.Properties.VariableNames{i-1}, '_mean'];
end

%% process daily means for all sensor variables R
% Create a copy of allDataR
dailyDataR = allDataR;
dailyDataR = rmmissing(dailyDataR);


% Convert datetime to daily datetime
dailyDataR.Date = dateshift(dailyDataR.Date, 'start', 'day');

% Group data by daily datetime and find @mean for each day
dailyDataR = varfun(@mean, dailyDataR, 'GroupingVariables', 'Date');

% Rename the variables
dailyDataR.Properties.VariableNames{1} = 'DailyDateTime';
for i = 2:width(dailyDataR)
    dailyDataR.Properties.VariableNames{i} = [allDataR.Properties.VariableNames{i-1}, '_mean'];
end

%% spot differences in data (debug only!)
valuesOnlyInL = setdiff(hourlyDataL(:, 1), hourlyDataR(:, 1));
valuesOnlyInR = setdiff(hourlyDataR(:, 1), hourlyDataL(:, 1));

%% GRAPHING

%% graph raw data against date and time (Left)
figure(1)
set(gcf, 'name', 'Raw Data for all Variables (Left)');
for i = 2:width(allDataL)
    
    % display in 2 columns of subplots
    subplot(ceil((width(allDataL)-2)/2),2,i-1)
    
    % plot datetime against all data with dots
    plot(allDataL{:,1}, allDataL{:,i},'.');
    
    % label axis
    xlabel('Time');
    ylabel(allDataL.Properties.VariableNames{i});
    title(allDataL.Properties.VariableNames{i});
    sgtitle('Raw Sensor Data against Time (System 1)');
end

%% graph raw data against date and time (Right)
figure(2)
set(gcf, 'name', 'Raw Data for all Variables (Right)');
for i = 2:width(allDataR)
    
    % display in 2 columns of subplots
    subplot(ceil((width(allDataR)-2)/2),2,i-1)
    
    % plot datetime against all data with dots
    plot(allDataR{:,1}, allDataR{:,i},'.');
    
    % label axis
    xlabel('Time');
    ylabel(allDataR.Properties.VariableNames{i});
    title(allDataR.Properties.VariableNames{i});
    sgtitle('Raw Sensor Data against Time (System 2)');
end



%% create graph for variables together (Left)
figure(5)
set(gcf, 'name', 'All data against date and time (Left)');
for i = 3:width(allDataL)
    plot(allDataL{:,1}, allDataL{:,i},'.');
    hold on; 
end

xlabel('Time');
ylabel('Values');
title('All Variables against Time (System 1)');
legend(allDataL.Properties.VariableNames(3:end)); 
hold off; 

%% create graph for variables together (Right)
figure(6)
set(gcf, 'name', 'All data against date and time (Right)');
for i = 3:width(allDataR)
    plot(allDataR{:,1}, allDataR{:,i},'.');
    hold on; 
end

xlabel('Time');
ylabel('Values');
title('All Variables against Time (System 2)');
legend(allDataR.Properties.VariableNames(3:end)); 
hold off; 


%% graph hourly averaged data against date and time (Left)
figure(7)
set(gcf, 'name', 'Hourly Data for all Variables (Left)');
for i = 2:width(hourlyDataL)
    
    % display in 2 columns of subplots
    subplot(ceil((width(hourlyDataL)-2)/2),2,i-1)
    
    % plot datetime against all data with dots
 
    plot(hourlyDataL{:,1}, hourlyDataL{:,i},'.');
    
    % label axis
    xlabel('Time');
    ylabel(allDataL.Properties.VariableNames{i});
    title(allDataL.Properties.VariableNames{i});
    sgtitle('Hourly data against Time (System 1)');
end

%% graph hourly averaged data against date and time (Right)
figure(8)
set(gcf, 'name', 'Hourly Data for all Variables (Right)');
for i = 2:width(hourlyDataR)
    
    % display in 2 columns of subplots
    subplot(ceil((width(hourlyDataR)-2)/2),2,i-1)
    
    % plot datetime against all data with dots
 
    plot(hourlyDataR{:,1}, hourlyDataR{:,i},'.');
    
    % label axis
    xlabel('Time');
    ylabel(allDataR.Properties.VariableNames{i});
    title(allDataR.Properties.VariableNames{i});
    sgtitle('Hourly data against Time (System 2)');
end

%% graph with left vs right vs actual for TEMPERATURE
figure(9)
set(gcf, 'name', 'Hourly averaged temperature data for system 1, 2 against actual data');
% Plot the data
plot(hourlyDataL{:, 1}, hourlyDataL{:, 2}, hourlyDataR{:, 1}, hourlyDataR{:, 2}, realData{:, 1}, realData{:, 2});

% Add axis labels and a legend
xlabel('Time');
ylabel('Temperature, *C');
legend('Hourly average from system 1', 'Hourly average from system 2', 'Real Data');
title('Temperature against historical data');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{:, 2}, hourlyDataRC{:, 2},'rows','complete');
r_temp1_temp2 = corr_mat(1, 2)

%corellation coefficient for sensor 1 vs real temp data
corr_mat = corrcoef(hourlyDataLC{:, 2}, realData{:, 2},'rows','complete');
r_temp1_real = corr_mat(1, 2)

%corellation coefficient for sensor 2 vs real temp data
corr_mat = corrcoef(hourlyDataRC{:, 2}, realData{:, 2},'rows','complete');
r_temp2_real = corr_mat(1, 2)

%% graph with left vs right vs actual for HUMIDITY
figure(10)
set(gcf, 'name', 'Hourly averaged humidity data for system 1, 2 against actual data');
% Plot the data
plot(hourlyDataL{:, 1}, hourlyDataL{:, 3}, hourlyDataR{:, 1}, hourlyDataR{:, 3}, realData{:, 1}, realData{:, 3});

% Add axis labels and a legend
xlabel('Time');
ylabel('Relative Humidity, %');
legend('Hourly average from system 1', 'Hourly average from system 2', 'Real Data');
title('Relative humidity against historical data');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{:, 3}, hourlyDataRC{:, 3},'rows','complete');
r_hum1_hum2 = corr_mat(1, 2)

%corellation coefficient for sensor 1 vs real data
corr_mat = corrcoef(hourlyDataLC{:, 3}, realData{:, 3},'rows','complete');
r_hum1_real = corr_mat(1, 2)

%corellation coefficient for sensor 2 vs real data
corr_mat = corrcoef(hourlyDataRC{:, 3}, realData{:, 3},'rows','complete');
r_hum2_real = corr_mat(1, 2)

%% graph with left vs right vs actual for PRESSURE
figure(11)
set(gcf, 'name', 'Hourly averaged pressure data for system 1, 2 against actual data');
% Plot the data
plot(hourlyDataL{:, 1}, hourlyDataL{:, 4}, hourlyDataR{:, 1}, hourlyDataR{:, 4}, realData{:, 1}, realData{:, 4});

% Add axis labels and a legend
xlabel('Time');
ylabel('Atmospheric Pressure, hPa');
legend('Hourly average from system 1', 'Hourly average from system 2', 'Real Data');
title('Atmospheric pressure against historical data');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{:, 4}, hourlyDataRC{:, 4},'rows','complete');
r_pre1_pre2 = corr_mat(1, 2)

%corellation coefficient for sensor 1 vs real data
corr_mat = corrcoef(hourlyDataLC{:, 4}, realData{:, 4},'rows','complete');
r_pre1_real = corr_mat(1, 2)

%corellation coefficient for sensor 2 vs real data
corr_mat = corrcoef(hourlyDataRC{:, 4}, realData{:, 4},'rows','complete');
r_pre2_real = corr_mat(1, 2)

%% graph with left vs right vs actual for OZONE 
figure(12)
set(gcf, 'name', 'Twelve hourly averaged ozone level data for system 1, 2 against actual data');
% Plot the data
plot(twhourlyDataL{:, 1}, twhourlyDataL{:, 6}, twhourlyDataR{:, 1}, twhourlyDataR{:, 6}, twrealData{:, 1}, twrealData{:, 5});

% Add axis labels and a legend
xlabel('Time');
ylabel('O3 levels, ppb');
legend('Twelve hourly average from system 1', 'Twelve hourly average from system 2', 'Real Data');
title('12-hour average ozone data against historical data');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(twhourlyDataL{:, 6}, twhourlyDataR{:, 6},'rows','complete');
r_oz1_oz2 = corr_mat(1, 2)

%corellation coefficient for sensor 1 vs real data
corr_mat = corrcoef(twhourlyDataL{:, 6}, twrealData{:, 5},'rows','complete');
r_oz1_real = corr_mat(1, 2)

%corellation coefficient for sensor 2 vs real data
corr_mat = corrcoef(twhourlyDataR{:, 6}, twrealData{:, 5},'rows','complete');
r_oz2_real = corr_mat(1, 2)

%% graph with left vs right vs actual for GAS RESISTANCE W1
figure(13)
set(gcf, 'name', 'Hourly averaged gas resistance data for system 1 against system 1 for week 1 of experiment');
% Plot the data
plot(hourlyDataL{1:180, 1}, hourlyDataL{1:180, 5}, hourlyDataR{1:180, 1}, hourlyDataR{1:180, 5});

% Add axis labels and a legend
xlabel('Time');
ylabel('Gas Resistance, kOhm');
legend('Hourly average from system 1', 'Hourly average from system 2');
title('Gas resistance against historical data (Week 1/2)');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{1:180, 5}, hourlyDataRC{1:180, 5},'rows','complete');
r_gas11_gas12 = corr_mat(1, 2)


%% graph with left vs right for GAS RESISTANCE W2
figure(14)
set(gcf, 'name', 'Hourly averaged gas resistance data for system 1 against system 1 for week 2 of experiment');
% Plot the data
plot(hourlyDataL{180:360, 1}, hourlyDataL{180:360, 5}, hourlyDataR{180:360, 1}, hourlyDataR{180:360, 5});

% Add axis labels and a legend
xlabel('Time');
ylabel('Gas Resistance, kOhm');
legend('Hourly average from system 1', 'Hourly average from system 2');
title('Gas resistance against historical data (Week 2/2)');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{180:360, 5}, hourlyDataRC{180:360, 5},'rows','complete');
r_gas21_gas22 = corr_mat(1, 2)

%% graph with left vs right vs precipitation for SOIL CONDUCTIVITY
figure(15)
set(gcf, 'name', 'Hourly averaged soil conductivity for system 1, 2 against precipitation');

% Plot the soil conductivity data from hourlyDataL and hourlyDataR
yyaxis left;
plot(hourlyDataL{43:360, 1}, hourlyDataL{43:360, 8}, hourlyDataR{43:360, 1}, hourlyDataR{43:360, 8},'-r');
ylabel('Soil Conductivity, mS/m');
ylim([600, 1100]);

% Plot the precipitation data from realData
yyaxis right;
h = plot(realData{43:360, 1}, realData{43:360, 6},'b');
ylabel('Precipitation, mm');
set(get(h(1),'Parent'), 'YColor', 'b');
ylim([0, 6]);

% Add axis labels and a legend
xlabel('Time');
legend('Hourly average from system 1', 'Hourly average from system 2', 'Precipitation', 'Location', 'NorthWest');
title('Hourly soil conductivity against precipitation data');
tstart = datetime(2023, 2, 25, 22, 0, 0);
tend = datetime(2023, 3, 10, 23, 00, 0);
xlim([tstart, tend]);

% Correlation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{43:360, 8}, hourlyDataRC{43:360, 8},'rows','complete');
r_soi1_soi2 = corr_mat(1, 2)

%% graph with left vs right for VOCe
figure(16)
set(gcf, 'name', 'Hourly averaged VOCe data for system 1 and 2');
% Plot the data
plot(hourlyDataL{:, 1}, hourlyDataL{:, 11}, hourlyDataR{:, 1}, hourlyDataR{:, 11});
ylim([0, 100]);
% Add axis labels and a legend
xlabel('Time');
ylabel('Presence of VOC, ppm');
legend('Hourly average from system 1', 'Hourly average from system 2');
title('Hourly VOC data');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{:, 11}, hourlyDataRC{:, 11},'rows','complete');
r_voc1_voc2 = corr_mat(1, 2)

%% graph with left vs right for CO2e
figure(17)
set(gcf, 'name', 'Hourly averaged CO2 data for system 1 and 2');
% Plot the data
plot(hourlyDataL{:, 1}, hourlyDataL{:, 10}, hourlyDataR{:, 1}, hourlyDataR{:, 10});
%ylim([0, 100]);
% Add axis labels and a legend
xlabel('Time');
ylabel('Presence of CO2, ppm');
legend('Hourly average from system 1', 'Hourly average from system 2');
title('Hourly CO2 data');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{:, 10}, hourlyDataRC{:, 10},'rows','complete');
r_co21_co22 = corr_mat(1, 2)

%% graph with left vs right soil temperature vs air temperature 
figure(18)
set(gcf, 'name', 'Hourly averaged soil temperature data and air temperature for system 1 and 2');

% Plot the data
yyaxis left;
plot(hourlyDataL{:, 1}, hourlyDataL{:, 9},'b-', hourlyDataR{:, 1}, hourlyDataR{:, 9},'r-');
ylabel('Soil Temperature, *C');
ylim([-2, 16]);

avgTemp = (hourlyDataL{:,2} + hourlyDataR{:,2}) / 2;

% Plot the average air temperature data on the right y-axis
yyaxis right;
h = plot(hourlyDataL{:, 1}, avgTemp, '-k');
ylabel('Air Temperature, *C');
set(get(h(1),'Parent'), 'YColor', 'k');
ylim([-2, 16]);

% Add axis labels and a legend
xlabel('Time');
legend('System 1 soil temperature', 'System 2 soil temperature','Average air temperature');
title('Hourly average Soil Temperature against average Air Temperature');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{:, 10}, hourlyDataRC{:, 10},'rows','complete');
r_soi11_soi12 = corr_mat(1, 2);

%% graph with left vs right soil temperature vs air temperature over 48 hour period to show the delay
figure(19)
set(gcf, 'name', 'Hourly averaged soil temperature data and air temperature for system 1 and 2 over 48 hour period');

% Plot the data
yyaxis left;
plot(hourlyDataL{169:217, 1}, hourlyDataL{169:217, 9},'b-', hourlyDataR{169:217, 1}, hourlyDataR{169:217, 9},'r-');
ylabel('Soil Temperature, *C');
ylim([0, 12]);

% Plot the air temperature data on the right y-axis
yyaxis right;
h = plot(hourlyDataL{169:217, 1}, hourlyDataL{169:217, 2},'k');
ylabel('Air Temperature, *C');
set(get(h(1),'Parent'), 'YColor', 'k');
ylim([0, 12]);

% Add axis labels and a legend
xlabel('Time');
legend('System 1 soil temperature', 'System 2 soil temperature','Average air temperature');
title('Hourly average Soil Temperature against average Air Temperature over random 48-hour period');

%corellation coefficient for sensor 1 vs sensor 2
corr_mat = corrcoef(hourlyDataLC{169:217, 10}, hourlyDataRC{169:217, 10},'rows','complete');
r_soi21_soi22 = corr_mat(1, 2);

%% graph with dendrometers L and max temperatures L
figure(20)
set(gcf, 'name', 'Tree diameter and maximum daily temperature against time for System 1');

yyaxis left;
bar(dailymaxtempL{:,1}, dailymaxtempL{:,2},'w');
ylabel('Daily Maximum Air Temperature, *C');
ylim([0, 20]);

yyaxis right;
plot(dailymaxtempL{:,1}, dendrometer{:,2},'-o');
ylabel('Tree Diameter, mm');
ylim([19.6, 19.625]);


% Add axis labels and a legend
xlabel('Time');
legend('Daily Maxmimum Air Temperature', 'Tree Diameter');
title('Tree diameter against Daily Maximum Air Temperature for System 1');

%corellation coefficient for sensor 1 vs sensor 2
%corr_mat = corrcoef(hourlyDataL{1:180, 5}, hourlyDataR{1:180, 5},'rows','complete');
%r_gas11_gas12 = corr_mat(1, 2)

%% graph with dendrometers R and max temperatures R
figure(21)
set(gcf, 'name', 'Tree diameter and maximum daily temperature against time for System 2');

yyaxis left;
bar(dailymaxtempR{:,1}, dailymaxtempR{:,2},'w');
ylabel('Daily Maximum Air Temperature, *C');
ylim([0, 20]);

yyaxis right;
plot(dailymaxtempL{:,1}, dendrometer{:,3},'-o');
ylabel('Tree Diameter, mm');
ylim([14.365, 14.374]);


% Add axis labels and a legend
xlabel('Time');
legend('Daily Maximum Air Temperature', 'Tree Diameter');
title('Tree Diameter against Daily Maximum Air Temperature for System 2');

%corellation coefficient for sensor 1 vs sensor 2
%corr_mat = corrcoef(hourlyDataL{1:180, 5}, hourlyDataR{1:180, 5},'rows','complete');
%r_gas11_gas12 = corr_mat(1, 2)

%% graph with daily mean soil moisture and diameter readings L
figure(22)
set(gcf, 'name', 'Tree diameter and daily mean soil moisture against time for System 1');

yyaxis left;
bar(dailyDataL{:,1}, dailyDataL{:,9},'w');
ylabel('Daily Mean Soil Conductivity, mS/m');
ylim([0, max(dailyDataL{:,9} + 200)]);

yyaxis right;
plot(dailymaxtempL{:,1}, dendrometer{:,2},'-o');
ylabel('Tree Diameter, mm');
ylim([19.6, 19.625]);


% Add axis labels and a legend
xlabel('Time');
legend('Daily Mean Soil Conductivity', 'Tree Diameter');
title('Tree diameter against Daily Mean Soil Conductivity for System 1');

%corellation coefficient for sensor 1 vs sensor 2
%corr_mat = corrcoef(hourlyDataL{1:180, 5}, hourlyDataR{1:180, 5},'rows','complete');
%r_gas11_gas12 = corr_mat(1, 2)

%% graph with daily mean soil moisture and diameter readings R
figure(23)
set(gcf, 'name', 'Tree diameter and daily mean soil moisture against time for System 2');

yyaxis left;
bar(dailyDataR{:,1}, dailyDataR{:,9},'w');
ylabel('Daily Mean Soil Conductivity, mS/m');
ylim([0, max(dailyDataL{:,9} + 200)]);

yyaxis right;
plot(dailymaxtempR{:,1}, dendrometer{:,3},'-o');
ylabel('Tree Diameter, mm');
ylim([14.365, 14.374]);


% Add axis labels and a legend
xlabel('Time');
legend('Daily Mean Soil Conducvitity', 'Tree Diameter');
title('Tree diameter against daily mean Soil Conductivity for System 2');

%corellation coefficient for sensor 1 vs sensor 2
%corr_mat = corrcoef(hourlyDataL{1:180, 5}, hourlyDataR{1:180, 5},'rows','complete');
%r_gas11_gas12 = corr_mat(1, 2)


%% save all figs
cd('figs');
res = 900;
size = [900, 700];

figHandles = findall(0, 'Type', 'figure');
for i = numel(figHandles):-1:1
    figName = sprintf('figure%d.png', numel(figHandles)-i+1);
    set(figHandles(i), 'Position', [0, 0, size(1), size(2)]); % Set figure size
    print(figHandles(i), figName, '-dpng', ['-r' num2str(res)]);
end

cd('..');