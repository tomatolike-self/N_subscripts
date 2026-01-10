function plot_downstream_pol_profiles_separate_figs(all_radiationData, groupDirs, varargin)
% =========================================================================
% plot_downstream_pol_profiles_separate_figs - 独立Figure模式绘制下游靶板剖面
% =========================================================================
%
% 功能描述：
%   - 以独立Figure方式（而非子图）绘制下游靶板附近的物理量分布
%   - 每个figure使用相同的PaperSize和PlotBox Position，便于直接导出对齐的PDF
%   - 每个group生成8个独立figure：
%     * Inner/Outer Target的电子密度、电子温度、杂质密度、极向热流密度
%
% 输入参数：
%   all_radiationData - 包含辐射数据的元胞数组
%   groupDirs - 元胞数组的元胞数组，每个包含要分组的目录
%   varargin - 可选参数（名值对）:
%       'usePredefinedLegend', true/false (默认: false)
%       'useUnfavBTLegend', true/false (默认: false)
%       'useUnfavBTPowerLegend', true/false (默认: false)
%       'useUnfavBTSequenceLegend', true/false (默认: false)
%       'useCustomExponentLabels', true/false (默认: true)
%       'axisMode', 'fixed'/'auto' (默认: 'fixed') - 轴范围模式
%
% 输出：
%   生成8个独立figure窗口和对应的.fig文件（每个group）
%
% 依赖函数/工具箱：
%   无
%
% 注意事项：
%   - R2019a 兼容性：使用 inputParser，不使用 arguments 块
%   - 氮杂质离子价态索引为 4:10 (N1+ 到 N7+)
%   - 核心改动：使用独立figure替代subplot，统一PaperSize和PlotBox Position
%
% =========================================================================

%% 处理可选输入参数
p = inputParser;
addParameter(p, 'usePredefinedLegend', false, @islogical);
addParameter(p, 'useUnfavBTLegend', false, @islogical);
addParameter(p, 'useUnfavBTPowerLegend', false, @islogical);
addParameter(p, 'useUnfavBTSequenceLegend', false, @islogical);
addParameter(p, 'useCustomExponentLabels', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'axisMode', 'fixed', @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

usePredefinedLegend = p.Results.usePredefinedLegend;
useUnfavBTLegend = p.Results.useUnfavBTLegend;
useUnfavBTPowerLegend = p.Results.useUnfavBTPowerLegend;
useUnfavBTSequenceLegend = p.Results.useUnfavBTSequenceLegend;
useCustomExponentLabels = logical(p.Results.useCustomExponentLabels);
axisMode = lower(char(p.Results.axisMode));
if ~ismember(axisMode, {'fixed','auto'})
    axisMode = 'fixed';
end

%% 统一画布配置（核心：确保所有figure的PaperSize和PlotBox Position一致）
% 与Ne版本多图布局完全一致：14×10 inches figure，子图Position=[0.38, 0.35]
% 实际子图尺寸 = 14×0.38 = 5.32 inches (width) × 10×0.35 = 3.5 inches (height)
paperW = 7.8;    % 画布宽度（左侧1.50 + plotBox 5.32 + 右侧1.0 ≈ 7.8）
paperH = 6.0;    % 画布高度（底1.5 + plotBox 3.5 + 顶部1.0 = 6.0）
plotBoxPos = [1.50, 1.5, 5.32, 3.5];  % [left, bottom, width, height] inches
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
linewidth = 3.0;

%% 网格与索引定义
separatrix_radial_index = 12;
outer_target_j_index = 1;
inner_target_j_index = 96;

% 预定义图例名称
predefined_legend_names = {'$\mathrm{fav.}~B_{\mathrm{T}}$', '$\mathrm{unfav.}~B_{\mathrm{T}}$', '$\mathrm{w/o~drift}$'};
unfav_bt_legend_names = {'$\mathrm{unfav.}~B_{\mathrm{T}}~0.5$', '$\mathrm{unfav.}~B_{\mathrm{T}}~1.0$'};
unfav_bt_power_legend_names = {'$\mathrm{unfav.}~B_{\mathrm{T}}~5.5~\mathrm{MW}$', '$\mathrm{unfav.}~B_{\mathrm{T}}~7~\mathrm{MW}$'};
unfav_bt_sequence_legend_names = {'$\mathrm{unfav.}~B_{\mathrm{T}}~0.5$', '$\mathrm{unfav.}~B_{\mathrm{T}}~1.0$', '$\mathrm{unfav.}~B_{\mathrm{T}}~1.5$', '$\mathrm{unfav.}~B_{\mathrm{T}}~2.0$'};

%% 遍历各组
num_groups = length(groupDirs);

for g = 1:num_groups
    
    currentGroup = groupDirs{g};
    
    % 创建8个独立figure
    fig1 = createUniformFigure('Inner Target ne', g, paperW, paperH);
    ax1 = axes(fig1, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax1, 'on');
    
    fig2 = createUniformFigure('Outer Target ne', g, paperW, paperH);
    ax2 = axes(fig2, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax2, 'on');
    
    fig3 = createUniformFigure('Inner Target Te', g, paperW, paperH);
    ax3 = axes(fig3, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax3, 'on');
    
    fig4 = createUniformFigure('Outer Target Te', g, paperW, paperH);
    ax4 = axes(fig4, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax4, 'on');
    
    fig5 = createUniformFigure('Inner Target n_N', g, paperW, paperH);
    ax5 = axes(fig5, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax5, 'on');
    
    fig6 = createUniformFigure('Outer Target n_N', g, paperW, paperH);
    ax6 = axes(fig6, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax6, 'on');
    
    fig7 = createUniformFigure('Inner Target qpol', g, paperW, paperH);
    ax7 = axes(fig7, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax7, 'on');
    
    fig8 = createUniformFigure('Outer Target qpol', g, paperW, paperH);
    ax8 = axes(fig8, 'Units', 'normalized', 'Position', plotBoxPos_normalized); hold(ax8, 'on');
    
    % 设置所有axes的通用属性
    axList = [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8];
    for ax = axList
        set(ax, 'LineWidth', 1.5);
        set(ax, 'Box', 'on');
        set(ax, 'TickDir', 'in');
        set(ax, 'YScale', 'linear');  % 确保Y轴使用线性刻度
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
    ax5_handles = gobjects(0); ax5_entries = {};
    ax6_handles = gobjects(0); ax6_entries = {};
    ax7_handles = gobjects(0); ax7_entries = {};
    ax8_handles = gobjects(0); ax8_entries = {};
    
    %% 遍历组内目录
    for k = 1:length(currentGroup)
        
        currentDir = currentGroup{k};
        idx_in_all = findDirIndexInRadiationData(all_radiationData, currentDir);
        if idx_in_all < 0
            fprintf('Warning: directory %s not found in all_radiationData.\n', currentDir);
            continue;
        end
        
        dataStruct = all_radiationData{idx_in_all};
        if ~isfield(dataStruct,'plasma') || ~isfield(dataStruct,'gmtry')
            fprintf('Warning: dataStruct for %s missing .plasma or .gmtry\n', currentDir);
            continue;
        end
        
        gmtry = dataStruct.gmtry;
        plasma = dataStruct.plasma;
        fhi_mdf = plasma.fhi_mdf;
        fhe_mdf = plasma.fhe_mdf;
        dirName = dataStruct.dirName;
        
        % 生成图例名称
        if useUnfavBTSequenceLegend
            legend_index = mod(k-1, length(unfav_bt_sequence_legend_names)) + 1;
            simplifiedDirName = unfav_bt_sequence_legend_names{legend_index};
        elseif useUnfavBTPowerLegend
            legend_index = mod(k-1, length(unfav_bt_power_legend_names)) + 1;
            simplifiedDirName = unfav_bt_power_legend_names{legend_index};
        elseif useUnfavBTLegend
            legend_index = mod(k-1, length(unfav_bt_legend_names)) + 1;
            simplifiedDirName = unfav_bt_legend_names{legend_index};
        elseif usePredefinedLegend
            legend_index = mod(k-1, length(predefined_legend_names)) + 1;
            simplifiedDirName = predefined_legend_names{legend_index};
        else
            simplifiedDirName = getShortDirName(dirName);
        end
        
        %% 计算下游方向的物理坐标
        % 外靶板
        Y_down_outer = gmtry.hy(outer_target_j_index+1, 2:end-1);
        W_down_outer = [0.5*Y_down_outer(1), 0.5*(Y_down_outer(2:end)+Y_down_outer(1:end-1))];
        hy_center_outer = cumsum(W_down_outer);
        sep_outer = hy_center_outer(separatrix_radial_index) + 0.5*Y_down_outer(separatrix_radial_index);
        x_outer = hy_center_outer - sep_outer;
        
        % 内靶板
        Y_down_inner = gmtry.hy(inner_target_j_index+1, 2:end-1);
        W_down_inner = [0.5*Y_down_inner(1), 0.5*(Y_down_inner(2:end)+Y_down_inner(1:end-1))];
        hy_center_inner = cumsum(W_down_inner);
        sep_inner = hy_center_inner(separatrix_radial_index) + 0.5*Y_down_inner(separatrix_radial_index);
        x_inner = hy_center_inner - sep_inner;
        
        % 检查必要字段
        if ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev')
            fprintf('Missing fields in plasma: ne / te_ev.\n');
            continue;
        end
        if ~isfield(gmtry, 'gs') || ~isfield(gmtry, 'qz')
            fprintf('Missing fields in gmtry: gs / qz.\n');
            continue;
        end
        
        ne_2D = plasma.ne(2:end-1, 2:end-1);
        te_2D = plasma.te_ev(2:end-1, 2:end-1);
        
        % 计算极向热流密度
        total_heat_pol = fhi_mdf(:,:,1) + fhe_mdf(:,:,1);
        area_pol = gmtry.gs(:,:,1) .* gmtry.qz(:,:,2);
        qpol_full = total_heat_pol ./ area_pol;
        qpol_2D = qpol_full(2:end-1, 2:end-1);
        
        % 计算杂质密度
        if isfield(plasma, 'na')
            n_imp_2D = sum(plasma.na(2:end-1, 2:end-1, 4:10), 3);
        else
            n_imp_2D = zeros(size(ne_2D));
        end
        
        % 分配绘图样式
        dir_color = line_colors(mod(k-1, size(line_colors,1))+1, :);
        plotStyle = {'-', 'Color', dir_color, 'LineWidth', linewidth};
        
        % 绘制数据
        h1 = plot(ax1, x_inner, ne_2D(inner_target_j_index,:), plotStyle{:});
        set(h1, 'UserData', dirName);
        ax1_handles(end+1) = h1; ax1_entries{end+1} = simplifiedDirName;
        
        h2 = plot(ax2, x_outer, ne_2D(outer_target_j_index,:), plotStyle{:});
        set(h2, 'UserData', dirName);
        ax2_handles(end+1) = h2; ax2_entries{end+1} = simplifiedDirName;
        
        h3 = plot(ax3, x_inner, te_2D(inner_target_j_index,:), plotStyle{:});
        set(h3, 'UserData', dirName);
        ax3_handles(end+1) = h3; ax3_entries{end+1} = simplifiedDirName;
        
        h4 = plot(ax4, x_outer, te_2D(outer_target_j_index,:), plotStyle{:});
        set(h4, 'UserData', dirName);
        ax4_handles(end+1) = h4; ax4_entries{end+1} = simplifiedDirName;
        
        h5 = plot(ax5, x_inner, n_imp_2D(inner_target_j_index,:), plotStyle{:});
        set(h5, 'UserData', dirName);
        ax5_handles(end+1) = h5; ax5_entries{end+1} = simplifiedDirName;
        
        h6 = plot(ax6, x_outer, n_imp_2D(outer_target_j_index,:), plotStyle{:});
        set(h6, 'UserData', dirName);
        ax6_handles(end+1) = h6; ax6_entries{end+1} = simplifiedDirName;
        
        h7 = plot(ax7, x_inner, qpol_2D(inner_target_j_index,:), plotStyle{:});
        set(h7, 'UserData', dirName);
        ax7_handles(end+1) = h7; ax7_entries{end+1} = simplifiedDirName;
        
        % 外靶板的极向热流取负值（与Ne版本保持一致）
        h8 = plot(ax8, x_outer, -qpol_2D(outer_target_j_index,:), plotStyle{:});
        set(h8, 'UserData', dirName);
        ax8_handles(end+1) = h8; ax8_entries{end+1} = simplifiedDirName;
    end
    
    %% 设置轴范围
    if strcmp(axisMode, 'auto')
        % 自动模式：X和Y轴都由MATLAB自动调整
        for ax = axList
            set(ax, 'XLimMode', 'auto', 'YLimMode', 'auto');
            set(ax, 'XTickMode', 'auto', 'YTickMode', 'auto');
        end
        % 自动模式完成绑定后，确保首尾有刻度（需要在绑制完成后执行）
        drawnow;  % 先完成绑图才能获取实际的轴范围
        for ax = axList
            % 确保X轴首尾有刻度
            xLimits = xlim(ax);
            xTicks = get(ax, 'XTick');
            if xTicks(1) > xLimits(1)
                xTicks = [xLimits(1), xTicks];
            end
            if xTicks(end) < xLimits(2)
                xTicks = [xTicks, xLimits(2)];
            end
            set(ax, 'XTick', xTicks);
            
            % 确保Y轴首尾有刻度
            yLimits = ylim(ax);
            yTicks = get(ax, 'YTick');
            if yTicks(1) > yLimits(1)
                yTicks = [yLimits(1), yTicks];
            end
            if yTicks(end) < yLimits(2)
                yTicks = [yTicks, yLimits(2)];
            end
            set(ax, 'YTick', yTicks);
        end
    else
        % 固定模式：使用预设范围，并显式设置刻度确保首尾有值
        % Y轴范围和刻度
        ylim(ax1, [0 5e20]); set(ax1, 'YTick', [0, 2.5e20, 5e20]);
        ylim(ax2, [0 5e20]); set(ax2, 'YTick', [0, 2.5e20, 5e20]);
        ylim(ax3, [0 25]); set(ax3, 'YTick', [0, 5, 10, 15, 20, 25]);
        ylim(ax4, [0 25]); set(ax4, 'YTick', [0, 5, 10, 15, 20, 25]);
        ylim(ax5, [0 6e19]); set(ax5, 'YTick', [0, 2e19, 4e19, 6e19]);
        ylim(ax6, [0 6e19]); set(ax6, 'YTick', [0, 2e19, 4e19, 6e19]);
        ylim(ax7, [0 2e6]); set(ax7, 'YTick', [0, 0.5e6, 1e6, 1.5e6, 2e6]);
        ylim(ax8, [0 2e6]); set(ax8, 'YTick', [0, 0.5e6, 1e6, 1.5e6, 2e6]);
        
        % X轴范围和刻度：IT（内靶板）-0.1~0.3，OT（外靶板）-0.1~0.2
        % Inner Target: ax1,ax3,ax5,ax7
        xlim(ax1, [-0.1 0.3]); set(ax1, 'XTick', [-0.1, 0, 0.1, 0.2, 0.3]);
        xlim(ax3, [-0.1 0.3]); set(ax3, 'XTick', [-0.1, 0, 0.1, 0.2, 0.3]);
        xlim(ax5, [-0.1 0.3]); set(ax5, 'XTick', [-0.1, 0, 0.1, 0.2, 0.3]);
        xlim(ax7, [-0.1 0.3]); set(ax7, 'XTick', [-0.1, 0, 0.1, 0.2, 0.3]);
        % Outer Target: ax2,ax4,ax6,ax8
        xlim(ax2, [-0.1 0.2]); set(ax2, 'XTick', [-0.1, 0, 0.1, 0.2]);
        xlim(ax4, [-0.1 0.2]); set(ax4, 'XTick', [-0.1, 0, 0.1, 0.2]);
        xlim(ax6, [-0.1 0.2]); set(ax6, 'XTick', [-0.1, 0, 0.1, 0.2]);
        xlim(ax8, [-0.1 0.2]); set(ax8, 'XTick', [-0.1, 0, 0.1, 0.2]);
    end
    
    %% 绘制分离面参考线
    sepStyle = {'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off'};
    plot(ax1, [0 0], ylim(ax1), sepStyle{:});
    plot(ax2, [0 0], ylim(ax2), sepStyle{:});
    plot(ax3, [0 0], ylim(ax3), sepStyle{:});
    plot(ax4, [0 0], ylim(ax4), sepStyle{:});
    plot(ax5, [0 0], ylim(ax5), sepStyle{:});
    plot(ax6, [0 0], ylim(ax6), sepStyle{:});
    plot(ax7, [0 0], ylim(ax7), sepStyle{:});
    plot(ax8, [0 0], ylim(ax8), sepStyle{:});
    
    %% 设置轴标签
    xLabelInner = '$r - r_{\mathrm{sep}}$ at IT (m)';
    xLabelOuter = '$r - r_{\mathrm{sep}}$ at OT (m)';
    
    xlabel(ax1, xLabelInner, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax1, '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax2, xLabelOuter, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax2, '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax3, xLabelInner, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax3, '$T_{\mathrm{e}}$ (eV)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax4, xLabelOuter, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax4, '$T_{\mathrm{e}}$ (eV)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax5, xLabelInner, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax5, '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax6, xLabelOuter, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax6, '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax7, xLabelInner, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax7, '$q_{\mathrm{pol}}$ (W/m$^{2}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    xlabel(ax8, xLabelOuter, 'FontSize', xlabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    ylabel(ax8, '$q_{\mathrm{pol}}$ (W/m$^{2}$)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    
    %% 设置图例
    legend(ax1, ax1_handles, ax1_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax2, ax2_handles, ax2_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax3, ax3_handles, ax3_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax4, ax4_handles, ax4_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax5, ax5_handles, ax5_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax6, ax6_handles, ax6_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax7, ax7_handles, ax7_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    legend(ax8, ax8_handles, ax8_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', legendsize, 'FontName', fontName);
    
    %% 增强坐标轴刻度字体
    for ax = axList
        set(ax, 'FontName', fontName, 'FontSize', xlabelsize);
    end
    
    %% 自定义指数角标
    if useCustomExponentLabels
        ax1.YAxis.Exponent = 20;
        addExponentLabel(ax1, '$\times 10^{20}$', fontName, ylabelsize);
        ax2.YAxis.Exponent = 20;
        addExponentLabel(ax2, '$\times 10^{20}$', fontName, ylabelsize);
        
        ax5.YAxis.Exponent = 19;
        addExponentLabel(ax5, '$\times 10^{19}$', fontName, ylabelsize);
        ax6.YAxis.Exponent = 19;
        addExponentLabel(ax6, '$\times 10^{19}$', fontName, ylabelsize);
        
        ax7.YAxis.Exponent = 6;
        addExponentLabel(ax7, '$\times 10^{6}$', fontName, ylabelsize);
        ax8.YAxis.Exponent = 6;
        addExponentLabel(ax8, '$\times 10^{6}$', fontName, ylabelsize);
    end
    
    %% 保存各个figure
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
    
    saveFigureWithTimestamp(fig1, sprintf('Inner_ne_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig2, sprintf('Outer_ne_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig3, sprintf('Inner_Te_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig4, sprintf('Outer_Te_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig5, sprintf('Inner_nN_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig6, sprintf('Outer_nN_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig7, sprintf('Inner_qpol_Group%d', g), timestampStr);
    saveFigureWithTimestamp(fig8, sprintf('Outer_qpol_Group%d', g), timestampStr);
    
    fprintf('>>> Finished group %d (Downstream Profiles - Separate Figures Mode) with %d directories.\n', g, length(currentGroup));
    fprintf('    8 figures saved with uniform canvas: %.1f x %.1f inches\n', paperW, paperH);
    
end

fprintf('\nAll groups plotted in separate figures mode.\n');
fprintf('Each figure has identical PaperSize and PlotBox Position for easy alignment.\n');

end


%% ========== 子函数：创建统一配置的figure ==========
function fig = createUniformFigure(titlePrefix, groupNum, paperW, paperH)
figTitle = sprintf('%s - Group %d', titlePrefix, groupNum);
fig = figure('Name', figTitle, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [1 1 paperW paperH], ...
    'PaperUnits', 'inches', 'PaperSize', [paperW paperH], ...
    'PaperPosition', [0 0 paperW paperH]);
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
