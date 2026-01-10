function plot_OMP_IMP_impurity_distribution_separate_figs(all_radiationData, groupDirs, varargin)
% =========================================================================
% plot_OMP_IMP_impurity_distribution_separate_figs - 独立Figure模式绘制OMP/IMP剖面
% =========================================================================
%
% 功能描述：
%   - 以独立Figure方式（而非子图）绘制OMP和IMP处的密度、温度和氮杂质离子密度
%   - 每个figure使用相同的PaperSize和PlotBox Position，便于直接导出对齐的PDF
%   - 适合需要用MATLAB轴工具栏单独导出每个图的场景
%
% 输入参数：
%   all_radiationData - 包含辐射数据的元胞数组
%   groupDirs - 元胞数组的元胞数组，每个包含要分组的目录
%   varargin - 可选参数（名值对）:
%       'usePresetLegends', true/false (默认: false)
%       'useUnfavBTPowerLegend', true/false (默认: false)
%       'useCustomExponentLabels', true/false (默认: true)
%       'xAxisUnit', 'm'/'cm' (默认: 'cm')
%       'usePointLineStyle', true/false (默认: false)
%       'yAxisMode', 'fixed'/'auto' (默认: 'fixed')
%
% 输出：
%   生成4个独立figure窗口和对应的.fig文件
%
% 依赖函数/工具箱：
%   无
%
% 注意事项：
%   - R2019a 兼容性：使用 inputParser，不使用 arguments 块
%   - 氮杂质离子价态索引为 4:10 (N1+ 到 N7+)
%   - 本文件包含 5 个辅助函数，与原版脚本保持一致结构
%   - 核心改动：使用独立figure替代subplot，统一PaperSize和PlotBox Position
%
% =========================================================================

%% 处理可选输入参数
p = inputParser;
addParameter(p, 'usePresetLegends', false, @islogical);
addParameter(p, 'useUnfavBTPowerLegend', false, @islogical);
addParameter(p, 'useCustomExponentLabels', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'xAxisUnit', 'cm', @(x) ischar(x) || isstring(x));
addParameter(p, 'usePointLineStyle', false, @islogical);
addParameter(p, 'yAxisMode', 'fixed', @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

usePresetLegends = p.Results.usePresetLegends;
useUnfavBTPowerLegend = p.Results.useUnfavBTPowerLegend;
useCustomExponentLabels = logical(p.Results.useCustomExponentLabels);
xAxisUnit = lower(char(p.Results.xAxisUnit));
if ~ismember(xAxisUnit, {'m','cm'})
    xAxisUnit = 'cm';
end
usePointLineStyle = p.Results.usePointLineStyle;
yAxisMode = lower(char(p.Results.yAxisMode));
if ~ismember(yAxisMode, {'fixed','auto'})
    yAxisMode = 'fixed';
end

%% 统一画布配置（核心：确保所有figure的PaperSize和PlotBox Position一致）
% 单位：inches
% 与Ne版本多图布局完全一致：14×10 inches figure，子图Position=[0.38, 0.35]
% 实际子图尺寸 = 14×0.38 = 5.32 inches (width) × 10×0.35 = 3.5 inches (height)
paperW = 7.8;               % 画布宽度（左边1.50 + plotBox 5.32 + 右边1.0 ≈ 7.8）
paperH = 6.0;               % 画布高度（底1.5 + plotBox 3.5 + 顶部1.0 = 6.0）
plotBoxPos = [1.50, 1.5, 5.32, 3.5];  % [left, bottom, width, height] inches

% 将plotBox位置转换为归一化坐标（相对于figure）
plotBoxPos_normalized = [plotBoxPos(1)/paperW, plotBoxPos(2)/paperH, ...
    plotBoxPos(3)/paperW, plotBoxPos(4)/paperH];

%% 预定义绘图风格
fontName = 'Times New Roman';
xlabelsize = 36;
ylabelsize = 36;
legendsize = 33;

set(0, 'DefaultAxesFontName', fontName);
set(0, 'DefaultTextFontName', fontName);
set(0, 'DefaultAxesFontSize', xlabelsize);
set(0, 'DefaultTextFontSize', xlabelsize);
set(0, 'DefaultAxesLineWidth', 1.5);
set(0, 'DefaultAxesBox', 'on');

line_colors = lines(20);
line_markers = {'o','s','d','^','v','>','<','p','h','*','+','x'};
linewidth = 3.0;

% 分离面参数
default_sep_color = [0 0 0];
default_sep_style = '--';
default_sep_linewidth = 1.2;
pointline_sep_color = [0.6 0.0 0.0];
pointline_sep_style = '--';
pointline_sep_linewidth = 3.0;

preset_legend_names = {'$\mathrm{fav.}~B_{\mathrm{T}}$', '$\mathrm{unfav.}~B_{\mathrm{T}}$', '$\mathrm{w/o~drift}$'};
unfav_bt_power_legend_names = {'$\mathrm{unfav.}~B_{\mathrm{T}}~5.5~\mathrm{MW}$', '$\mathrm{unfav.}~B_{\mathrm{T}}~7~\mathrm{MW}$'};

% 获取X轴配置
[axisScale, xAxisLabel, omp_xlim, omp_xticks, imp_xlim, imp_xticks] = getXAxisConfiguration(xAxisUnit);

if usePointLineStyle
    sep_color = pointline_sep_color;
    sep_style = pointline_sep_style;
    sep_linewidth = pointline_sep_linewidth;
else
    sep_color = default_sep_color;
    sep_style = default_sep_style;
    sep_linewidth = default_sep_linewidth;
end

%% 遍历每个组
for g = 1:length(groupDirs)
    currentGroup = groupDirs{g};
    
    % 创建4个独立figure（统一画布和PlotBox配置）
    % Figure 1: OMP ne
    fig1 = createUniformFigure('OMP ne - Group', g, paperW, paperH);
    ax1 = axes(fig1, 'Units', 'normalized', 'Position', plotBoxPos_normalized);
    hold(ax1, 'on');
    
    % Figure 2: OMP Te
    fig2 = createUniformFigure('OMP Te - Group', g, paperW, paperH);
    ax2 = axes(fig2, 'Units', 'normalized', 'Position', plotBoxPos_normalized);
    hold(ax2, 'on');
    
    % Figure 3: OMP n_N
    fig3 = createUniformFigure('OMP n_N - Group', g, paperW, paperH);
    ax3 = axes(fig3, 'Units', 'normalized', 'Position', plotBoxPos_normalized);
    hold(ax3, 'on');
    
    % Figure 4: IMP n_N
    fig4 = createUniformFigure('IMP n_N - Group', g, paperW, paperH);
    ax4 = axes(fig4, 'Units', 'normalized', 'Position', plotBoxPos_normalized);
    hold(ax4, 'on');
    
    % 设置所有axes的通用属性
    axList = [ax1, ax2, ax3, ax4];
    for ax = axList
        set(ax, 'LineWidth', 1.5);
        set(ax, 'Box', 'on');
        set(ax, 'TickDir', 'in');
        grid(ax, 'on');
        set(ax, 'GridLineStyle', ':');
        set(ax, 'GridAlpha', 0.25);
        set(ax, 'ActivePositionProperty', 'position');
    end
    
    % 初始化图例参数
    ax1_handles = gobjects(0); ax1_entries = {};
    ax2_handles = gobjects(0); ax2_entries = {};
    ax3_handles = gobjects(0); ax3_entries = {};
    ax4_handles = gobjects(0); ax4_entries = {};
    
    %% 遍历组内目录
    for k = 1:length(currentGroup)
        currentDir = currentGroup{k};
        idx = findDirIndexInRadiationData(all_radiationData, currentDir);
        if idx < 0
            fprintf('Warning: directory %s not found in all_radiationData.\n', currentDir);
            continue;
        end
        data = all_radiationData{idx};
        
        % 获取物理坐标
        gmtry = data.gmtry;
        
        outer_j_original = 42;
        inner_j_original = 59;
        outer_j_cropped = outer_j_original - 1;
        inner_j_cropped = inner_j_original - 1;
        
        [x_upstream_omp, ~] = calculate_separatrix_coordinates(gmtry, outer_j_original);
        [x_upstream_imp, ~] = calculate_separatrix_coordinates(gmtry, inner_j_original);
        
        x_upstream_omp_plot = x_upstream_omp * axisScale;
        x_upstream_imp_plot = x_upstream_imp * axisScale;
        
        ne_2D = data.plasma.ne(2:end-1, 2:end-1);
        te_2D = data.plasma.te_ev(2:end-1, 2:end-1);
        na_2D = data.plasma.na(2:end-1, 2:end-1, :);
        
        ne_omp = ne_2D(outer_j_cropped, :);
        te_omp = te_2D(outer_j_cropped, :);
        n_imp_tot_omp = sum(na_2D(outer_j_cropped, :, 4:10), 3);
        n_imp_tot_imp = sum(na_2D(inner_j_cropped, :, 4:10), 3);
        
        % 获取图例名称
        if useUnfavBTPowerLegend
            legend_index = mod(k-1, length(unfav_bt_power_legend_names)) + 1;
            shortName = unfav_bt_power_legend_names{legend_index};
        elseif usePresetLegends
            legend_index = mod(k-1, length(preset_legend_names)) + 1;
            shortName = preset_legend_names{legend_index};
        else
            shortName = getShortDirName(data.dirName);
        end
        
        dir_color = line_colors(mod(k-1, size(line_colors,1))+1, :);
        
        if usePointLineStyle
            marker_idx = mod(k-1, length(line_markers)) + 1;
            plotStyle = {'-', 'Color', dir_color, 'LineWidth', linewidth, ...
                'Marker', line_markers{marker_idx}, 'MarkerSize', 9, ...
                'MarkerFaceColor', dir_color, 'MarkerEdgeColor', dir_color};
        else
            plotStyle = {'-', 'Color', dir_color, 'LineWidth', linewidth};
        end
        
        % 绘制数据
        h1 = plot(ax1, x_upstream_omp_plot, ne_omp, plotStyle{:});
        set(h1, 'UserData', currentDir);
        ax1_handles(end+1) = h1;
        ax1_entries{end+1} = shortName;
        
        h2 = plot(ax2, x_upstream_omp_plot, te_omp, plotStyle{:});
        set(h2, 'UserData', currentDir);
        ax2_handles(end+1) = h2;
        ax2_entries{end+1} = shortName;
        
        h3 = plot(ax3, x_upstream_omp_plot, n_imp_tot_omp, plotStyle{:});
        set(h3, 'UserData', currentDir);
        ax3_handles(end+1) = h3;
        ax3_entries{end+1} = shortName;
        
        h4 = plot(ax4, x_upstream_imp_plot, n_imp_tot_imp, plotStyle{:});
        set(h4, 'UserData', currentDir);
        ax4_handles(end+1) = h4;
        ax4_entries{end+1} = shortName;
    end
    
    %% 设置Y轴范围
    if strcmp(yAxisMode, 'auto')
        set(ax1, 'YLimMode', 'auto', 'YTickMode', 'auto');
        set(ax2, 'YLimMode', 'auto', 'YTickMode', 'auto');
        set(ax3, 'YLimMode', 'auto', 'YTickMode', 'auto');
        set(ax4, 'YLimMode', 'auto', 'YTickMode', 'auto');
    else
        ylim(ax1, [1e19, 3e19]);
        ylim(ax2, [0, 400]);
        ylim(ax3, [2e17, 6e17]);
        ylim(ax4, [1e17, 7e17]);
        
        set(ax1, 'YTick', [1e19, 2e19, 3e19]);
        set(ax2, 'YTick', [0, 100, 200, 300, 400]);
        set(ax3, 'YTick', [2e17, 4e17, 6e17]);
        set(ax4, 'YTick', [1e17, 4e17, 7e17]);
    end
    
    %% 绘制分离面参考线
    plot(ax1, [0 0], ylim(ax1), sep_style, 'Color', sep_color, 'LineWidth', sep_linewidth, 'HandleVisibility', 'off');
    plot(ax2, [0 0], ylim(ax2), sep_style, 'Color', sep_color, 'LineWidth', sep_linewidth, 'HandleVisibility', 'off');
    plot(ax3, [0 0], ylim(ax3), sep_style, 'Color', sep_color, 'LineWidth', sep_linewidth, 'HandleVisibility', 'off');
    plot(ax4, [0 0], ylim(ax4), sep_style, 'Color', sep_color, 'LineWidth', sep_linewidth, 'HandleVisibility', 'off');
    
    %% 设置X轴范围和刻度
    xlim(ax1, omp_xlim); set(ax1, 'XTick', omp_xticks);
    xlim(ax2, omp_xlim); set(ax2, 'XTick', omp_xticks);
    xlim(ax3, omp_xlim); set(ax3, 'XTick', omp_xticks);
    xlim(ax4, imp_xlim); set(ax4, 'XTick', imp_xticks);
    
    %% 设置轴标签
    xAxisLabel_omp = strrep(xAxisLabel, '$r - r_{\mathrm{sep}}$', '$r - r_{\mathrm{sep}}~\mathrm{at~OMP}$');
    xAxisLabel_imp = strrep(xAxisLabel, '$r - r_{\mathrm{sep}}$', '$r - r_{\mathrm{sep}}~\mathrm{at~IMP}$');
    
    xlabel(ax1, xAxisLabel_omp, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax1, '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax2, xAxisLabel_omp, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax2, '$T_{\mathrm{e}}$ (eV)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax3, xAxisLabel_omp, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax3, '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax4, xAxisLabel_imp, 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax4, '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    %% 设置图例
    legend(ax1, ax1_handles, ax1_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax2, ax2_handles, ax2_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax3, ax3_handles, ax3_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax4, ax4_handles, ax4_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    
    %% 增强坐标轴刻度字体
    set(ax1, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax2, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax3, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax4, 'FontName', fontName, 'FontSize', xlabelsize);
    
    %% 自定义指数角标
    if useCustomExponentLabels
        ax1.YAxis.Exponent = 19;
        addExponentLabel(ax1, '$\times 10^{19}$', fontName, ylabelsize);
        
        ax3.YAxis.Exponent = 17;
        addExponentLabel(ax3, '$\times 10^{17}$', fontName, ylabelsize);
        
        ax4.YAxis.Exponent = 17;
        addExponentLabel(ax4, '$\times 10^{17}$', fontName, ylabelsize);
    end
    
    %% 保存各个figure
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
    
    saveFigureWithTimestamp(fig1, sprintf('OMP_ne_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig2, sprintf('OMP_Te_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig3, sprintf('OMP_nN_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig4, sprintf('IMP_nN_Group%d', g), timestampStr);
    
    fprintf('>>> Finished group %d (Separate Figures Mode) with %d directories.\n', g, length(currentGroup));
    fprintf('    4 figures saved with uniform canvas: %.1f x %.1f inches\n', paperW, paperH);
end

fprintf('\nAll groups plotted in separate figures mode.\n');
fprintf('Each figure has identical PaperSize and PlotBox Position for easy alignment.\n');
end


%% ========== 子函数：创建统一配置的figure ==========
function fig = createUniformFigure(titlePrefix, groupNum, paperW, paperH)
% 创建具有统一画布配置的figure
figTitle = sprintf('%s %d', titlePrefix, groupNum);
fig = figure('Name', figTitle, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [1 1 paperW paperH], ...
    'PaperUnits', 'inches', 'PaperSize', [paperW paperH], ...
    'PaperPosition', [0 0 paperW paperH]);
end


%% ========== 子函数：获取X轴配置 ==========
function [scaleFactor, axisLabel, omp_xlim, omp_xticks, imp_xlim, imp_xticks] = getXAxisConfiguration(unitStr)
switch unitStr
    case 'cm'
        scaleFactor = 100;
        axisLabel = '$r - r_{\mathrm{sep}}$ (cm)';
        omp_xlim = [-3, 3];
        omp_xticks = -3:1:3;
        imp_xlim = [-6, 6];
        imp_xticks = -6:2:6;
    otherwise
        scaleFactor = 1;
        axisLabel = '$r - r_{\mathrm{sep}}$ (m)';
        omp_xlim = [-0.03, 0.03];
        omp_xticks = -0.03:0.01:0.03;
        imp_xlim = [-0.06, 0.06];
        imp_xticks = -0.06:0.02:0.06;
end
end


%% ========== 子函数：计算分离面坐标 ==========
function [x_upstream, separatrix] = calculate_separatrix_coordinates(gmtry, plane_j)
separatrix_radial_index = 12;
Y = gmtry.hy(plane_j+1, 2:end-1);
W = [0.5*Y(1), 0.5*(Y(2:end)+Y(1:end-1))];
hy_center = cumsum(W);
separatrix = hy_center(separatrix_radial_index) + 0.5*Y(separatrix_radial_index);
x_upstream = hy_center - separatrix;
end


%% ========== 子函数：在radiationData中查找目录索引 ==========
function idx = findDirIndexInRadiationData(all_radiationData, dirName)
idx = -1;
for i = 1:length(all_radiationData)
    if strcmp(all_radiationData{i}.dirName, dirName)
        idx = i;
        return;
    end
end
end


%% ========== 子函数：获取短目录名 ==========
function shortName = getShortDirName(fullPath)
parts = strsplit(fullPath, filesep);
shortName = parts{end};
end


%% ========== 子函数：添加自定义指数角标 ==========
function addExponentLabel(ax, exponent_str, fontName, fontSize)
if isprop(ax, 'YAxis') && isprop(ax.YAxis, 'SecondaryLabel')
    ax.YAxis.SecondaryLabel.String = '';
    ax.YAxis.SecondaryLabel.Visible = 'off';
end
delete(findall(ax, 'Tag', 'CustomExponentLabel'));
text(ax, 0.02, 1.02, exponent_str, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', ...
    'Interpreter', 'latex', ...
    'FontName', fontName, ...
    'FontSize', fontSize, ...
    'Tag', 'CustomExponentLabel');
end


%% ========== 子函数：保存figure ==========
function saveFigureWithTimestamp(fig, baseName, timestampStr)
figure(fig);
set(fig, 'PaperPositionMode', 'manual');
outFile = sprintf('%s_%s.fig', baseName, timestampStr);
savefig(fig, outFile);
fprintf('Figure saved: %s\n', outFile);
end
