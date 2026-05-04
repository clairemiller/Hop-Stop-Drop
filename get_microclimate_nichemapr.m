function [temperature, filename, R_output] = get_microclimate_nichemapr(lat, long, month)
% lat = 150.7049;
% long = -33.69492;
% month = "Jan";

% Run the R script
cmd = sprintf('/usr/local/bin/Rscript run_microclimate.R %f %f %s', lat, long, month)
[status, R_output] = system(cmd);

if (status ~= 0)
    print(R_output)
end
filename = "data/microclimate_data-" + month + ".txt";

% Read in the data
temperature = read_microclimate_file(filename);

end