%% =========================================================================
%% 主函数：分组对比的分离面杂质径向总通量剖面图绘制
%% =========================================================================

function plot_separatrix_flux_comparison_grouped(all_radiationData, groupDirs)
% PLOT_SEPARATRIX_FLUX_COMPARISON_GROUPED 绘制分组对比的分离面杂质径向总通量剖面图 (主SOL区)
%
%   此函数为每个提供的SOLPS算例数据计算分离面处的杂质径向总通量，
%   并在一张图上进行对比。来自同一个 groupDirs 分组的算例将使用相同颜色绘制。
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组。
%     groupDirs         - 包含分组目录信息的元胞数组。

    %% =====================================================================
    %% 初始化设置
    %% =====================================================================

    % 设置绘图属性
    setupPlottingDefaults();

    %% =====================================================================
    %% 数据收集与预处理
    %% =====================================================================

    % 数据收集
    [all_sep_radial_flux_data, all_sep_dir_names, all_sep_full_paths, ...
     all_sep_radial_flux_sums_main_sol, all_total_ion_sources_inside_sep, ...
     common_nx_plot_for_sep_fig, valid_cases_for_sep_fig] = collectSeparatrixFluxData(all_radiationData);

    %% =====================================================================
    %% 绘制分离面通量线性对比图
    %% =====================================================================

    % 绘制线图
    if valid_cases_for_sep_fig > 0 && ~isempty(all_sep_radial_flux_data)
        plotSeparatrixFluxLineChart(all_sep_radial_flux_data, all_sep_dir_names, all_sep_full_paths, ...
                                   groupDirs, common_nx_plot_for_sep_fig);
    else
        fprintf('No data collected for separatrix flux line plot. Skipping.\n');
    end

    %% =====================================================================
    %% 绘制径向通量总和分组柱状图
    %% =====================================================================

    % 绘制径向通量总和柱状图
    if valid_cases_for_sep_fig > 0 && length(all_sep_dir_names) == length(all_sep_radial_flux_sums_main_sol)
        plotGroupedBarChart(all_sep_dir_names, all_sep_full_paths, all_sep_radial_flux_sums_main_sol, ...
                           groupDirs, 'Sum of Separatrix Impurity Radial Flux (Main SOL, Grouped)', ...
                           'Sum of Impurity Radial Flux at Separatrix (Main SOL) ($\mathrm{particles \cdot s^{-1}}$)', ...
                           'Separatrix_Impurity_Radial_Flux_Sum_MainSOL_Grouped_BarChart', [0, 4.5e20]);
    else
        fprintf('No data for separatrix flux sum bar chart. Skipping.\n');
    end

    %% =====================================================================
    %% 绘制电离源总和分组柱状图
    %% =====================================================================

    % 绘制电离源总和柱状图
    if valid_cases_for_sep_fig > 0 && length(all_sep_dir_names) == length(all_total_ion_sources_inside_sep)
        plotGroupedBarChart(all_sep_dir_names, all_sep_full_paths, all_total_ion_sources_inside_sep, ...
                           groupDirs, 'Sum of Total Ne Ionization Source (Inside Separatrix, Grouped)', ...
                           'Total Ne Ionization Source Inside Separatrix ($\mathrm{particles \cdot s^{-1}}$)', ...
                           'Total_Ne_Ion_Source_Inside_Sep_Grouped_BarChart', [0, 4.5e20]);
    else
        fprintf('No data for ionization source bar chart. Skipping.\n');
    end

    %% =====================================================================
    %% 绘制径向通量与电离源并排对比柱状图
    %% =====================================================================

    % 绘制径向通量与电离源对比柱状图
    if valid_cases_for_sep_fig > 0 && length(all_sep_dir_names) == length(all_sep_radial_flux_sums_main_sol) && ...
       length(all_sep_dir_names) == length(all_total_ion_sources_inside_sep)
        plotFluxVsIonSourceComparison(all_sep_dir_names, all_sep_full_paths, ...
                                     all_sep_radial_flux_sums_main_sol, all_total_ion_sources_inside_sep, ...
                                     groupDirs);
    else
        fprintf('No data for flux vs ion source comparison chart. Skipping.\n');
    end
end

%% =========================================================================
%% 内部函数区域
%% =========================================================================

%% =====================================================================
%% 绘图属性设置函数
%% =====================================================================

function setupPlottingDefaults()
% 设置绘图默认属性
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 24);
    set(0, 'DefaultTextFontSize', 24);
    set(0, 'DefaultLineLineWidth', 2);
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 24);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');
    set(0, 'DefaultAxesTickDir', 'in');
end

%% =====================================================================
%% 数据收集与预处理函数
%% =====================================================================

function [all_sep_radial_flux_data, all_sep_dir_names, all_sep_full_paths, ...
          all_sep_radial_flux_sums_main_sol, all_total_ion_sources_inside_sep, ...
          common_nx_plot_for_sep_fig, valid_cases_for_sep_fig] = collectSeparatrixFluxData(all_radiationData)
% 收集分离面通量数据
    all_sep_radial_flux_data = {};
    all_sep_dir_names = {};
    all_sep_full_paths = {};
    all_sep_radial_flux_sums_main_sol = [];
    all_total_ion_sources_inside_sep = [];
    common_nx_plot_for_sep_fig = NaN;
    valid_cases_for_sep_fig = 0;

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;

        fprintf('Processing case: %s\n', dirName);

        % 获取网格维度
        [nx_orig, ny_orig] = size(gmtry.crx);
        nx_plot = nx_orig - 2;

        if nx_plot <= 0, continue; end

        % 计算分离面通量
        iy_sep_data = 14; % 分离面径向索引
        if iy_sep_data > ny_orig, continue; end

        % 计算Ne离子径向通量
        fna_rad_sep_sum = sum(plasma.fna_mdf(:, iy_sep_data, 2, 4:13), 4, 'omitnan');
        flux_profile = fna_rad_sep_sum(2:nx_orig-1);

        all_sep_radial_flux_data{end+1} = flux_profile;
        all_sep_dir_names{end+1} = dirName;
        all_sep_full_paths{end+1} = dirName;

        % 计算主SOL区通量总和
        main_sol_indices = 25:72;
        main_sol_indices = main_sol_indices(main_sol_indices <= length(flux_profile));
        if ~isempty(main_sol_indices)
            all_sep_radial_flux_sums_main_sol(end+1) = sum(flux_profile(main_sol_indices), 'omitnan');
        else
            all_sep_radial_flux_sums_main_sol(end+1) = NaN;
        end

        % 计算电离源
        ion_source_total = 0;
        for chargeState = 1:10
            ionSource2D = compute_Ne_ionSource_for_charge_state_local(plasma, gmtry, chargeState);
            ion_source_particles = ionSource2D .* gmtry.vol;
            ion_source_total = ion_source_total + sum(ion_source_particles(26:73, 2:13), 'all', 'omitnan');
        end
        all_total_ion_sources_inside_sep(end+1) = ion_source_total;

        if isnan(common_nx_plot_for_sep_fig)
            common_nx_plot_for_sep_fig = nx_plot;
        end
        valid_cases_for_sep_fig = valid_cases_for_sep_fig + 1;
    end
end

%% =====================================================================
%% 分离面通量线性对比图绘制函数
%% =====================================================================

function plotSeparatrixFluxLineChart(all_sep_radial_flux_data, all_sep_dir_names, all_sep_full_paths, ...
                                    groupDirs, common_nx_plot_for_sep_fig)
% 绘制分离面通量线图
    fig = figure('Name', 'Separatrix Impurity Radial Total Flux (Grouped, Main SOL)', ...
                 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [1, 1, 12, 8]);

    ax = axes(fig);
    hold(ax, 'on');

    % 主SOL区域索引
    x_indices = 25:72;
    x_indices = x_indices(x_indices <= common_nx_plot_for_sep_fig);

    num_groups = length(groupDirs);
    group_colors = lines(max(num_groups, 1));

    plot_handles = [];
    legend_strings = {};

    for i = 1:length(all_sep_dir_names)
        group_idx = findGroupIndex(all_sep_full_paths{i}, groupDirs);
        if group_idx > 0
            flux_profile = all_sep_radial_flux_data{i};
            if length(flux_profile) >= max(x_indices)
                data_to_plot = flux_profile(x_indices);
                h = plot(ax, x_indices, data_to_plot, 'Color', group_colors(group_idx, :), 'LineWidth', 2);
                plot_handles(end+1) = h;
                legend_strings{end+1} = getShortDirName(all_sep_dir_names{i});
            end
        end
    end

    xlabel(ax, 'Poloidal Cell Index in Main SOL');
    ylabel(ax, 'Impurity Radial Flux at Separatrix (particles/s)');
    title(ax, 'Separatrix Impurity Radial Flux Comparison (Main SOL)');
    grid(ax, 'on');
    box(ax, 'on');
    set(ax, 'TickDir', 'in');
    ylim(ax, [-2.5e20, 2.5e20]);

    if ~isempty(plot_handles)
        legend(ax, plot_handles, legend_strings, 'Location', 'best', 'Interpreter', 'none');
    end

    saveFigureWithTimestamp(fig, 'Separatrix_Impurity_Radial_Total_Flux_MainSOL_Grouped_Comparison');
    fprintf('Saved separatrix flux line chart.\n');
end

%% =====================================================================
%% 分组柱状图绘制函数
%% =====================================================================

function plotGroupedBarChart(dir_names, full_paths, data_values, groupDirs, ...
                            fig_title, ylabel_text, save_name, ylim_range)
% 绘制分组柱状图
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 14, 7]);

    ax = axes(fig);
    hold(ax, 'on');

    num_cases = length(dir_names);
    num_groups = length(groupDirs);
    group_colors = lines(max(num_groups, 1));

    % 准备颜色
    bar_colors = zeros(num_cases, 3);
    for i = 1:num_cases
        group_idx = findGroupIndex(full_paths{i}, groupDirs);
        if group_idx > 0
            bar_colors(i, :) = group_colors(group_idx, :);
        else
            bar_colors(i, :) = [0.5 0.5 0.5];
        end
    end

    % 绘制柱状图
    if ~isempty(data_values) && ~all(isnan(data_values))
        bh = bar(ax, 1:num_cases, data_values, 'FaceColor', 'flat');
        bh.CData = bar_colors;

        % 设置坐标轴
        xticks(ax, 1:num_cases);
        short_names = cellfun(@getShortDirName, dir_names, 'UniformOutput', false);
        xticklabels(ax, short_names);
        xtickangle(ax, 45);
        set(ax, 'TickLabelInterpreter', 'none');

        xlabel(ax, 'Simulation Case');
        ylabel(ax, ylabel_text);
        title(ax, strrep(fig_title, ' (Grouped)', ''));
        grid(ax, 'on');
        box(ax, 'on');
        set(ax, 'TickDir', 'in');

        if nargin >= 8 && ~isempty(ylim_range)
            ylim(ax, ylim_range);
        end

        % 添加分组图例
        addGroupLegend(ax, groupDirs, group_colors);
    end

    saveFigureWithTimestamp(fig, save_name);
    fprintf('Saved grouped bar chart: %s\n', save_name);
end

%% =====================================================================
%% 径向通量与电离源并排对比图绘制函数
%% =====================================================================

function plotFluxVsIonSourceComparison(dir_names, full_paths, flux_data, ion_source_data, groupDirs)
% 绘制径向通量与电离源对比柱状图（每个案例显示左右两个柱子）
    fig = figure('Name', 'Separatrix Flux vs Ion Source Comparison (Grouped)', ...
                 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 16, 8]);

    ax = axes(fig);
    hold(ax, 'on');

    num_cases = length(dir_names);
    num_groups = length(groupDirs);
    group_colors = lines(max(num_groups, 1));

    % 准备数据和颜色
    bar_colors_flux = zeros(num_cases, 3);
    bar_colors_ion = zeros(num_cases, 3);

    for i = 1:num_cases
        group_idx = findGroupIndex(full_paths{i}, groupDirs);
        if group_idx > 0
            base_color = group_colors(group_idx, :);
            bar_colors_flux(i, :) = base_color;
            bar_colors_ion(i, :) = base_color * 0.7; % 稍微暗一些的颜色用于电离源
        else
            bar_colors_flux(i, :) = [0.5 0.5 0.5];
            bar_colors_ion(i, :) = [0.3 0.3 0.3];
        end
    end

    % 设置柱子位置
    bar_width = 0.35;
    x_positions = 1:num_cases;
    x_flux = x_positions - bar_width/2;
    x_ion = x_positions + bar_width/2;

    % 绘制柱状图
    if ~isempty(flux_data) && ~all(isnan(flux_data)) && ~isempty(ion_source_data) && ~all(isnan(ion_source_data))
        % 径向通量柱子
        for i = 1:num_cases
            if ~isnan(flux_data(i))
                bar(ax, x_flux(i), flux_data(i), bar_width, 'FaceColor', bar_colors_flux(i, :), ...
                    'EdgeColor', 'k', 'LineWidth', 0.5);
            end
        end

        % 电离源柱子
        for i = 1:num_cases
            if ~isnan(ion_source_data(i))
                bar(ax, x_ion(i), ion_source_data(i), bar_width, 'FaceColor', bar_colors_ion(i, :), ...
                    'EdgeColor', 'k', 'LineWidth', 0.5);
            end
        end

        % 设置坐标轴
        xticks(ax, x_positions);
        short_names = cellfun(@getShortDirName, dir_names, 'UniformOutput', false);
        xticklabels(ax, short_names);
        xtickangle(ax, 45);
        set(ax, 'TickLabelInterpreter', 'none');

        xlabel(ax, 'Simulation Case');
        ylabel(ax, 'Particles per Second ($\mathrm{particles \cdot s^{-1}}$)');
        title(ax, 'Separatrix Radial Flux vs Ne Ionization Source Comparison');
        grid(ax, 'on');
        box(ax, 'on');
        set(ax, 'TickDir', 'in');

        % 设置Y轴范围
        ylim(ax, [0, 4.5e20]);

        % 添加数据类型图例
        h_flux = bar(NaN, NaN, 'FaceColor', [0.3 0.3 0.8], 'EdgeColor', 'k');
        h_ion = bar(NaN, NaN, 'FaceColor', [0.2 0.2 0.6], 'EdgeColor', 'k');
        legend_data = legend(ax, [h_flux, h_ion], {'Left Bar: Radial Flux (Main SOL)', 'Right Bar: Ion Source (Inside Sep)'}, ...
                           'Location', 'northwest', 'Interpreter', 'none');
        title(legend_data, 'Data Type');

        % 添加分组颜色图例
        addGroupLegendForComparison(ax, groupDirs, group_colors);
    end

    saveFigureWithTimestamp(fig, 'Separatrix_Flux_vs_IonSource_Comparison_Grouped');
    fprintf('Saved flux vs ion source comparison chart.\n');
end

%% =====================================================================
%% 辅助函数区域
%% =====================================================================

function group_idx = findGroupIndex(full_path, groupDirs)
% 查找路径所属的组索引
    group_idx = 0;
    for g = 1:length(groupDirs)
        paths_in_group = groupDirs{g};
        if ischar(paths_in_group)
            paths_in_group = {paths_in_group};
        end
        if iscell(paths_in_group) && ismember(full_path, paths_in_group)
            group_idx = g;
            break;
        end
    end
end

function addGroupLegend(ax, groupDirs, group_colors)
% 添加分组图例
    legend_handles = [];
    legend_strings = {};

    for g = 1:length(groupDirs)
        h_patch = patch(NaN, NaN, group_colors(g, :), 'Parent', ax, 'EdgeColor', 'none');
        legend_handles(end+1) = h_patch;
        legend_strings{end+1} = sprintf('Group %d', g);
    end

    if ~isempty(legend_handles)
        L = legend(ax, legend_handles, legend_strings, 'Location', 'bestoutside', 'Interpreter', 'none');
        title(L, 'Case Groups');
    end
end

function addGroupLegendForComparison(ax, groupDirs, group_colors)
% 为对比图添加分组颜色图例（位置调整以避免与数据类型图例冲突）
    if length(groupDirs) <= 1
        return; % 只有一个组时不需要分组图例
    end

    % 创建一个新的坐标轴用于分组图例
    ax_pos = get(ax, 'Position');
    legend_ax = axes('Position', [ax_pos(1) + ax_pos(3) + 0.02, ax_pos(2) + ax_pos(4) - 0.2, 0.1, 0.15]);
    axis(legend_ax, 'off');

    legend_handles = [];
    legend_strings = {};

    for g = 1:length(groupDirs)
        h_patch = patch(NaN, NaN, group_colors(g, :), 'Parent', legend_ax, 'EdgeColor', 'none');
        legend_handles(end+1) = h_patch;
        legend_strings{end+1} = sprintf('Group %d', g);
    end

    if ~isempty(legend_handles)
        L = legend(legend_ax, legend_handles, legend_strings, 'Location', 'best', 'Interpreter', 'none');
        title(L, 'Case Groups');
        set(L, 'FontSize', 10);
    end
end

%% =====================================================================
%% 文件处理与工具函数
%% =====================================================================

function short_name = getShortDirName(full_path)
% 获取简短的目录名
    [~, short_name, ~] = fileparts(full_path);
    if length(short_name) > 15
        short_name = [short_name(1:12), '...'];
    end
end

function safeName = createSafeFilename(originalName)
% 创建安全的文件名
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if length(safeName) > 200
        safeName = safeName(1:200);
    end
    if isempty(safeName)
        safeName = 'unnamed_figure';
    end
end

function saveFigureWithTimestamp(figHandle, baseName)
% 保存图形文件
    set(figHandle, 'PaperPositionMode', 'auto');
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
    safeBaseName = createSafeFilename(baseName);
    fileName = sprintf('%s_%s.fig', safeBaseName, timestampStr);

    try
        savefig(figHandle, fileName);
        fprintf('Figure saved: %s\n', fileName);
    catch ME
        fprintf('Warning: Failed to save figure. Error: %s\n', ME.message);
    end
end

%% =====================================================================
%% Ne电离源计算函数
%% =====================================================================

function ionSource2D_Ne_ion = compute_Ne_ionSource_for_charge_state_local(plasma_tmp, gmtry_tmp, chargeState)
    % 说明：
    %   - 此函数为 plot_separatrix_flux_comparison_grouped 内部使用
    %   - 电离源计算基于等离子体源项(sna)和密度(na)数据, 针对指定的Ne价态
    [nx, ny, ~] = size(gmtry_tmp.crx);
    ionSource2D_Ne_ion = zeros(nx, ny);

    % 确定对应Ne Z+的组分索引 (iComp_Ne_ion)
    % 假设：杂质的第一个电离态(如Ne1+)在EIRENE输出中通常是species_idx=4 (紧随 D0, D+, e-)
    % 因此 Ne(Z)+ 对应索引 3 + Z
    iComp_Ne_ion = 3 + chargeState;
    
    % 检查计算出的 species index 是否在 plasma_tmp.sna 和 plasma_tmp.na 的有效范围内
    valid_species_index = true;
    if ~(isfield(plasma_tmp, 'sna') && ndims(plasma_tmp.sna) >= 4 && iComp_Ne_ion <= size(plasma_tmp.sna, 4))
        valid_species_index = false;
    end
    if ~(isfield(plasma_tmp, 'na') && ndims(plasma_tmp.na) >= 3 && iComp_Ne_ion <= size(plasma_tmp.na, 3))
        valid_species_index = false;
    end

    if ~valid_species_index
        % 如果索引无效，不打印警告（避免刷屏），直接返回零源
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