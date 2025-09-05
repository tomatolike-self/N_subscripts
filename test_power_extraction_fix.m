% ========================================================================
% 测试功率提取修复的脚本
% ========================================================================
% 
% 用途：验证修复后的 extract_power_from_path 函数是否能正确提取功率信息
%
% 创建时间：2025-08-25
% ========================================================================

fprintf('========================================================================\n');
fprintf('测试功率提取修复\n');
fprintf('========================================================================\n');

% 测试1：测试预定义组加载
fprintf('\n1. 测试预定义组加载...\n');
try
    groups = predefined_case_groups_N_real();
    fprintf('✓ 成功加载预定义N杂质算例组\n');
    fprintf('  - fav BT组数: %d\n', length(groups.fav_BT));
    fprintf('  - unfav BT组数: %d\n', length(groups.unfav_BT));
    
    % 统计总算例数
    total_fav = 0;
    for i = 1:length(groups.fav_BT)
        total_fav = total_fav + length(groups.fav_BT{i});
    end
    
    total_unfav = 0;
    for i = 1:length(groups.unfav_BT)
        total_unfav = total_unfav + length(groups.unfav_BT{i});
    end
    
    fprintf('  - fav BT总算例数: %d\n', total_fav);
    fprintf('  - unfav BT总算例数: %d\n', total_unfav);
    fprintf('  - 总算例数: %d\n', total_fav + total_unfav);
    
catch ME
    fprintf('✗ 加载预定义组失败: %s\n', ME.message);
    return;
end

% 测试2：测试功率提取函数
fprintf('\n2. 测试功率提取函数...\n');

% 测试路径样例
test_paths = {
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/5p5mw_flux_1p0415e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/7mw_flux_1p1230e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/8mw_flux_1p1541e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p2882e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/6mw_flux_1p0720e22/baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5';
};

expected_powers = [5.5, 7.0, 8.0, 10.0, 6.0];

fprintf('测试路径功率提取:\n');
all_correct = true;
for i = 1:length(test_paths)
    test_path = test_paths{i};
    expected_power = expected_powers(i);
    
    % 调用内部函数进行测试
    extracted_power = test_extract_power_from_path(test_path);
    
    if extracted_power == expected_power
        fprintf('  ✓ 路径 %d: 提取功率 %.1f MW (期望 %.1f MW)\n', i, extracted_power, expected_power);
    else
        fprintf('  ✗ 路径 %d: 提取功率 %.1f MW (期望 %.1f MW)\n', i, extracted_power, expected_power);
        all_correct = false;
    end
end

if all_correct
    fprintf('✓ 所有功率提取测试通过\n');
else
    fprintf('✗ 部分功率提取测试失败\n');
end

% 测试3：测试完整的数据加载
fprintf('\n3. 测试完整的数据加载...\n');
try
    all_cases = get_all_case_data_N();
    fprintf('✓ 成功加载所有N杂质算例数据\n');
    fprintf('  - 总算例数: %d\n', length(all_cases));
    
    % 检查是否还有警告
    fprintf('\n检查功率提取结果:\n');
    power_stats = containers.Map();
    warning_count = 0;
    
    for i = 1:length(all_cases)
        power = all_cases(i).power;
        power_str = sprintf('%.1f', power);
        
        if isKey(power_stats, power_str)
            power_stats(power_str) = power_stats(power_str) + 1;
        else
            power_stats(power_str) = 1;
        end
        
        % 检查是否使用了默认值6MW（可能表示提取失败）
        if power == 6.0
            % 进一步检查路径是否真的包含6mw_flux
            if ~contains(all_cases(i).path, '6mw_flux')
                warning_count = warning_count + 1;
            end
        end
    end
    
    % 显示功率分布统计
    power_keys = keys(power_stats);
    power_values = values(power_stats);
    fprintf('  功率分布统计:\n');
    for i = 1:length(power_keys)
        fprintf('    %.1f MW: %d个算例\n', str2double(power_keys{i}), power_values{i});
    end
    
    if warning_count == 0
        fprintf('✓ 没有发现功率提取警告\n');
    else
        fprintf('✗ 发现 %d 个可能的功率提取问题\n', warning_count);
    end
    
catch ME
    fprintf('✗ 数据加载失败: %s\n', ME.message);
end

fprintf('\n========================================================================\n');
fprintf('测试完成\n');
fprintf('========================================================================\n');

% ========================================================================
% 辅助函数：测试功率提取（复制自get_all_case_data_N.m）
% ========================================================================
function power = test_extract_power_from_path(case_path)
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
        power = 6;
    end
end
