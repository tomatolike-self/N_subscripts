function plot_downstream_pol_profiles(all_radiationData, groupDirs, varargin)
% =========================================================================
% plot_downstream_pol_profiles - 绘制下游靶板附近的电子密度、温度、杂质密度和热流密度分布
% =========================================================================
%
% 功能描述：
%   - 按"组"为单位绘制下游靶板附近的电子密度、电子温度、杂质密度和极向热流密度的极向分布
%   - 每个 group 生成两个 figure：
%     * Figure 1: 内外靶板的电子密度和电子温度 (2×2 布局)
%     * Figure 2: 内外靶板的杂质密度和极向热流密度分布 (2×2 布局)
%
% 输入：
%   all_radiationData : cell 数组，每个元素包含:
%       .dirName  (string)  => 当前算例的全路径/标识
%       .gmtry    (struct)  => 包含 crx/cry/hx/hy/vol 等网格信息
%       .plasma   (struct)  => 包含 ne, te_ev, ti_ev 等
%
%   groupDirs : cell 数组 => { Group1Dirs, Group2Dirs, ... }
%
%   varargin: 可选参数（名值对）:
%       'usePredefinedLegend', true/false (默认: false)
%       'useUnfavBTLegend', true/false (默认: false)
%       'useUnfavBTPowerLegend', true/false (默认: false)
%       'useUnfavBTSequenceLegend', true/false (默认: false)
%       'useCustomExponentLabels', true/false (默认: true)
%
% 输出：
%   本函数无显式返回值，每个 group 生成 2 个图形
%
% 依赖函数/工具箱：
%   无
%
% 注意事项：
%   - R2019a 兼容性：使用 inputParser 处理可选参数
%   - 氮杂质离子价态索引为 4:10 (N1+ 到 N7+)
%   - 本文件包含 4 个辅助函数；拆分理由：与Ne脚本一致，便于维护
%
% =========================================================================

%% 处理可选输入参数
p = inputParser;
addParameter(p, 'usePredefinedLegend', false, @islogical);
addParameter(p, 'useUnfavBTLegend', false, @islogical);
addParameter(p, 'useUnfavBTPowerLegend', false, @islogical);
addParameter(p, 'useUnfavBTSequenceLegend', false, @islogical);
addParameter(p, 'useCustomExponentLabels', true, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});

usePredefinedLegend = p.Results.usePredefinedLegend;
useUnfavBTLegend = p.Results.useUnfavBTLegend;
useUnfavBTPowerLegend = p.Results.useUnfavBTPowerLegend;
useUnfavBTSequenceLegend = p.Results.useUnfavBTSequenceLegend;
useCustomExponentLabels = logical(p.Results.useCustomExponentLabels);

%% 预定义绘图风格（与Ne脚本保持一致）
fontName = 'Times New Roman';
xlabelsize = 36;    % 与Ne脚本一致
ylabelsize = 36;
legendsize = 33;

% 设置默认字体
set(0, 'DefaultAxesFontName', fontName);
set(0, 'DefaultTextFontName', fontName);
set(0, 'DefaultAxesFontSize', xlabelsize);
set(0, 'DefaultTextFontSize', xlabelsize);

% 设置坐标轴线宽和框线风格
set(0, 'DefaultAxesLineWidth', 1.5);
set(0, 'DefaultAxesBox', 'on');

% 颜色定义
line_colors = lines(20);

% 线宽设置
linewidth = 3.0;

%% 网格与索引定义
% 网格说明：
% - 原始网格（包含保护单元）：98×28
% - 裁剪网格（去除保护单元）：96×26，对应原始网格(2:97, 2:27)
% - 内靶板：原始网格97号 → 裁剪网格96号
% - 外靶板：原始网格2号 → 裁剪网格1号
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

for g = 1 : num_groups
    
    currentGroup = groupDirs{g};
    
    %% 创建第一个 figure - 电子密度和电子温度
    figTitle1 = sprintf('Group %d: Target ne & Te Profiles', g);
    fig1 = figure('Name', figTitle1, 'NumberTitle', 'off', 'Color','w', ...
        'Units', 'inches', 'Position', [0.5 0.5 18 12]);
    
    ax1  = subplot(2,2,1); hold(ax1,'on'); % Inner Target, ne
    ax2  = subplot(2,2,2); hold(ax2,'on'); % Outer Target, ne
    ax3  = subplot(2,2,3); hold(ax3,'on'); % Inner Target, te
    ax4  = subplot(2,2,4); hold(ax4,'on'); % Outer Target, te
    
    % 设置子图位置（与plot_OMP_IMP_impurity_distribution.m保持一致）
    % Position格式: [left bottom width height]
    set(ax1, 'Position', [0.10 0.58 0.36 0.34]); % 左上
    set(ax2, 'Position', [0.56 0.58 0.36 0.34]); % 右上
    set(ax3, 'Position', [0.10 0.10 0.36 0.34]); % 左下
    set(ax4, 'Position', [0.56 0.10 0.36 0.34]); % 右下
    
    % 设置坐标轴属性并添加白边控制
    axList1 = [ax1, ax2, ax3, ax4];
    for ax = axList1
        set(ax, 'Units', 'normalized');
        set(ax, 'ActivePositionProperty', 'position'); % 锁定轴框大小
        set(ax, 'LineWidth', 1.5);
        set(ax, 'Box', 'on');
        set(ax, 'TickDir', 'in');
        grid(ax, 'on');
        set(ax, 'GridLineStyle', ':');
        set(ax, 'GridAlpha', 0.25);
        set(ax, 'LooseInset', [0.12, 0.12, 0.05, 0.05]); % 固定边距
        
        % 强制统一 Y 轴刻度显示格式
        if ax == ax1 || ax == ax2
            ytickformat(ax, '%.1f');
        else
            ytickformat(ax, '%.0f');
        end
        
        % 注意：原先的 ghost 占位符已删除
        % 统一画布导出使用固定 PaperSize/PaperPosition，不需要 ghost 文本
    end
    
    %% 创建第二个 figure - 杂质密度和极向热流密度
    figTitle2 = sprintf('Group %d: Target Impurity & Poloidal Heat Flux Profiles', g);
    fig2 = figure('Name', figTitle2, 'NumberTitle', 'off', 'Color','w', ...
        'Units', 'inches', 'Position', [19 0.5 18 12]);
    
    ax5  = subplot(2,2,1); hold(ax5,'on'); % Inner Target, impurity density
    ax6  = subplot(2,2,2); hold(ax6,'on'); % Outer Target, impurity density
    ax7  = subplot(2,2,3); hold(ax7,'on'); % Inner Target, poloidal heat flux density
    ax8  = subplot(2,2,4); hold(ax8,'on'); % Outer Target, poloidal heat flux density
    
    % 设置子图位置（与plot_OMP_IMP_impurity_distribution.m保持一致）
    set(ax5, 'Position', [0.10 0.58 0.36 0.34]); % 左上
    set(ax6, 'Position', [0.56 0.58 0.36 0.34]); % 右上
    set(ax7, 'Position', [0.10 0.10 0.36 0.34]); % 左下
    set(ax8, 'Position', [0.56 0.10 0.36 0.34]); % 右下
    
    axList2 = [ax5, ax6, ax7, ax8];
    for ax = axList2
        set(ax, 'Units', 'normalized');
        set(ax, 'ActivePositionProperty', 'position');
        set(ax, 'LineWidth', 1.5);
        set(ax, 'Box', 'on');
        set(ax, 'TickDir', 'in');
        grid(ax, 'on');
        set(ax, 'GridLineStyle', ':');
        set(ax, 'GridAlpha', 0.25);
        set(ax, 'LooseInset', [0.12, 0.12, 0.05, 0.05]);
        
        % 强制统一 Y 轴刻度显示格式
        ytickformat(ax, '%.1f');
        
        % 注意：原先的 ghost 占位符已删除
        % 统一画布导出使用固定 PaperSize/PaperPosition，不需要 ghost 文本
    end
    
    % 初始化 legend 相关的 cell 数组
    ax1_handles = gobjects(0); ax1_legend_entries = {};
    ax2_handles = gobjects(0); ax2_legend_entries = {};
    ax3_handles = gobjects(0); ax3_legend_entries = {};
    ax4_handles = gobjects(0); ax4_legend_entries = {};
    ax5_handles = gobjects(0); ax5_legend_entries = {};
    ax6_handles = gobjects(0); ax6_legend_entries = {};
    ax7_handles = gobjects(0); ax7_legend_entries = {};
    ax8_handles = gobjects(0); ax8_legend_entries = {};
    
    %% 遍历本组内的各算例目录
    for k = 1 : length(currentGroup)
        
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
        
        gmtry  = dataStruct.gmtry;
        plasma = dataStruct.plasma;
        fhi_mdf = plasma.fhi_mdf;
        fhe_mdf = plasma.fhe_mdf;
        dirName= dataStruct.dirName;
        
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
        Y_down_outer_target = gmtry.hy(outer_target_j_index+1,2:end-1);
        W_down_outer_target = [0.5*Y_down_outer_target(1), 0.5*(Y_down_outer_target(2:end)+Y_down_outer_target(1:end-1))];
        hy_downstream_center_outer_target = cumsum(W_down_outer_target);
        separatrix_downstream_outer_target = hy_downstream_center_outer_target(separatrix_radial_index) + 0.5*Y_down_outer_target(separatrix_radial_index);
        x_downstream_outer_target = hy_downstream_center_outer_target - separatrix_downstream_outer_target;
        
        % 内靶板
        Y_down_inner_target = gmtry.hy(inner_target_j_index+1,2:end-1);
        W_down_inner_target = [0.5*Y_down_inner_target(1), 0.5*(Y_down_inner_target(2:end)+Y_down_inner_target(1:end-1))];
        hy_downstream_center_inner_target = cumsum(W_down_inner_target);
        separatrix_downstream_inner_target = hy_downstream_center_inner_target(separatrix_radial_index) + 0.5*Y_down_inner_target(separatrix_radial_index);
        x_downstream_inner_target = hy_downstream_center_inner_target - separatrix_downstream_inner_target;
        
        % 检查必要字段
        if ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev') || ~isfield(plasma, 'fhi_mdf') || ~isfield(plasma, 'fhe_mdf')
            fprintf('Missing fields in plasma: ne / te_ev / fhi_mdf / fhe_mdf.\n');
            continue;
        end
        if ~isfield(gmtry, 'gs') || ~isfield(gmtry, 'qz')
            fprintf('Missing fields in gmtry: gs / qz.\n');
            continue;
        end
        
        ne_2D = plasma.ne(2:end-1,2:end-1);
        te_2D = plasma.te_ev(2:end-1,2:end-1);
        
        % 计算极向热流密度
        total_heat_pol_full = fhi_mdf(:,:,1) + fhe_mdf(:,:,1);
        area_pol_full = gmtry.gs(:,:,1) .* gmtry.qz(:,:,2);
        poloidal_heat_flux_density_full = total_heat_pol_full ./ area_pol_full;
        poloidal_heat_flux_density_2D = poloidal_heat_flux_density_full(2:end-1,2:end-1);
        
        % 计算杂质密度（N1+到N7+，索引4-10）
        if isfield(plasma, 'na')
            impurity_density_total = sum(plasma.na(2:end-1,2:end-1,4:10), 3);
        else
            fprintf('Warning: plasma.na field not found for impurity calculation in %s\n', dirName);
            impurity_density_total = zeros(size(ne_2D));
        end
        
        % 分配绘图样式
        dir_color  = line_colors(mod(k-1,size(line_colors,1))+1,:);
        plotStyle  = {'-','Color', dir_color, 'LineWidth',linewidth};
        
        %% Figure 1: 电子密度和电子温度
        h1 = plot(ax1, x_downstream_inner_target, ne_2D(inner_target_j_index,:), plotStyle{:});
        set(h1, 'DisplayName', simplifiedDirName);
        set(h1, 'UserData', dirName);
        ax1_handles(end+1) = h1; ax1_legend_entries{end+1} = simplifiedDirName;
        
        h2 = plot(ax2, x_downstream_outer_target, ne_2D(outer_target_j_index,:), plotStyle{:});
        set(h2,'UserData', dirName);
        ax2_handles(end+1) = h2; ax2_legend_entries{end+1} = simplifiedDirName;
        
        h3 = plot(ax3, x_downstream_inner_target, te_2D(inner_target_j_index,:), plotStyle{:});
        set(h3,'UserData', dirName);
        ax3_handles(end+1) = h3; ax3_legend_entries{end+1} = simplifiedDirName;
        
        h4 = plot(ax4, x_downstream_outer_target, te_2D(outer_target_j_index,:), plotStyle{:});
        set(h4,'UserData', dirName);
        ax4_handles(end+1) = h4; ax4_legend_entries{end+1} = simplifiedDirName;
        
        %% Figure 2: 杂质密度和极向热流密度
        h5 = plot(ax5, x_downstream_inner_target, impurity_density_total(inner_target_j_index,:), plotStyle{:});
        set(h5,'UserData', dirName);
        ax5_handles(end+1) = h5; ax5_legend_entries{end+1} = simplifiedDirName;
        
        h6 = plot(ax6, x_downstream_outer_target, impurity_density_total(outer_target_j_index,:), plotStyle{:});
        set(h6,'UserData', dirName);
        ax6_handles(end+1) = h6; ax6_legend_entries{end+1} = simplifiedDirName;
        
        h7 = plot(ax7, x_downstream_inner_target, poloidal_heat_flux_density_2D(inner_target_j_index,:), plotStyle{:});
        set(h7,'UserData', dirName);
        ax7_handles(end+1) = h7; ax7_legend_entries{end+1} = simplifiedDirName;
        
        h8 = plot(ax8, x_downstream_outer_target, poloidal_heat_flux_density_2D(outer_target_j_index,:), plotStyle{:});
        set(h8,'UserData', dirName);
        ax8_handles(end+1) = h8; ax8_legend_entries{end+1} = simplifiedDirName;
        
    end % 结束目录遍历
    
    %% Figure 1: 完成设置
    figure(fig1);
    
    % 设置Y轴范围
    ylim(ax1, [0 5e20]);
    ylim(ax2, [0 5e20]);
    ylim(ax3, [0 25]);
    ylim(ax4, [0 25]);
    
    % 绘制分离面参考线
    plot(ax1, [0 0], ylim(ax1),'k--','LineWidth',1.2,'HandleVisibility','off');
    plot(ax2, [0 0], ylim(ax2),'k--','LineWidth',1.2,'HandleVisibility','off');
    plot(ax3, [0 0], ylim(ax3),'k--','LineWidth',1.2,'HandleVisibility','off');
    plot(ax4, [0 0], ylim(ax4),'k--','LineWidth',1.2,'HandleVisibility','off');
    
    % 同步左右两侧的y轴范围
    linkaxes([ax1, ax2], 'y');
    linkaxes([ax3, ax4], 'y');
    
    % 设置标签
    xlabel(ax1,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax1,'$n_{\mathrm{e}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    xlabel(ax2,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax2,'$n_{\mathrm{e}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    xlabel(ax3,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax3,'$T_{\mathrm{e}}$ (eV)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    xlabel(ax4,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax4,'$T_{\mathrm{e}}$ (eV)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    
    % 设置图例
    legend(ax1, ax1_handles, ax1_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    legend(ax2, ax2_handles, ax2_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    legend(ax3, ax3_handles, ax3_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    legend(ax4, ax4_handles, ax4_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    
    % 增强坐标轴刻度字体
    set(ax1, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax2, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax3, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax4, 'FontName', fontName, 'FontSize', xlabelsize);
    
    % 自定义指数角标
    if useCustomExponentLabels
        ax1.YAxis.Exponent = 20;
        addExponentLabel(ax1, '$\times 10^{20}$', fontName, ylabelsize);
        ax2.YAxis.Exponent = 20;
        addExponentLabel(ax2, '$\times 10^{20}$', fontName, ylabelsize);
        % Te子图使用不可见占位符
        addExponentLabel(ax3, '$\vphantom{\times 10^{20}}$', fontName, ylabelsize);
        addExponentLabel(ax4, '$\vphantom{\times 10^{20}}$', fontName, ylabelsize);
    end
    
    dcm1 = datacursormode(fig1);
    set(dcm1,'UpdateFcn',@myDataCursorUpdateFcn);
    
    saveFigureWithTimestamp(sprintf('target_ne_te_profiles_group%d', g));
    
    %% Figure 2: 完成设置
    figure(fig2);
    
    % 设置Y轴范围
    ylim(ax5, [0 6e19]);
    ylim(ax6, [0 6e19]);
    ylim(ax7, [-2e6 2e6]);
    ylim(ax8, [-2e6 2e6]);
    
    % 绘制分离面参考线
    plot(ax5, [0 0], ylim(ax5),'k--','LineWidth',1.2,'HandleVisibility','off');
    plot(ax6, [0 0], ylim(ax6),'k--','LineWidth',1.2,'HandleVisibility','off');
    plot(ax7, [0 0], ylim(ax7),'k--','LineWidth',1.2,'HandleVisibility','off');
    plot(ax8, [0 0], ylim(ax8),'k--','LineWidth',1.2,'HandleVisibility','off');
    
    % 同步左右两侧的y轴范围
    linkaxes([ax5, ax6], 'y');
    linkaxes([ax7, ax8], 'y');
    
    % 设置标签
    xlabel(ax5,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax5,'$n_{\mathrm{N}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    xlabel(ax6,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax6,'$n_{\mathrm{N}}$ (m$^{-3}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    xlabel(ax7,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax7,'$q_{\mathrm{pol}}$ (W/m$^{2}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    xlabel(ax8,'$r - r_{\mathrm{sep}}$ (m)','FontSize',xlabelsize,'FontName',fontName,'Interpreter','latex');
    ylabel(ax8,'$q_{\mathrm{pol}}$ (W/m$^{2}$)','FontSize',ylabelsize,'FontName',fontName,'Interpreter','latex');
    
    % 设置图例
    legend(ax5, ax5_handles, ax5_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    legend(ax6, ax6_handles, ax6_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    legend(ax7, ax7_handles, ax7_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    legend(ax8, ax8_handles, ax8_legend_entries, 'Location','northwest','Interpreter','latex','FontSize',legendsize,'FontName',fontName);
    
    % 增强坐标轴刻度字体
    set(ax5, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax6, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax7, 'FontName', fontName, 'FontSize', xlabelsize);
    set(ax8, 'FontName', fontName, 'FontSize', xlabelsize);
    
    % 自定义指数角标
    if useCustomExponentLabels
        ax5.YAxis.Exponent = 19;
        addExponentLabel(ax5, '$\times 10^{19}$', fontName, ylabelsize);
        ax6.YAxis.Exponent = 19;
        addExponentLabel(ax6, '$\times 10^{19}$', fontName, ylabelsize);
        ax7.YAxis.Exponent = 6;
        addExponentLabel(ax7, '$\times 10^{6}$', fontName, ylabelsize);
        ax8.YAxis.Exponent = 6;
        addExponentLabel(ax8, '$\times 10^{6}$', fontName, ylabelsize);
    end
    
    dcm2 = datacursormode(fig2);
    set(dcm2,'UpdateFcn',@myDataCursorUpdateFcn);
    
    saveFigureWithTimestamp(sprintf('target_impurity_poloidal_heatflux_profiles_group%d', g));
    
    %% 统一画布PDF导出（用于LaTeX拼版对齐）
    drawnow;
    
    % 设置输出目录
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
    outDir1 = fullfile(pwd, sprintf('export_downstream_ne_Te_Group%d_%s', g, timestampStr));
    outDir2 = fullfile(pwd, sprintf('export_downstream_nN_qpol_Group%d_%s', g, timestampStr));
    
    % Figure 1: 电子密度和电子温度
    axListExport1 = [ax1 ax2 ax3 ax4];
    fileNamesExport1 = {
        sprintf('Inner_ne_Group%d', g), ...
        sprintf('Outer_ne_Group%d', g), ...
        sprintf('Inner_Te_Group%d', g), ...
        sprintf('Outer_Te_Group%d', g)
        };
    % 先清除函数缓存，确保使用最新版本
    clear export_axes_uniform_pdf
    export_axes_uniform_pdf(axListExport1, outDir1, fileNamesExport1, ...
        'ExtraPaddingInches', [0.08 0.08 0.08 0.18], ...
        'UseLoose', true, 'Renderer', 'painters');
    
    % Figure 2: 杂质密度和极向热流密度
    axListExport2 = [ax5 ax6 ax7 ax8];
    fileNamesExport2 = {
        sprintf('Inner_nN_Group%d', g), ...
        sprintf('Outer_nN_Group%d', g), ...
        sprintf('Inner_qpol_Group%d', g), ...
        sprintf('Outer_qpol_Group%d', g)
        };
    export_axes_uniform_pdf(axListExport2, outDir2, fileNamesExport2, ...
        'ExtraPaddingInches', [0.08 0.08 0.08 0.18], ...
        'UseLoose', true, 'Renderer', 'painters');
    
    fprintf('>>> Finished group %d (Target Profiles) with %d directories.\n', g, length(currentGroup));
    fprintf('    - Figure 1: Electron density and temperature profiles\n');
    fprintf('    - Figure 2: Impurity density and poloidal heat flux density profiles\n');
    fprintf('    Uniform PDF exports saved to:\n');
    fprintf('      - %s\n', outDir1);
    fprintf('      - %s\n', outDir2);
    
end % 结束组遍历

fprintf('\nAll groups of target profiles have been plotted in separate figures.\n');
fprintf('Each group generates 2 figures:\n');
fprintf('  - Figure 1: Electron density and temperature profiles (ne, Te)\n');
fprintf('  - Figure 2: Impurity density and poloidal heat flux density profiles (n_N, q_pol)\n');
fprintf('Note: In each figure, left column shows Inner Target profiles, right column shows Outer Target profiles.\n');

end % 主函数结束


%% ========== 子函数：找出 dirName 在 all_radiationData 中的索引 ==========
function idx = findDirIndexInRadiationData(all_radiationData, dirName)
idx = -1;
for i = 1 : length(all_radiationData)
    thisDir = all_radiationData{i}.dirName;
    if strcmp(thisDir, dirName)
        idx = i;
        return;
    end
end
end


%% ========== 子函数：取简短目录名 ==========
function shortName = getShortDirName(fullPath)
parts = strsplit(fullPath, filesep);
shortName = parts{end};
end


%% ========== 子函数：添加自定义指数角标 ==========
function addExponentLabel(ax, exponent_str, fontName, fontSize)
% 关闭默认的 SecondaryLabel 避免多子图导出时重复
if isprop(ax, 'YAxis') && isprop(ax.YAxis, 'SecondaryLabel')
    ax.YAxis.SecondaryLabel.String = '';
    ax.YAxis.SecondaryLabel.Visible = 'off';
end

% 删除已有的自定义标签
delete(findall(ax, 'Tag', 'CustomExponentLabel'));

% 创建附属在该轴的自定义角标
text(ax, 0.02, 1.02, exponent_str, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', ...
    'Interpreter', 'latex', ...
    'FontName', fontName, ...
    'FontSize', fontSize, ...
    'Tag', 'CustomExponentLabel');
end


%% ========== 子函数：DataCursor 回调 ==========
function txt = myDataCursorUpdateFcn(~, event_obj)
pos = get(event_obj,'Position');
target = get(event_obj,'Target');
dirPath = get(target,'UserData');
if ~isempty(dirPath)
    txt = {
        ['X: ', num2str(pos(1))],...
        ['Y: ', num2str(pos(2))],...
        ['Dir: ', dirPath]
        };
else
    txt = {
        ['X: ', num2str(pos(1))],...
        ['Y: ', num2str(pos(2))]
        };
end
end


%% ========== 子函数：保存图形（带时间戳）==========
function saveFigureWithTimestamp(baseName)
set(gcf,'PaperPositionMode','auto');
timestampStr = datestr(now,'yyyymmdd_HHMMSS');
outFile = sprintf('%s_%s.fig', baseName, timestampStr);
savefig(outFile);
fprintf('Figure saved: %s\n', outFile);
end