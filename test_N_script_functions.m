% ========================================================================
% N脚本功能测试脚本
% 用于验证N杂质专用函数是否正常工作
% ========================================================================

fprintf('========================================================================\n');
fprintf('Testing N Script Functions\n');
fprintf('========================================================================\n');

% 测试1：测试预定义算例组加载
fprintf('\n1. Testing predefined_case_groups_N...\n');
try
    groups = predefined_case_groups_N();
    fprintf('✓ Successfully loaded predefined N case groups\n');
    fprintf('  - fav BT groups: %d\n', length(groups.fav_BT));
    fprintf('  - unfav BT groups: %d\n', length(groups.unfav_BT));
    fprintf('  - combined groups: %d\n', length(groups.combined));
    
    % 统计总算例数
    total_fav = 0;
    for i = 1:length(groups.fav_BT)
        total_fav = total_fav + length(groups.fav_BT{i});
    end
    
    total_unfav = 0;
    for i = 1:length(groups.unfav_BT)
        total_unfav = total_unfav + length(groups.unfav_BT{i});
    end
    
    fprintf('  - fav cases total: %d\n', total_fav);
    fprintf('  - unfav cases total: %d\n', total_unfav);
    fprintf('  - total cases: %d\n', total_fav + total_unfav);
    
catch ME
    fprintf('✗ Error loading predefined N case groups: %s\n', ME.message);
end

% 测试2：测试数据获取函数
fprintf('\n2. Testing get_all_case_data_N...\n');
try
    all_cases = get_all_case_data_N();
    fprintf('✓ Successfully loaded all N case data\n');
    fprintf('  - Total cases: %d\n', length(all_cases));
    
    if ~isempty(all_cases)
        % 显示第一个算例的信息
        fprintf('  - Sample case info:\n');
        fprintf('    Path: %s\n', all_cases(1).path);
        fprintf('    BT direction: %s\n', all_cases(1).bt_direction);
        fprintf('    N concentration: %.1f\n', all_cases(1).n_concentration);
        fprintf('    Power: %.1f MW\n', all_cases(1).power);
        fprintf('    Case name: %s\n', all_cases(1).case_name);
    end
    
catch ME
    fprintf('✗ Error loading N case data: %s\n', ME.message);
    all_cases = [];
end

% 测试3：测试筛选函数
fprintf('\n3. Testing filter_cases_N...\n');
if ~isempty(all_cases)
    try
        % 测试筛选：fav BT, N浓度1.0, 功率6MW
        test_bt = {'fav'};
        test_n = [1.0];
        test_power = [6];
        
        filtered_cases = filter_cases_N(all_cases, test_bt, test_n, test_power);
        fprintf('✓ Successfully filtered N cases\n');
        fprintf('  - Filtered cases: %d\n', length(filtered_cases));
        
    catch ME
        fprintf('✗ Error filtering N cases: %s\n', ME.message);
        filtered_cases = [];
    end
else
    fprintf('⚠ Skipping filter test due to empty case data\n');
    filtered_cases = [];
end

% 测试4：测试分组函数
fprintf('\n4. Testing group_cases_N...\n');
if ~isempty(filtered_cases)
    try
        % 测试分组：按BT方向分组
        groupDirs = group_cases_N(filtered_cases, true, false, false);
        fprintf('✓ Successfully grouped N cases\n');
        fprintf('  - Number of groups: %d\n', length(groupDirs));
        
        for g = 1:length(groupDirs)
            fprintf('    Group %d: %d cases\n', g, length(groupDirs{g}));
        end
        
    catch ME
        fprintf('✗ Error grouping N cases: %s\n', ME.message);
    end
else
    fprintf('⚠ Skipping grouping test due to empty filtered cases\n');
end

% 测试5：测试高级筛选函数（仅检查函数存在性）
fprintf('\n5. Testing advanced_flexible_filtering_N existence...\n');
if exist('advanced_flexible_filtering_N', 'file') == 2
    fprintf('✓ advanced_flexible_filtering_N function exists\n');
else
    fprintf('✗ advanced_flexible_filtering_N function not found\n');
end

if exist('execute_filtering_and_grouping_N', 'file') == 2
    fprintf('✓ execute_filtering_and_grouping_N function exists\n');
else
    fprintf('✗ execute_filtering_and_grouping_N function not found\n');
end

fprintf('\n========================================================================\n');
fprintf('N Script Function Testing Completed\n');
fprintf('========================================================================\n');
