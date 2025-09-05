function groupDirs = execute_filtering_and_grouping_N(selected_bt, selected_n, selected_power, ...
                                                     bt_as_group, n_as_group, power_as_group)
% ========================================================================
% 执行筛选和分组的核心函数 - N杂质专用版本
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

% 获取所有可用的算例数据
fprintf('Loading predefined case groups...\n');
raw_groups = predefined_case_groups_N_real();

% 验证和去重算例
fprintf('Validating and deduplicating cases...\n');
[validated_groups, ~] = validate_and_deduplicate_cases_simple(raw_groups);

% 使用验证后的组生成算例数据
all_cases = get_all_case_data_from_validated_groups(validated_groups);

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
    fprintf('Total groups: %d\n', length(groupDirs));

    for g = 1:length(groupDirs)
        fprintf('\n--- Group %d: %d cases ---\n', g, length(groupDirs{g}));

        % 显示前几个算例的详细信息
        max_display = min(3, length(groupDirs{g}));
        for k = 1:max_display
            case_path = groupDirs{g}{k};
            [bt_info, n_info, power_info] = extract_case_info_N(case_path);
            fprintf('  %d. %s %s %s\n', k, bt_info, power_info, n_info);
        end

        if length(groupDirs{g}) > max_display
            fprintf('  ... and %d more cases\n', length(groupDirs{g}) - max_display);
        end
    end

    fprintf('\n========================================================================\n');
end

% ========================================================================
% 辅助函数：从路径提取算例信息
% ========================================================================
function [bt_info, n_info, power_info] = extract_case_info_N(case_path)
    % 提取BT方向信息
    if contains(case_path, '_un_')
        bt_info = '[unfav]';
    else
        bt_info = '[fav]';
    end

    % 提取N浓度信息
    if contains(case_path, 'N0p5') || contains(case_path, 'changeto_N0p5')
        n_info = '[N0.5]';
    elseif contains(case_path, 'N1p5') || contains(case_path, 'changeto_N1p5')
        n_info = '[N1.5]';
    elseif contains(case_path, 'N2') || contains(case_path, 'changeto_N2')
        n_info = '[N2.0]';
    elseif (contains(case_path, 'N1') && ~contains(case_path, 'N1p5')) || contains(case_path, 'changeto_N1')
        n_info = '[N1.0]';
    else
        n_info = '[N?]';
    end

    % 提取功率信息
    if contains(case_path, '5p5mw_flux')
        power_info = '[5.5MW]';
    elseif contains(case_path, '6mw_flux')
        power_info = '[6MW]';
    elseif contains(case_path, '7mw_flux')
        power_info = '[7MW]';
    elseif contains(case_path, '8mw_flux')
        power_info = '[8MW]';
    elseif contains(case_path, '10mw_flux')
        power_info = '[10MW]';
    else
        power_info = '[?MW]';
    end
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
