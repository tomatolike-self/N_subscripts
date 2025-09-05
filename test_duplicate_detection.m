% ========================================================================
% 测试重复算例检测功能
% ========================================================================
%
% 这个脚本用于测试修改后的N脚本是否能正确检测和处理重复算例
%
% ========================================================================

clear;
clc;

fprintf('========================================================================\n');
fprintf('TESTING DUPLICATE CASE DETECTION\n');
fprintf('========================================================================\n');

% 测试1：加载原始预定义组并检查重复
fprintf('\nTest 1: Loading original predefined groups and checking for duplicates...\n');
try
    original_groups = predefined_case_groups_N_real();
    fprintf('Successfully loaded predefined groups.\n');
    
    % 统计原始组的算例数量
    fav_count = 0;
    unfav_count = 0;
    
    if isfield(original_groups, 'fav_BT')
        for i = 1:length(original_groups.fav_BT)
            fav_count = fav_count + length(original_groups.fav_BT{i});
        end
    end
    
    if isfield(original_groups, 'unfav_BT')
        for i = 1:length(original_groups.unfav_BT)
            unfav_count = unfav_count + length(original_groups.unfav_BT{i});
        end
    end
    
    fprintf('Original groups statistics:\n');
    fprintf('  FAV BT cases: %d\n', fav_count);
    fprintf('  UNFAV BT cases: %d\n', unfav_count);
    fprintf('  Total cases: %d\n', fav_count + unfav_count);
    
catch ME
    fprintf('Error loading predefined groups: %s\n', ME.message);
    return;
end

% 测试2：验证和去重
fprintf('\nTest 2: Validating and deduplicating cases...\n');
try
    [validated_groups, duplicate_report] = validate_and_deduplicate_cases_simple(original_groups);
    fprintf('Successfully validated and deduplicated cases.\n');
    
    % 统计验证后的算例数量
    validated_fav_count = 0;
    validated_unfav_count = 0;
    
    if isfield(validated_groups, 'fav_BT')
        for i = 1:length(validated_groups.fav_BT)
            validated_fav_count = validated_fav_count + length(validated_groups.fav_BT{i});
        end
    end
    
    if isfield(validated_groups, 'unfav_BT')
        for i = 1:length(validated_groups.unfav_BT)
            validated_unfav_count = validated_unfav_count + length(validated_groups.unfav_BT{i});
        end
    end
    
    fprintf('Validated groups statistics:\n');
    fprintf('  FAV BT cases: %d\n', validated_fav_count);
    fprintf('  UNFAV BT cases: %d\n', validated_unfav_count);
    fprintf('  Total cases: %d\n', validated_fav_count + validated_unfav_count);
    
    % 显示重复报告摘要
    fprintf('\nDuplicate detection results:\n');
    fprintf('  Duplicates found: %d\n', length(duplicate_report.duplicates_found));
    fprintf('  Invalid paths found: %d\n', length(duplicate_report.invalid_paths));
    
    if ~isempty(duplicate_report.duplicates_found)
        fprintf('\nDuplicate cases:\n');
        for i = 1:length(duplicate_report.duplicates_found)
            dup = duplicate_report.duplicates_found{i};
            fprintf('  %d. %s\n', i, dup.path);
            fprintf('     First: %s, Duplicate: %s\n', dup.first_location, dup.duplicate_location);
        end
    end
    
catch ME
    fprintf('Error during validation: %s\n', ME.message);
    return;
end

% 测试3：生成算例数据
fprintf('\nTest 3: Generating case data from validated groups...\n');
try
    all_cases = get_all_case_data_from_validated_groups(validated_groups);
    fprintf('Successfully generated case data.\n');
    fprintf('Total cases in data structure: %d\n', length(all_cases));
    
    % 检查是否还有重复路径
    unique_paths = unique({all_cases.path});
    if length(unique_paths) == length(all_cases)
        fprintf('✓ No duplicate paths found in final case data.\n');
    else
        fprintf('✗ Still found duplicate paths in final case data!\n');
        fprintf('  Unique paths: %d, Total cases: %d\n', length(unique_paths), length(all_cases));
    end
    
    % 按BT方向和N浓度统计
    fav_cases = sum(strcmp({all_cases.bt_direction}, 'fav'));
    unfav_cases = sum(strcmp({all_cases.bt_direction}, 'unfav'));
    
    fprintf('\nCase distribution:\n');
    fprintf('  FAV BT: %d cases\n', fav_cases);
    fprintf('  UNFAV BT: %d cases\n', unfav_cases);
    
    % 按N浓度统计
    n_concentrations = [0.5, 1.0, 1.5, 2.0];
    for n_conc = n_concentrations
        n_cases = sum([all_cases.n_concentration] == n_conc);
        fprintf('  N%.1f: %d cases\n', n_conc, n_cases);
    end
    
catch ME
    fprintf('Error generating case data: %s\n', ME.message);
    return;
end

% 测试4：比较修改前后的差异
fprintf('\nTest 4: Comparing before and after modification...\n');
original_total = fav_count + unfav_count;
validated_total = validated_fav_count + validated_unfav_count;
difference = original_total - validated_total;

fprintf('Summary of changes:\n');
fprintf('  Original total cases: %d\n', original_total);
fprintf('  Validated total cases: %d\n', validated_total);
fprintf('  Cases removed (duplicates + invalid): %d\n', difference);

if difference > 0
    fprintf('✓ Successfully removed %d problematic cases.\n', difference);
else
    fprintf('ℹ No cases were removed.\n');
end

fprintf('\n========================================================================\n');
fprintf('DUPLICATE DETECTION TEST COMPLETED\n');
fprintf('========================================================================\n');

% 测试5：检查存在问题的算例.md中的路径
fprintf('\nTest 5: Checking problematic cases from 存在问题的算例.md...\n');
problematic_file = fullfile('算例测试', '存在问题的算例.md');
if exist(problematic_file, 'file')
    try
        fid = fopen(problematic_file, 'r');
        problematic_paths = {};
        while ~feof(fid)
            line = fgetl(fid);
            if ischar(line) && ~isempty(line)
                problematic_paths{end+1} = strtrim(line);
            end
        end
        fclose(fid);
        
        fprintf('Found %d problematic paths in the file.\n', length(problematic_paths));
        
        % 检查这些路径是否在验证后的组中
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
        for i = 1:length(problematic_paths)
            if any(strcmp(all_validated_paths, problematic_paths{i}))
                still_present = still_present + 1;
                fprintf('  Still present: %s\n', problematic_paths{i});
            end
        end
        
        fprintf('Problematic paths still present after validation: %d/%d\n', still_present, length(problematic_paths));
        
    catch ME
        fprintf('Error reading problematic cases file: %s\n', ME.message);
    end
else
    fprintf('Problematic cases file not found: %s\n', problematic_file);
end

fprintf('\nTest completed successfully!\n');
