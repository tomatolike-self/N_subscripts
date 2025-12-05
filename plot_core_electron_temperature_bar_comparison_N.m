function plot_core_electron_temperature_bar_comparison_N(all_radiationData, groupDirs, usePresetLegends)
% PLOT_CORE_ELECTRON_TEMPERATURE_BAR_COMPARISON_N
%   适用于 N 杂质算例的芯部电子温度柱状对比与排序，逻辑对齐 Ne 版本：
%   1) 按输入顺序绘制柱状图；2) 以能量加权芯部 Te 升序生成排序列表和 TXT。
%
%   计算公式：
%       <Te> = Σ(ne * Te * vol) / Σ(ne * vol)
%       其中 ne、Te、vol 取 i=26:73, j=2 的芯部区域
%
%   参数:
%     all_radiationData - 仿真数据结构体数组
%     groupDirs - 分组目录元胞数组
%     usePresetLegends - 是否使用预设图例名称（fav/unfav/w/o drift）

    % -------- 参数默认值 --------
    if nargin < 3
        usePresetLegends = false;
    end

    % -------- 全局绘图样式 --------
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 14);
    set(0, 'DefaultTextFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 12);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    % -------- 计算区域与预设图例 --------
    core_indices = 26:73;    % 极向索引
    core_radial_index = 2;   % 径向索引
    preset_legends = {'favorable B_T', 'unfavorable B_T', 'w/o drift'};

    % -------- 数据收集容器（对齐 Ne 版字段） --------
    case_names = {};
    core_te_values = [];
    case_dirs = {};
    group_labels = {};

    fprintf('Calculating energy-weighted core electron temperature for N impurity cases...\n');

    % -------- 遍历各组与各算例 --------
    for g = 1:numel(groupDirs)
        currentGroup = groupDirs{g};
        fprintf('Processing group %d with %d cases...\n', g, numel(currentGroup));

        for k = 1:numel(currentGroup)
            currentDir = currentGroup{k};

            % 查找对应数据
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx < 0
                fprintf('Warning: Directory %s not found in radiation data, skipping.\n', currentDir);
                continue;
            end

            dataStruct = all_radiationData{idx};
            if ~isfield(dataStruct, 'plasma') || ~isfield(dataStruct, 'gmtry')
                fprintf('Warning: Missing plasma or gmtry data for %s, skipping.\n', currentDir);
                continue;
            end

            plasma = dataStruct.plasma;
            gmtry = dataStruct.gmtry;
            if ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev') || ~isfield(gmtry, 'vol')
                fprintf('Warning: Missing ne, te_ev, or vol data for %s, skipping.\n', currentDir);
                continue;
            end

            % 越界检查
            [nxd, nyd] = size(plasma.ne);
            if max(core_indices) > nxd || core_radial_index > nyd
                fprintf('Warning: Core indices out of bounds for %s (grid: %dx%d), skipping.\n', currentDir, nxd, nyd);
                continue;
            end

            % 取芯部数据
            core_ne = plasma.ne(core_indices, core_radial_index);
            core_te = plasma.te_ev(core_indices, core_radial_index);
            core_vol = gmtry.vol(core_indices, core_radial_index);

            % 能量加权平均
            numerator = sum(core_ne .* core_te .* core_vol, 'omitnan');
            denominator = sum(core_ne .* core_vol, 'omitnan');
            if denominator == 0 || isnan(denominator)
                core_te_avg = NaN;
                fprintf('Warning: Electron density-volume sum is zero or NaN for %s.\n', currentDir);
            else
                core_te_avg = numerator / denominator;
            end

            % 生成案例名称（与 Ne 版保持一致的图例逻辑）
            if usePresetLegends && g <= numel(preset_legends)
                case_name = sprintf('%s_%d', preset_legends{g}, k);
                group_labels{end+1} = preset_legends{g}; %#ok<AGROW>
            else
                [~, dirName] = fileparts(currentDir);
                case_name = dirName;
                group_labels{end+1} = sprintf('Group%d', g); %#ok<AGROW>
            end

            % 记录结果（顺序即输入顺序，用于绘图）
            core_te_values(end+1) = core_te_avg; %#ok<AGROW>
            case_names{end+1} = case_name;
            case_dirs{end+1} = currentDir;

            fprintf('  Case %s: Core Te = %.2f eV\n', case_name, core_te_avg);
        end
    end

    % -------- 基本检查 --------
    if isempty(core_te_values)
        fprintf('Error: No valid data found for plotting.\n');
        return;
    end

    % -------- 绘制柱状图（保持原输入顺序） --------
    figure('Name', 'Core Electron Temperature Comparison (N cases)', 'NumberTitle', 'off', ...
           'Color', 'w', 'Position', [100, 100, 1100, 640]);

    bar_handle = bar(1:length(core_te_values), core_te_values, 'FaceColor', 'flat');

    % 按组上色，逻辑与 Ne 版一致
    num_groups = length(groupDirs);
    if num_groups > 1
        group_colors = lines(num_groups);
        color_idx = 1;
        for g = 1:num_groups
            group_size = length(groupDirs{g});
            for k = 1:group_size
                if color_idx <= length(core_te_values)
                    bar_handle.CData(color_idx, :) = group_colors(g, :);
                    color_idx = color_idx + 1;
                end
            end
        end
    else
        case_colors = lines(length(core_te_values));
        bar_handle.CData = case_colors;
    end

    xlabel('Cases', 'FontSize', 14, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
    ylabel('Core Electron Temperature (eV)', 'FontSize', 14, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
    title('Core Electron Temperature Comparison (Energy-Weighted Average, N cases)', ...
          'FontSize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');

    set(gca, 'XTick', 1:length(case_names), 'XTickLabel', case_names, ...
        'XTickLabelRotation', 45, 'FontSize', 12, 'FontName', 'Times New Roman');

    grid on;
    set(gca, 'GridAlpha', 0.3);
    set(gca, 'Position', [0.08, 0.2, 0.9, 0.7]);

    % 柱顶数值标签（跳过 NaN）
    valid_for_offset = core_te_values(~isnan(core_te_values));
    if ~isempty(valid_for_offset)
        label_offset = max(valid_for_offset) * 0.02;
    else
        label_offset = 0;
    end
    for i = 1:length(core_te_values)
        if ~isnan(core_te_values(i))
            text(i, core_te_values(i) + label_offset, sprintf('%.1f', core_te_values(i)), ...
                 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                 'FontSize', 10, 'FontName', 'Times New Roman');
        end
    end

    % -------- 保存图形 --------
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fig_name = sprintf('Core_Electron_Temperature_Bar_Comparison_N_%s.fig', timestamp);
    savefig(fig_name);
    fprintf('Figure saved as: %s\n', fig_name);

    % -------- 统计信息 --------
    fprintf('\n========== Core Electron Temperature Statistics ==========\n');
    valid_values = core_te_values(~isnan(core_te_values));
    if ~isempty(valid_values)
        fprintf('Number of valid cases: %d\n', length(valid_values));
        fprintf('Mean core Te: %.2f eV\n', mean(valid_values));
        fprintf('Std core Te: %.2f eV\n', std(valid_values));
        fprintf('Min core Te: %.2f eV\n', min(valid_values));
        fprintf('Max core Te: %.2f eV\n', max(valid_values));
    else
        fprintf('No valid data for statistics.\n');
    end
    fprintf('=========================================================\n');

    % -------- 排序输出（按 Te 升序） --------
    if ~isempty(case_dirs)
        fprintf('\nSorting cases by core electron temperature (low to high)...\n');

        case_data = struct('temperature', num2cell(core_te_values), ...
                           'directory', case_dirs, ...
                           'case_name', case_names);

        [~, sort_idx] = sort([case_data.temperature]); % NaN 自动排到末尾
        sorted_case_data = case_data(sort_idx);

        output_filename = sprintf('Core_Te_Sorted_Cases_N_%s.txt', timestamp);
        fid = fopen(output_filename, 'w');
        if fid == -1
            fprintf('Error: Could not create output file %s\n', output_filename);
        else
            fprintf(fid, '%% Core Electron Temperature Sorted Cases (N impurity)\n');
            fprintf(fid, '%% Generated on: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
            fprintf(fid, '%% Sorted by core electron temperature (low to high)\n');
            fprintf(fid, '%% Format: [Temperature (eV)] Case_Name\n');
            fprintf(fid, '%%\n');

            for i = 1:length(sorted_case_data)
                if ~isnan(sorted_case_data(i).temperature)
                    fprintf(fid, '%% [%.2f eV] %s\n', sorted_case_data(i).temperature, sorted_case_data(i).case_name);
                    fprintf(fid, '%s\n', sorted_case_data(i).directory);
                end
            end

            fclose(fid);
            fprintf('Sorted case directories saved to: %s\n', output_filename);

            fprintf('\n========== Cases Sorted by Core Temperature ==========\n');
            for i = 1:length(sorted_case_data)
                if ~isnan(sorted_case_data(i).temperature)
                    fprintf('%2d. [%.2f eV] %s\n', i, sorted_case_data(i).temperature, sorted_case_data(i).case_name);
                end
            end
            fprintf('======================================================\n');
        end
    else
        fprintf('Warning: No valid data available for sorting.\n');
    end
end

% 辅助：在 all_radiationData 中查找目录索引
function idx = findDirIndexInRadiationData(all_radiationData, targetDir)
    idx = -1;
    for i = 1:length(all_radiationData)
        if isfield(all_radiationData{i}, 'dirName')
            if strcmp(all_radiationData{i}.dirName, targetDir)
                idx = i;
                return;
            end
        end
    end
end
