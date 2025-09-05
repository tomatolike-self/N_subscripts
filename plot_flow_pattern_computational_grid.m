function plot_flow_pattern_computational_grid(all_radiationData)
% 绘制计算网格中的Ne离子流模式图
% 输入: all_radiationData - SOLPS仿真数据结构体数组

    % 设置全局绘图属性
    setupPlotDefaults();

    % 初始化分界面通量数据收集
    sep_flux_data = initializeSepFluxData();

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        fprintf('处理算例: %s\n', radData.dirName);

        % 获取网格维度
        [nx_orig, ny_orig] = getGridDimensions(radData.gmtry, radData.dirName);
        if isempty(nx_orig), continue; end

        nx_plot = nx_orig - 2;  % 去除保护单元
        ny_plot = ny_orig - 2;

        % 收集分界面通量数据
        sep_flux_data = collectSepFluxData(radData, nx_orig, ny_orig, nx_plot, sep_flux_data);

        % 计算Ne离子通量
        if size(radData.plasma.fna_mdf, 4) < 13
            warning('算例 %s: Ne离子数据不足，跳过主绘图', radData.dirName);
            continue;
        end

        [sum_fna_pol_plot, sum_fna_rad_plot, flux_magnitude_plot, u_norm_plot, v_norm_plot] = ...
            calculateFluxData(radData.plasma, nx_orig, ny_orig);
        
        % 创建并绘制主图
        fig = createMainFigure(radData.dirName);
        ax = plotFluxBackground(fig, nx_plot, ny_plot, flux_magnitude_plot);
        setupDataCursor(fig, nx_plot, ny_plot, sum_fna_pol_plot, sum_fna_rad_plot, flux_magnitude_plot);
        plotFlowArrows(ax, nx_plot, ny_plot, u_norm_plot, v_norm_plot);

        % 添加区域标签和设置坐标轴
        addRegionLabels(ax, nx_plot, ny_plot);
        setupAxes(ax, nx_plot, ny_plot);

        % 保存图像
        saveFigureWithTimestamp(gcf, sprintf('FlowPattern_CompGrid_NoGuard_%s', createSafeFilename(radData.dirName)));
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
        fprintf('图形已保存: %s\n', figFile);
    catch ME
        fprintf('警告: 保存图形失败 - %s\n', ME.message);
    end
end

function output_txt = myDataCursorUpdateFcn(~, event_obj, nx_p, ny_p, fna_pol_plot_data, fna_rad_plot_data, flux_magnitude_plot_data)
% 自定义数据游标更新函数
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);
    y_clicked = pos(2);

    if nx_p > 1 && ny_p > 1
        % 找到最近的箭头中心
        x_arrow_centers = (1:(nx_p-1)) + 0.5;
        y_arrow_centers = (1:(ny_p-1)) + 0.5;
        [~, idx_pol] = min(abs(x_arrow_centers - x_clicked));
        [~, idx_rad] = min(abs(y_arrow_centers - y_clicked));

        % 获取通量值
        pol_flux = fna_pol_plot_data(idx_pol, idx_rad);
        rad_flux = fna_rad_plot_data(idx_pol, idx_rad);
        mag_flux = flux_magnitude_plot_data(idx_pol, idx_rad);

        output_txt = {sprintf('单元格 (ix, iy): (%d, %d)', idx_pol, idx_rad), ...
                      sprintf('极向通量: %.3e', pol_flux), ...
                      sprintf('径向通量: %.3e', rad_flux), ...
                      sprintf('通量大小: %.3e', mag_flux)};
    else
        % 显示surf图数据
        ix = max(1, min(round(x_clicked), nx_p));
        iy = max(1, min(round(y_clicked), ny_p));
        z_value = flux_magnitude_plot_data(ix, iy);

        output_txt = {sprintf('极向单元: %d', ix), ...
                      sprintf('径向单元: %d', iy), ...
                      sprintf('通量大小: %.3e', z_value)};
    end
end

%% 辅助函数

function setupPlotDefaults()
% 设置全局绘图属性
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 18);
    set(0, 'DefaultTextFontSize', 18);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 16);
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
        warning('算例 %s: 未找到网格坐标字段，跳过', dirName);
        return;
    end

    if nx_orig < 3 || ny_orig < 3
        warning('算例 %s: 网格维度过小 (%dx%d)，跳过', dirName, nx_orig, ny_orig);
        nx_orig = [];
        ny_orig = [];
    end
end

function sep_flux_data = collectSepFluxData(radData, nx_orig, ny_orig, nx_plot, sep_flux_data)
% 收集分界面通量数据
    isep_idx = 13;  % 分界面径向索引
    iy_sep = isep_idx + 1;  % 原始数据网格中的索引

    % 检查数据有效性
    if iy_sep > ny_orig || size(radData.plasma.fna_mdf, 4) < 13
        return;
    end

    % 计算Ne离子径向通量
    fna_rad_sep = sum(radData.plasma.fna_mdf(:, iy_sep, 2, 4:13), 4, 'omitnan');
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

function [sum_fna_pol_plot, sum_fna_rad_plot, flux_magnitude_plot, u_norm_plot, v_norm_plot] = calculateFluxData(plasma, nx_orig, ny_orig)
% 计算通量数据
    % 计算Ne离子通量
    sum_fna_pol_full = sum(plasma.fna_mdf(:, :, 1, 4:13), 4, 'omitnan');
    sum_fna_rad_full = sum(plasma.fna_mdf(:, :, 2, 4:13), 4, 'omitnan');

    % 去除保护单元
    sum_fna_pol_plot = sum_fna_pol_full(2:nx_orig-1, 2:ny_orig-1);
    sum_fna_rad_plot = sum_fna_rad_full(2:nx_orig-1, 2:ny_orig-1);

    % 计算通量大小
    flux_magnitude_plot = sqrt(sum_fna_pol_plot.^2 + sum_fna_rad_plot.^2);

    % 归一化通量方向
    u_norm_plot = zeros(size(sum_fna_pol_plot));
    v_norm_plot = zeros(size(sum_fna_rad_plot));

    non_zero_flux = flux_magnitude_plot > 1e-9;
    u_norm_plot(non_zero_flux) = sum_fna_pol_plot(non_zero_flux) ./ flux_magnitude_plot(non_zero_flux);
    v_norm_plot(non_zero_flux) = sum_fna_rad_plot(non_zero_flux) ./ flux_magnitude_plot(non_zero_flux);
end

function fig = createMainFigure(dirName)
% 创建主图形窗口
    fig = figure('Name', sprintf('Ne离子流模式 - %s', dirName), ...
                 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [1, 1, 10, 7]);
end

function ax = plotFluxBackground(fig, nx_plot, ny_plot, flux_magnitude_plot)
% 绘制通量背景色图
    ax = axes(fig);
    hold(ax, 'on');

    [X_mesh, Y_mesh] = meshgrid(1:nx_plot, 1:ny_plot);
    surf(ax, X_mesh, Y_mesh, zeros(size(X_mesh)), flux_magnitude_plot', 'EdgeColor', 'none');
    shading(ax, 'interp');
    view(ax, 2);

    h_cb = colorbar(ax);
    set(ax, 'ColorScale', 'log');
    set(ax, 'CLim', [2.5e18, 2.5e20]);
    ylabel(h_cb, 'Ne离子总通量大小 (particles/s)', 'FontSize', 16);
    colormap(ax, 'jet');
    set(ax, 'YDir', 'normal');
end

function setupDataCursor(fig, nx_plot, ny_plot, sum_fna_pol_plot, sum_fna_rad_plot, flux_magnitude_plot)
% 设置数据游标
    dcm_obj = datacursormode(fig);
    set(dcm_obj, 'Enable', 'on');
    set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn, nx_plot, ny_plot, sum_fna_pol_plot, sum_fna_rad_plot, flux_magnitude_plot});
end

function plotFlowArrows(ax, nx_plot, ny_plot, u_norm_plot, v_norm_plot)
% 绘制流向箭头
    if nx_plot <= 1 || ny_plot <= 1
        return;
    end

    arrow_scale = 0.4;
    x_centers = (1:(nx_plot-1)) + 0.5;
    y_centers = (1:(ny_plot-1)) + 0.5;
    [X_quiver, Y_quiver] = meshgrid(x_centers, y_centers);

    u_quiver = u_norm_plot(1:nx_plot-1, 1:ny_plot-1);
    v_quiver = v_norm_plot(1:nx_plot-1, 1:ny_plot-1);

    quiver(ax, X_quiver, Y_quiver, u_quiver', v_quiver', arrow_scale, 'k', 'LineWidth', 0.5);
end

function addRegionLabels(ax, nx_plot, ny_plot)
% 添加区域标签
    % 固定区域索引
    isep_idx = 12;
    inner_div_end = 24;
    omp_idx = 41;
    imp_idx = 58;
    outer_div_start = 73;

    % 绘制分隔线
    plot(ax, [inner_div_end + 1, inner_div_end + 1], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [outer_div_start, outer_div_start], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [omp_idx, omp_idx], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [imp_idx, imp_idx], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [1, nx_plot], [isep_idx + 1, isep_idx + 1], 'k-', 'LineWidth', 1.5);

    % 顶部标签
    label_font_size = 16;
    top_y = ny_plot + 1.2;
    text(ax, 1, top_y, 'OT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, inner_div_end, top_y, 'ODE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, omp_idx, top_y, 'OMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, imp_idx, top_y, 'IMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, outer_div_start, top_y, 'IDE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, nx_plot, top_y, 'IT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % 区域标签
    center_x = round(nx_plot / 2);
    core_y = round(isep_idx * 0.6);
    sol_y = isep_idx + round((ny_plot - isep_idx) * 0.65);

    text(ax, center_x, core_y, 'Core', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, center_x, sol_y, 'SOL', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % PFR标签
    pfr_x_left = round(inner_div_end * 0.5);
    pfr_x_right = round(outer_div_start + (nx_plot - outer_div_start) * 0.5);
    text(ax, pfr_x_left, core_y, 'PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, pfr_x_right, core_y, 'PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

    % 分界面标签
    text(ax, center_x, isep_idx + 2, 'Separatrix', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

function setupAxes(ax, nx_plot, ny_plot)
% 设置坐标轴
    isep_idx = 12;
    inner_div_end = 24;
    omp_idx = 41;
    imp_idx = 58;
    outer_div_start = 73;

    xlabel(ax, '$\mathrm{i_x}$ (极向单元索引)', 'FontSize', 18);
    ylabel(ax, '$\mathrm{i_y}$ (径向单元索引)', 'FontSize', 18);

    axis(ax, [1, nx_plot, 1, ny_plot]);
    set(ax, 'XTick', unique(sort([1, inner_div_end, omp_idx, imp_idx, outer_div_start, nx_plot])));
    set(ax, 'YTick', unique(sort([1, isep_idx, ny_plot])));

    box(ax, 'on');
    grid(ax, 'off');
    hold(ax, 'off');
end

function plotSepFluxComparison(sep_flux_data)
% 绘制分界面通量对比图
    if sep_flux_data.valid_cases == 0 || isempty(sep_flux_data.all_flux_data)
        fprintf('无有效分界面通量数据，跳过绘图\n');
        return;
    end

    fig = figure('Name', '分界面杂质径向总通量对比 (主SOL区)', ...
                 'NumberTitle', 'off', 'Color', 'w');
    setupPlotDefaults();

    ax = axes(fig);
    hold(ax, 'on');

    % 主SOL区域范围
    main_sol_start = 25;
    main_sol_end = 72;
    actual_start = max(1, main_sol_start);
    actual_end = min(sep_flux_data.common_nx_plot, main_sol_end);

    if actual_start > actual_end
        fprintf('主SOL区域索引超出范围，跳过绘图\n');
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
    xlabel(ax, '$\mathrm{i_x}$ (主SOL区极向单元索引)');
    ylabel(ax, '杂质(Ne)分界面径向总通量 ($\mathrm{particles \cdot s^{-1}}$)');
    title(ax, '分界面杂质径向总通量沿主SOL区对比');
    grid(ax, 'on');

    % 添加图例
    legend(ax, sep_flux_data.all_dir_names, 'Location', 'best', 'Interpreter', 'none');
    xlim(ax, [x_indices(1) - 0.5, x_indices(end) + 0.5]);

    hold(ax, 'off');

    % 保存图形
    saveFigureWithTimestamp(fig, 'Separatrix_Impurity_Radial_Total_Flux_MainSOL_Comparison');
    fprintf('已保存分界面杂质径向总通量对比图\n');
end