function temperature = read_microclimate_file(filename)
% filename = "data/microclimate_data-Jan.txt";
% Read in the data
temperature_array = readmatrix(filename, 'CommentStyle', '#');
temperature = array2table(temperature_array(:,2:end), ...
    'RowNames', string(temperature_array(:,1)), 'VariableNames', string(0:23));
end