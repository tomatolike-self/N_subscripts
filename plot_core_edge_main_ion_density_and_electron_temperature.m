function plot_core_edge_main_ion_density_and_electron_temperature(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% PLOT_CORE_EDGE_MAIN_ION_DENSITY_AND_ELECTRON_TEMPERATURE 绘制芯部边缘主离子平均密度和电子温度平均分组柱状图
%
%   此函数计算并绘制：
%   1) 芯部边缘主离子平均密度（按体积加权）分组柱状图
%   2) 芯部边缘电子温度平均（按能量加权）分组柱状图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于 plot_Ne8_ionization_source_and_flux_statistics.m 修改
%     - 专门针对主离子密度和电子温度进行统计
%     - 使用分组柱状图显示不同算例的对比
%     - 支持MATLAB 2017b兼容性

    fprintf('\n=== Starting core edge main ion density and electron temperature analysis ===\n');
    
    % 检查输入参数
    if nargin < 4
        showLegendsForDirNames = true;
    end
    if nargin < 3
        usePresetLegends = false;
    end
    
    % 检查MATLAB版本兼容性
    isMATLAB2017b = verLessThan('matlab', '9.4'); % MATLAB 2018a对应版本9.4
    fontSize = 12;
    
    % 初始化存储数组
    all_dir_names = {};
    all_full_paths = {};
    all_main_ion_density_core_edge = [];
    all_electron_temperature_core_edge = [];
    
    valid_cases = 0;
    
    % 定义芯部边缘区域索引（与主脚本保持一致）
    core_indices = 26:73;
    
    %% ======================== 数据处理循环 ============================
    
    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;
        
        current_full_path = dirName;
        fprintf('Processing case for core edge analysis: %s\n', dirName);
        
        % 检查数据完整性
        can_process = true;
        if ~isfield(plasma, 'na') || ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            can_process = false;
        end
        
        if ~can_process
            continue;
        end
        
        % 获取网格尺寸
        [nx_orig, ny_orig] = size(gmtry.crx(:,:,1));
        
        % 检查索引有效性
        if ny_orig < 2 || max(core_indices) > nx_orig
            fprintf('Warning: Invalid grid indices for case %s. Skipping.\n', dirName);
            continue;
        end
        
        %% 计算主离子平均密度（体积加权）
        % 主离子为D+，对应plasma.na(:,:,2)
        nD_plus = plasma.na(:,:,2); % 主离子密度
        core_nD_plus = nD_plus(core_indices, 2); % 芯部边缘区域，第二列对应芯部位置
        core_vol = gmtry.vol(core_indices, 2); % 对应体积
        
        % 体积加权平均主离子密度
        core_nD_plus_vol_sum = sum(core_nD_plus .* core_vol, 'omitnan');
        core_vol_sum = sum(core_vol, 'omitnan');
        
        if core_vol_sum == 0 || isnan(core_vol_sum)
            main_ion_density_avg = NaN;
            fprintf('Warning: Core volume sum is zero or NaN for case %s.\n', dirName);
        else
            main_ion_density_avg = core_nD_plus_vol_sum / core_vol_sum;
        end
        
        %% 计算电子温度平均（能量加权）
        % 能量加权平均：<Te> = sum(ne * Te * vol) / sum(ne * vol)
        core_ne = plasma.ne(core_indices, 2); % 芯部边缘电子密度
        core_te = plasma.te_ev(core_indices, 2); % 芯部边缘电子温度（eV）
        
        % 能量加权平均电子温度
        numerator_te = sum(core_ne .* core_te .* core_vol, 'omitnan');
        denominator_te = sum(core_ne .* core_vol, 'omitnan');
        
        if denominator_te == 0 || isnan(denominator_te)
            electron_temperature_avg = NaN;
            fprintf('Warning: Electron density-volume sum is zero or NaN for case %s.\n', dirName);
        else
            electron_temperature_avg = numerator_te / denominator_te;
        end
        
        %% 存储结果
        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_main_ion_density_core_edge(end+1) = main_ion_density_avg;
        all_electron_temperature_core_edge(end+1) = electron_temperature_avg;
        
        fprintf('  Main ion density (volume-weighted): %.3e m^-3\n', main_ion_density_avg);
        fprintf('  Electron temperature (energy-weighted): %.2f eV\n', electron_temperature_avg);
    end
    
    fprintf('Successfully processed %d cases for core edge analysis.\n', valid_cases);
    
    %% ======================== 绘制分组柱状图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    group_colors_set = lines(max(num_groups, 1));
    
    %% 绘制主离子密度柱状图
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_main_ion_density_core_edge, ...
                          groupDirs, group_colors_set, ...
                          'Core Edge Main Ion Density (Volume-Weighted Average)', ...
                          'Main Ion Density ($\mathrm{m^{-3}}$)', ...
                          'CoreEdge_MainIon_Density_VolumeWeighted', fontSize, isMATLAB2017b, ...
                          usePresetLegends, showLegendsForDirNames);
    
    %% 绘制电子温度柱状图
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_electron_temperature_core_edge, ...
                          groupDirs, group_colors_set, ...
                          'Core Edge Electron Temperature (Energy-Weighted Average)', ...
                          'Electron Temperature ($\mathrm{eV}$)', ...
                          'CoreEdge_Electron_Temperature_EnergyWeighted', fontSize, isMATLAB2017b, ...
                          usePresetLegends, showLegendsForDirNames);

    %% 绘制组合对比图
    plot_combined_comparison_chart(all_dir_names, all_full_paths, ...
                                  all_main_ion_density_core_edge, all_electron_temperature_core_edge, ...
                                  groupDirs, group_colors_set, fontSize, isMATLAB2017b, ...
                                  usePresetLegends, showLegendsForDirNames);

    fprintf('\n=== Core edge main ion density and electron temperature analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
                                fig_title, ylabel_text, save_name, fontSize, isMATLAB2017b, ...
                                usePresetLegends, showLegendsForDirNames)
    
    % 创建图窗
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 14, 7]);
    
    % 设置LaTeX解释器
    if ~isMATLAB2017b
        set(fig, 'DefaultTextInterpreter', 'latex', ...
                 'DefaultAxesTickLabelInterpreter', 'latex', ...
                 'DefaultLegendInterpreter', 'latex');
    end
    
    % 准备数据
    num_cases = length(dir_names);
    num_groups = length(groupDirs);
    
    if num_cases == 0
        fprintf('Warning: No valid data to plot for %s.\n', fig_title);
        close(fig);
        return;
    end
    
    % 为每个案例分配颜色
    bar_colors = zeros(num_cases, 3);
    group_assignments = zeros(num_cases, 1);
    
    for i_data = 1:num_cases
        current_full_path = full_paths{i_data};
        
        % 查找当前案例属于哪个组
        group_index = -1;
        for i_group = 1:num_groups
            current_group_dirs = groupDirs{i_group};
            for j = 1:length(current_group_dirs)
                if contains(current_full_path, current_group_dirs{j})
                    group_index = i_group;
                    break;
                end
            end
            if group_index > 0
                break;
            end
        end
        
        % 分配颜色
        if group_index > 0
            bar_colors(i_data, :) = group_colors_set(group_index, :);
            group_assignments(i_data) = group_index;
        else
            bar_colors(i_data, :) = [0.5, 0.5, 0.5]; % 灰色表示未分组
            group_assignments(i_data) = 0;
        end
    end
    
    % 创建坐标轴
    ax = axes(fig);
    hold(ax, 'on');
    set(ax, 'FontSize', fontSize*0.9);
    
    % 绘制柱状图
    if ~isempty(data_values) && ~all(isnan(data_values))
        bh = bar(ax, 1:num_cases, data_values, 'FaceColor', 'flat');
        bh.CData = bar_colors;
        
        % 设置x轴
        xticks(ax, 1:num_cases);
        xticklabels(ax, {});  % 不显示x轴标签以避免重叠
        xtickangle(ax, 45);
        set(ax, 'TickLabelInterpreter', 'none');
        
        % 设置标签和标题
        xlabel(ax, 'Simulation Case');
        if isMATLAB2017b
            ylabel(ax, strrep(ylabel_text, '$', ''), 'FontSize', fontSize);
            title(ax, fig_title, 'FontSize', fontSize+2);
        else
            ylabel(ax, ylabel_text, 'FontSize', fontSize);
            title(ax, fig_title, 'FontSize', fontSize+2);
        end
        
        % 设置网格和坐标轴属性
        grid(ax, 'on');
        box(ax, 'on');
        set(ax, 'TickDir', 'in');
        
        % 添加图例（如果需要）
        if showLegendsForDirNames && num_groups > 1
            legend_entries = {};
            legend_colors = [];
            
            if usePresetLegends
                % 使用预设图例名称
                preset_names = {'favorable B_T', 'unfavorable B_T', 'w/o drift'};
                for i_group = 1:min(num_groups, length(preset_names))
                    legend_entries{end+1} = preset_names{i_group};
                    legend_colors(end+1, :) = group_colors_set(i_group, :);
                end
            else
                % 使用组目录名称作为图例
                for i_group = 1:num_groups
                    if any(group_assignments == i_group)
                        % 简化组名显示
                        group_name = sprintf('Group %d', i_group);
                        legend_entries{end+1} = group_name;
                        legend_colors(end+1, :) = group_colors_set(i_group, :);
                    end
                end
            end
            
            % 创建图例
            if ~isempty(legend_entries)
                legend_handles = [];
                for i = 1:length(legend_entries)
                    legend_handles(end+1) = patch(ax, 'XData', NaN, 'YData', NaN, ...
                                                 'FaceColor', legend_colors(i, :), ...
                                                 'EdgeColor', 'k', 'LineWidth', 0.5);
                end
                
                if isMATLAB2017b
                    legend(ax, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2);
                else
                    legend(ax, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2, 'Interpreter', 'latex');
                end
            end
        end
    else
        text(ax, 0.5, 0.5, 'No valid data to display', 'Units', 'normalized', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
             'FontSize', fontSize, 'Color', 'red');
    end
    
    hold(ax, 'off');
    
    % 保存图形
    saveFigureWithTimestamp(save_name);
end

%% =========================================================================
%% 内部函数：绘制组合对比图
%% =========================================================================
function plot_combined_comparison_chart(dir_names, full_paths, main_ion_data, electron_temp_data, ...
                                       groupDirs, group_colors_set, fontSize, isMATLAB2017b, ...
                                       usePresetLegends, showLegendsForDirNames)

    % 创建图窗
    fig_title = 'Core Edge Main Ion Density vs Electron Temperature (Combined Comparison)';
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 16, 8]);

    % 设置LaTeX解释器
    if ~isMATLAB2017b
        set(fig, 'DefaultTextInterpreter', 'latex', ...
                 'DefaultAxesTickLabelInterpreter', 'latex', ...
                 'DefaultLegendInterpreter', 'latex');
    end

    % 准备数据
    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    if num_cases == 0
        fprintf('Warning: No valid data to plot for combined comparison.\n');
        close(fig);
        return;
    end

    % 定义暖色系和冷色系颜色
    warm_colors = [
        0.8, 0.2, 0.2;  % 红色
        1.0, 0.5, 0.0;  % 橙色
        0.9, 0.7, 0.1;  % 黄色
        0.8, 0.4, 0.6;  % 粉红色
        0.7, 0.3, 0.0;  % 棕色
        0.9, 0.6, 0.2;  % 橙黄色
        0.8, 0.1, 0.4;  % 深红色
        1.0, 0.7, 0.3   % 浅橙色
    ];

    cool_colors = [
        0.2, 0.4, 0.8;  % 蓝色
        0.0, 0.6, 0.6;  % 青色
        0.3, 0.7, 0.3;  % 绿色
        0.4, 0.2, 0.8;  % 紫色
        0.1, 0.5, 0.7;  % 深蓝色
        0.2, 0.8, 0.5;  % 青绿色
        0.5, 0.3, 0.9;  % 蓝紫色
        0.0, 0.4, 0.5   % 深青色
    ];

    % 准备分组颜色
    bar_colors_density = zeros(num_cases, 3);
    bar_colors_temp = zeros(num_cases, 3);
    group_assignments = zeros(num_cases, 1);

    % 为每个案例分配颜色
    for i_data = 1:num_cases
        current_full_path = full_paths{i_data};

        % 查找当前案例属于哪个组
        group_index = -1;
        for i_group = 1:num_groups
            current_group_dirs = groupDirs{i_group};
            for j = 1:length(current_group_dirs)
                if contains(current_full_path, current_group_dirs{j})
                    group_index = i_group;
                    break;
                end
            end
            if group_index > 0
                break;
            end
        end

        % 分配颜色 - 密度用暖色系，温度用冷色系
        if group_index > 0
            color_idx = mod(group_index - 1, size(warm_colors, 1)) + 1;
            bar_colors_density(i_data, :) = warm_colors(color_idx, :);  % 暖色系
            bar_colors_temp(i_data, :) = cool_colors(color_idx, :);     % 冷色系
            group_assignments(i_data) = group_index;
        else
            bar_colors_density(i_data, :) = [0.6, 0.3, 0.3];  % 暖灰色表示未分组
            bar_colors_temp(i_data, :) = [0.3, 0.3, 0.6];     % 冷灰色表示未分组
            group_assignments(i_data) = 0;
        end
    end

    % 创建双y轴图
    yyaxis left
    ax_left = gca;

    % 绘制主离子密度柱状图
    bar_density = bar(ax_left, 1:num_cases, main_ion_data, 0.4, 'FaceColor', 'flat');
    bar_density.CData = bar_colors_density;

    % 设置左y轴
    if isMATLAB2017b
        ylabel(ax_left, 'Main Ion Density (m^{-3})', 'FontSize', fontSize, 'Color', 'b');
    else
        ylabel(ax_left, 'Main Ion Density ($\mathrm{m^{-3}}$)', 'FontSize', fontSize, 'Color', 'b');
    end
    ax_left.YColor = 'b';

    yyaxis right
    ax_right = gca;

    % 绘制电子温度柱状图（稍微偏移位置）
    bar_temp = bar(ax_right, (1:num_cases) + 0.4, electron_temp_data, 0.4, 'FaceColor', 'flat');
    bar_temp.CData = bar_colors_temp;

    % 设置右y轴
    if isMATLAB2017b
        ylabel(ax_right, 'Electron Temperature (eV)', 'FontSize', fontSize, 'Color', 'r');
    else
        ylabel(ax_right, 'Electron Temperature ($\mathrm{eV}$)', 'FontSize', fontSize, 'Color', 'r');
    end
    ax_right.YColor = 'r';

    % 设置x轴
    xticks(ax_right, 1:num_cases);

    % 简化案例名称用于x轴标签
    x_labels = {};
    for i = 1:num_cases
        case_name = dir_names{i};
        if length(case_name) > 15
            case_name = [case_name(1:12), '...'];
        end
        x_labels{end+1} = case_name;
    end

    xticklabels(ax_right, x_labels);
    xtickangle(ax_right, 45);
    set(ax_right, 'TickLabelInterpreter', 'none');

    % 设置标签和标题
    xlabel(ax_right, 'Simulation Cases');

    if isMATLAB2017b
        title(ax_right, 'Core Edge Main Ion Density vs Electron Temperature', 'FontSize', fontSize+2);
    else
        title(ax_right, 'Core Edge Main Ion Density vs Electron Temperature', 'FontSize', fontSize+2, 'Interpreter', 'latex');
    end

    % 设置网格和坐标轴属性
    grid(ax_right, 'on');
    box(ax_right, 'on');
    set(ax_right, 'TickDir', 'in');

    % 添加图例（如果需要）
    if showLegendsForDirNames && num_groups > 1
        legend_entries = {};
        legend_colors = [];

        % 添加数据类型图例 - 暖色系 vs 冷色系
        legend_entries{end+1} = 'Main Ion Density (Warm Colors)';
        legend_entries{end+1} = 'Electron Temperature (Cool Colors)';
        legend_colors(end+1, :) = [0.8, 0.3, 0.2];  % 暖色代表
        legend_colors(end+1, :) = [0.2, 0.4, 0.8];  % 冷色代表

        if usePresetLegends
            % 使用预设图例名称
            preset_names = {'favorable B_T', 'unfavorable B_T', 'w/o drift'};
            for i_group = 1:min(num_groups, length(preset_names))
                color_idx = mod(i_group - 1, size(warm_colors, 1)) + 1;
                legend_entries{end+1} = [preset_names{i_group}, ' (Density)'];
                legend_entries{end+1} = [preset_names{i_group}, ' (Temperature)'];
                legend_colors(end+1, :) = warm_colors(color_idx, :);
                legend_colors(end+1, :) = cool_colors(color_idx, :);
            end
        else
            % 使用组目录名称作为图例
            for i_group = 1:num_groups
                if any(group_assignments == i_group)
                    color_idx = mod(i_group - 1, size(warm_colors, 1)) + 1;
                    group_name = sprintf('Group %d', i_group);
                    legend_entries{end+1} = [group_name, ' (Density)'];
                    legend_entries{end+1} = [group_name, ' (Temperature)'];
                    legend_colors(end+1, :) = warm_colors(color_idx, :);
                    legend_colors(end+1, :) = cool_colors(color_idx, :);
                end
            end
        end

        % 创建图例
        if ~isempty(legend_entries)
            legend_handles = [];
            for i = 1:length(legend_entries)
                legend_handles(end+1) = patch(ax_right, 'XData', NaN, 'YData', NaN, ...
                                             'FaceColor', legend_colors(i, :), ...
                                             'EdgeColor', 'k', 'LineWidth', 0.5);
            end

            if isMATLAB2017b
                legend(ax_right, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2);
            else
                legend(ax_right, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2, 'Interpreter', 'latex');
            end
        end
    else
        % 即使不显示分组图例，也显示数据类型区分
        legend_entries = {'Main Ion Density (Warm Colors)', 'Electron Temperature (Cool Colors)'};
        legend_colors = [[0.8, 0.3, 0.2]; [0.2, 0.4, 0.8]];

        legend_handles = [];
        for i = 1:length(legend_entries)
            legend_handles(end+1) = patch(ax_right, 'XData', NaN, 'YData', NaN, ...
                                         'FaceColor', legend_colors(i, :), ...
                                         'EdgeColor', 'k', 'LineWidth', 0.5);
        end

        if isMATLAB2017b
            legend(ax_right, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2);
        else
            legend(ax_right, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2, 'Interpreter', 'latex');
        end
    end

    % 保存图形
    saveFigureWithTimestamp('CoreEdge_MainIon_Density_vs_Electron_Temperature_Combined');
end

%% =========================================================================
%% 内部函数：保存图形并添加时间戳
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 获取当前时间戳
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % 构建文件名
    fileName = sprintf('%s_%s', baseName, timestamp);

    % 保存为FIG格式（MATLAB格式）
    try
        savefig(gcf, [fileName, '.fig']);
        fprintf('Figure saved as: %s.fig\n', fileName);
    catch ME
        fprintf('Warning: Failed to save figure as FIG: %s\n', ME.message);
    end
end
