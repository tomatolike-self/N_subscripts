function groupDirs = group_cases_N(filtered_cases, bt_as_group, n_as_group, power_as_group)
% ========================================================================
% 对筛选后的N杂质算例进行分组
% 与充Ne脚本的分组逻辑完全一致
% ========================================================================
%
% 输入参数：
%   filtered_cases - 筛选后的算例结构体数组
%   bt_as_group    - 是否将BT方向作为分组依据 (logical)
%   n_as_group     - 是否将N浓度作为分组依据 (logical)
%   power_as_group - 是否将功率作为分组依据 (logical)
%
% 返回值：
%   groupDirs - 分组后的算例目录 (cell array of cell arrays)
%
% ========================================================================

if ~bt_as_group && ~n_as_group && ~power_as_group
    % 所有算例放在一个组中
    groupDirs = {{filtered_cases.path}};
    return;
end

% 创建分组键
group_keys = {};
group_map = containers.Map();

for i = 1:length(filtered_cases)
    case_info = filtered_cases(i);

    % 构建分组键
    key_parts = {};
    if bt_as_group
        key_parts{end+1} = case_info.bt_direction;
    end
    if n_as_group
        key_parts{end+1} = sprintf('N%.1f', case_info.n_concentration);
    end
    if power_as_group
        key_parts{end+1} = sprintf('%.1fMW', case_info.power);
    end

    group_key = strjoin(key_parts, '_');

    % 将算例添加到对应的组
    if isKey(group_map, group_key)
        current_group = group_map(group_key);
        current_group{end+1} = case_info.path;
        group_map(group_key) = current_group;
    else
        group_map(group_key) = {case_info.path};
        group_keys{end+1} = group_key;
    end
end

% 转换为cell array格式
groupDirs = cell(length(group_keys), 1);
for i = 1:length(group_keys)
    groupDirs{i} = group_map(group_keys{i});
end

end
