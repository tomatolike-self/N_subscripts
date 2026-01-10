function plot_upstream_downstream_profiles_for_export(all_radiationData, groupDirs, varargin)
% =========================================================================
% plot_upstream_downstream_profiles_for_export - 综合上下游剖面导出脚本
% =========================================================================
%
% 功能描述：
%   - 结合OMP/IMP和IT/OT共12个子图，每个子图使用独立figure绘制
%   - 每个figure添加(a)-(l)序号标签于plotBox左上角
%   - 只在第一个子图(a)显示图例
%   - 自动将所有figure导出为PDF文件到以时间戳命名的文件夹
%
% 输入参数：
%   all_radiationData - 包含辐射数据的元胞数组
%   groupDirs - 元胞数组的元胞数组，每个包含要分组的目录
%   varargin - 可选参数（名值对）:
%       'usePredefinedLegend', true/false (默认: true)
%       'axisMode', 'fixed'/'auto' (默认: 'fixed')
%
% 输出：
%   - 12个独立figure窗口
%   - 自动创建文件夹并导出PDF文件（按a-l命名）
%
% 子图序号顺序：
%   (a) OMP ne    (b) IT ne     (c) OT ne
%   (d) OMP Te    (e) IT Te     (f) OT Te
%   (g) OMP n_N   (h) IT n_N    (i) OT n_N
%   (j) IMP n_N   (k) IT q_pol  (l) OT q_pol
%
% 依赖函数/工具箱：无
%
% 注意事项：
%   - R2019a 兼容性：使用 inputParser，不使用 arguments 块
%   - 氮杂质离子价态索引为 4:10 (N1+ 到 N7+)
%   - 本文件包含 3 个辅助函数；拆分理由：复用figure创建和PDF导出逻辑
%
% =========================================================================

%% 处理可选输入参数
p = inputParser;
addParameter(p, 'usePredefinedLegend', true, @islogical);
addParameter(p, 'axisMode', 'fixed', @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

usePredefinedLegend = p.Results.usePredefinedLegend;
axisMode = lower(char(p.Results.axisMode));
if ~ismember(axisMode, {'fixed','auto'})
    axisMode = 'fixed';
end

%% 统一画布配置（与独立figure脚本完全一致）
paperW = 7.8;    % 画布宽度
paperH = 6.0;    % 画布高度
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

% 预定义图例名称
preset_legend_names = {'$\mathrm{fav.}~B_{\mathrm{T}}$', '$\mathrm{unfav.}~B_{\mathrm{T}}$', '$\mathrm{w/o~drift}$'};

%% 网格与索引定义
separatrix_radial_index = 12;
outer_target_j_index = 1;
inner_target_j_index = 96;
outer_j_original = 42;  % OMP位置
inner_j_original = 59;  % IMP位置
outer_j_cropped = outer_j_original - 1;
inner_j_cropped = inner_j_original - 1;

%% 子图序号标签
subplot_labels = {'(a)', '(b)', '(c)', '(d)', '(e)', '(f)', ...
    '(g)', '(h)', '(i)', '(j)', '(k)', '(l)'};

%% 遍历各组
num_groups = length(groupDirs);

for g = 1:num_groups
    
    currentGroup = groupDirs{g};
    
    % 创建输出文件夹（英文名称 + 时间戳）
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
    outputFolder = sprintf('upstream_downstream_profiles_group%d_%s', g, timestampStr);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    fprintf('Output folder: %s\n', outputFolder);
    
    % 创建12个figure句柄数组
    figHandles = gobjects(12, 1);
    axHandles = gobjects(12, 1);
    
    % 用于存储图例句柄的数组（只在图a使用）
    legend_handles = gobjects(0);
    legend_entries = {};
    
    % 创建12个独立figure
    for idx = 1:12
        figHandles(idx) = createUniformFigure(paperW, paperH);
        axHandles(idx) = axes(figHandles(idx), 'Units', 'normalized', ...
            'Position', plotBoxPos_normalized);
        hold(axHandles(idx), 'on');
        
        % 设置axes属性
        set(axHandles(idx), 'LineWidth', 1.5);
        set(axHandles(idx), 'Box', 'on');
        set(axHandles(idx), 'TickDir', 'in');
        set(axHandles(idx), 'YScale', 'linear');
        grid(axHandles(idx), 'on');
        set(axHandles(idx), 'GridLineStyle', ':');
        set(axHandles(idx), 'GridAlpha', 0.25);
        set(axHandles(idx), 'ActivePositionProperty', 'position');
    end
    
    %% 遍历组内目录，绘制数据
    for k = 1:length(currentGroup)
        
        currentDir = currentGroup{k};
        idx_in_all = findDirIndex(all_radiationData, currentDir);
        if idx_in_all < 0
            fprintf('Warning: directory %s not found.\n', currentDir);
            continue;
        end
        
        dataStruct = all_radiationData{idx_in_all};
        if ~isfield(dataStruct, 'plasma') || ~isfield(dataStruct, 'gmtry')
            fprintf('Warning: missing plasma or gmtry in %s.\n', currentDir);
            continue;
        end
        
        gmtry = dataStruct.gmtry;
        plasma = dataStruct.plasma;
        dirName = dataStruct.dirName;
        
        % 生成图例名称
        if usePredefinedLegend
            legend_index = mod(k-1, length(preset_legend_names)) + 1;
            legendName = preset_legend_names{legend_index};
        else
            parts = strsplit(dirName, filesep);
            legendName = parts{end};
        end
        
        %% 计算物理坐标
        % OMP坐标
        Y_omp = gmtry.hy(outer_j_original+1, 2:end-1);
        W_omp = [0.5*Y_omp(1), 0.5*(Y_omp(2:end)+Y_omp(1:end-1))];
        hy_center_omp = cumsum(W_omp);
        sep_omp = hy_center_omp(separatrix_radial_index) + 0.5*Y_omp(separatrix_radial_index);
        x_omp = (hy_center_omp - sep_omp) * 100;  % 转换为cm
        
        % IMP坐标
        Y_imp = gmtry.hy(inner_j_original+1, 2:end-1);
        W_imp = [0.5*Y_imp(1), 0.5*(Y_imp(2:end)+Y_imp(1:end-1))];
        hy_center_imp = cumsum(W_imp);
        sep_imp = hy_center_imp(separatrix_radial_index) + 0.5*Y_imp(separatrix_radial_index);
        x_imp = (hy_center_imp - sep_imp) * 100;  % 转换为cm
        
        % IT坐标
        Y_it = gmtry.hy(inner_target_j_index+1, 2:end-1);
        W_it = [0.5*Y_it(1), 0.5*(Y_it(2:end)+Y_it(1:end-1))];
        hy_center_it = cumsum(W_it);
        sep_it = hy_center_it(separatrix_radial_index) + 0.5*Y_it(separatrix_radial_index);
        x_it = hy_center_it - sep_it;  % 单位m
        
        % OT坐标
        Y_ot = gmtry.hy(outer_target_j_index+1, 2:end-1);
        W_ot = [0.5*Y_ot(1), 0.5*(Y_ot(2:end)+Y_ot(1:end-1))];
        hy_center_ot = cumsum(W_ot);
        sep_ot = hy_center_ot(separatrix_radial_index) + 0.5*Y_ot(separatrix_radial_index);
        x_ot = hy_center_ot - sep_ot;  % 单位m
        
        %% 提取物理量（裁剪后的网格）
        ne_2D = plasma.ne(2:end-1, 2:end-1);
        te_2D = plasma.te_ev(2:end-1, 2:end-1);
        
        % 杂质密度（N1+ 到 N7+，索引4:10）
        if isfield(plasma, 'na')
            n_imp_2D = sum(plasma.na(2:end-1, 2:end-1, 4:10), 3);
        else
            n_imp_2D = zeros(size(ne_2D));
        end
        
        % 极向热流密度
        if isfield(plasma, 'fhi_mdf') && isfield(plasma, 'fhe_mdf')
            total_heat_pol = plasma.fhi_mdf(:,:,1) + plasma.fhe_mdf(:,:,1);
            area_pol = gmtry.gs(:,:,1) .* gmtry.qz(:,:,2);
            qpol_full = total_heat_pol ./ area_pol;
            qpol_2D = qpol_full(2:end-1, 2:end-1);
        else
            qpol_2D = zeros(size(ne_2D));
        end
        
        %% 提取各位置的数据
        ne_omp = ne_2D(outer_j_cropped, :);
        te_omp = te_2D(outer_j_cropped, :);
        n_imp_omp = n_imp_2D(outer_j_cropped, :);
        n_imp_imp = n_imp_2D(inner_j_cropped, :);
        
        ne_it = ne_2D(inner_target_j_index, :);
        te_it = te_2D(inner_target_j_index, :);
        n_imp_it = n_imp_2D(inner_target_j_index, :);
        qpol_it = qpol_2D(inner_target_j_index, :);
        
        ne_ot = ne_2D(outer_target_j_index, :);
        te_ot = te_2D(outer_target_j_index, :);
        n_imp_ot = n_imp_2D(outer_target_j_index, :);
        qpol_ot = -qpol_2D(outer_target_j_index, :);  % OT取负值
        
        %% 分配颜色
        dir_color = line_colors(mod(k-1, size(line_colors,1))+1, :);
        plotStyle = {'-', 'Color', dir_color, 'LineWidth', linewidth};
        
        %% 绘制12个子图
        % (a) OMP ne
        h = plot(axHandles(1), x_omp, ne_omp, plotStyle{:});
        if k == 1
            legend_handles(end+1) = h;
            legend_entries{end+1} = legendName;
        elseif k <= length(preset_legend_names)
            legend_handles(end+1) = h;
            legend_entries{end+1} = legendName;
        end
        
        % (b) IT ne
        plot(axHandles(2), x_it, ne_it, plotStyle{:});
        
        % (c) OT ne
        plot(axHandles(3), x_ot, ne_ot, plotStyle{:});
        
        % (d) OMP Te
        plot(axHandles(4), x_omp, te_omp, plotStyle{:});
        
        % (e) IT Te
        plot(axHandles(5), x_it, te_it, plotStyle{:});
        
        % (f) OT Te
        plot(axHandles(6), x_ot, te_ot, plotStyle{:});
        
        % (g) OMP n_N
        plot(axHandles(7), x_omp, n_imp_omp, plotStyle{:});
        
        % (h) IT n_N
        plot(axHandles(8), x_it, n_imp_it, plotStyle{:});
        
        % (i) OT n_N
        plot(axHandles(9), x_ot, n_imp_ot, plotStyle{:});
        
        % (j) IMP n_N
        plot(axHandles(10), x_imp, n_imp_imp, plotStyle{:});
        
        % (k) IT q_pol
        plot(axHandles(11), x_it, qpol_it, plotStyle{:});
        
        % (l) OT q_pol
        plot(axHandles(12), x_ot, qpol_ot, plotStyle{:});
    end
    
    %% 设置轴范围和刻度
    % X轴配置
    omp_xlim = [-3, 3];  omp_xticks = -3:1:3;
    imp_xlim = [-6, 6];  imp_xticks = -6:2:6;
    it_xlim = [-0.1, 0.3];  it_xticks = -0.1:0.1:0.3;
    ot_xlim = [-0.1, 0.2];  ot_xticks = -0.1:0.1:0.2;
    
    if strcmp(axisMode, 'auto')
        % 自动模式
        for idx = 1:12
            set(axHandles(idx), 'XLimMode', 'auto', 'YLimMode', 'auto');
        end
    else
        % 固定模式
        % (a) OMP ne
        xlim(axHandles(1), omp_xlim); set(axHandles(1), 'XTick', omp_xticks);
        ylim(axHandles(1), [1e19, 3e19]); set(axHandles(1), 'YTick', [1e19, 2e19, 3e19]);
        
        % (b) IT ne
        xlim(axHandles(2), it_xlim); set(axHandles(2), 'XTick', it_xticks);
        ylim(axHandles(2), [0, 5e20]); set(axHandles(2), 'YTick', [0, 2.5e20, 5e20]);
        
        % (c) OT ne
        xlim(axHandles(3), ot_xlim); set(axHandles(3), 'XTick', ot_xticks);
        ylim(axHandles(3), [0, 5e20]); set(axHandles(3), 'YTick', [0, 2.5e20, 5e20]);
        
        % (d) OMP Te
        xlim(axHandles(4), omp_xlim); set(axHandles(4), 'XTick', omp_xticks);
        ylim(axHandles(4), [0, 400]); set(axHandles(4), 'YTick', 0:100:400);
        
        % (e) IT Te
        xlim(axHandles(5), it_xlim); set(axHandles(5), 'XTick', it_xticks);
        ylim(axHandles(5), [0, 25]); set(axHandles(5), 'YTick', 0:5:25);
        
        % (f) OT Te
        xlim(axHandles(6), ot_xlim); set(axHandles(6), 'XTick', ot_xticks);
        ylim(axHandles(6), [0, 25]); set(axHandles(6), 'YTick', 0:5:25);
        
        % (g) OMP n_N - 按原脚本196设置
        xlim(axHandles(7), omp_xlim); set(axHandles(7), 'XTick', omp_xticks);
        ylim(axHandles(7), [2e17, 6e17]); set(axHandles(7), 'YTick', [2e17, 4e17, 6e17]);
        
        % (h) IT n_N - 按原脚本197设置
        xlim(axHandles(8), it_xlim); set(axHandles(8), 'XTick', it_xticks);
        ylim(axHandles(8), [0, 6e19]); set(axHandles(8), 'YTick', [0, 2e19, 4e19, 6e19]);
        
        % (i) OT n_N - 按原脚本197设置
        xlim(axHandles(9), ot_xlim); set(axHandles(9), 'XTick', ot_xticks);
        ylim(axHandles(9), [0, 6e19]); set(axHandles(9), 'YTick', [0, 2e19, 4e19, 6e19]);
        
        % (j) IMP n_N - 按原脚本196设置
        xlim(axHandles(10), imp_xlim); set(axHandles(10), 'XTick', imp_xticks);
        ylim(axHandles(10), [1e17, 7e17]); set(axHandles(10), 'YTick', [1e17, 4e17, 7e17]);
        
        % (k) IT q_pol
        xlim(axHandles(11), it_xlim); set(axHandles(11), 'XTick', it_xticks);
        ylim(axHandles(11), [0, 2e6]); set(axHandles(11), 'YTick', [0, 0.5e6, 1e6, 1.5e6, 2e6]);
        
        % (l) OT q_pol
        xlim(axHandles(12), ot_xlim); set(axHandles(12), 'XTick', ot_xticks);
        ylim(axHandles(12), [0, 2e6]); set(axHandles(12), 'YTick', [0, 0.5e6, 1e6, 1.5e6, 2e6]);
    end
    
    %% 绘制分离面参考线
    sepStyle = {'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off'};
    for idx = 1:12
        plot(axHandles(idx), [0 0], ylim(axHandles(idx)), sepStyle{:});
    end
    
    %% 设置轴标签
    xLabel_OMP = '$r - r_{\mathrm{sep}}$ at OMP (cm)';
    xLabel_IMP = '$r - r_{\mathrm{sep}}$ at IMP (cm)';
    xLabel_IT = '$r - r_{\mathrm{sep}}$ at IT (m)';
    xLabel_OT = '$r - r_{\mathrm{sep}}$ at OT (m)';
    
    % X轴标签
    xlabel(axHandles(1), xLabel_OMP, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(2), xLabel_IT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(3), xLabel_OT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(4), xLabel_OMP, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(5), xLabel_IT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(6), xLabel_OT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(7), xLabel_OMP, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(8), xLabel_IT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(9), xLabel_OT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(10), xLabel_IMP, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(11), xLabel_IT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    xlabel(axHandles(12), xLabel_OT, 'FontSize', xlabelsize, 'Interpreter', 'latex');
    
    % Y轴标签
    ylabel(axHandles(1), '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(2), '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(3), '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(4), '$T_{\mathrm{e}}$ (eV)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(5), '$T_{\mathrm{e}}$ (eV)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(6), '$T_{\mathrm{e}}$ (eV)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(7), '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(8), '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(9), '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(10), '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(11), '$q_{\mathrm{pol}}$ (W/m$^{2}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    ylabel(axHandles(12), '$q_{\mathrm{pol}}$ (W/m$^{2}$)', 'FontSize', ylabelsize, 'Interpreter', 'latex');
    
    %% 添加位置标注（右上角）
    positionLabels = {'OMP', 'IT', 'OT', 'OMP', 'IT', 'OT', ...
        'OMP', 'IT', 'OT', 'IMP', 'IT', 'OT'};
    for idx = 1:12
        text(axHandles(idx), 0.95, 0.95, positionLabels{idx}, ...
            'Units', 'normalized', 'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'top', 'FontSize', xlabelsize, ...
            'FontName', fontName, 'FontWeight', 'normal');
    end
    
    %% 添加序号标签（左上角）
    for idx = 1:12
        text(axHandles(idx), 0.02, 0.95, subplot_labels{idx}, ...
            'Units', 'normalized', 'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', 'FontSize', xlabelsize, ...
            'FontName', fontName, 'FontWeight', 'bold');
    end
    
    %% 只在图(a)添加图例
    if ~isempty(legend_handles)
        legend(axHandles(1), legend_handles, legend_entries, ...
            'Location', 'southwest', 'Interpreter', 'latex', ...
            'FontSize', legendsize, 'FontName', fontName);
    end
    
    %% 添加指数角标
    % ne子图
    axHandles(1).YAxis.Exponent = 19;
    addExponentLabel(axHandles(1), '$\times 10^{19}$', fontName, ylabelsize);
    axHandles(2).YAxis.Exponent = 20;
    addExponentLabel(axHandles(2), '$\times 10^{20}$', fontName, ylabelsize);
    axHandles(3).YAxis.Exponent = 20;
    addExponentLabel(axHandles(3), '$\times 10^{20}$', fontName, ylabelsize);
    
    % n_N子图 - 按原脚本设置指数
    axHandles(7).YAxis.Exponent = 17;  % OMP n_N: 10^17
    addExponentLabel(axHandles(7), '$\times 10^{17}$', fontName, ylabelsize);
    axHandles(8).YAxis.Exponent = 19;  % IT n_N: 10^19（按原脚本197）
    addExponentLabel(axHandles(8), '$\times 10^{19}$', fontName, ylabelsize);
    axHandles(9).YAxis.Exponent = 19;  % OT n_N: 10^19（按原脚本197）
    addExponentLabel(axHandles(9), '$\times 10^{19}$', fontName, ylabelsize);
    axHandles(10).YAxis.Exponent = 17; % IMP n_N: 10^17
    addExponentLabel(axHandles(10), '$\times 10^{17}$', fontName, ylabelsize);
    
    % q_pol子图
    axHandles(11).YAxis.Exponent = 6;
    addExponentLabel(axHandles(11), '$\times 10^{6}$', fontName, ylabelsize);
    axHandles(12).YAxis.Exponent = 6;
    addExponentLabel(axHandles(12), '$\times 10^{6}$', fontName, ylabelsize);
    
    %% 增强坐标轴刻度字体
    for idx = 1:12
        set(axHandles(idx), 'FontName', fontName, 'FontSize', xlabelsize);
    end
    
    %% 导出PDF文件到pdf子文件夹
    pdfFolder = fullfile(outputFolder, 'pdf');
    if ~exist(pdfFolder, 'dir')
        mkdir(pdfFolder);
    end
    fileLetters = 'abcdefghijkl';
    fprintf('Exporting PDF files to: %s\n', pdfFolder);
    for idx = 1:12
        pdfFile = fullfile(pdfFolder, sprintf('%c.pdf', fileLetters(idx)));
        exportFigureToPDF(figHandles(idx), pdfFile);
        fprintf('  Exported: %s\n', pdfFile);
    end
    
    %% 保存.fig文件到fig子文件夹
    figFolder = fullfile(outputFolder, 'fig');
    if ~exist(figFolder, 'dir')
        mkdir(figFolder);
    end
    fprintf('Saving .fig files to: %s\n', figFolder);
    for idx = 1:12
        figFile = fullfile(figFolder, sprintf('%c.fig', fileLetters(idx)));
        savefig(figHandles(idx), figFile);
    end
    
    fprintf('>>> Group %d completed. %d figures exported to: %s\n', g, 12, outputFolder);
    
end

fprintf('\nAll groups processed.\n');

end


%% ========== 辅助函数：创建统一配置的figure ==========
function fig = createUniformFigure(paperW, paperH)
fig = figure('NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [1 1 paperW paperH], ...
    'PaperUnits', 'inches', 'PaperSize', [paperW paperH], ...
    'PaperPosition', [0 0 paperW paperH]);
end


%% ========== 辅助函数：在radiationData中查找目录索引 ==========
function idx = findDirIndex(all_radiationData, dirName)
idx = -1;
for i = 1:length(all_radiationData)
    if strcmp(all_radiationData{i}.dirName, dirName)
        idx = i;
        return;
    end
end
end


%% ========== 辅助函数：添加自定义指数角标 ==========
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


%% ========== 辅助函数：导出figure为PDF ==========
function exportFigureToPDF(fig, pdfFile)
figure(fig);
set(fig, 'PaperPositionMode', 'manual');
% 使用painters渲染器导出矢量图
print(fig, '-dpdf', '-painters', pdfFile);
end
