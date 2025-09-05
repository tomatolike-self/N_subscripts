function comprehensive_file_check()
% ========================================================================
% 全面的N杂质算例文件检查脚本
% 检查所有配置的算例，生成完整的文件状态报告
% ========================================================================

fprintf('========================================================================\n');
fprintf('Comprehensive N Impurity Case File Check\n');
fprintf('========================================================================\n');

% 获取所有配置的算例
try
    groups = predefined_case_groups_N_real();
    fprintf('✅ Successfully loaded predefined case groups\n');
catch ME
    fprintf('❌ Failed to load predefined case groups: %s\n', ME.message);
    return;
end

% 定义需要检查的关键文件
key_files = {
    'b2fgmtry';
    'fort.44';
    'b2fstate';
    'b2fplasmf'
};

% 收集所有算例路径
all_cases = {};
case_labels = {};

% 收集fav BT组
n_concentrations = [0.5, 1.0, 1.5, 2.0];
for i = 1:length(groups.fav_BT)
    for j = 1:length(groups.fav_BT{i})
        all_cases{end+1} = groups.fav_BT{i}{j};
        case_labels{end+1} = sprintf('fav-N%.1f', n_concentrations(i));
    end
end

% 收集unfav BT组
for i = 1:length(groups.unfav_BT)
    for j = 1:length(groups.unfav_BT{i})
        all_cases{end+1} = groups.unfav_BT{i}{j};
        case_labels{end+1} = sprintf('unfav-N%.1f', n_concentrations(i));
    end
end

fprintf('Total cases to check: %d\n', length(all_cases));
fprintf('Key files to check: %s\n', strjoin(key_files, ', '));
fprintf('\n');

% 初始化统计变量
complete_cases = 0;
incomplete_cases = 0;
nonexistent_cases = 0;
file_stats = containers.Map();
group_stats = containers.Map();

% 初始化文件统计
for i = 1:length(key_files)
    file_stats(key_files{i}) = 0;
end

% 初始化组统计
unique_labels = unique(case_labels);
for i = 1:length(unique_labels)
    group_stats(unique_labels{i}) = struct('total', 0, 'complete', 0, 'incomplete', 0, 'nonexistent', 0);
end

% 详细检查结果
detailed_results = {};

% 检查每个算例
fprintf('Checking individual cases...\n');
for i = 1:length(all_cases)
    case_path = all_cases{i};
    case_label = case_labels{i};
    [~, case_name] = fileparts(case_path);
    
    % 更新组统计
    group_stats(case_label).total = group_stats(case_label).total + 1;
    
    % 检查目录是否存在
    if ~exist(case_path, 'dir')
        nonexistent_cases = nonexistent_cases + 1;
        group_stats(case_label).nonexistent = group_stats(case_label).nonexistent + 1;
        detailed_results{end+1} = sprintf('❌ [%s] %s - DIRECTORY NOT FOUND', case_label, case_name);
        continue;
    end
    
    % 检查关键文件
    missing_files = {};
    for j = 1:length(key_files)
        file_path = fullfile(case_path, key_files{j});
        if ~exist(file_path, 'file')
            missing_files{end+1} = key_files{j};
            file_stats(key_files{j}) = file_stats(key_files{j}) + 1;
        end
    end
    
    if isempty(missing_files)
        complete_cases = complete_cases + 1;
        group_stats(case_label).complete = group_stats(case_label).complete + 1;
        detailed_results{end+1} = sprintf('✅ [%s] %s - ALL FILES PRESENT', case_label, case_name);
    else
        incomplete_cases = incomplete_cases + 1;
        group_stats(case_label).incomplete = group_stats(case_label).incomplete + 1;
        detailed_results{end+1} = sprintf('⚠️  [%s] %s - MISSING: %s', case_label, case_name, strjoin(missing_files, ', '));
    end
end

% 输出详细结果
fprintf('\n========================================================================\n');
fprintf('DETAILED RESULTS\n');
fprintf('========================================================================\n');
for i = 1:length(detailed_results)
    fprintf('%s\n', detailed_results{i});
end

% 输出总体统计
fprintf('\n========================================================================\n');
fprintf('OVERALL STATISTICS\n');
fprintf('========================================================================\n');
fprintf('Total cases: %d\n', length(all_cases));
fprintf('Complete cases: %d (%.1f%%)\n', complete_cases, complete_cases/length(all_cases)*100);
fprintf('Incomplete cases: %d (%.1f%%)\n', incomplete_cases, incomplete_cases/length(all_cases)*100);
fprintf('Non-existent cases: %d (%.1f%%)\n', nonexistent_cases, nonexistent_cases/length(all_cases)*100);

% 按组统计
fprintf('\n========================================================================\n');
fprintf('STATISTICS BY GROUP\n');
fprintf('========================================================================\n');
group_names = keys(group_stats);
for i = 1:length(group_names)
    group_name = group_names{i};
    stats = group_stats(group_name);
    fprintf('%s:\n', group_name);
    fprintf('  Total: %d\n', stats.total);
    fprintf('  Complete: %d (%.1f%%)\n', stats.complete, stats.complete/stats.total*100);
    fprintf('  Incomplete: %d (%.1f%%)\n', stats.incomplete, stats.incomplete/stats.total*100);
    fprintf('  Non-existent: %d (%.1f%%)\n', stats.nonexistent, stats.nonexistent/stats.total*100);
end

% 文件缺失统计
fprintf('\n========================================================================\n');
fprintf('FILE MISSING STATISTICS\n');
fprintf('========================================================================\n');
file_names = keys(file_stats);
for i = 1:length(file_names)
    file_name = file_names{i};
    count = file_stats(file_name);
    fprintf('%s: missing in %d cases (%.1f%%)\n', file_name, count, count/length(all_cases)*100);
end

% 保存报告到文件
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
report_file = sprintf('comprehensive_file_check_report_%s.txt', timestamp);

try
    fid = fopen(report_file, 'w');
    fprintf(fid, 'Comprehensive N Impurity Case File Check Report\n');
    fprintf(fid, 'Generated: %s\n\n', datestr(now));
    
    fprintf(fid, 'OVERALL STATISTICS\n');
    fprintf(fid, '==================\n');
    fprintf(fid, 'Total cases: %d\n', length(all_cases));
    fprintf(fid, 'Complete cases: %d (%.1f%%)\n', complete_cases, complete_cases/length(all_cases)*100);
    fprintf(fid, 'Incomplete cases: %d (%.1f%%)\n', incomplete_cases, incomplete_cases/length(all_cases)*100);
    fprintf(fid, 'Non-existent cases: %d (%.1f%%)\n\n', nonexistent_cases, nonexistent_cases/length(all_cases)*100);
    
    fprintf(fid, 'DETAILED RESULTS\n');
    fprintf(fid, '================\n');
    for i = 1:length(detailed_results)
        fprintf(fid, '%s\n', detailed_results{i});
    end
    
    fclose(fid);
    fprintf('\n✅ Detailed report saved to: %s\n', report_file);
catch
    fprintf('\n⚠️  Could not save report to file\n');
end

% 给出建议
fprintf('\n========================================================================\n');
fprintf('RECOMMENDATIONS\n');
fprintf('========================================================================\n');

if complete_cases == 0
    fprintf('❌ No complete cases found!\n');
    fprintf('Immediate actions needed:\n');
    fprintf('  1. Verify SOLPS simulation completion status\n');
    fprintf('  2. Check file locations and naming conventions\n');
    fprintf('  3. Verify file permissions and access rights\n');
elseif complete_cases < length(all_cases) * 0.3
    fprintf('⚠️  Very few complete cases (%.1f%%).\n', complete_cases/length(all_cases)*100);
    fprintf('Suggested actions:\n');
    fprintf('  1. Focus on complete cases for immediate analysis\n');
    fprintf('  2. Investigate incomplete cases systematically\n');
    fprintf('  3. Consider updating configuration to exclude incomplete cases\n');
elseif complete_cases < length(all_cases) * 0.7
    fprintf('⚠️  Moderate number of complete cases (%.1f%%).\n', complete_cases/length(all_cases)*100);
    fprintf('Suggested actions:\n');
    fprintf('  1. Proceed with complete cases\n');
    fprintf('  2. Selectively fix incomplete cases as needed\n');
else
    fprintf('✅ Good number of complete cases (%.1f%%).\n', complete_cases/length(all_cases)*100);
    fprintf('You can proceed with analysis using complete cases.\n');
end

fprintf('\n========================================================================\n');
fprintf('Check completed. Review the detailed output and saved report.\n');
fprintf('========================================================================\n');

end
