function plot_radiation_Cz_distribution_simple_N(all_radiationData, domain, varargin)
% =========================================================================
% plot_radiation_Cz_distribution_simple - 简化版辐射与N杂质浓度分布绘图
% =========================================================================
%
% 功能描述：
%   绘制SOLPS算例的辐射分布和杂质离子浓度分布图。
%   每个算例生成一个独立的figure，包含1行3列子图：
%     - 第1列：总辐射功率密度分布 (P_rad)
%     - 第2列：N杂质辐射功率密度分布 (P_rad,N)
%     - 第3列：N杂质离子浓度分布 (c_N)
%
% 输入：
%   - all_radiationData : cell数组，包含各算例的辐射数据结构体
%   - domain            : 绘图区域（0=全域，1=上偏滤器，2=下偏滤器）
%
% 可选参数（名称-值对）：
%   'use_custom_colormap' - 是否使用自定义colormap，默认: true
%   'clim_totrad'         - 总辐射colorbar范围 [min, max] (W/m³)
%   'clim_nerad'          - N辐射colorbar范围 [min, max] (W/m³)
%   'clim_Cz'             - N浓度colorbar范围
%   'cz_scale'            - N浓度标尺类型: 'linear' 或 'log'
%
% 输出：
%   - figure窗口并保存为.fig文件
%
% 依赖函数/工具箱：
%   - surfplot, plot3sep, plotstructure（SOLPS绘图工具）
%
% 注意事项：
%   - R2019a兼容
%   - N系统：N1+到N7+（索引4-10），c_N = sum(N1+~N7+) / ne
%   - 不包含中性N0
% =========================================================================

%% 解析输入参数
p = inputParser;
addParameter(p, 'use_custom_colormap', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'clim_totrad', [5e5, 1e7], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'clim_nerad', [5e5, 1e7], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'clim_Cz', [0.01, 0.1], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'cz_scale', 'log', @(x) ismember(x, {'linear', 'log'}));
addParameter(p, 'save_fig', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'save_path', './', @ischar);
parse(p, varargin{:});

use_custom_colormap = logical(p.Results.use_custom_colormap);
clim_totrad = p.Results.clim_totrad;
clim_nerad = p.Results.clim_nerad;
clim_Cz = p.Results.clim_Cz;
cz_scale = p.Results.cz_scale;
save_fig = logical(p.Results.save_fig);
save_path = p.Results.save_path;

%% 常量定义
% N系统species索引范围（N1+到N7+）
N_ION_START_IDX = 4;   % N1+在plasma.na中的索引
N_ION_END_IDX = 10;    % N7+在plasma.na中的索引

% 字体设置
FONT_NAME = 'Times New Roman';
FONT_SIZE_AXIS = 16;
FONT_SIZE_LABEL = 18;
FONT_SIZE_COLORBAR = 14;

%% 设置全局绘图参数
set(0, 'DefaultAxesFontName', FONT_NAME);
set(0, 'DefaultTextFontName', FONT_NAME);
set(0, 'DefaultAxesFontSize', FONT_SIZE_AXIS);
set(0, 'DefaultTextFontSize', FONT_SIZE_AXIS);
set(0, 'DefaultLineLineWidth', 1.5);

%% 检查输入数据
num_cases = length(all_radiationData);
if num_cases < 1
    error('At least 1 case data is required');
end

%% 根据domain设置坐标范围
if domain == 1
    xlim_range = [1.30, 2.00];
    ylim_range = [0.50, 1.20];
    x_ticks = [];
    y_ticks = [];
elseif domain == 2
    xlim_range = [1.30, 2.05];
    ylim_range = [-1.15, -0.40];
    x_ticks = [];
    y_ticks = [];
else
    xlim_range = [1.20, 2.40];
    ylim_range = [-0.80, 1.20];
    x_ticks = 1.20:0.40:2.40;
    y_ticks = -0.80:0.40:1.20;
end

%% 加载自定义colormap
custom_cmap = [];
if use_custom_colormap
    try
        load('mycontour.mat', 'mycontour');
        custom_cmap = mycontour;
    catch
        warning('Failed to load mycontour.mat, using default jet colormap');
        use_custom_colormap = false;
    end
end

%% 定义子图配置
% 子图1：总辐射
config_totrad.title_str = '$P_{\mathrm{rad}}$ (W/m$^3$)';
config_totrad.clim = clim_totrad;
config_totrad.use_log = true;
config_totrad.data_name = 'P_rad';
config_totrad.data_unit = 'W/m^3';

% 子图2：N辐射
config_nerad.title_str = '$P_{\mathrm{rad,N}}$ (W/m$^3$)';
config_nerad.clim = clim_nerad;
config_nerad.use_log = true;
config_nerad.data_name = 'P_rad,N';
config_nerad.data_unit = 'W/m^3';

% 子图3：N浓度
config_cz.title_str = '$c_{\mathrm{N}}$';
config_cz.clim = clim_Cz;
config_cz.use_log = strcmp(cz_scale, 'log');
config_cz.data_name = 'c_N';
config_cz.data_unit = '';

subplot_configs = {config_totrad, config_nerad, config_cz};

%% 遍历每个算例
for iDir = 1:num_cases
    
    radInfo = all_radiationData{iDir};
    
    %% 计算N杂质离子浓度
    % c_N = sum(N1+ to N7+) / ne
    % N系统：plasma.na(:,:,4:10) 对应 N1+到N7+
    impurity_ion_density = sum(radInfo.plasma.na(:,:,N_ION_START_IDX:N_ION_END_IDX), 3);
    cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;
    cz_ratio(~isfinite(cz_ratio) | cz_ratio <= 0) = NaN;
    
    %% 准备绘图数据
    plot_data = cell(1, 3);
    plot_data{1} = log10(max(radInfo.totrad_ns, clim_totrad(1)));
    
    % N系统使用totrad_N字段
    if isfield(radInfo, 'totrad_N')
        plot_data{2} = log10(max(radInfo.totrad_N, clim_nerad(1)));
    else
        warning('N radiation data (totrad_N) not found for case %d', iDir);
        plot_data{2} = zeros(size(radInfo.totrad_ns));
    end
    
    if strcmp(cz_scale, 'log')
        plot_data{3} = log10(max(cz_ratio, clim_Cz(1)));
    else
        plot_data{3} = cz_ratio;
    end
    
    %% 创建figure
    figure('Name', sprintf('Radiation Distribution - Case %d', iDir), ...
        'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 18, 5]);
    
    cb_handles = gobjects(1, 3);
    cb_tick_labels = cell(1, 3);
    
    %% 绘制三个子图
    for iSub = 1:3
        
        subplot(1, 3, iSub);
        
        % 绘制2D分布图
        surfplot(radInfo.gmtry, plot_data{iSub});
        shading interp;
        view(2);
        hold on;
        
        % 分离面
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        
        % colormap
        if use_custom_colormap && ~isempty(custom_cmap)
            colormap(gca, custom_cmap);
        else
            colormap(gca, jet);
        end
        
        cfg = subplot_configs{iSub};
        
        % 设置色标
        if cfg.use_log
            caxis([log10(cfg.clim(1)), log10(cfg.clim(2))]);
            cb = colorbar;
            cb_handles(iSub) = cb;
            
            if iSub <= 2
                exp_display = floor(log10(cfg.clim(2)) - 2);
            else
                exp_display = floor(log10(cfg.clim(1)));
            end
            scale_factor = 10^exp_display;
            
            log_ticks = linspace(log10(cfg.clim(1)), log10(cfg.clim(2)), 4);
            real_ticks = 10.^log_ticks / scale_factor;
            
            tick_labels = cell(1, 4);
            for iTick = 1:4
                tick_labels{iTick} = sprintf('%.2f', real_ticks(iTick));
            end
            set(cb, 'Ticks', log_ticks, 'TickLabels', tick_labels, ...
                'FontName', FONT_NAME, 'FontSize', FONT_SIZE_COLORBAR);
            cb_tick_labels{iSub} = tick_labels;
            
            title(cb, ['$\times10^{', num2str(exp_display), '}$'], ...
                'FontSize', FONT_SIZE_COLORBAR, 'Interpreter', 'latex');
        else
            caxis(cfg.clim);
            cb = colorbar;
            set(cb, 'FontName', FONT_NAME, 'FontSize', FONT_SIZE_COLORBAR);
            cb_handles(iSub) = cb;
            cb_tick_labels{iSub} = get(cb, 'TickLabels');
        end
        
        % 坐标轴格式
        set(gca, 'FontName', FONT_NAME, 'FontSize', FONT_SIZE_AXIS, ...
            'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'FontSize', FONT_SIZE_LABEL, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontSize', FONT_SIZE_LABEL, 'Interpreter', 'latex');
        title(cfg.title_str, 'FontSize', FONT_SIZE_AXIS, 'Interpreter', 'latex');
        
        axis equal; box on;
        xlim(xlim_range);
        ylim(ylim_range);
        
        if ~isempty(x_ticks)
            set(gca, 'XTick', x_ticks);
        end
        if ~isempty(y_ticks)
            set(gca, 'YTick', y_ticks);
        end
        
        % 装置结构
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        
        % DataCursor数据
        data_info_struct.data_name = cfg.data_name;
        data_info_struct.data_unit = cfg.data_unit;
        data_info_struct.is_log = cfg.use_log;
        set(gca, 'UserData', data_info_struct);
        
        hold off;
    end
    
    %% 统一colorbar刻度文字宽度
    target_len = 0;
    for iSub = 1:3
        labels_i = cb_tick_labels{iSub};
        if isempty(labels_i), continue; end
        if isstring(labels_i), labels_i = cellstr(labels_i); end
        if ischar(labels_i), labels_i = cellstr(labels_i); end
        for iLab = 1:numel(labels_i)
            lab_str = labels_i{iLab};
            if isstring(lab_str), lab_str = char(lab_str); end
            target_len = max(target_len, length(lab_str));
        end
    end
    
    for iSub = 1:3
        if ~isgraphics(cb_handles(iSub)), continue; end
        labels_i = cb_tick_labels{iSub};
        if isempty(labels_i), continue; end
        if isstring(labels_i), labels_i = cellstr(labels_i); end
        if ischar(labels_i), labels_i = cellstr(labels_i); end
        
        padded_labels = cell(size(labels_i));
        for iLab = 1:numel(labels_i)
            lab_str = labels_i{iLab};
            if isstring(lab_str), lab_str = char(lab_str); end
            pad_count = target_len - length(lab_str);
            if pad_count > 0
                padded_labels{iLab} = ['\color{black}', lab_str, '\color{white}', repmat('0', 1, pad_count)];
            else
                padded_labels{iLab} = ['\color{black}', lab_str];
            end
        end
        set(cb_handles(iSub), 'TickLabels', padded_labels, 'TickLabelInterpreter', 'tex');
    end
    
    %% DataCursor
    dcm = datacursormode(gcf);
    set(dcm, 'Enable', 'on');
    set(dcm, 'UpdateFcn', @datacursor_callback);
    
    %% 保存figure
    if save_fig
        if ~exist(save_path, 'dir')
            mkdir(save_path);
        end
        time_stamp = datestr(now, 'yyyymmdd_HHMMSS');
        fig_filename = sprintf('radiation_cN_distribution_case_%d_%s.fig', iDir, time_stamp);
        full_path = fullfile(save_path, fig_filename);
        savefig(gcf, full_path);
        fprintf('Saved figure: %s\n', full_path);
    end
    
    fprintf('Completed plotting for Case %d\n', iDir);
end

fprintf('\nAll cases plotting completed\n');

end


%% =========================================================================
% 辅助函数：DataCursor回调
% =========================================================================
function txt = datacursor_callback(~, event_obj)

pos = get(event_obj, 'Position');
R_val = pos(1);
Z_val = pos(2);

target = get(event_obj, 'Target');

try
    data_idx = get(event_obj, 'DataIndex');
    cdata = get(target, 'CData');
    if numel(data_idx) == 1
        data_val = cdata(data_idx);
    else
        data_val = cdata(data_idx(1), data_idx(2));
    end
catch
    if length(pos) >= 3
        data_val = pos(3);
    else
        data_val = NaN;
    end
end

ax = get(target, 'Parent');
data_info = get(ax, 'UserData');

if isstruct(data_info) && isfield(data_info, 'data_name')
    data_name = data_info.data_name;
    data_unit = data_info.data_unit;
    is_log = data_info.is_log;
    
    if is_log && isfinite(data_val)
        original_val = 10^data_val;
        val_str = sprintf('%.3e', original_val);
    else
        val_str = sprintf('%.4g', data_val);
    end
else
    data_name = 'Value';
    data_unit = '';
    val_str = sprintf('%.4g', data_val);
end

txt = {sprintf('R: %.4f m', R_val), sprintf('Z: %.4f m', Z_val)};
if isempty(data_unit)
    txt{end+1} = sprintf('%s: %s', data_name, val_str);
else
    txt{end+1} = sprintf('%s: %s %s', data_name, val_str, data_unit);
end

end
