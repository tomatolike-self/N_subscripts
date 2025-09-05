% ========================================================================
% 快速测试修改后的功能
% ========================================================================

clear;
clc;

fprintf('========================================================================\n');
fprintf('QUICK TEST OF DUPLICATE DETECTION FIXES\n');
fprintf('========================================================================\n');

% 测试1：检查预定义组的修改
fprintf('\nTest 1: Checking predefined groups modification...\n');
try
    groups = predefined_case_groups_N_real();
    
    % 统计各组的算例数量
    fav_counts = zeros(1, 4);
    unfav_counts = zeros(1, 4);
    
    for i = 1:4
        if i <= length(groups.fav_BT)
            fav_counts(i) = length(groups.fav_BT{i});
        end
        if i <= length(groups.unfav_BT)
            unfav_counts(i) = length(groups.unfav_BT{i});
        end
    end
    
    fprintf('FAV BT groups: [%s] = %d total\n', num2str(fav_counts), sum(fav_counts));
    fprintf('UNFAV BT groups: [%s] = %d total\n', num2str(unfav_counts), sum(unfav_counts));
    fprintf('Total cases: %d\n', sum(fav_counts) + sum(unfav_counts));
    
    % 检查是否还有重复
    all_paths = {};
    
    % 收集所有路径
    for i = 1:length(groups.fav_BT)
        for j = 1:length(groups.fav_BT{i})
            all_paths{end+1} = groups.fav_BT{i}{j};
        end
    end
    
    for i = 1:length(groups.unfav_BT)
        for j = 1:length(groups.unfav_BT{i})
            all_paths{end+1} = groups.unfav_BT{i}{j};
        end
    end
    
    % 检查重复
    [unique_paths, ~, idx] = unique(all_paths);
    duplicate_counts = histcounts(idx, 1:length(unique_paths)+1);
    duplicate_indices = find(duplicate_counts > 1);
    
    if isempty(duplicate_indices)
        fprintf('✓ No duplicates found in predefined groups.\n');
    else
        fprintf('✗ Still found %d duplicate paths:\n', length(duplicate_indices));
        for i = 1:min(3, length(duplicate_indices))  % 只显示前3个
            dup_idx = duplicate_indices(i);
            dup_path = unique_paths{dup_idx};
            count = duplicate_counts(dup_idx);
            fprintf('  %d. %s (appears %d times)\n', i, dup_path, count);
        end
    end
    
catch ME
    fprintf('✗ Error loading predefined groups: %s\n', ME.message);
end

% 测试2：检查简化验证函数
fprintf('\nTest 2: Testing simplified validation function...\n');
try
    [validated_groups, duplicate_report] = validate_and_deduplicate_cases_simple(groups);
    
    % 统计验证后的数量
    validated_fav_counts = zeros(1, 4);
    validated_unfav_counts = zeros(1, 4);
    
    for i = 1:4
        if i <= length(validated_groups.fav_BT)
            validated_fav_counts(i) = length(validated_groups.fav_BT{i});
        end
        if i <= length(validated_groups.unfav_BT)
            validated_unfav_counts(i) = length(validated_groups.unfav_BT{i});
        end
    end
    
    fprintf('Validated FAV BT groups: [%s] = %d total\n', num2str(validated_fav_counts), sum(validated_fav_counts));
    fprintf('Validated UNFAV BT groups: [%s] = %d total\n', num2str(validated_unfav_counts), sum(validated_unfav_counts));
    fprintf('Total validated cases: %d\n', sum(validated_fav_counts) + sum(validated_unfav_counts));
    
    fprintf('Duplicates found and removed: %d\n', length(duplicate_report.duplicates_found));
    fprintf('Invalid paths found: %d\n', length(duplicate_report.invalid_paths));
    
    if ~isempty(duplicate_report.duplicates_found)
        fprintf('Duplicate paths:\n');
        for i = 1:length(duplicate_report.duplicates_found)
            dup = duplicate_report.duplicates_found{i};
            fprintf('  %d. %s\n', i, dup.path);
        end
    end
    
catch ME
    fprintf('✗ Error in validation: %s\n', ME.message);
end

% 测试3：检查算例数据生成
fprintf('\nTest 3: Testing case data generation...\n');
try
    all_cases = get_all_case_data_from_validated_groups(validated_groups);
    
    fprintf('Generated case data: %d cases\n', length(all_cases));
    
    % 检查最终数据中是否还有重复
    case_paths = {all_cases.path};
    unique_case_paths = unique(case_paths);
    
    if length(unique_case_paths) == length(case_paths)
        fprintf('✓ No duplicates in final case data.\n');
    else
        fprintf('✗ Still found duplicates in final case data!\n');
        fprintf('  Unique: %d, Total: %d\n', length(unique_case_paths), length(case_paths));
    end
    
    % 按BT方向统计
    fav_cases = sum(strcmp({all_cases.bt_direction}, 'fav'));
    unfav_cases = sum(strcmp({all_cases.bt_direction}, 'unfav'));
    
    fprintf('Case distribution by BT direction:\n');
    fprintf('  FAV: %d cases\n', fav_cases);
    fprintf('  UNFAV: %d cases\n', unfav_cases);
    
    % 按N浓度统计
    n_concentrations = [0.5, 1.0, 1.5, 2.0];
    fprintf('Case distribution by N concentration:\n');
    for n_conc = n_concentrations
        n_cases = sum([all_cases.n_concentration] == n_conc);
        fprintf('  N%.1f: %d cases\n', n_conc, n_cases);
    end
    
catch ME
    fprintf('✗ Error generating case data: %s\n', ME.message);
end

% 测试4：检查特定的问题算例
fprintf('\nTest 4: Checking specific problematic cases...\n');

% 这些是从存在问题的算例.md中提取的重复路径
problematic_cases = {
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N2';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_changeto_N2'
};

fprintf('Checking if problematic cases are still present in validated groups...\n');

% 收集所有验证后的路径
all_validated_paths = {};
if isfield(validated_groups, 'fav_BT')
    for i = 1:length(validated_groups.fav_BT)
        all_validated_paths = [all_validated_paths, validated_groups.fav_BT{i}];
    end
end
if isfield(validated_groups, 'unfav_BT')
    for i = 1:length(validated_groups.unfav_BT)
        all_validated_paths = [all_validated_paths, validated_groups.unfav_BT{i}];
    end
end

still_present = 0;
for i = 1:length(problematic_cases)
    if any(strcmp(all_validated_paths, problematic_cases{i}))
        still_present = still_present + 1;
        fprintf('  ✓ Present: %s\n', problematic_cases{i});
    else
        fprintf('  ✗ Missing: %s\n', problematic_cases{i});
    end
end

fprintf('Problematic cases still present: %d/%d\n', still_present, length(problematic_cases));

fprintf('\n========================================================================\n');
fprintf('QUICK TEST COMPLETED\n');
fprintf('========================================================================\n');
