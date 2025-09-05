function all_cases = get_all_case_data_from_validated_groups(validated_groups)
% ========================================================================
% 从验证后的算例组生成算例数据的函数
% ========================================================================
%
% 功能：
%   从已验证和去重的算例组中生成完整的算例数据结构
%
% 输入参数：
%   validated_groups - 已验证的算例组结构体
%
% 返回值：
%   all_cases - 包含所有算例信息的结构体数组，每个元素包含：
%     .path - 算例路径
%     .bt_direction - BT方向 ('fav' 或 'unfav')
%     .n_concentration - N浓度 (0.5, 1.0, 1.5, 2.0)
%     .power - 功率 (5.5, 6, 7, 8, 10)
%     .case_name - 算例名称
%
% ========================================================================

fprintf('Generating case data from validated groups...\n');

% 初始化输出数组
all_cases = [];

% N浓度值
n_concentrations = [0.5, 1.0, 1.5, 2.0];

% 处理fav BT组
if isfield(validated_groups, 'fav_BT')
    fprintf('Processing validated fav_BT groups...\n');
    for n_idx = 1:length(n_concentrations)
        n_conc = n_concentrations(n_idx);
        if n_idx <= length(validated_groups.fav_BT)
            group_paths = validated_groups.fav_BT{n_idx};
            for path_idx = 1:length(group_paths)
                case_path = group_paths{path_idx};
                
                % 从路径中提取功率信息
                power = extract_power_from_path(case_path);
                
                % 创建算例结构体
                case_info = struct();
                case_info.path = case_path;
                case_info.bt_direction = 'fav';
                case_info.n_concentration = n_conc;
                case_info.power = power;
                case_info.case_name = generate_case_name(case_path);
                
                all_cases = [all_cases; case_info];
            end
            fprintf('  N%.1f group: %d cases\n', n_conc, length(group_paths));
        end
    end
end

% 处理unfav BT组
if isfield(validated_groups, 'unfav_BT')
    fprintf('Processing validated unfav_BT groups...\n');
    for n_idx = 1:length(n_concentrations)
        n_conc = n_concentrations(n_idx);
        if n_idx <= length(validated_groups.unfav_BT)
            group_paths = validated_groups.unfav_BT{n_idx};
            for path_idx = 1:length(group_paths)
                case_path = group_paths{path_idx};
                
                % 从路径中提取功率信息
                power = extract_power_from_path(case_path);
                
                % 创建算例结构体
                case_info = struct();
                case_info.path = case_path;
                case_info.bt_direction = 'unfav';
                case_info.n_concentration = n_conc;
                case_info.power = power;
                case_info.case_name = generate_case_name(case_path);
                
                all_cases = [all_cases; case_info];
            end
            fprintf('  N%.1f group: %d cases\n', n_conc, length(group_paths));
        end
    end
end

fprintf('Total validated N impurity cases loaded: %d\n', length(all_cases));

% 检查是否有重复的算例路径（最终验证）
unique_paths = unique({all_cases.path});
if length(unique_paths) ~= length(all_cases)
    warning('Still found duplicate paths after validation! This should not happen.');
    % 进行最终去重
    [~, unique_indices] = unique({all_cases.path});
    all_cases = all_cases(unique_indices);
    fprintf('Final deduplication: %d unique cases remain\n', length(all_cases));
end

end

% ========================================================================
% 辅助函数：从路径中提取功率信息
% ========================================================================
function power = extract_power_from_path(case_path)
    % 从路径中提取功率信息
    % 路径格式示例: .../5p5mw_flux_1p0415e22/... 或 .../7mw_flux_1p1230e22/...

    % 使用contains函数检查路径中的功率标识符
    if contains(case_path, '5p5mw_flux')
        power = 5.5;
    elseif contains(case_path, '6mw_flux')
        power = 6.0;
    elseif contains(case_path, '7mw_flux')
        power = 7.0;
    elseif contains(case_path, '8mw_flux')
        power = 8.0;
    elseif contains(case_path, '10mw_flux')
        power = 10.0;
    else
        % 如果无法从路径提取功率，使用默认值
        warning('Could not extract power from path: %s. Using default power 6MW.', case_path);
        power = 6;
    end
end

% ========================================================================
% 辅助函数：生成算例名称
% ========================================================================
function case_name = generate_case_name(case_path)
    % 从路径生成简化的算例名称
    [~, name, ~] = fileparts(case_path);
    case_name = name;
    
    % 如果名称太长，进行简化
    if length(case_name) > 50
        case_name = case_name(1:50);
    end
end
