% ========================================================================
% 调试验证功能
% ========================================================================

clear;
clc;

fprintf('Debug: Testing validation function step by step...\n');

% 步骤1：加载预定义组
fprintf('\nStep 1: Loading predefined groups...\n');
try
    groups = predefined_case_groups_N_real();
    fprintf('✓ Successfully loaded groups\n');
    
    % 检查组结构
    if isfield(groups, 'fav_BT')
        fprintf('  fav_BT groups: %d\n', length(groups.fav_BT));
        for i = 1:length(groups.fav_BT)
            fprintf('    Group %d: %d cases\n', i, length(groups.fav_BT{i}));
        end
    end
    
    if isfield(groups, 'unfav_BT')
        fprintf('  unfav_BT groups: %d\n', length(groups.unfav_BT));
        for i = 1:length(groups.unfav_BT)
            fprintf('    Group %d: %d cases\n', i, length(groups.unfav_BT{i}));
        end
    end
    
catch ME
    fprintf('✗ Error loading groups: %s\n', ME.message);
    return;
end

% 步骤2：手动检查重复
fprintf('\nStep 2: Manual duplicate check...\n');
all_paths_manual = {};

% 收集所有路径
if isfield(groups, 'fav_BT')
    for i = 1:length(groups.fav_BT)
        group_paths = groups.fav_BT{i};
        for j = 1:length(group_paths)
            all_paths_manual{end+1} = group_paths{j};
        end
    end
end

if isfield(groups, 'unfav_BT')
    for i = 1:length(groups.unfav_BT)
        group_paths = groups.unfav_BT{i};
        for j = 1:length(group_paths)
            all_paths_manual{end+1} = group_paths{j};
        end
    end
end

fprintf('Total paths collected: %d\n', length(all_paths_manual));

% 检查重复
[unique_paths, ~, idx] = unique(all_paths_manual);
duplicate_counts = histcounts(idx, 1:length(unique_paths)+1);
duplicate_indices = find(duplicate_counts > 1);

if ~isempty(duplicate_indices)
    fprintf('Found %d duplicate paths:\n', length(duplicate_indices));
    for i = 1:length(duplicate_indices)
        dup_idx = duplicate_indices(i);
        dup_path = unique_paths{dup_idx};
        count = duplicate_counts(dup_idx);
        fprintf('  %d. %s (appears %d times)\n', i, dup_path, count);
        
        % 找到所有出现位置
        occurrences = find(strcmp(all_paths_manual, dup_path));
        fprintf('     Positions: %s\n', mat2str(occurrences));
    end
else
    fprintf('No duplicates found in manual check.\n');
end

% 步骤3：测试简化的验证函数
fprintf('\nStep 3: Testing simplified validation...\n');
try
    % 创建简化的验证函数
    validated_groups_simple = struct();
    duplicate_report_simple = struct();
    duplicate_report_simple.duplicates_found = {};
    duplicate_report_simple.invalid_paths = {};
    
    all_paths_validation = {};
    path_locations_validation = {};
    
    % 处理fav_BT组
    if isfield(groups, 'fav_BT')
        validated_groups_simple.fav_BT = cell(size(groups.fav_BT));
        
        for group_idx = 1:length(groups.fav_BT)
            group_paths = groups.fav_BT{group_idx};
            validated_paths = {};
            
            for path_idx = 1:length(group_paths)
                current_path = group_paths{path_idx};
                
                % 检查重复
                if any(strcmp(all_paths_validation, current_path))
                    fprintf('  Duplicate found: %s\n', current_path);
                    duplicate_report_simple.duplicates_found{end+1} = current_path;
                    continue;
                end
                
                % 检查路径有效性（跳过，因为可能在本地不存在）
                % if ~exist(current_path, 'dir')
                %     duplicate_report_simple.invalid_paths{end+1} = current_path;
                %     continue;
                % end
                
                % 添加到验证列表
                validated_paths{end+1} = current_path;
                all_paths_validation{end+1} = current_path;
                path_locations_validation{end+1} = sprintf('fav_BT{%d}[%d]', group_idx, path_idx);
            end
            
            validated_groups_simple.fav_BT{group_idx} = validated_paths;
            fprintf('  fav_BT Group %d: %d valid paths (from %d original)\n', ...
                    group_idx, length(validated_paths), length(group_paths));
        end
    end
    
    % 处理unfav_BT组
    if isfield(groups, 'unfav_BT')
        validated_groups_simple.unfav_BT = cell(size(groups.unfav_BT));
        
        for group_idx = 1:length(groups.unfav_BT)
            group_paths = groups.unfav_BT{group_idx};
            validated_paths = {};
            
            for path_idx = 1:length(group_paths)
                current_path = group_paths{path_idx};
                
                % 检查重复
                if any(strcmp(all_paths_validation, current_path))
                    fprintf('  Duplicate found: %s\n', current_path);
                    duplicate_report_simple.duplicates_found{end+1} = current_path;
                    continue;
                end
                
                % 添加到验证列表
                validated_paths{end+1} = current_path;
                all_paths_validation{end+1} = current_path;
                path_locations_validation{end+1} = sprintf('unfav_BT{%d}[%d]', group_idx, path_idx);
            end
            
            validated_groups_simple.unfav_BT{group_idx} = validated_paths;
            fprintf('  unfav_BT Group %d: %d valid paths (from %d original)\n', ...
                    group_idx, length(validated_paths), length(group_paths));
        end
    end
    
    fprintf('✓ Simplified validation completed successfully\n');
    fprintf('Total duplicates found: %d\n', length(duplicate_report_simple.duplicates_found));
    fprintf('Total valid paths: %d\n', length(all_paths_validation));
    
catch ME
    fprintf('✗ Error in simplified validation: %s\n', ME.message);
    fprintf('Error stack:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

% 步骤4：测试原始验证函数
fprintf('\nStep 4: Testing original validation function...\n');
try
    [validated_groups_orig, duplicate_report_orig] = validate_and_deduplicate_cases(groups);
    fprintf('✓ Original validation completed successfully\n');
    
catch ME
    fprintf('✗ Error in original validation: %s\n', ME.message);
    fprintf('Error stack:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

fprintf('\nDebug completed.\n');
