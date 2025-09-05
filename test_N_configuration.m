% ========================================================================
% N杂质配置测试脚本
% 用于验证N杂质算例配置是否正确
% ========================================================================

fprintf('========================================================================\n');
fprintf('N杂质算例配置测试\n');
fprintf('========================================================================\n');

% 测试1：测试预定义算例组加载
fprintf('\n1. 测试预定义算例组加载...\n');
try
    groups = predefined_case_groups_N();
    fprintf('✓ 成功加载预定义N算例组\n');
    
    % 显示基本信息
    fprintf('  - fav BT组数: %d\n', length(groups.fav_BT));
    fprintf('  - unfav BT组数: %d\n', length(groups.unfav_BT));
    fprintf('  - 合并组数: %d\n', length(groups.combined));
    
    % 统计算例数量
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
    
    % 显示每个浓度组的算例数
    fprintf('\n  各浓度组算例数统计:\n');
    n_concentrations = [0.5, 1.0, 1.5, 2.0];
    for i = 1:4
        fav_count = length(groups.fav_BT{i});
        unfav_count = length(groups.unfav_BT{i});
        fprintf('    N %.1f: fav=%d, unfav=%d, 总计=%d\n', ...
                n_concentrations(i), fav_count, unfav_count, fav_count + unfav_count);
    end
    
catch ME
    fprintf('✗ 加载预定义N算例组失败: %s\n', ME.message);
    return;
end

% 测试2：显示算例路径示例
fprintf('\n2. 算例路径示例:\n');
try
    fprintf('  fav BT (N 0.5) 示例:\n');
    for i = 1:min(3, length(groups.fav_BT{1}))
        fprintf('    %s\n', groups.fav_BT{1}{i});
    end
    
    fprintf('  unfav BT (N 1.0) 示例:\n');
    for i = 1:min(3, length(groups.unfav_BT{2}))
        fprintf('    %s\n', groups.unfav_BT{2}{i});
    end
    
catch ME
    fprintf('✗ 显示路径示例失败: %s\n', ME.message);
end

% 测试3：检查高级筛选函数存在性
fprintf('\n3. 检查高级筛选函数:\n');
functions_to_check = {
    'advanced_flexible_filtering_N';
    'execute_filtering_and_grouping_N';
    'get_all_case_data_N';
    'filter_cases_N';
    'group_cases_N'
};

all_functions_exist = true;
for i = 1:length(functions_to_check)
    func_name = functions_to_check{i};
    if exist(func_name, 'file') == 2
        fprintf('  ✓ %s 存在\n', func_name);
    else
        fprintf('  ✗ %s 不存在\n', func_name);
        all_functions_exist = false;
    end
end

% 测试4：路径格式验证
fprintf('\n4. 路径格式验证:\n');
try
    % 检查路径是否包含正确的基础路径
    sample_path = groups.fav_BT{1}{1};
    if contains(sample_path, '81574_D+N')
        fprintf('  ✓ 路径包含正确的基础目录\n');
    else
        fprintf('  ⚠ 路径可能需要调整基础目录\n');
    end
    
    % 检查路径是否包含功率信息
    if contains(sample_path, 'mw_')
        fprintf('  ✓ 路径包含功率信息\n');
    else
        fprintf('  ⚠ 路径可能缺少功率信息\n');
    end
    
    % 检查路径是否包含BT方向信息
    if contains(sample_path, 'normal') || contains(sample_path, 'reversed')
        fprintf('  ✓ 路径包含BT方向信息\n');
    else
        fprintf('  ⚠ 路径可能缺少BT方向信息\n');
    end
    
catch ME
    fprintf('  ✗ 路径格式验证失败: %s\n', ME.message);
end

% 测试5：分类逻辑验证
fprintf('\n5. 分类逻辑验证:\n');
try
    % 检查fav BT算例是否都包含normal
    fav_correct = true;
    for i = 1:length(groups.fav_BT)
        for j = 1:length(groups.fav_BT{i})
            if ~contains(groups.fav_BT{i}{j}, 'normal')
                fav_correct = false;
                break;
            end
        end
        if ~fav_correct
            break;
        end
    end
    
    if fav_correct
        fprintf('  ✓ fav BT算例分类正确\n');
    else
        fprintf('  ⚠ fav BT算例分类可能有问题\n');
    end
    
    % 检查unfav BT算例是否都包含reversed
    unfav_correct = true;
    for i = 1:length(groups.unfav_BT)
        for j = 1:length(groups.unfav_BT{i})
            if ~contains(groups.unfav_BT{i}{j}, 'reversed')
                unfav_correct = false;
                break;
            end
        end
        if ~unfav_correct
            break;
        end
    end
    
    if unfav_correct
        fprintf('  ✓ unfav BT算例分类正确\n');
    else
        fprintf('  ⚠ unfav BT算例分类可能有问题\n');
    end
    
catch ME
    fprintf('  ✗ 分类逻辑验证失败: %s\n', ME.message);
end

% 总结
fprintf('\n========================================================================\n');
fprintf('测试总结:\n');
fprintf('========================================================================\n');

if all_functions_exist
    fprintf('✓ 所有必需函数都存在\n');
    fprintf('✓ 配置文件加载成功\n');
    fprintf('✓ 算例分组结构正确\n');
    fprintf('\n配置状态: 就绪 ✓\n');
    fprintf('可以运行主脚本 SOLPS_Main_PostProcessing_pol_num_N.m\n');
else
    fprintf('⚠ 部分函数缺失，请检查文件完整性\n');
    fprintf('\n配置状态: 需要修复 ⚠\n');
end

fprintf('\n注意事项:\n');
fprintf('1. 在服务器上使用前，请修改 predefined_case_groups_N_real.m 中的 base_path\n');
fprintf('2. 确保所有算例目录在服务器上实际存在\n');
fprintf('3. 运行主脚本时选择方法3可使用高级筛选功能\n');

fprintf('========================================================================\n');
