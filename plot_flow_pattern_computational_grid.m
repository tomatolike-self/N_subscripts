function plot_flow_pattern_computational_grid(all_radiationData)
% 绘制计算网格中的N离子通量密度分布图 - 采用学术标准的单元中心箭头法
%
% 实现方法：
% 1. 背景着色：使用imagesc函数为每个网格单元进行均匀着色，避免插值模糊
% 2. 箭头位置：精确绘制在每个单元格的中心位置
% 3. 坐标系统：单元格中心坐标为1,2,3,...，边界为0.5,1.5,2.5,...
% 4. 数据对应：一个单元格，一个统一背景色，一个中心点箭头
% 5. 通量密度计算：使用通量(fna_mdf)除以对应面积实现，单位为m^-2s^-1
%
% 输入: all_radiationData - SOLPS仿真数据结构体数组

    % 设置全局绘图属性
    setupPlotDefaults();

    % 初始化分界面通量数据收集
    sep_flux_data = initializeSepFluxData();

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        fprintf('Processing case: %s\n', radData.dirName);

        % 获取网格维度
        [nx_orig, ny_orig] = getGridDimensions(radData.gmtry, radData.dirName);
        if isempty(nx_orig), continue; end

        nx_plot = nx_orig - 2;  % 去除保护单元
        ny_plot = ny_orig - 2;

        % 收集分界面通量数据
        sep_flux_data = collectSepFluxData(radData, nx_orig, ny_orig, nx_plot, sep_flux_data);

        % 计算N离子通量密度
        if ~isfield(radData.plasma, 'fna_mdf')
            warning('Case %s: fna_mdf field not found, skipping main plot', radData.dirName);
            continue;
        end
        if size(radData.plasma.fna_mdf, 4) < 10
            warning('Case %s: Insufficient N ion data, skipping main plot', radData.dirName);
            continue;
        end

        [sum_flux_density_pol_plot, sum_flux_density_rad_plot, flux_density_magnitude_plot, u_norm_plot, v_norm_plot] = ...
            calculateFluxDensityData(radData.plasma, radData.gmtry, nx_orig, ny_orig);

        % 创建并绘制主图
        fig = createMainFigure(radData.dirName);
        ax = plotFluxDensityBackground(fig, nx_plot, ny_plot, flux_density_magnitude_plot);
        setupDataCursor(fig, nx_plot, ny_plot, sum_flux_density_pol_plot, sum_flux_density_rad_plot, flux_density_magnitude_plot);
        plotFlowArrows(ax, nx_plot, ny_plot, u_norm_plot, v_norm_plot);

        % 添加区域标签和设置坐标轴
        addRegionLabels(ax, nx_plot, ny_plot);
        setupAxes(ax, nx_plot, ny_plot);

        % 保存图像
        saveFigureWithTimestamp(gcf, sprintf('FluxDensityPattern_CompGrid_NoGuard_%s', createSafeFilename(radData.dirName)));


    end

    % 绘制分界面通量对比图
    plotSepFluxComparison(sep_flux_data);

end

function safeName = createSafeFilename(originalName)
% CREATESAFEFILENAME 从原始名称创建适用于文件名的安全字符串
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if strlength(safeName) > 100 % 限制文件名长度
        safeName = safeName(1:100);
    end
end

function saveFigureWithTimestamp(figHandle, baseName)
% 保存图形为.fig格式并添加时间戳
    set(figHandle,'PaperPositionMode','auto');
    timestampStr = string(datetime('now','Format','yyyyMMdd_HHmmss'));
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);

    try
        savefig(figHandle, figFile);
        fprintf('Figure saved: %s\n', figFile);
    catch ME
        fprintf('Warning: Failed to save figure - %s\n', ME.message);
    end
end

function output_txt = myDataCursorUpdateFcn(~, event_obj, nx_p, ny_p, flux_density_pol_plot_data, flux_density_rad_plot_data, flux_density_magnitude_plot_data)
% 自定义数据游标更新函数 - 适配单元中心坐标系统
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);
    y_clicked = pos(2);

    if nx_p > 1 && ny_p > 1
        % 找到最近的单元格中心（标准单元中心方法）
        x_cell_centers = 1:nx_p;  % 单元格中心: 1, 2, 3, ..., nx_p
        y_cell_centers = 1:ny_p;  % 单元格中心: 1, 2, 3, ..., ny_p
        [~, idx_pol] = min(abs(x_cell_centers - x_clicked));
        [~, idx_rad] = min(abs(y_cell_centers - y_clicked));

        % 获取通量密度值
        pol_flux_density = flux_density_pol_plot_data(idx_pol, idx_rad);
        rad_flux_density = flux_density_rad_plot_data(idx_pol, idx_rad);
        mag_flux_density = flux_density_magnitude_plot_data(idx_pol, idx_rad);

        output_txt = {sprintf('Cell (ix, iy): (%d, %d)', idx_pol, idx_rad), ...
                      sprintf('Poloidal Flux Density: %.3e m^{-2}s^{-1}', pol_flux_density), ...
                      sprintf('Radial Flux Density: %.3e m^{-2}s^{-1}', rad_flux_density), ...
                      sprintf('Flux Density Magnitude: %.3e m^{-2}s^{-1}', mag_flux_density)};
    else
        % 显示单元格数据
        ix = max(1, min(round(x_clicked), nx_p));
        iy = max(1, min(round(y_clicked), ny_p));
        z_value = flux_density_magnitude_plot_data(ix, iy);

        output_txt = {sprintf('Poloidal Cell: %d', ix), ...
                      sprintf('Radial Cell: %d', iy), ...
                      sprintf('Flux Density Magnitude: %.3e m^{-2}s^{-1}', z_value)};
    end
end

%% 辅助函数
function C = getGridRegionConstants()
% 统一的网格区域常量（与 plot_solps_grid_structure_from_radData_enhanced.m 保持一致）
    C.inner_div_end    = 24;  % ODE
    C.outer_div_start  = 73;  % IDE
    C.separatrix_line  = 12;  % 分离面在 12 与 13 之间（绘图线在 12.5）
    C.omp_idx          = 41;
    C.imp_idx          = 58;
end


function setupPlotDefaults()
% 设置全局绘图属性
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 36);
    set(0, 'DefaultTextFontSize', 36);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 32);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');
end

function sep_flux_data = initializeSepFluxData()
% 初始化分界面通量数据结构
    sep_flux_data.all_flux_data = {};
    sep_flux_data.all_dir_names = {};
    sep_flux_data.common_nx_plot = NaN;
    sep_flux_data.first_case_processed = false;
    sep_flux_data.valid_cases = 0;
end

function [nx_orig, ny_orig] = getGridDimensions(gmtry, dirName)
% 获取网格维度
    nx_orig = [];
    ny_orig = [];

    if isfield(gmtry, 'crx')
        s = size(gmtry.crx);
        nx_orig = s(1);
        ny_orig = s(2);
    elseif isfield(gmtry, 'cry')
        s = size(gmtry.cry);
        nx_orig = s(1);
        ny_orig = s(2);
    else
        warning('Case %s: Grid coordinate fields not found, skipping', dirName);
        return;
    end

    if nx_orig < 3 || ny_orig < 3
        warning('Case %s: Grid dimensions too small (%dx%d), skipping', dirName, nx_orig, ny_orig);
        nx_orig = [];
        ny_orig = [];
    end
end

function sep_flux_data = collectSepFluxData(radData, nx_orig, ny_orig, nx_plot, sep_flux_data)
% 收集分界面通量数据
    % 分离面行（与增强版一致，剔除保护单元后为 12）
    C = getGridRegionConstants();
    separatrix_line = C.separatrix_line;  % 12
    % 分离面索引换算说明（为何是 +2）：
    % - 原始网格在首尾各有1层保护单元；计算网格的分离面在 iy=12 与 13 之间
    % - 映射回原始网格，分离面位于 13(=12+1) 与 14 之间
    % - fna_mdf 的径向通量定义在“当前网格与其下方网格的交界面”上
    %   因此穿过分离面的通量应取 14 号原始网格的径向面量，即 12+2
    % 注：这里的 +2 不是“加两层保护单元”，而是由通量定义的界面位置决定
    iy_sep = separatrix_line + 2;

    % 检查数据有效性
    if iy_sep > ny_orig || size(radData.plasma.fna_mdf, 4) < 10
        return;
    end

    % 计算N离子径向通量
    fna_rad_sep = sum(radData.plasma.fna_mdf(:, iy_sep, 2, 4:10), 4, 'omitnan');
    sep_flux_profile = fna_rad_sep(2:nx_orig-1);  % 去除保护单元

    % 存储数据
    sep_flux_data.all_flux_data{end+1} = sep_flux_profile;
    sep_flux_data.all_dir_names{end+1} = radData.dirName;
    sep_flux_data.valid_cases = sep_flux_data.valid_cases + 1;

    % 设置公共网格尺寸
    if ~sep_flux_data.first_case_processed
        sep_flux_data.common_nx_plot = nx_plot;
        sep_flux_data.first_case_processed = true;
    end
end

function [sum_flux_density_pol_plot, sum_flux_density_rad_plot, flux_density_magnitude_plot, u_norm_plot, v_norm_plot] = calculateFluxDensityData(plasma, gmtry, nx_orig, ny_orig)
% 计算通量密度数据 - 使用fna_mdf通量除以面积的物理定义
    % 计算N离子通量密度 (通量 / 面积)
    sum_fna_pol_full = sum(plasma.fna_mdf(:, :, 1, 4:10), 4, 'omitnan');  % N1+到N7+极向通量总和
    sum_fna_rad_full = sum(plasma.fna_mdf(:, :, 2, 4:10), 4, 'omitnan');  % N1+到N7+径向通量总和

    % 计算面积
    area_pol_full = gmtry.gs(:, :, 1) .* gmtry.qz(:, :, 2);  % 极向通量对应的面积 (m^2)
    area_rad_full = gmtry.gs(:, :, 2);  % 径向通量对应的面积 (m^2)

    % 计算通量密度 = 通量 / 面积
    sum_flux_density_pol_full = sum_fna_pol_full ./ area_pol_full;  % 极向通量密度 (m^-2 s^-1)
    sum_flux_density_rad_full = sum_fna_rad_full ./ area_rad_full;  % 径向通量密度 (m^-2 s^-1)

    % 去除保护单元
    sum_flux_density_pol_plot = sum_flux_density_pol_full(2:nx_orig-1, 2:ny_orig-1);
    sum_flux_density_rad_plot = sum_flux_density_rad_full(2:nx_orig-1, 2:ny_orig-1);

    % 计算通量密度大小
    flux_density_magnitude_plot = sqrt(sum_flux_density_pol_plot.^2 + sum_flux_density_rad_plot.^2);

    % 归一化通量密度方向
    u_norm_plot = zeros(size(sum_flux_density_pol_plot));
    v_norm_plot = zeros(size(sum_flux_density_rad_plot));

    non_zero_flux = flux_density_magnitude_plot > 1e-15;
    u_norm_plot(non_zero_flux) = sum_flux_density_pol_plot(non_zero_flux) ./ flux_density_magnitude_plot(non_zero_flux);
    v_norm_plot(non_zero_flux) = sum_flux_density_rad_plot(non_zero_flux) ./ flux_density_magnitude_plot(non_zero_flux);
end

function fig = createMainFigure(dirName)
% 创建主图形窗口
    fig = figure('Name', sprintf('N Ion Flux Density Pattern - %s', dirName), ...
                 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [1, 1, 10, 7]);
end

function ax = plotFluxDensityBackground(fig, nx_plot, ny_plot, flux_density_magnitude_plot)
% 绘制通量密度背景色图 - 使用学术标准的单元中心方法（imagesc实现）
    ax = axes(fig);
    hold(ax, 'on');

    % 为log色标避免0或负值
    min_positive = min(flux_density_magnitude_plot(flux_density_magnitude_plot>0),[],'all');
    if isempty(min_positive); min_positive = 1e15; end
    flux_display = flux_density_magnitude_plot;
    flux_display(flux_display<=0) = 0.1*min_positive;

    % 使用imagesc实现标准的单元格着色
    % imagesc直接使用数据矩阵，避免pcolor的复杂网格匹配问题
    imagesc(ax, 1:nx_plot, 1:ny_plot, flux_display');

    % 设置坐标轴范围以显示完整的单元格
    set(ax, 'XLim', [0.5, nx_plot + 0.5]);
    set(ax, 'YLim', [0.5, ny_plot + 0.5]);
    shading(ax, 'flat');  % 使用flat着色确保每个单元格颜色均匀

    h_cb = colorbar(ax);
    set(ax, 'ColorScale', 'log');
    ylabel(h_cb, 'N Ion Total Flux Density Magnitude (m$^{-2}$s$^{-1}$)', 'FontSize', 32, 'Interpreter', 'latex');
    colormap(ax, 'jet');
    set(ax, 'YDir', 'normal');
end

function setupDataCursor(fig, nx_plot, ny_plot, sum_flux_density_pol_plot, sum_flux_density_rad_plot, flux_density_magnitude_plot)
% 设置数据游标
    dcm_obj = datacursormode(fig);
    set(dcm_obj, 'Enable', 'on');
    set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn, nx_plot, ny_plot, sum_flux_density_pol_plot, sum_flux_density_rad_plot, flux_density_magnitude_plot});
end

function plotFlowArrows(ax, nx_plot, ny_plot, u_norm_plot, v_norm_plot)
% 绘制流向箭头 - 标准单元中心箭头法
    if nx_plot <= 1 || ny_plot <= 1
        return;
    end



    arrow_scale = 0.4;

    % 标准方法：箭头精确绘制在每个单元格的中心
    % 单元格中心坐标：1, 2, 3, ..., nx_plot (对应单元格边界0.5-1.5, 1.5-2.5, ...)
    x_centers = 1:nx_plot;  % 单元格中心: 1, 2, 3, ..., nx_plot
    y_centers = 1:ny_plot;  % 单元格中心: 1, 2, 3, ..., ny_plot
    [X_quiver, Y_quiver] = meshgrid(x_centers, y_centers);

    % 确保数据维度与网格匹配
    if size(u_norm_plot, 1) == nx_plot && size(u_norm_plot, 2) == ny_plot
        % 数据是nx_plot x ny_plot，需要转置为ny_plot x nx_plot用于quiver
        u_quiver = u_norm_plot';
        v_quiver = v_norm_plot';
    elseif size(u_norm_plot, 1) == ny_plot && size(u_norm_plot, 2) == nx_plot
        % 数据已经是ny_plot x nx_plot
        u_quiver = u_norm_plot;
        v_quiver = v_norm_plot;
    else
        error('Arrow data dimensions do not match grid dimensions');
    end

    % 绘制箭头
    quiver(ax, X_quiver, Y_quiver, u_quiver, v_quiver, arrow_scale, 'k', 'LineWidth', 0.8);
end

function addRegionLabels(ax, nx_plot, ny_plot)
% 添加区域标签 - 适配单元中心坐标系统
    % 边界常量（与增强版脚本一致）
    C = getGridRegionConstants();
    isep_idx = C.separatrix_line;     % 12
    inner_div_end = C.inner_div_end;  % 24
    omp_idx = C.omp_idx;              % 41
    imp_idx = C.imp_idx;              % 58
    outer_div_start = C.outer_div_start; % 73

    % 绘制分隔线（在单元格边界处）
    plot(ax, [inner_div_end + 0.5, inner_div_end + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
    plot(ax, [outer_div_start - 0.5, outer_div_start - 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
    plot(ax, [omp_idx + 0.5, omp_idx + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
    plot(ax, [imp_idx + 0.5, imp_idx + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
    plot(ax, [0.5, nx_plot + 0.5], [isep_idx + 0.5, isep_idx + 0.5], 'k-', 'LineWidth', 1.5);

    % 顶部标签（在单元格中心）
    label_font_size = 32;
    top_y = ny_plot + 1.2;
    text(ax, 1, top_y, 'OT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, inner_div_end, top_y, 'ODE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, omp_idx, top_y, 'OMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, imp_idx, top_y, 'IMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, outer_div_start, top_y, 'IDE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, nx_plot, top_y, 'IT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % 区域标签（在单元格中心）
    center_x = round(nx_plot / 2);
    core_y = round(isep_idx * 0.6);
    sol_y = isep_idx + round((ny_plot - isep_idx) * 0.65);

    text(ax, center_x, core_y, 'Core', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, center_x, sol_y, 'SOL', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % PFR标签（在单元格中心）
    pfr_x_left = round(inner_div_end * 0.5);
    pfr_x_right = round(outer_div_start + (nx_plot - outer_div_start) * 0.5);
    text(ax, pfr_x_left, core_y, 'PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, pfr_x_right, core_y, 'PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % 分界面标签（在单元格中心）
    text(ax, center_x, isep_idx + 2, 'Separatrix', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

function setupAxes(ax, nx_plot, ny_plot)
% 设置坐标轴 - 适配单元中心坐标系统
    xlabel(ax, '$\mathrm{i_x}$ (Poloidal Cell Index)', 'FontSize', 34);
    ylabel(ax, '$\mathrm{i_y}$ (Radial Cell Index)', 'FontSize', 34);

    % 坐标轴范围：显示从0.5到nx_plot+0.5，确保单元格完整显示
    axis(ax, [0.5, nx_plot + 0.5, 0.5, ny_plot + 0.5]);

    % 设置关键刻度（与增强版保持一致风格）
    C = getGridRegionConstants();
    xticks = unique([1, C.inner_div_end, C.omp_idx, C.imp_idx, C.outer_div_start, nx_plot]);
    yticks = unique([1, C.separatrix_line, ny_plot]);
    set(ax, 'XTick', xticks, 'YTick', yticks);
    set(ax, 'FontSize', 28);

    box(ax, 'on');
    grid(ax, 'off');
    hold(ax, 'off');
end

function plotSepFluxComparison(sep_flux_data)
% 绘制分界面通量对比图
    if sep_flux_data.valid_cases == 0 || isempty(sep_flux_data.all_flux_data)
        fprintf('No valid separatrix flux data, skipping plot\n');
        return;
    end

    fig = figure('Name', 'Separatrix Impurity Radial Total Flux Comparison (Main SOL)', ...
                 'NumberTitle', 'off', 'Color', 'w');
    setupPlotDefaults();

    ax = axes(fig);
    hold(ax, 'on');

    % 主SOL区域范围
    C = getGridRegionConstants();
    main_sol_start = C.inner_div_end + 1;       % 25
    main_sol_end = C.outer_div_start - 1;       % 72
    actual_start = max(1, main_sol_start);
    actual_end = min(sep_flux_data.common_nx_plot, main_sol_end);

    if actual_start > actual_end
        fprintf('Main SOL region indices out of range, skipping plot\n');
        return;
    end

    x_indices = actual_start:actual_end;
    line_colors = lines(sep_flux_data.valid_cases);

    % 绘制每个算例的数据
    for i = 1:sep_flux_data.valid_cases
        flux_data = sep_flux_data.all_flux_data{i};

        % 调整数据长度
        if length(flux_data) > sep_flux_data.common_nx_plot
            flux_data = flux_data(1:sep_flux_data.common_nx_plot);
        elseif length(flux_data) < sep_flux_data.common_nx_plot
            flux_data = [flux_data(:); NaN(sep_flux_data.common_nx_plot - length(flux_data), 1)];
        end

        % 提取主SOL区域数据
        data_for_plot = flux_data(x_indices);
        plot(ax, x_indices, data_for_plot, 'Color', line_colors(i,:), 'LineWidth', 1.5);
    end

    % 设置图形属性
    xlabel(ax, '$\mathrm{i_x}$ (Main SOL Poloidal Cell Index)', 'FontSize', 34);
    ylabel(ax, 'Impurity (N) Separatrix Radial Total Flux ($\mathrm{particles \cdot s^{-1}}$)', 'FontSize', 34);
    title(ax, 'Separatrix Impurity Radial Total Flux Comparison along Main SOL', 'FontSize', 36);
    grid(ax, 'on');

    % 添加图例
    legend(ax, sep_flux_data.all_dir_names, 'Location', 'best', 'Interpreter', 'none');
    xlim(ax, [x_indices(1) - 0.5, x_indices(end) + 0.5]);

    % 固定Y轴范围为-2.5e20到2.5e20
    ylim(ax, [-2.5e20, 2.5e20]);

    hold(ax, 'off');

    % 保存图形
    saveFigureWithTimestamp(fig, 'Separatrix_Impurity_Radial_Total_Flux_MainSOL_Comparison');
    fprintf('Separatrix impurity radial total flux comparison plot saved\n');
end

