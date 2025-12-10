function DATA = add_dist_dt(DATA)
% ADD_DIST_DT Compute per-frame distance change and store in dist_dt.
%
%   DATA = ADD_DIST_DT(DATA) walks through the nested structure:
%       DATA.(strain).(sex)(idx).(condition)
%   For every lowest-level struct that has a field 'dist_data', except when
%   the penultimate field name is 'meta', it creates:
%       .dist_dt
%   with the same size as .dist_data.
%
%   For each row of dist_data:
%       mov_data = movmean(row, 5);
%       diff_data = diff(mov_data);
%       final_data = diff_data * -30;
%
%   dist_dt is padded with NaNs in the first column so size matches
%   dist_data.

    strainNames = fieldnames(DATA);

    for iStrain = 1:numel(strainNames)
        strainName = strainNames{iStrain};

        % Fields under each strain (e.g. 'F', 'M')
        sexNames = fieldnames(DATA.(strainName));

        for iSex = 1:numel(sexNames)
            sexName = sexNames{iSex};

            % This is typically a struct array: DATA.strain.sex(idx)
            sexStruct = DATA.(strainName).(sexName);
            if ~isstruct(sexStruct)
                continue; % Just in case
            end

            % Field names at the penultimate level (e.g. 'R1_condition_10', 'meta', etc.)
            condFieldNames = fieldnames(sexStruct);

            for idx = 1:numel(sexStruct)
                for iField = 1:numel(condFieldNames)
                    condName = condFieldNames{iField};

                    % Skip 'meta' fields
                    if strcmp(condName, 'meta')
                        continue;
                    end

                    % Make sure the field exists for this element and is a struct
                    if ~isfield(sexStruct(idx), condName)
                        continue;
                    end
                    if ~isstruct(sexStruct(idx).(condName))
                        continue;
                    end

                    leafStruct = sexStruct(idx).(condName);

                    % Only proceed if there is a dist_data field
                    if ~isfield(leafStruct, 'dist_data')
                        continue;
                    end

                    dist_data = leafStruct.dist_data;

                    % Require 2D numeric matrix
                    if ~isnumeric(dist_data) || ~ismatrix(dist_data)
                        continue;
                    end

                    [nRows, nCols] = size(dist_data);

                    % Preallocate output with same size, first column NaN
                    dist_dt = nan(nRows, nCols);

                    for r = 1:nRows
                        row_data = dist_data(r, :);

                        % Moving mean over 5-frame window
                        mov_data = movmean(row_data, 5);

                        % Frame-to-frame difference
                        diff_data = diff(mov_data);

                        % Multiply by -30
                        final_data = diff_data * -30;

                        % Put into columns 2:end, leaving first column NaN
                        if numel(final_data) == nCols - 1
                            dist_dt(r, 2:end) = final_data;

                        else
                            % Fallback in weird edge cases (very short vectors)
                            dist_dt(r, 2:(1+numel(final_data))) = final_data;
                        end
                    end

                    % Assign back into DATA
                    DATA.(strainName).(sexName)(idx).(condName).dist_dt = dist_dt;
                end
            end
        end
    end
end
