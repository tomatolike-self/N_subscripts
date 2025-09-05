function [validated_groups, duplicate_report] = validate_and_deduplicate_cases(groups)
% ========================================================================
% 验证和去重算例组函数
% ========================================================================
%
% 功能：
%   1. 检查算例组中的重复路径
%   2. 验证路径的有效性
%   3. 生成重复报告
%   4. 返回去重后的算例组
%
% 输入参数：
%   groups - 原始算例组结构体
%
% 返回值：
%   validated_groups - 去重后的算例组
%   duplicate_report - 重复算例报告
%
% ========================================================================

fprintf('Starting case validation and deduplication...\n');

% 初始化输出结构体
validated_groups = struct();
duplicate_report = struct();
duplicate_report.duplicates_found = {};
duplicate_report.invalid_paths = {};
duplicate_report.summary = '';

% 收集所有路径用于重复检查 - 使用列向量确保一致性
all_paths = cell(0, 1);  % 初始化为列向量
path_locations = cell(0, 1);  % 初始化为列向量

% 处理fav_BT组
if isfield(groups, 'fav_BT')
    fprintf('Processing fav_BT groups...\n');
    validated_groups.fav_BT = cell(size(groups.fav_BT));
    
    for group_idx = 1:length(groups.fav_BT)
        group_paths = groups.fav_BT{group_idx};
        validated_paths = {};
        
        for path_idx = 1:length(group_paths)
            current_path = group_paths{path_idx};
            
            % 检查是否已存在
            existing_idx = find(strcmp(all_paths, current_path));
            if ~isempty(existing_idx)
                % 发现重复
                duplicate_info = struct();
                duplicate_info.path = current_path;
                duplicate_info.first_location = path_locations{existing_idx(1)};
                duplicate_info.duplicate_location = sprintf('fav_BT{%d}[%d]', group_idx, path_idx);
                duplicate_report.duplicates_found{end+1} = duplicate_info;
                
                fprintf('  Duplicate found: %s\n', current_path);
                fprintf('    First location: %s\n', duplicate_info.first_location);
                fprintf('    Duplicate location: %s\n', duplicate_info.duplicate_location);
                continue;  % 跳过重复路径
            end
            
            % 检查路径有效性
            if ~exist(current_path, 'dir')
                duplicate_report.invalid_paths{end+1} = current_path;
                fprintf('  Invalid path: %s\n', current_path);
                continue;  % 跳过无效路径
            end
            
            % 添加到验证列表
            validated_paths{end+1} = current_path;
            all_paths{end+1, 1} = current_path;  % 直接索引赋值，确保列向量
            path_locations{end+1, 1} = sprintf('fav_BT{%d}[%d]', group_idx, path_idx);  % 直接索引赋值，确保列向量
        end
        
        validated_groups.fav_BT{group_idx} = validated_paths;
        fprintf('  Group %d: %d valid paths (from %d original)\n', ...
                group_idx, length(validated_paths), length(group_paths));
    end
end

% 处理unfav_BT组
if isfield(groups, 'unfav_BT')
    fprintf('Processing unfav_BT groups...\n');
    validated_groups.unfav_BT = cell(size(groups.unfav_BT));
    
    for group_idx = 1:length(groups.unfav_BT)
        group_paths = groups.unfav_BT{group_idx};
        validated_paths = {};
        
        for path_idx = 1:length(group_paths)
            current_path = group_paths{path_idx};
            
            % 检查是否已存在
            existing_idx = find(strcmp(all_paths, current_path));
            if ~isempty(existing_idx)
                % 发现重复
                duplicate_info = struct();
                duplicate_info.path = current_path;
                duplicate_info.first_location = path_locations{existing_idx(1)};
                duplicate_info.duplicate_location = sprintf('unfav_BT{%d}[%d]', group_idx, path_idx);
                duplicate_report.duplicates_found{end+1} = duplicate_info;
                
                fprintf('  Duplicate found: %s\n', current_path);
                fprintf('    First location: %s\n', duplicate_info.first_location);
                fprintf('    Duplicate location: %s\n', duplicate_info.duplicate_location);
                continue;  % 跳过重复路径
            end
            
            % 检查路径有效性
            if ~exist(current_path, 'dir')
                duplicate_report.invalid_paths{end+1} = current_path;
                fprintf('  Invalid path: %s\n', current_path);
                continue;  % 跳过无效路径
            end
            
            % 添加到验证列表
            validated_paths{end+1} = current_path;
            all_paths{end+1, 1} = current_path;  % 直接索引赋值，确保列向量
            path_locations{end+1, 1} = sprintf('unfav_BT{%d}[%d]', group_idx, path_idx);  % 直接索引赋值，确保列向量
        end
        
        validated_groups.unfav_BT{group_idx} = validated_paths;
        fprintf('  Group %d: %d valid paths (from %d original)\n', ...
                group_idx, length(validated_paths), length(group_paths));
    end
end

% 更新combined组
if isfield(validated_groups, 'fav_BT') && isfield(validated_groups, 'unfav_BT')
    validated_groups.combined = [validated_groups.fav_BT, validated_groups.unfav_BT];
end

% 生成总结报告
total_duplicates = length(duplicate_report.duplicates_found);
total_invalid = length(duplicate_report.invalid_paths);
total_valid = length(all_paths);

duplicate_report.summary = sprintf(...
    ['Validation Summary:\n', ...
     '  Total valid paths: %d\n', ...
     '  Duplicates removed: %d\n', ...
     '  Invalid paths removed: %d\n'], ...
    total_valid, total_duplicates, total_invalid);

fprintf('\n%s\n', duplicate_report.summary);

% 保存重复报告到文件
save_duplicate_report(duplicate_report);

end

% ========================================================================
% 辅助函数：保存重复报告
% ========================================================================
function save_duplicate_report(duplicate_report)
    timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    report_filename = sprintf('duplicate_validation_report_%s.txt', timestamp);
    
    fid = fopen(report_filename, 'w');
    if fid == -1
        warning('Could not create duplicate report file: %s', report_filename);
        return;
    end
    
    fprintf(fid, 'Case Validation and Deduplication Report\n');
    fprintf(fid, 'Generated on: %s\n\n', char(datetime('now')));
    
    fprintf(fid, '%s\n\n', duplicate_report.summary);
    
    if ~isempty(duplicate_report.duplicates_found)
        fprintf(fid, 'Duplicate Cases Found:\n');
        fprintf(fid, '========================================\n');
        for i = 1:length(duplicate_report.duplicates_found)
            dup = duplicate_report.duplicates_found{i};
            fprintf(fid, '%d. %s\n', i, dup.path);
            fprintf(fid, '   First location: %s\n', dup.first_location);
            fprintf(fid, '   Duplicate location: %s\n\n', dup.duplicate_location);
        end
    end
    
    if ~isempty(duplicate_report.invalid_paths)
        fprintf(fid, 'Invalid Paths Found:\n');
        fprintf(fid, '========================================\n');
        for i = 1:length(duplicate_report.invalid_paths)
            fprintf(fid, '%d. %s\n', i, duplicate_report.invalid_paths{i});
        end
    end
    
    fclose(fid);
    fprintf('Duplicate report saved to: %s\n', report_filename);
end
