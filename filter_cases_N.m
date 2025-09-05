function filtered_cases = filter_cases_N(all_cases, selected_bt, selected_n, selected_power)
% ========================================================================
% 根据选择条件筛选N杂质算例的函数
% ========================================================================
%
% 输入参数：
%   all_cases     - 所有算例的结构体数组
%   selected_bt   - 选择的BT方向 (cell array)
%   selected_n    - 选择的N浓度 (numeric array)
%   selected_power - 选择的功率 (numeric array)
%
% 返回值：
%   filtered_cases - 筛选后的算例结构体数组
%
% ========================================================================

if isempty(all_cases)
    filtered_cases = [];
    return;
end

% 初始化筛选结果
filtered_cases = [];

fprintf('Filtering criteria:\n');
fprintf('  BT directions: %s\n', strjoin(selected_bt, ', '));
fprintf('  N concentrations: %s\n', mat2str(selected_n));
fprintf('  Powers: %s\n', mat2str(selected_power));

% 遍历所有算例进行筛选
for i = 1:length(all_cases)
    case_info = all_cases(i);
    
    % 检查BT方向
    bt_match = false;
    for j = 1:length(selected_bt)
        if strcmpi(case_info.bt_direction, selected_bt{j})
            bt_match = true;
            break;
        end
    end
    
    % 检查N浓度
    n_match = false;
    for j = 1:length(selected_n)
        if abs(case_info.n_concentration - selected_n(j)) < 0.01  % 允许小的数值误差
            n_match = true;
            break;
        end
    end
    
    % 检查功率
    power_match = false;
    for j = 1:length(selected_power)
        if abs(case_info.power - selected_power(j)) < 0.01  % 允许小的数值误差
            power_match = true;
            break;
        end
    end
    
    % 如果所有条件都匹配，则添加到筛选结果中
    if bt_match && n_match && power_match
        filtered_cases = [filtered_cases; case_info];
    end
end

fprintf('Filtering completed: %d cases match the criteria.\n', length(filtered_cases));

% 显示筛选结果摘要
if ~isempty(filtered_cases)
    fprintf('\nFiltered cases summary:\n');
    
    % 统计BT方向分布
    fav_count = sum(strcmpi({filtered_cases.bt_direction}, 'fav'));
    unfav_count = sum(strcmpi({filtered_cases.bt_direction}, 'unfav'));
    fprintf('  BT directions: fav=%d, unfav=%d\n', fav_count, unfav_count);
    
    % 统计N浓度分布
    unique_n = unique([filtered_cases.n_concentration]);
    fprintf('  N concentrations: ');
    for i = 1:length(unique_n)
        count = sum([filtered_cases.n_concentration] == unique_n(i));
        fprintf('%.1f=%d ', unique_n(i), count);
    end
    fprintf('\n');
    
    % 统计功率分布
    unique_power = unique([filtered_cases.power]);
    fprintf('  Powers: ');
    for i = 1:length(unique_power)
        count = sum([filtered_cases.power] == unique_power(i));
        fprintf('%.1fMW=%d ', unique_power(i), count);
    end
    fprintf('\n');
end

end
