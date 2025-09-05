function write_detailed_error_info(currentDir, missing_files, found_files, key_file_names)
% ========================================================================
% 写入详细的错误诊断信息到文件
% 
% 输入参数:
%   currentDir - 当前处理的算例目录路径
%   missing_files - 缺失的文件列表 (cell array)
%   found_files - 找到的文件映射 (containers.Map)
%   key_file_names - 关键文件名列表 (cell array)
% ========================================================================

    % 生成时间戳
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    [~, case_name] = fileparts(currentDir);
    
    % 创建错误报告文件名
    error_report_file = sprintf('error_diagnosis_%s_%s.txt', case_name, timestamp);
    
    try
        fid = fopen(error_report_file, 'w');
        
        % 写入报告头部
        fprintf(fid, '========================================================================\n');
        fprintf(fid, 'SOLPS Case Error Diagnosis Report\n');
        fprintf(fid, '========================================================================\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, 'Case Path: %s\n', currentDir);
        fprintf(fid, 'Case Name: %s\n\n', case_name);
        
        % 分析算例分类信息
        fprintf(fid, 'CASE CLASSIFICATION:\n');
        fprintf(fid, '--------------------\n');
        
        % BT方向分析
        if contains(case_name, 'reversed')
            fprintf(fid, 'BT Direction: unfav (reversed)\n');
        elseif contains(case_name, 'normal')
            fprintf(fid, 'BT Direction: fav (normal)\n');
        else
            fprintf(fid, 'BT Direction: unknown\n');
        end
        
        % N浓度分析
        if contains(case_name, 'changeto_N0p5')
            fprintf(fid, 'N Concentration: 0.5\n');
        elseif contains(case_name, 'changeto_N1') && ~contains(case_name, 'changeto_N1p5')
            fprintf(fid, 'N Concentration: 1.0\n');
        elseif contains(case_name, 'changeto_N1p5')
            fprintf(fid, 'N Concentration: 1.5\n');
        elseif contains(case_name, 'changeto_N2')
            fprintf(fid, 'N Concentration: 2.0\n');
        elseif contains(case_name, 'N1_N2')
            fprintf(fid, 'N Concentration: 1.0->2.0 (transition)\n');
        else
            fprintf(fid, 'N Concentration: unknown\n');
        end
        
        % 功率分析
        if contains(currentDir, '5p5mw_flux')
            fprintf(fid, 'Power: 5.5MW\n');
        elseif contains(currentDir, '6mw_flux')
            fprintf(fid, 'Power: 6MW\n');
        elseif contains(currentDir, '7mw_flux')
            fprintf(fid, 'Power: 7MW\n');
        elseif contains(currentDir, '8mw_flux')
            fprintf(fid, 'Power: 8MW\n');
        elseif contains(currentDir, '10mw_flux')
            fprintf(fid, 'Power: 10MW\n');
        else
            fprintf(fid, 'Power: unknown\n');
        end
        
        fprintf(fid, '\n');
        
        % 写入缺失文件信息
        fprintf(fid, 'MISSING FILES:\n');
        fprintf(fid, '--------------\n');
        if isempty(missing_files)
            fprintf(fid, 'None (all key files found)\n');
        else
            for i = 1:length(missing_files)
                fprintf(fid, '%d. %s\n', i, missing_files{i});
            end
        end
        fprintf(fid, '\n');
        
        % 写入找到的文件信息
        fprintf(fid, 'FOUND FILES:\n');
        fprintf(fid, '------------\n');
        for i = 1:length(key_file_names)
            file_name = key_file_names{i};
            if isKey(found_files, file_name) && ~isempty(found_files(file_name))
                fprintf(fid, '✓ %s: %s\n', file_name, found_files(file_name));
            else
                fprintf(fid, '✗ %s: NOT FOUND\n', file_name);
            end
        end
        fprintf(fid, '\n');
        
        % 写入目录层级信息
        fprintf(fid, 'DIRECTORY HIERARCHY:\n');
        fprintf(fid, '--------------------\n');
        parentDir = fileparts(currentDir);
        grandparentDir = fileparts(parentDir);
        fprintf(fid, 'Current: %s\n', currentDir);
        fprintf(fid, 'Parent: %s\n', parentDir);
        fprintf(fid, 'Grandparent: %s\n\n', grandparentDir);
        
        % 写入搜索位置信息
        fprintf(fid, 'SEARCH LOCATIONS CHECKED:\n');
        fprintf(fid, '-------------------------\n');
        fprintf(fid, 'For each missing file, the following locations were checked:\n');
        fprintf(fid, '1. Current directory: %s\n', currentDir);
        fprintf(fid, '2. Parent directory: %s\n', parentDir);
        fprintf(fid, '3. Grandparent directory: %s\n', grandparentDir);
        fprintf(fid, '4. Parent baserun: %s\n', fullfile(parentDir, 'baserun'));
        fprintf(fid, '5. Grandparent baserun: %s\n\n', fullfile(grandparentDir, 'baserun'));
        
        % 检查并列出实际存在的文件
        fprintf(fid, 'FILES ACTUALLY PRESENT IN CURRENT DIRECTORY:\n');
        fprintf(fid, '--------------------------------------------\n');
        try
            dir_contents = dir(currentDir);
            file_count = 0;
            for k = 1:length(dir_contents)
                if ~dir_contents(k).isdir
                    file_count = file_count + 1;
                    file_info = dir_contents(k);
                    fprintf(fid, '- %s (%.1f KB, %s)\n', file_info.name, file_info.bytes/1024, file_info.date);
                end
            end
            if file_count == 0
                fprintf(fid, '(No files found in current directory)\n');
            else
                fprintf(fid, 'Total files in current directory: %d\n', file_count);
            end
        catch
            fprintf(fid, '(Cannot list directory contents - permission issue?)\n');
        end
        fprintf(fid, '\n');
        
        % 检查baserun目录
        fprintf(fid, 'BASERUN DIRECTORY CHECK:\n');
        fprintf(fid, '------------------------\n');
        baserun_dir = fullfile(parentDir, 'baserun');
        if exist(baserun_dir, 'dir')
            fprintf(fid, '✓ baserun directory exists: %s\n', baserun_dir);
            try
                baserun_contents = dir(baserun_dir);
                fprintf(fid, 'Files in baserun directory:\n');
                for k = 1:length(baserun_contents)
                    if ~baserun_contents(k).isdir
                        fprintf(fid, '- %s\n', baserun_contents(k).name);
                    end
                end
            catch
                fprintf(fid, '(Cannot list baserun contents)\n');
            end
        else
            fprintf(fid, '✗ baserun directory not found: %s\n', baserun_dir);
        end
        fprintf(fid, '\n');
        
        % 写入可能的原因和建议
        fprintf(fid, 'POSSIBLE CAUSES:\n');
        fprintf(fid, '----------------\n');
        fprintf(fid, '1. SOLPS simulation did not complete successfully\n');
        fprintf(fid, '2. Output files were moved or deleted\n');
        fprintf(fid, '3. Simulation is still running\n');
        fprintf(fid, '4. File naming convention differs from expected\n');
        fprintf(fid, '5. Permission issues preventing file access\n');
        fprintf(fid, '6. Disk space issues during simulation\n');
        fprintf(fid, '7. Simulation crashed or was interrupted\n\n');
        
        fprintf(fid, 'RECOMMENDED ACTIONS:\n');
        fprintf(fid, '-------------------\n');
        fprintf(fid, '1. Check if simulation is still running (ps aux | grep solps)\n');
        fprintf(fid, '2. Verify simulation log files for errors\n');
        fprintf(fid, '3. Check file permissions (ls -la in the directory)\n');
        fprintf(fid, '4. Check disk space (df -h)\n');
        fprintf(fid, '5. Manually verify file locations\n');
        fprintf(fid, '6. Check if files exist with different names\n');
        fprintf(fid, '7. Consider re-running the simulation if needed\n');
        fprintf(fid, '8. Check if this is a complex transition case that needs special handling\n\n');
        
        % 特殊情况分析
        if contains(case_name, 'N1_N2') || contains(case_name, 'changeto_N1_changeto_N2')
            fprintf(fid, 'SPECIAL CASE ANALYSIS:\n');
            fprintf(fid, '----------------------\n');
            fprintf(fid, 'This appears to be a nitrogen concentration transition case.\n');
            fprintf(fid, 'Such cases may:\n');
            fprintf(fid, '- Take longer to converge\n');
            fprintf(fid, '- Require different file handling\n');
            fprintf(fid, '- Have intermediate output files\n');
            fprintf(fid, '- Need special post-processing\n\n');
        end
        
        fprintf(fid, '========================================================================\n');
        fprintf(fid, 'End of Error Diagnosis Report\n');
        fprintf(fid, '========================================================================\n');
        
        fclose(fid);
        
        fprintf('Detailed error diagnosis saved to: %s\n', error_report_file);
        
    catch ME
        fprintf('Warning: Could not write detailed error report: %s\n', ME.message);
    end
end
