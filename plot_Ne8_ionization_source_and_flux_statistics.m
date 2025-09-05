function plot_Ne8_ionization_source_and_flux_statistics(all_radiationData, groupDirs)
% PLOT_NE8_IONIZATION_SOURCE_AND_FLUX_STATISTICS 绘制Ne8+电离源和通量统计图
%
%   此函数计算并绘制：
%   1) Ne8+在分离面内的电离源强度总和分组柱状图
%   2) Ne8+离子流流过分离面的flux总和统计分组柱状图
%   3) Ne8+在芯部边缘（径向网格数2）的离子密度体积加权平均值分组柱状图
%   4) Ne8+电离源和通量组合对比图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%
%   依赖函数:
%     - compute_Ne_ionSource_for_charge_state_local (内部函数)
%     - plot_grouped_bar_chart (内部函数)
%     - plot_combined_comparison_chart (内部函数)
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于 plot_separatrix_flux_comparison_grouped.m 修改
%     - 专门针对Ne8+价态进行电离源和通量统计
%     - 新增Ne8+芯部边缘密度体积加权平均值计算和绘制
%     - 使用分组柱状图显示不同算例的对比
%     - 支持MATLAB 2017b兼容性
%     - 设置Y轴为规范的科学计数法格式

    fprintf('\n=== Starting Ne8+ ionization source and flux statistics analysis ===\n');
    
    %% ========================== 全局参数设置 ================================
    fontSize = 14;          % 统一字体大小
    chargeState = 8;        % 专门针对Ne8+
    
    %% ======================== 数据收集和计算 ============================
    all_dir_names = {};
    all_full_paths = {};
    all_Ne8_ion_sources_inside_sep = [];  % Ne8+分离面内电离源
    all_Ne8_flux_through_sep = [];        % Ne8+流过分离面的通量
    all_Ne8_core_edge_density = [];       % Ne8+芯部边缘密度体积加权平均值
    valid_cases = 0;
    
    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;
        
        current_full_path = dirName;
        fprintf('Processing case for Ne8+ statistics: %s\n', dirName);
        
        % 检查数据完整性
        can_process = true;
        if ~isfield(plasma, 'fna_mdf') || ~isfield(plasma, 'sna') || ~isfield(plasma, 'na') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            can_process = false;
        end
        
        if ~can_process
            continue;
        end
        
        % 获取网格信息
        [nx_orig, ny_orig] = size(gmtry.crx);
        nx_plot = nx_orig - 2;
        
        % 定义分离面位置 (径向索引14，对应plot网格的13)
        iy_sep_data = 14; % 分离面在原始网格中的径向索引
        
        % 检查分离面索引是否有效
        if iy_sep_data > ny_orig
            fprintf('Warning: Separatrix index (%d) exceeds grid size (%d) for case %s. Skipping.\n', iy_sep_data, ny_orig, dirName);
            continue;
        end
        
        %% 计算Ne8+分离面内电离源
        Ne8_ion_source_inside_sep = 0;
        
        % 定义积分区域 (与其他脚本保持一致)
        radial_indices = 2:13;  % 分离面内侧径向范围
        poloidal_plot_start_ix = 25;
        poloidal_plot_end_ix = 72;
        actual_poloidal_plot_start = max(1, poloidal_plot_start_ix);
        actual_poloidal_plot_end = min(nx_plot, poloidal_plot_end_ix);
        
        poloidal_indices = [];
        if actual_poloidal_plot_start <= actual_poloidal_plot_end
            poloidal_indices = (actual_poloidal_plot_start:actual_poloidal_plot_end) + 1;
        end
        
        if ~isempty(poloidal_indices) && ny_orig >= max(radial_indices)
            % 计算Ne8+电离源分布
            ionSource2D_Ne8 = compute_Ne_ionSource_for_charge_state_local(plasma, gmtry, chargeState);
            
            % 将电离源密度(m-3s-1)乘以单元体积(m3)得到粒子数(s-1)
            ion_source_particles_2d = ionSource2D_Ne8 .* gmtry.vol;
            
            % 对指定区域内的粒子源进行求和
            Ne8_ion_source_inside_sep = sum(ion_source_particles_2d(poloidal_indices, radial_indices), 'all', 'omitnan');
        else
            Ne8_ion_source_inside_sep = NaN;
            fprintf('Warning: Invalid grid indices for ionization source calculation in case %s.\n', dirName);
        end
        
        %% 计算Ne8+流过分离面的通量
        Ne8_flux_through_sep = 0;

        % Ne8+对应的物种索引 (3 + chargeState = 11)
        iComp_Ne8 = 3 + chargeState;

        % 检查物种索引是否有效
        if size(plasma.fna_mdf, 4) >= iComp_Ne8
            % fna_mdf(ix,iy,direction,species), direction: 2=radial
            % 计算Ne8+在分离面处的径向通量
            fna_rad_sep_Ne8 = plasma.fna_mdf(:, iy_sep_data, 2, iComp_Ne8); % (nx_orig, 1)

            % 对主SOL区域求和
            if ~isempty(poloidal_indices) && length(fna_rad_sep_Ne8) >= max(poloidal_indices)
                Ne8_flux_through_sep = sum(fna_rad_sep_Ne8(poloidal_indices), 'omitnan');
            else
                Ne8_flux_through_sep = NaN;
                fprintf('Warning: Invalid poloidal indices for flux calculation in case %s.\n', dirName);
            end
        else
            Ne8_flux_through_sep = NaN;
            fprintf('Warning: Ne8+ species index (%d) exceeds available species (%d) for case %s.\n', iComp_Ne8, size(plasma.fna_mdf, 4), dirName);
        end

        %% 计算Ne8+芯部边缘密度体积加权平均值
        Ne8_core_edge_density = NaN;

        % 芯部边缘位置：径向网格数2
        iy_core_edge = 2;

        % 检查径向索引是否有效
        if iy_core_edge <= ny_orig && size(plasma.na, 3) >= iComp_Ne8
            % 获取Ne8+在芯部边缘位置的密度分布
            Ne8_density_core_edge = plasma.na(:, iy_core_edge, iComp_Ne8); % (nx_orig, 1)

            % 获取对应位置的体积
            volume_core_edge = gmtry.vol(:, iy_core_edge); % (nx_orig, 1)

            % 计算体积加权平均密度
            if ~isempty(poloidal_indices) && length(Ne8_density_core_edge) >= max(poloidal_indices)
                % 提取主要区域的密度和体积
                density_region = Ne8_density_core_edge(poloidal_indices);
                volume_region = volume_core_edge(poloidal_indices);

                % 去除NaN值
                valid_mask = ~isnan(density_region) & ~isnan(volume_region) & volume_region > 0;

                if any(valid_mask)
                    density_valid = density_region(valid_mask);
                    volume_valid = volume_region(valid_mask);

                    % 体积加权平均：sum(density * volume) / sum(volume)
                    Ne8_core_edge_density = sum(density_valid .* volume_valid) / sum(volume_valid);
                else
                    Ne8_core_edge_density = NaN;
                    fprintf('Warning: No valid density/volume data for core-edge calculation in case %s.\n', dirName);
                end
            else
                Ne8_core_edge_density = NaN;
                fprintf('Warning: Invalid poloidal indices for core-edge density calculation in case %s.\n', dirName);
            end
        else
            Ne8_core_edge_density = NaN;
            fprintf('Warning: Core-edge index (%d) exceeds grid size (%d) or species index invalid for case %s.\n', iy_core_edge, ny_orig, dirName);
        end
        
        % 存储结果
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_Ne8_ion_sources_inside_sep(end+1) = Ne8_ion_source_inside_sep;
        all_Ne8_flux_through_sep(end+1) = Ne8_flux_through_sep;
        all_Ne8_core_edge_density(end+1) = Ne8_core_edge_density;
        valid_cases = valid_cases + 1;

        fprintf('  Ne8+ ionization source inside separatrix: %.4e particles/s\n', Ne8_ion_source_inside_sep);
        fprintf('  Ne8+ flux through separatrix: %.4e particles/s\n', Ne8_flux_through_sep);
        fprintf('  Ne8+ core-edge density (volume-weighted): %.4e m^-3\n', Ne8_core_edge_density);
    end
    
    if valid_cases == 0
        fprintf('No valid cases found for Ne8+ statistics. Exiting.\n');
        return;
    end
    
    fprintf('Successfully processed %d cases for Ne8+ statistics.\n', valid_cases);
    
    %% ======================== 绘制分组柱状图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    group_colors_set = lines(max(num_groups, 1));
    
    %% 绘制Ne8+分离面内电离源柱状图
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_Ne8_ion_sources_inside_sep, ...
                          groupDirs, group_colors_set, ...
                          'Ne8+ Ionization Source Inside Separatrix (Grouped)', ...
                          'Ne8+ Ionization Source Inside Separatrix ($\mathrm{particles \cdot s^{-1}}$)', ...
                          'Ne8plus_IonSource_InsideSep_Grouped', fontSize, []);

    %% 绘制Ne8+流过分离面通量柱状图
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_Ne8_flux_through_sep, ...
                          groupDirs, group_colors_set, ...
                          'Ne8+ Flux Through Separatrix (Grouped)', ...
                          'Ne8+ Flux Through Separatrix ($\mathrm{particles \cdot s^{-1}}$)', ...
                          'Ne8plus_Flux_ThroughSep_Grouped', fontSize, []);

    %% 绘制Ne8+芯部边缘密度体积加权平均值柱状图
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_Ne8_core_edge_density, ...
                          groupDirs, group_colors_set, ...
                          'Ne8+ Core-Edge Density (Volume-Weighted Average)', ...
                          'Ne8+ Core-Edge Density ($\mathrm{m^{-3}}$)', ...
                          'Ne8plus_CoreEdge_Density_Grouped', fontSize, [0, 7e17]);

    %% 绘制Ne8+电离源和通量组合对比图
    plot_combined_comparison_chart(all_dir_names, all_full_paths, ...
                                  all_Ne8_ion_sources_inside_sep, all_Ne8_flux_through_sep, ...
                                  groupDirs, group_colors_set, fontSize);

    fprintf('\n=== Ne8+ ionization source and flux statistics analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
                                fig_title, ylabel_text, save_name, fontSize, y_axis_range)
    
    % 创建图窗
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 14, 7]);
    
    % 设置LaTeX解释器
    set(fig, 'DefaultTextInterpreter', 'latex', ...
             'DefaultAxesTickLabelInterpreter', 'latex', ...
             'DefaultLegendInterpreter', 'latex');
    
    ax = axes(fig);
    hold(ax, 'on');
    set(ax, 'FontSize', fontSize*0.9);
    
    num_cases = length(dir_names);
    num_groups = length(groupDirs);
    
    % 准备颜色和图例
    bar_colors = zeros(num_cases, 3);
    legend_handles = [];
    legend_strings = {};
    unique_groups_plotted = containers.Map('KeyType','double','ValueType','logical');
    
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
        
        % 分配颜色
        if group_index > 0
            bar_colors(i_data, :) = group_colors_set(group_index, :);
        else
            bar_colors(i_data, :) = [0.5, 0.5, 0.5]; % 灰色表示未分组
            group_index = 0;
        end
        
        % 添加图例条目（每组只添加一次）
        if group_index > 0 && ~isKey(unique_groups_plotted, group_index)
            unique_groups_plotted(group_index) = true;
            dummy_handle = plot(ax, NaN, NaN, 's', 'Color', group_colors_set(group_index, :), ...
                               'MarkerFaceColor', group_colors_set(group_index, :), 'MarkerSize', 10);
            legend_handles(end+1) = dummy_handle;
            legend_strings{end+1} = sprintf('Group %d', group_index);
        end
    end
    
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
        ylabel(ax, ylabel_text, 'FontSize', fontSize);
        title(ax, fig_title, 'FontSize', fontSize+2);
        
        grid(ax, 'on');
        box(ax, 'on');
        set(ax, 'TickDir', 'in');
        
        % 添加图例
        if ~isempty(legend_handles)
            legend(legend_handles, legend_strings, 'Location', 'best', 'Interpreter', 'latex');
        end
        
        % 设置Y轴范围（如果指定）
        if ~isempty(y_axis_range) && length(y_axis_range) == 2
            ylim(ax, y_axis_range);
        end
        
    else
        text(ax, 0.5, 0.5, 'No valid data to plot', 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Units', 'normalized', 'FontSize', fontSize);
    end
    
    hold(ax, 'off');

    % 在所有绘制完成后设置y轴为MATLAB默认的科学计数法格式
    format_matlab_style_scientific_notation(ax);

    % 保存图形
    saveFigureWithTimestamp(save_name);
end

%% =========================================================================
%% 内部函数：绘制Ne8+电离源和通量组合对比图
%% =========================================================================
function plot_combined_comparison_chart(dir_names, full_paths, ion_source_data, flux_data, ...
                                       groupDirs, group_colors_set, fontSize)

    % 创建图窗
    fig_title = 'Ne8+ Ionization Source vs Flux Through Separatrix (Combined Comparison)';
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 16, 8]);

    % 设置LaTeX解释器
    set(fig, 'DefaultTextInterpreter', 'latex', ...
             'DefaultAxesTickLabelInterpreter', 'latex', ...
             'DefaultLegendInterpreter', 'latex');

    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    % 检查数据有效性
    if isempty(ion_source_data) || isempty(flux_data) || all(isnan(ion_source_data)) || all(isnan(flux_data))
        ax = axes(fig);
        text(ax, 0.5, 0.5, 'No valid data to plot', 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Units', 'normalized', 'FontSize', fontSize);
        saveFigureWithTimestamp('Ne8plus_Combined_Comparison');
        return;
    end

    % 使用固定Y轴范围，以便更好地显示数据
    y_axis_max = 8e20;  % 固定Y轴最大值为8e20

    % 保留原始数据
    ion_source_plot_data = ion_source_data;
    flux_plot_data = flux_data;

    % 记录原始最大值用于信息显示
    ion_source_max = max(abs(ion_source_data(~isnan(ion_source_data))));
    flux_max = max(abs(flux_data(~isnan(flux_data))));

    if ion_source_max == 0, ion_source_max = 1; end
    if flux_max == 0, flux_max = 1; end

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
    bar_colors_ion = zeros(num_cases, 3);
    bar_colors_flux = zeros(num_cases, 3);

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

        % 分配颜色 - 电离源用暖色系，通量用冷色系
        if group_index > 0
            color_idx = mod(group_index - 1, size(warm_colors, 1)) + 1;
            bar_colors_ion(i_data, :) = warm_colors(color_idx, :);    % 暖色系
            bar_colors_flux(i_data, :) = cool_colors(color_idx, :);   % 冷色系
        else
            bar_colors_ion(i_data, :) = [0.6, 0.3, 0.3];  % 暖灰色表示未分组
            bar_colors_flux(i_data, :) = [0.3, 0.3, 0.6]; % 冷灰色表示未分组
        end
    end

    % 创建坐标轴
    ax = axes(fig);
    hold(ax, 'on');
    set(ax, 'FontSize', fontSize*0.9);

    % 准备x轴位置 - 每个case占用2个位置，中间留间隔
    x_positions = [];
    x_labels = {};
    x_tick_positions = [];

    for i = 1:num_cases
        base_pos = (i-1) * 3 + 1; % 每组间隔3个单位
        x_positions = [x_positions, base_pos, base_pos + 0.8]; % 电离源和通量的位置
        x_tick_positions = [x_tick_positions, base_pos + 0.4]; % 标签位置在中间

        % 简化案例名称用于x轴标签
        case_name = dir_names{i};
        if length(case_name) > 15
            case_name = [case_name(1:12), '...'];
        end
        x_labels{end+1} = case_name;
    end

    % 绘制柱状图
    bar_width = 0.35;

    % 电离源柱状图 - 实心填充
    for i = 1:num_cases
        if ~isnan(ion_source_data(i))
            bh_ion = bar(ax, x_positions(2*i-1), ion_source_data(i), bar_width, ...
                        'FaceColor', bar_colors_ion(i, :), 'EdgeColor', 'k', 'LineWidth', 1.0);
        end
    end

    % 通量柱状图 - 冷色系实心填充
    for i = 1:num_cases
        if ~isnan(flux_data(i))
            bh_flux = bar(ax, x_positions(2*i), flux_data(i), bar_width, ...
                         'FaceColor', bar_colors_flux(i, :), 'EdgeColor', 'k', 'LineWidth', 1.0);
        end
    end

    % 设置x轴
    xticks(ax, x_tick_positions);
    xticklabels(ax, x_labels);
    xtickangle(ax, 45);
    set(ax, 'TickLabelInterpreter', 'none');

    % 设置标签和标题
    xlabel(ax, 'Simulation Cases');
    ylabel(ax, 'Ne8+ Values ($\mathrm{particles \cdot s^{-1}}$)', 'FontSize', fontSize);
    title(ax, 'Ne8+ Ionization Source vs Flux Through Separatrix', 'FontSize', fontSize+2, 'Interpreter', 'latex');

    % 创建图例
    legend_handles = [];
    legend_strings = {};

    % 添加数据类型图例 - 暖色系 vs 冷色系
    dummy_ion = bar(ax, NaN, NaN, 'FaceColor', [0.8, 0.3, 0.2], 'EdgeColor', 'k', 'LineWidth', 1.0);  % 暖色代表
    dummy_flux = bar(ax, NaN, NaN, 'FaceColor', [0.2, 0.4, 0.8], 'EdgeColor', 'k', 'LineWidth', 1.0); % 冷色代表
    legend_handles = [legend_handles, dummy_ion, dummy_flux];
    legend_strings = [legend_strings, {'Ionization Source (Warm Colors)', 'Flux Through Sep (Cool Colors)'}];

    % 添加分组说明（简化版本）
    if num_groups > 1
        % 添加分组说明文本
        text(ax, 0.02, 0.98, sprintf('Groups 1-%d: Different color pairs (warm/cool)', num_groups), ...
             'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
             'FontSize', fontSize-2, 'BackgroundColor', 'white', 'EdgeColor', [0.5, 0.5, 0.5], 'Margin', 3);
    end

    % 显示图例
    if ~isempty(legend_handles)
        legend(legend_handles, legend_strings, 'Location', 'best', 'NumColumns', 2, 'Interpreter', 'latex');
    end

    % 添加数据信息文本框
    info_text = {
        sprintf('Ion Source Max: %.2e particles/s', ion_source_max);
        sprintf('Flux Max: %.2e particles/s', flux_max);
        sprintf('Y-axis range: 0 - %.1e particles/s', y_axis_max)
    };

    % 在图的右上角添加信息文本
    text(ax, 0.98, 0.98, info_text, 'Units', 'normalized', ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
         'FontSize', fontSize-2, 'BackgroundColor', 'white', ...
         'EdgeColor', 'black', 'Margin', 5);

    % 设置网格和坐标轴属性
    grid(ax, 'on');
    box(ax, 'on');
    set(ax, 'TickDir', 'in');

    % 设置固定的y轴范围
    ylim(ax, [0, y_axis_max]);

    hold(ax, 'off');

    % 在所有绘制完成后设置y轴为MATLAB默认的科学计数法格式
    format_matlab_style_scientific_notation(ax);

    % 保存图形
    saveFigureWithTimestamp('Ne8plus_Combined_Comparison');
end

%% =========================================================================
%% 内部函数：计算Ne指定价态的电离源分布
%% =========================================================================
function ionSource2D_Ne_ion = compute_Ne_ionSource_for_charge_state_local(plasma_tmp, gmtry_tmp, chargeState)
    % 说明：
    %   - 此函数计算指定Ne价态的电离源分布
    %   - 电离源计算基于等离子体源项(sna)和密度(na)数据

    [nx, ny, ~] = size(gmtry_tmp.crx);
    ionSource2D_Ne_ion = zeros(nx, ny);

    % 确定对应Ne Z+的组分索引 (iComp_Ne_ion)
    % 假设：杂质的第一个电离态(如Ne1+)在EIRENE输出中通常是species_idx=4 (紧随 D0, D+, e-)
    % 因此 Ne(Z)+ 对应索引 3 + Z
    iComp_Ne_ion = 3 + chargeState;

    % 检查计算出的 species index 是否在有效范围内
    valid_species_index = true;
    if ~(isfield(plasma_tmp, 'sna') && ndims(plasma_tmp.sna) >= 4 && iComp_Ne_ion <= size(plasma_tmp.sna, 4))
        valid_species_index = false;
    end
    if ~(isfield(plasma_tmp, 'na') && ndims(plasma_tmp.na) >= 3 && iComp_Ne_ion <= size(plasma_tmp.na, 3))
        valid_species_index = false;
    end

    if ~valid_species_index
        % 如果索引无效，返回零源
        return;
    end

    for jPos = 1 : ny
        for iPos = 1 : nx
            % ----- Ne Z+ 电离源计算 -----
            sVal_Ne_ion = 0;
            if iComp_Ne_ion <= size(plasma_tmp.sna, 4) && iComp_Ne_ion <= size(plasma_tmp.na, 3)
                coeff0_Ne_ion = plasma_tmp.sna(iPos, jPos, 1, iComp_Ne_ion);
                coeff1_Ne_ion = plasma_tmp.sna(iPos, jPos, 2, iComp_Ne_ion);
                n_Ne_ion      = plasma_tmp.na(iPos, jPos, iComp_Ne_ion);
                sVal_Ne_ion   = coeff0_Ne_ion + coeff1_Ne_ion * n_Ne_ion;
            end

            % 单元体积归一化，并检查vol字段和值的有效性
            if isfield(gmtry_tmp, 'vol') && ...
               iPos <= size(gmtry_tmp.vol,1) && jPos <= size(gmtry_tmp.vol,2) && ...
               gmtry_tmp.vol(iPos, jPos) > 0
                ionSource2D_Ne_ion(iPos, jPos) = sVal_Ne_ion / gmtry_tmp.vol(iPos, jPos);
            else
                ionSource2D_Ne_ion(iPos, jPos) = 0; % 如果体积无效或为零，则源为零
            end
        end
    end
end

%% =========================================================================
%% 内部函数：带时间戳保存图窗
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 说明：
    %   - 保存为.fig格式，文件名包含生成时间戳
    %   - 自动调整窗口尺寸避免裁剪

    % 确保图窗尺寸适合学术出版要求
    set(gcf,'Units','pixels','Position',[100 50 1600 1200]);
    set(gcf,'PaperPositionMode','auto');

    % 生成时间戳
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');

    % 保存.fig格式(用于后续编辑)
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(figFile);
    fprintf('MATLAB图形文件已保存: %s\n', figFile);
end

%% =========================================================================
%% 内部函数：MATLAB默认样式的科学计数法格式化
%% =========================================================================
function format_matlab_style_scientific_notation(ax)
    % 说明：
    %   - 使用最简单的方法实现MATLAB默认的科学计数法显示
    %   - 让MATLAB自动处理科学计数法，然后在Y轴上方添加指数标注

    try
        % 强制刷新坐标轴
        drawnow;
        pause(0.1);

        % 获取当前Y轴范围
        ylim_current = get(ax, 'YLim');
        y_max = ylim_current(2);

        % 如果最大值小于1000，使用MATLAB默认格式
        if y_max < 1000
            set(ax, 'TickLabelInterpreter', 'latex');
            return;
        end

        % 让MATLAB自动生成科学计数法格式
        % 这会在Y轴上方自动显示指数
        set(ax, 'YTickMode', 'auto');
        set(ax, 'YTickLabelMode', 'auto');

        % 强制使用科学计数法
        ax.YAxis.Exponent = floor(log10(y_max));

        % 设置LaTeX解释器
        set(ax, 'TickLabelInterpreter', 'latex');

        fprintf('Applied MATLAB default scientific notation with exponent = %d\n', ax.YAxis.Exponent);

    catch ME
        fprintf('Warning: Failed to apply MATLAB default scientific notation: %s\n', ME.message);
        % 回退到基本设置
        set(ax, 'TickLabelInterpreter', 'latex');
    end
end


