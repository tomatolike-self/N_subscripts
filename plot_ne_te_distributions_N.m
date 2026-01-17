function plot_ne_te_distributions_N(all_radiationData, ~, domain)
% =========================================================================
% plot_ne_te_distributions_N - 绘制N杂质算例的电子密度和电子温度二维分布图
% =========================================================================
%
% 功能描述：
% - 为每个算例生成独立的Figure，便于单独审视每个算例的数据
% - 每个Figure布局：1行2列（左：ne，右：te）
% - 统一全局colorbar范围（基于所有算例的最小/最大值），便于跨算例对比
%
% 输入：
% - all_radiationData: 包含所有SOLPS仿真数据的结构体数组
% - groupDirs: （保留接口但不使用，兼容调用）
% - domain: 绘图区域 (0=全域, 1=EAST上偏滤器, 2=EAST下偏滤器)
%
% 输出：
% - 为每个算例生成一个Figure（保存为 .fig 文件）
%
% 使用示例：
% - plot_ne_te_distributions_N(all_radiationData, [], 0)
%     全域绘图，每个算例一张图
%
% 依赖函数/工具箱：
% - surfplot, plot3sep, plotstructure（SOLPS绘图辅助函数）
%
% 注意事项：
% - R2019a 兼容，不使用 arguments 块或 tiledlayout
% - ne 和 te 数据与杂质种类无关，N体系与Ne体系通用
% - 使用对数colorbar标尺，避免极小值导致的可视化问题
% =========================================================================

%% 参数默认值设置
if nargin < 3 || isempty(domain)
    domain = 0;  % 默认全域绘图
end

%% 全局绘图样式设置
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 24);   % 增大默认字体
set(0, 'DefaultTextFontSize', 24);   % 增大默认字体
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultLineLineWidth', 2);

%% 遍历所有算例，计算全局colorbar范围（对数尺度）
% 这确保所有Figure使用相同的颜色映射，便于跨算例对比
fprintf('Calculating global colorbar ranges for ne and te...\n');

all_log_ne_min = +Inf;
all_log_ne_max = -Inf;
all_log_te_min = +Inf;
all_log_te_max = -Inf;

for i_case = 1:length(all_radiationData)
    radInfo = all_radiationData{i_case};
    
    % 检查必要字段
    if ~isfield(radInfo, 'plasma') || ~isfield(radInfo.plasma, 'ne') || ~isfield(radInfo.plasma, 'te')
        continue;
    end
    
    % 电子密度 ne（取对数，避免 log10(0) 或负数）
    ne_log = log10(max(radInfo.plasma.ne, eps));
    all_log_ne_min = min(all_log_ne_min, min(ne_log(:)));
    all_log_ne_max = max(all_log_ne_max, max(ne_log(:)));
    
    % 电子温度 te（转换为eV后取对数）
    te_ev = radInfo.plasma.te / 1.602e-19;  % J -> eV
    te_ev_log = log10(max(te_ev, eps));
    all_log_te_min = min(all_log_te_min, min(te_ev_log(:)));
    all_log_te_max = max(all_log_te_max, max(te_ev_log(:)));
end

% 转换回原始值用于colorbar标签
all_ne_min = 10^all_log_ne_min;
all_ne_max = 10^all_log_ne_max;
all_te_min = 10^all_log_te_min;
all_te_max = 10^all_log_te_max;

fprintf('  ne range: [%.2e, %.2e] m^-3\n', all_ne_min, all_ne_max);
fprintf('  te range: [%.2f, %.2f] eV\n', all_te_min, all_te_max);

%% 时间戳（用于文件命名）
timeSuffix = datestr(now, 'yyyymmdd_HHMMSS');

%% 遍历每个算例，生成独立Figure
num_cases = length(all_radiationData);
fprintf('Processing %d case(s), generating one figure per case...\n', num_cases);

for i_case = 1:num_cases
    radInfo = all_radiationData{i_case};
    dirName = radInfo.dirName;
    
    % 检查必要字段
    if ~isfield(radInfo, 'plasma') || ~isfield(radInfo.plasma, 'ne') || ...
            ~isfield(radInfo.plasma, 'te') || ~isfield(radInfo, 'gmtry')
        fprintf('Warning: Case %s missing required fields, skipping.\n', dirName);
        continue;
    end
    
    fprintf('Processing case %d/%d: %s\n', i_case, num_cases, dirName);
    
    % 准备数据（取对数）
    ne_log = log10(max(radInfo.plasma.ne, eps));
    te_ev = radInfo.plasma.te / 1.602e-19;  % J -> eV
    te_ev_log = log10(max(te_ev, eps));
    
    %% 创建Figure（1行2列布局）
    figure_width = 12;  % 宽度12英寸（两个子图）
    figure_height = 6;  % 高度6英寸
    
    % 提取简短的算例名用于Figure标题
    [~, caseName, ~] = fileparts(dirName);
    if isempty(caseName)
        caseName = dirName;
    end
    
    figureName = sprintf('ne and te: %s', caseName);
    fig = figure('Name', figureName, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, figure_width, figure_height]);
    
    %% 子图1：电子密度 ne（左侧）
    ax_ne = subplot(1, 2, 1);
    surfplot(radInfo.gmtry, ne_log);
    shading interp;
    view(2);
    hold on;
    
    % 绘制分离面
    plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 2);
    colormap(jet);
    
    % 统一色标（使用全局范围）
    caxis([all_log_ne_min, all_log_ne_max]);
    
    % 创建colorbar并设置对数刻度标签
    cb = colorbar;
    exp_max = floor(log10(all_ne_max));
    scale_factor = 10^exp_max;
    log_ticks = linspace(all_log_ne_min, all_log_ne_max, 5);
    real_ticks = 10.^log_ticks / scale_factor;
    set(cb, 'Ticks', log_ticks, ...
        'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
        'FontName', 'Times New Roman', 'FontSize', 22, 'TickLabelInterpreter', 'latex');
    title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontSize', 22);
    
    % 设置坐标轴
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 20, 'Box', 'on', 'LineWidth', 1.5);
    xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
    ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
    title('$n_e$ (m$^{-3}$)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
    axis equal;
    box on;
    
    % 根据domain设置绘图范围
    apply_domain_limits(domain, radInfo);
    
    hold off;
    
    %% 子图2：电子温度 te（右侧）
    ax_te = subplot(1, 2, 2);
    surfplot(radInfo.gmtry, te_ev_log);
    shading interp;
    view(2);
    hold on;
    
    % 绘制分离面
    plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 2);
    colormap(jet);
    
    % 统一色标
    caxis([all_log_te_min, all_log_te_max]);
    
    % 创建colorbar
    cb = colorbar;
    log_ticks = linspace(all_log_te_min, all_log_te_max, 5);
    
    % 根据温度范围决定是否使用科学计数法
    if all_te_max < 1000
        % 温度值较小，直接显示原始值
        set(cb, 'Ticks', log_ticks, ...
            'TickLabels', arrayfun(@(x) sprintf('%.2f', 10^x), log_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 22, 'TickLabelInterpreter', 'latex');
        title(cb, ' ', 'Interpreter', 'latex', 'FontSize', 22);
    else
        % 温度值较大，使用科学计数法
        exp_max = floor(log10(all_te_max));
        scale_factor = 10^exp_max;
        real_ticks = 10.^log_ticks / scale_factor;
        set(cb, 'Ticks', log_ticks, ...
            'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 22, 'TickLabelInterpreter', 'latex');
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontSize', 22);
    end
    
    % 设置坐标轴
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 20, 'Box', 'on', 'LineWidth', 1.5);
    xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
    ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
    title('$T_e$ (eV)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
    axis equal;
    box on;
    
    % 根据domain设置绘图范围
    apply_domain_limits(domain, radInfo);
    
    hold off;
    
    %% 添加Ghost占位符（实现统一紧裁剪导出边界）
    % =========================================================================
    % 原理说明：
    % 当使用MATLAB轴工具栏的"Export..."功能（紧裁剪导出）时，导出的图像边界
    % 是根据每个子图的"外接矩形"（包含所有可见内容）来确定的。
    %
    % 问题：如果ne的Y轴刻度标签是"3.0"而Te的是"400"，两者宽度不同，导致
    % 紧裁剪后的图像尺寸也不同——拼版到PPT/LaTeX时会出现对齐问题。
    %
    % 解决方案：在每个子图的四角外侧放置"隐形占位符"（白底白字，视觉不可见），
    % 并设置Clipping='off'使它们参与外接矩形计算。这样所有子图的外接矩形
    % 因为这些占位符而变得一致，紧裁剪导出后画布大小和plotbox位置都相同。
    %
    % 技术要点：
    % 1) 使用与背景同色（白色）的text对象作为占位符
    % 2) Clipping='off' 确保超出axes范围的文本仍参与边界计算
    % 3) HandleVisibility='off' 使占位符不出现在legend或其他自动发现中
    % 4) 占位符位置在axes四角外侧（归一化坐标），确保不遮挡数据或标签
    %
    % 备注：用户提到的LaTeX \phantom{}命令在纯MATLAB环境中不适用，
    % 因为MATLAB的text对象需要实际字符来占据空间。白色字符是最可靠的方式。
    % =========================================================================
    
    % 背景色与占位符颜色（白色）
    figBgColor = [1 1 1];  % 白色背景
    ghostFontSize = 22;    % 与标签字体大小相近，确保占位效果
    
    % 遍历两个子图，添加ghost占位符
    axList = [ax_ne, ax_te];
    for ax = axList
        % 设置ActivePositionProperty确保axes尺寸固定
        set(ax, 'ActivePositionProperty', 'position');
        
        % Ghost占位符公共参数
        ghostArgs = {'Units', 'normalized', 'HandleVisibility', 'off', ...
            'Clipping', 'off', 'Interpreter', 'none', ...
            'FontName', 'Times New Roman', 'FontSize', ghostFontSize, ...
            'Color', figBgColor};
        
        % 左侧占位符（扩展左边界）
        text(ax, -0.30, 0.02, '00000', ghostArgs{:}, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
        
        % 右侧占位符（扩展右边界）- 主要用于平衡colorbar
        text(ax, 1.25, 0.02, '00000', ghostArgs{:}, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
        
        % 底部占位符（扩展下边界）
        text(ax, 0.02, -0.25, '0', ghostArgs{:}, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
        
        % 顶部占位符（扩展上边界）- 用于平衡colorbar标题
        text(ax, 0.02, 1.12, '0', ghostArgs{:}, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    end
    
    %% 保存Figure
    % 使用算例序号+算例名生成唯一文件名
    safeFileName = regexprep(caseName, '[^\w]', '_');  % 替换非字母数字字符
    % 截断过长的文件名（保留前30个字符）
    if length(safeFileName) > 30
        safeFileName = safeFileName(1:30);
    end
    figFilename = sprintf('ne_te_case%02d_%s_%s', i_case, safeFileName, timeSuffix);
    figFullPath = fullfile(pwd, [figFilename, '.fig']);
    
    try
        savefig(fig, figFullPath);
        fprintf('  Figure saved: %s.fig\n', figFilename);
    catch ME
        fprintf('  Warning: Failed to save figure: %s\n', ME.message);
    end
end

fprintf('\nAll cases processed. Total %d figure(s) generated.\n', num_cases);

end


%% =========================================================================
%% 辅助函数：应用绘图区域限制
%% =========================================================================
function apply_domain_limits(domain, radInfo)
% apply_domain_limits - 根据domain参数设置坐标轴范围并绘制结构
%
% 输入：
% - domain: 0=全域, 1=上偏滤器, 2=下偏滤器
% - radInfo: 算例数据结构体

if domain ~= 0
    if domain == 1
        % EAST上偏滤器区域（参考Ne脚本范围）
        xlim([1.30, 1.90]);
        ylim([0.60, 1.20]);
        % 显式设置刻度，确保首尾显示明确数值
        set(gca, 'XTick', 1.3:0.2:1.9, 'YTick', 0.6:0.2:1.2);
    elseif domain == 2
        % EAST下偏滤器区域
        xlim([1.30, 2.05]);
        ylim([-1.15, -0.40]);
        % 显式设置刻度，确保首尾显示明确数值
        set(gca, 'XTick', 1.3:0.25:2.05, 'YTick', -1.1:0.2:-0.5);
    end
    
    % 绘制真空室结构
    if isfield(radInfo, 'structure')
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2.5);
    end
end
end
