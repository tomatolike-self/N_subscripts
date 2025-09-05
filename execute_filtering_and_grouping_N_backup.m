function groupDirs = execute_filtering_and_grouping_N_backup(selected_bt, selected_n, selected_power, ...
                                                     bt_as_group, n_as_group, power_as_group)
% ========================================================================
% 执行筛选和分组的核心函数 - N杂质专用版本 (备份版本，不使用验证)
% ========================================================================
%
% 输入参数：
%   selected_bt     - 选择的BT方向 (cell array)
%   selected_n      - 选择的N浓度 (numeric array)
%   selected_power  - 选择的功率 (numeric array)
%   bt_as_group     - 是否将BT方向作为分组依据 (logical)
%   n_as_group      - 是否将N浓度作为分组依据 (logical)
%   power_as_group  - 是否将功率作为分组依据 (logical)
%
% 返回值：
%   groupDirs - 分组后的算例目录
%
% ========================================================================

% 获取所有可用的算例数据 (使用原始方法，不进行验证)
fprintf('Loading predefined case groups (backup method)...\n');
all_cases = get_all_case_data_N();

% 步骤1：根据选择条件筛选算例
fprintf('Step 1: Filtering cases based on selection criteria...\n');
filtered_cases = filter_cases_N(all_cases, selected_bt, selected_n, selected_power);
fprintf('Filtered %d cases from %d total cases.\n', length(filtered_cases), length(all_cases));

if isempty(filtered_cases)
    error('No cases match the selected criteria. Please adjust your selection.');
end

% 步骤2：根据分组依据对筛选后的算例进行分组
fprintf('Step 2: Grouping cases based on grouping criteria...\n');
groupDirs = group_cases_N(filtered_cases, bt_as_group, n_as_group, power_as_group);

% 步骤3：显示分组结果
display_grouping_results_N(groupDirs, bt_as_group, n_as_group, power_as_group);

% 步骤4：验证目录存在性
fprintf('\nStep 3: Validating directory paths...\n');
validate_directories_N(groupDirs);

end

% ========================================================================
% 辅助函数：显示分组结果
% ========================================================================
function display_grouping_results_N(groupDirs, bt_as_group, n_as_group, power_as_group)
    fprintf('\n========================================================================\n');
    fprintf('GROUPING RESULTS:\n');
    fprintf('========================================================================\n');
    
    % 确定分组维度
    grouping_vars = {};
    if bt_as_group
        grouping_vars{end+1} = 'BT';
    end
    if n_as_group
        grouping_vars{end+1} = 'N';
    end
    if power_as_group
        grouping_vars{end+1} = 'Power';
    end
    
    if isempty(grouping_vars)
        fprintf('All cases grouped into 1 group:\n');
        fprintf('  Group 1: %d cases\n', length(groupDirs{1}));
    else
        fprintf('Cases grouped by %s:\n', strjoin(grouping_vars, ' + '));
        for g = 1:length(groupDirs)
            fprintf('  Group %d: %d cases\n', g, length(groupDirs{g}));
        end
    end
    
    % 计算总算例数
    total_cases = 0;
    for g = 1:length(groupDirs)
        total_cases = total_cases + length(groupDirs{g});
    end
    fprintf('Total cases: %d\n', total_cases);
end

% ========================================================================
% 辅助函数：验证目录存在性
% ========================================================================
function validate_directories_N(groupDirs)
    invalid_paths = {};
    total_cases = 0;
    
    for g = 1:length(groupDirs)
        for k = 1:length(groupDirs{g})
            total_cases = total_cases + 1;
            if ~exist(groupDirs{g}{k}, 'dir')
                invalid_paths{end+1} = groupDirs{g}{k};
            end
        end
    end
    
    if ~isempty(invalid_paths)
        fprintf('Warning: %d out of %d paths do not exist:\n', length(invalid_paths), total_cases);
        for i = 1:min(5, length(invalid_paths))  % 只显示前5个
            fprintf('  %s\n', invalid_paths{i});
        end
        if length(invalid_paths) > 5
            fprintf('  ... and %d more invalid paths\n', length(invalid_paths) - 5);
        end
        
        continue_choice = input('Continue with existing paths? (y/n): ', 's');
        while ~strcmpi(continue_choice, 'y') && ~strcmpi(continue_choice, 'n')
            continue_choice = input('Please enter y or n: ', 's');
        end
        
        if strcmpi(continue_choice, 'n')
            error('Execution stopped due to invalid paths.');
        end
    else
        fprintf('All %d directory paths validated successfully.\n', total_cases);
    end
end
