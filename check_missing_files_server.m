function check_missing_files_server()
% ========================================================================
% 服务器端N杂质算例关键文件检查脚本
% 专门用于排查主脚本运行时报告的文件缺失问题
% ========================================================================

fprintf('========================================================================\n');
fprintf('Server-side N Impurity Case File Check\n');
fprintf('========================================================================\n');

% 定义需要检查的关键文件
key_files = {
    'b2fgmtry';
    'fort.44';
    'b2fstate';
    'b2fplasmf'
};

% 从错误信息中提取的问题算例路径
problem_cases = {
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/5p5mw_flux_1p1260e22/baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p20e22_target1_target1';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p3000e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_target1_target1';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5';
    '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p26e22_target1_target1'
};

fprintf('Checking %d problem cases reported by main script...\n\n', length(problem_cases));

% 检查每个问题算例
for i = 1:length(problem_cases)
    case_path = problem_cases{i};
    [~, case_name] = fileparts(case_path);
    
    fprintf('=== Case %d/%d ===\n', i, length(problem_cases));
    fprintf('Path: %s\n', case_path);
    fprintf('Name: %s\n', case_name);
    
    % 检查目录是否存在
    if ~exist(case_path, 'dir')
        fprintf('❌ Directory does not exist!\n\n');
        continue;
    end
    
    fprintf('✅ Directory exists\n');
    
    % 检查每个关键文件
    missing_files = {};
    existing_files = {};
    
    for j = 1:length(key_files)
        file_path = fullfile(case_path, key_files{j});
        if exist(file_path, 'file')
            existing_files{end+1} = key_files{j};
            fprintf('  ✅ %s - EXISTS\n', key_files{j});
        else
            missing_files{end+1} = key_files{j};
            fprintf('  ❌ %s - MISSING\n', key_files{j});
        end
    end
    
    % 总结当前算例状态
    if isempty(missing_files)
        fprintf('✅ All key files present for this case\n');
    else
        fprintf('❌ Missing files: %s\n', strjoin(missing_files, ', '));
    end
    
    % 列出目录中实际存在的文件
    fprintf('Files in directory:\n');
    try
        dir_contents = dir(case_path);
        file_count = 0;
        for k = 1:length(dir_contents)
            if ~dir_contents(k).isdir
                file_count = file_count + 1;
                fprintf('  - %s\n', dir_contents(k).name);
            end
        end
        if file_count == 0
            fprintf('  (No files found)\n');
        end
    catch
        fprintf('  (Cannot list directory contents)\n');
    end
    
    fprintf('\n');
end

% 生成总结报告
fprintf('========================================================================\n');
fprintf('SUMMARY REPORT\n');
fprintf('========================================================================\n');

% 统计每个文件的缺失情况
file_missing_count = containers.Map();
for i = 1:length(key_files)
    file_missing_count(key_files{i}) = 0;
end

total_missing_cases = 0;
for i = 1:length(problem_cases)
    case_path = problem_cases{i};
    if ~exist(case_path, 'dir')
        continue;
    end
    
    has_missing = false;
    for j = 1:length(key_files)
        file_path = fullfile(case_path, key_files{j});
        if ~exist(file_path, 'file')
            file_missing_count(key_files{j}) = file_missing_count(key_files{j}) + 1;
            has_missing = true;
        end
    end
    
    if has_missing
        total_missing_cases = total_missing_cases + 1;
    end
end

fprintf('Total problem cases checked: %d\n', length(problem_cases));
fprintf('Cases with missing files: %d\n', total_missing_cases);
fprintf('Cases with all files present: %d\n', length(problem_cases) - total_missing_cases);

fprintf('\nFile missing statistics:\n');
for i = 1:length(key_files)
    count = file_missing_count(key_files{i});
    fprintf('  %s: missing in %d cases\n', key_files{i}, count);
end

% 建议
fprintf('\n========================================================================\n');
fprintf('RECOMMENDATIONS\n');
fprintf('========================================================================\n');

if total_missing_cases == length(problem_cases)
    fprintf('❌ All checked cases have missing files.\n');
    fprintf('Possible causes:\n');
    fprintf('  1. SOLPS simulations did not complete successfully\n');
    fprintf('  2. Output files were moved or deleted\n');
    fprintf('  3. File naming convention changed\n');
    fprintf('  4. Simulation is still running\n');
    fprintf('\nSuggested actions:\n');
    fprintf('  - Check if simulations are still running\n');
    fprintf('  - Verify SOLPS output file locations\n');
    fprintf('  - Check simulation log files for errors\n');
elseif total_missing_cases > 0
    fprintf('⚠️  Some cases have missing files (%d/%d).\n', total_missing_cases, length(problem_cases));
    fprintf('Suggested actions:\n');
    fprintf('  - For cases with all files: proceed with analysis\n');
    fprintf('  - For cases with missing files: check simulation status\n');
    fprintf('  - Consider temporarily excluding incomplete cases\n');
else
    fprintf('✅ All cases have required files present.\n');
    fprintf('The issue might be:\n');
    fprintf('  - File permissions\n');
    fprintf('  - MATLAB path issues\n');
    fprintf('  - File corruption\n');
end

fprintf('\n========================================================================\n');
fprintf('Check completed. Review the detailed output above.\n');
fprintf('========================================================================\n');

end
