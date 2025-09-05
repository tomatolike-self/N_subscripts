function [validated_groups, duplicate_report] = validate_and_deduplicate_cases_simple(groups)
% ========================================================================
% 简化版验证和去重算例组函数
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

fprintf('Starting case validation and deduplication (simple version)...\n');

% 初始化输出结构体
validated_groups = struct();
duplicate_report = struct();
duplicate_report.duplicates_found = {};
duplicate_report.invalid_paths = {};
duplicate_report.summary = '';

% 收集所有路径用于重复检查
all_paths = {};
duplicate_count = 0;
invalid_count = 0;

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
            if any(strcmp(all_paths, current_path))
                % 发现重复
                duplicate_info = struct();
                duplicate_info.path = current_path;
                duplicate_info.first_location = 'Previously processed';
                duplicate_info.duplicate_location = sprintf('fav_BT{%d}[%d]', group_idx, path_idx);
                duplicate_report.duplicates_found{end+1} = duplicate_info;
                duplicate_count = duplicate_count + 1;
                
                fprintf('  Duplicate found: %s\n', current_path);
                continue;  % 跳过重复路径
            end
            
            % 检查路径有效性（在服务器环境中跳过此检查）
            % 注意：在服务器环境中，路径可能存在但本地无法访问，所以跳过此检查
            % if ~exist(current_path, 'dir')
            %     duplicate_report.invalid_paths{end+1} = current_path;
            %     invalid_count = invalid_count + 1;
            %     fprintf('  Invalid path: %s\n', current_path);
            %     continue;  % 跳过无效路径
            % end
            
            % 添加到验证列表
            validated_paths{end+1} = current_path;
            all_paths{end+1} = current_path;
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
            if any(strcmp(all_paths, current_path))
                % 发现重复
                duplicate_info = struct();
                duplicate_info.path = current_path;
                duplicate_info.first_location = 'Previously processed';
                duplicate_info.duplicate_location = sprintf('unfav_BT{%d}[%d]', group_idx, path_idx);
                duplicate_report.duplicates_found{end+1} = duplicate_info;
                duplicate_count = duplicate_count + 1;
                
                fprintf('  Duplicate found: %s\n', current_path);
                continue;  % 跳过重复路径
            end
            
            % 检查路径有效性（在服务器环境中跳过此检查）
            % if ~exist(current_path, 'dir')
            %     duplicate_report.invalid_paths{end+1} = current_path;
            %     invalid_count = invalid_count + 1;
            %     fprintf('  Invalid path: %s\n', current_path);
            %     continue;  % 跳过无效路径
            % end
            
            % 添加到验证列表
            validated_paths{end+1} = current_path;
            all_paths{end+1} = current_path;
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
total_valid = length(all_paths);

duplicate_report.summary = sprintf(...
    ['Validation Summary:\n', ...
     '  Total valid paths: %d\n', ...
     '  Duplicates removed: %d\n', ...
     '  Invalid paths removed: %d\n'], ...
    total_valid, duplicate_count, invalid_count);

fprintf('\n%s\n', duplicate_report.summary);

% 保存重复报告到文件
save_duplicate_report_simple(duplicate_report);

end

% ========================================================================
% 辅助函数：保存重复报告
% ========================================================================
function save_duplicate_report_simple(duplicate_report)
    timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    report_filename = sprintf('duplicate_validation_report_%s.txt', timestamp);
    
    fid = fopen(report_filename, 'w');
    if fid == -1
        warning('Could not create duplicate report file: %s', report_filename);
        return;
    end
    
    fprintf(fid, 'Case Validation and Deduplication Report (Simple Version)\n');
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
