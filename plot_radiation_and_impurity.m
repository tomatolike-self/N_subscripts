function plot_radiation_and_impurity(all_radiationData, domain, varargin)
% =========================================================================
% plot_radiation_and_impurity - 辐射分布和N杂质密度分布绘图
% =========================================================================
%
% 功能描述：
%   - 绘制每个算例的辐射和N杂质密度分布（2张子图）
%   - 统一colorbar范围，使用对数颜色标尺
%   - 输出辐射信息到txt文件
%
% 输入：
%   - all_radiationData : cell数组，包含各算例辐射数据
%   - domain            : 绘图区域（0=全域，1=上偏滤器，2=下偏滤器）
%
% 可选参数（名称-值对）：
%   'use_custom_colormap' - 是否使用mycontour.mat中的colormap（默认true）
%
% 输出：
%   - 辐射和杂质分布figure
%   - 辐射信息txt文件
%   - 自动保存.fig文件
%
% 依赖函数/工具箱：
%   - surfplot, plot3sep, plotstructure（SOLPS工具）
%
% 注意事项：
%   - R2019a兼容
%   - N系统：杂质索引3:10（N0到N7+）
%   - ratio_N表示N杂质辐射贡献比例
% =========================================================================

%% 解析输入参数
p = inputParser;
addParameter(p, 'use_custom_colormap', true, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});
use_custom_colormap = logical(p.Results.use_custom_colormap);

%% 常量定义
% N系统杂质索引范围（N0到N7+）
N_SPECIES_START = 3;    % N0在plasma.na中的索引
N_SPECIES_END = 10;     % N7+在plasma.na中的索引

% 字体设置
FONT_SIZE = 14;

%% 加载自定义colormap
custom_cmap = [];
if use_custom_colormap
    try
        load('mycontour.mat', 'mycontour');
        custom_cmap = mycontour;
    catch ME
        % 加载colormap失败时使用默认jet
        warning('plot_radiation_and_impurity:ColormapLoadFailed', ...
            'Failed to load mycontour.mat (%s). Using jet colormap.', ME.message);
        use_custom_colormap = false;
    end
end

%% 搜索全局最小/最大值用于统一colorbar
all_totrad_ns_min = +Inf;
all_totrad_ns_max = -Inf;
all_impDens_min = +Inf;
all_impDens_max = -Inf;

for iDir = 1:length(all_radiationData)
    radInfo = all_radiationData{iDir};
    
    % 总辐射
    valid_totrad = radInfo.totrad_ns(radInfo.totrad_ns > 0);
    if ~isempty(valid_totrad)
        all_totrad_ns_min = min(all_totrad_ns_min, min(valid_totrad));
        all_totrad_ns_max = max(all_totrad_ns_max, max(radInfo.totrad_ns(:)));
    end
    
    % 计算N杂质总密度（N0到N7+）
    n_species_end_adj = min(N_SPECIES_END, size(radInfo.plasma.na, 3));
    imp_density = sum(radInfo.plasma.na(:,:,N_SPECIES_START:n_species_end_adj), 3);
    
    valid_imp = imp_density(imp_density > 0);
    if ~isempty(valid_imp)
        all_impDens_min = min(all_impDens_min, min(valid_imp));
        all_impDens_max = max(all_impDens_max, max(imp_density(:)));
    end
end

% 防止最小值为Inf或太小导致对数标尺问题
% 如果所有数据都无效（min/max仍为初始的Inf/-Inf），使用合理的默认值
if ~isfinite(all_totrad_ns_max) || all_totrad_ns_max <= 0
    all_totrad_ns_max = 1e7;  % 默认最大辐射功率密度
    all_totrad_ns_min = 1e3;  % 默认最小值
else
    all_totrad_ns_min = max(all_totrad_ns_min, all_totrad_ns_max * 1e-6);
end

if ~isfinite(all_impDens_max) || all_impDens_max <= 0
    all_impDens_max = 1e19;   % 默认最大杂质密度
    all_impDens_min = 1e15;   % 默认最小值
else
    all_impDens_min = max(all_impDens_min, all_impDens_max * 1e-6);
end

log_totrad_ns_min = log10(all_totrad_ns_min);
log_totrad_ns_max = log10(all_totrad_ns_max);
log_impDens_min = log10(all_impDens_min);
log_impDens_max = log10(all_impDens_max);

%% 输出辐射信息到文件
timeSuffix = datestr(now, 'yyyymmdd_HHMMSS');
radInfoFilename = fullfile(pwd, ['radiation_info_N_', timeSuffix, '.txt']);

fid = fopen(radInfoFilename, 'w');
if fid < 0
    warning('Cannot open file %s for writing.', radInfoFilename);
end

for iDir = 1:length(all_radiationData)
    radInfo = all_radiationData{iDir};
    
    fprintf('\nDirectory: %s\n', radInfo.dirName);
    fprintf('\tTotal radiation power in domain:   %.3f MW\n', radInfo.totrad);
    fprintf('\tTotal radiation power in divertor: %.3f MW\n', radInfo.totrad_div);
    fprintf('\tDivertor fraction:                 %.3f\n', radInfo.div_fraction);
    
    % N系统：使用ratio_N表示N杂质辐射贡献
    if isfield(radInfo, 'ratio_N')
        fprintf('\tContribution ratio: D - %.3f, N - %.3f\n', radInfo.ratio_D, radInfo.ratio_N);
    end
    
    if fid >= 0
        fprintf(fid, '\nDirectory: %s\n', radInfo.dirName);
        fprintf(fid, '\tTotal radiation power in domain:   %.3f MW\n', radInfo.totrad);
        fprintf(fid, '\tTotal radiation power in divertor: %.3f MW\n', radInfo.totrad_div);
        fprintf(fid, '\tDivertor fraction:                 %.3f\n', radInfo.div_fraction);
        if isfield(radInfo, 'ratio_N')
            fprintf(fid, '\tContribution ratio: D - %.3f, N - %.3f\n', radInfo.ratio_D, radInfo.ratio_N);
        end
    end
end

if fid >= 0
    fclose(fid);
    fprintf('\nRadiation info saved to: %s\n', radInfoFilename);
end

%% 逐个算例绘图
for iDir = 1:length(all_radiationData)
    radInfo = all_radiationData{iDir};
    
    % 预处理数据
    log_totrad_ns = log10(max(radInfo.totrad_ns, all_totrad_ns_min));
    
    % 计算N杂质总密度
    n_species_end_adj = min(N_SPECIES_END, size(radInfo.plasma.na, 3));
    imp_density = sum(radInfo.plasma.na(:,:,N_SPECIES_START:n_species_end_adj), 3);
    log_imp_density = log10(max(imp_density, all_impDens_min));
    
    %% 创建Figure
    figure('Name', sprintf('RadiationAndImpurity_N: %s', radInfo.dirName), ...
        'NumberTitle', 'off', 'Color', 'w', ...
        'Position', [100, 100, 1200, 600]);
    
    %% 子图1：总辐射分布
    subplot(1, 2, 1);
    surfplot(radInfo.gmtry, log_totrad_ns);
    shading interp; view(2);
    hold on;
    plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
    
    % colormap
    if use_custom_colormap && ~isempty(custom_cmap)
        colormap(gca, custom_cmap);
    else
        colormap(gca, 'jet');
    end
    
    caxis([log10(2.3e03), log_totrad_ns_max]);
    
    % colorbar（对数刻度显示真实值）
    cb = colorbar;
    log_ticks = linspace(log10(2.3e03), log_totrad_ns_max, 5);
    real_ticks = 10.^log_ticks;
    tick_labels = cell(1, 5);
    for i = 1:5
        tick_labels{i} = sprintf('%.1e', real_ticks(i));
    end
    set(cb, 'Ticks', log_ticks, 'TickLabels', tick_labels);
    
    set(gca, 'FontName', 'Times New Roman', 'FontSize', FONT_SIZE);
    xlabel('$R$ (m)', 'FontSize', FONT_SIZE, 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontSize', FONT_SIZE, 'Interpreter', 'latex');
    title('Total $P_{\mathrm{rad}}$ (W/m$^3$)', 'FontSize', FONT_SIZE, 'Interpreter', 'latex');
    axis square; box on;
    
    % 区域缩放
    if domain == 1
        xlim([1.30, 2.00]); ylim([0.50, 1.20]);
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    elseif domain == 2
        xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    end
    
    hold off;
    
    %% 子图2：N杂质总密度
    subplot(1, 2, 2);
    surfplot(radInfo.gmtry, log_imp_density);
    shading interp; view(2);
    hold on;
    plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
    
    if use_custom_colormap && ~isempty(custom_cmap)
        colormap(gca, custom_cmap);
    else
        colormap(gca, 'jet');
    end
    
    caxis([log_impDens_min, log_impDens_max]);
    
    cb = colorbar;
    log_ticks = linspace(log_impDens_min, log_impDens_max, 5);
    real_ticks = 10.^log_ticks;
    tick_labels = cell(1, 5);
    for i = 1:5
        tick_labels{i} = sprintf('%.1e', real_ticks(i));
    end
    set(cb, 'Ticks', log_ticks, 'TickLabels', tick_labels);
    
    set(gca, 'FontName', 'Times New Roman', 'FontSize', FONT_SIZE);
    xlabel('$R$ (m)', 'FontSize', FONT_SIZE, 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontSize', FONT_SIZE, 'Interpreter', 'latex');
    title('$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', FONT_SIZE, 'Interpreter', 'latex');
    axis square; box on;
    
    if domain == 1
        xlim([1.30, 2.00]); ylim([0.50, 1.20]);
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    elseif domain == 2
        xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
    end
    
    hold off;
    
    %% 算例标签
    uicontrol('Style', 'text', ...
        'String', radInfo.dirName, ...
        'Units', 'normalized', ...
        'FontSize', 10, ...
        'BackgroundColor', 'w', ...
        'ForegroundColor', 'k', ...
        'Position', [0.2, 0.97, 0.6, 0.02]);
    
    %% 保存Figure
    figFilename = sprintf('rad_N_imp_dist_%d_%s.fig', iDir, timeSuffix);
    figFullPath = fullfile(pwd, figFilename);
    savefig(figFullPath);
    fprintf('Figure saved: %s\n', figFullPath);
end

fprintf('\nAll radiation and N impurity plots completed.\n');

end
