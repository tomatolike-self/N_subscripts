function groupDirs = advanced_flexible_filtering_N()
% ========================================================================
% 高级灵活算例筛选函数 - N杂质专用版本
% 支持自由选择变量值和分组依据的完整筛选系统
% ========================================================================
%
% 功能特性：
% 1. 自由选择BT方向：fav, unfav, 或 fav+unfav
% 2. 自由选择N浓度：单个值、组合值或全部
% 3. 自由选择功率：单个值、组合值或全部
% 4. 自由选择分组依据：任意变量组合作为分组维度
%
% 返回值：
%   groupDirs - 根据选择的分组依据组织的算例组
%
% ========================================================================

fprintf('\n========================================================================\n');
fprintf('ADVANCED FLEXIBLE CASE FILTERING - N IMPURITY VERSION\n');
fprintf('========================================================================\n');
fprintf('This mode allows you to:\n');
fprintf('1. Freely select values for each variable (single, combination, or all)\n');
fprintf('2. Choose which variables to use as grouping criteria\n');
fprintf('3. Get results grouped by your selected criteria\n');
fprintf('========================================================================\n');

% 步骤1：选择BT方向
fprintf('\n--- Step 1: Select BT Direction ---\n');
fprintf('Available options:\n');
fprintf('1: fav only\n');
fprintf('2: unfav only\n');
fprintf('3: Both (fav + unfav)\n');

bt_selection = input('Select BT direction (1-3): ');
while bt_selection < 1 || bt_selection > 3
    fprintf('Invalid input, please enter 1-3.\n');
    bt_selection = input('Select BT direction (1-3): ');
end

% 确定选择的BT方向
switch bt_selection
    case 1
        selected_bt = {'fav'};
        bt_desc = 'fav';
    case 2
        selected_bt = {'unfav'};
        bt_desc = 'unfav';
    case 3
        selected_bt = {'fav', 'unfav'};
        bt_desc = 'fav+unfav';
end

fprintf('Selected BT direction: %s\n', bt_desc);

% 询问是否将BT方向作为分组依据
bt_as_group = input('Use BT direction as grouping criterion? (y/n): ', 's');
while ~strcmpi(bt_as_group, 'y') && ~strcmpi(bt_as_group, 'n')
    bt_as_group = input('Please enter y or n: ', 's');
end
bt_as_group = strcmpi(bt_as_group, 'y');

% 步骤2：选择N浓度
fprintf('\n--- Step 2: Select N Concentration ---\n');
fprintf('Available options:\n');
fprintf('1: 0.5 only\n');
fprintf('2: 1.0 only\n');
fprintf('3: 1.5 only\n');
fprintf('4: 2.0 only\n');
fprintf('5: Custom combination (e.g., 0.5+1.0+2.0)\n');
fprintf('6: All (0.5+1.0+1.5+2.0)\n');

n_selection = input('Select N concentration (1-6): ');
while n_selection < 1 || n_selection > 6
    fprintf('Invalid input, please enter 1-6.\n');
    n_selection = input('Select N concentration (1-6): ');
end

% 确定选择的N浓度
n_values = [0.5, 1.0, 1.5, 2.0];
switch n_selection
    case 1
        selected_n = [0.5];
        n_desc = '0.5';
    case 2
        selected_n = [1.0];
        n_desc = '1.0';
    case 3
        selected_n = [1.5];
        n_desc = '1.5';
    case 4
        selected_n = [2.0];
        n_desc = '2.0';
    case 5
        % 自定义组合
        fprintf('Available N values: 1=0.5, 2=1.0, 3=1.5, 4=2.0\n');
        n_indices = input('Enter indices for custom combination (e.g., [1 2 4] for 0.5+1.0+2.0): ');
        while any(n_indices < 1) || any(n_indices > 4) || ~isvector(n_indices)
            fprintf('Invalid indices, please enter values between 1-4.\n');
            n_indices = input('Enter indices for custom combination (e.g., [1 2 4]): ');
        end
        selected_n = n_values(n_indices);
        n_desc = sprintf('%.1f', selected_n(1));
        for i = 2:length(selected_n)
            n_desc = [n_desc, sprintf('+%.1f', selected_n(i))];
        end
    case 6
        selected_n = n_values;
        n_desc = 'all';
end

fprintf('Selected N concentration: %s\n', n_desc);

% 询问是否将N浓度作为分组依据
n_as_group = input('Use N concentration as grouping criterion? (y/n): ', 's');
while ~strcmpi(n_as_group, 'y') && ~strcmpi(n_as_group, 'n')
    n_as_group = input('Please enter y or n: ', 's');
end
n_as_group = strcmpi(n_as_group, 'y');

% 步骤3：选择功率
fprintf('\n--- Step 3: Select Power ---\n');
fprintf('Available options:\n');
fprintf('1: 5.5MW only\n');
fprintf('2: 6MW only\n');
fprintf('3: 7MW only\n');
fprintf('4: 8MW only\n');
fprintf('5: 10MW only\n');
fprintf('6: Custom combination (e.g., 5.5+8+10MW)\n');
fprintf('7: All (5.5+6+7+8+10MW)\n');

power_selection = input('Select power (1-7): ');
while power_selection < 1 || power_selection > 7
    fprintf('Invalid input, please enter 1-7.\n');
    power_selection = input('Select power (1-7): ');
end

% 确定选择的功率
power_values = [5.5, 6, 7, 8, 10];
switch power_selection
    case 1
        selected_power = [5.5];
        power_desc = '5.5MW';
    case 2
        selected_power = [6];
        power_desc = '6MW';
    case 3
        selected_power = [7];
        power_desc = '7MW';
    case 4
        selected_power = [8];
        power_desc = '8MW';
    case 5
        selected_power = [10];
        power_desc = '10MW';
    case 6
        % 自定义组合
        fprintf('Available power values: 1=5.5MW, 2=6MW, 3=7MW, 4=8MW, 5=10MW\n');
        power_indices = input('Enter indices for custom combination (e.g., [1 4 5] for 5.5+8+10MW): ');
        while any(power_indices < 1) || any(power_indices > 5) || ~isvector(power_indices)
            fprintf('Invalid indices, please enter values between 1-5.\n');
            power_indices = input('Enter indices for custom combination (e.g., [1 4 5]): ');
        end
        selected_power = power_values(power_indices);
        power_desc = sprintf('%.1fMW', selected_power(1));
        for i = 2:length(selected_power)
            power_desc = [power_desc, sprintf('+%.1fMW', selected_power(i))];
        end
    case 7
        selected_power = power_values;
        power_desc = 'all';
end

fprintf('Selected power: %s\n', power_desc);

% 询问是否将功率作为分组依据
power_as_group = input('Use power as grouping criterion? (y/n): ', 's');
while ~strcmpi(power_as_group, 'y') && ~strcmpi(power_as_group, 'n')
    power_as_group = input('Please enter y or n: ', 's');
end
power_as_group = strcmpi(power_as_group, 'y');

% 步骤4：确认选择和分组策略
fprintf('\n========================================================================\n');
fprintf('SELECTION SUMMARY:\n');
fprintf('========================================================================\n');
fprintf('BT Direction: %s %s\n', bt_desc, ternary(bt_as_group, '[GROUPING]', ''));
fprintf('N Concentration: %s %s\n', n_desc, ternary(n_as_group, '[GROUPING]', ''));
fprintf('Power: %s %s\n', power_desc, ternary(power_as_group, '[GROUPING]', ''));

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
    fprintf('Grouping strategy: All cases in one group\n');
else
    fprintf('Grouping strategy: Group by %s\n', strjoin(grouping_vars, ' + '));
end

% 用户确认
confirm = input('\nProceed with this configuration? (y/n): ', 's');
while ~strcmpi(confirm, 'y') && ~strcmpi(confirm, 'n')
    confirm = input('Please enter y or n: ', 's');
end

if strcmpi(confirm, 'n')
    fprintf('Configuration cancelled. Restarting...\n');
    groupDirs = advanced_flexible_filtering_N();  % 递归重新开始
    return;
end

% 步骤5：执行筛选和分组
fprintf('\n========================================================================\n');
fprintf('EXECUTING FILTERING AND GROUPING...\n');
fprintf('========================================================================\n');

% 调用筛选和分组函数
groupDirs = execute_filtering_and_grouping_N(selected_bt, selected_n, selected_power, ...
                                           bt_as_group, n_as_group, power_as_group);

fprintf('Filtering and grouping completed successfully!\n');
fprintf('Total groups generated: %d\n', length(groupDirs));

end

% 辅助函数：三元运算符
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
