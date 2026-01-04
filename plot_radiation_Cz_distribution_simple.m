function plot_radiation_Cz_distribution_simple(all_radiationData, domain, varargin)
% =========================================================================
% plot_radiation_Cz_distribution_simple - 简化版辐射与杂质浓度分布绘图
% =========================================================================
%
% 功能描述：
%   绘制SOLPS算例的辐射分布和杂质离子浓度分布图。
%   每个算例生成一个独立的figure，包含1行3列子图：
%     - 第1列：总辐射功率密度分布 (P_rad)
%     - 第2列：Ne杂质辐射功率密度分布 (P_rad,Ne)
%     - 第3列：杂质离子浓度分布 (c_ne)
%
% 输入：
%   all_radiationData  - cell数组，包含各算例的辐射数据结构体
%   domain             - 绘图区域选择：
%                        0 = 全域 (默认)
%                        1 = EAST上偏滤器区域
%                        2 = EAST下偏滤器区域
%
% 可选参数（名称-值对）：
%   'use_custom_colormap' - 是否使用自定义colormap，默认: true
%   'clim_totrad'         - 总辐射colorbar范围 [min, max] (W/m³)，默认: [1e5, 1e7]
%   'clim_Ne_rad'         - Ne辐射colorbar范围 [min, max] (W/m³)，默认: [1e5, 1e7]
%   'clim_Cz'             - 杂质浓度colorbar范围，默认: [0.01, 0.1]
%   'cz_scale'            - 杂质浓度标尺类型: 'linear' 或 'log'，默认: 'log'
%   'save_fig'            - 是否保存为.fig文件，默认: true
%   'save_path'           - 保存路径，默认: 当前目录 './'
%
% 输出：
%   无返回值，直接生成figure窗口（可选保存为.fig文件）
%
% 依赖函数：
%   surfplot, plot3sep, plotstructure (外部自定义函数)
%
% 注意事项：
%   - 杂质离子浓度定义: c_ne = (Ne1+ + Ne2+ + ... + Ne10+) / ne
%   - 不包含中性Ne原子 (Ne0)
%   - 兼容 MATLAB R2019a
%
% =========================================================================

%% 解析输入参数
p = inputParser;
addParameter(p, 'use_custom_colormap', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'clim_totrad', [5e5, 1e7], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'clim_Ne_rad', [5e5, 1e7], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'clim_Cz', [0.01, 0.1], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'cz_scale', 'log', @(x) ismember(x, {'linear', 'log'}));
addParameter(p, 'save_fig', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'save_path', './', @ischar);
parse(p, varargin{:});

% 提取解析后的参数到局部变量，便于后续使用
use_custom_colormap = logical(p.Results.use_custom_colormap);
clim_totrad = p.Results.clim_totrad;
clim_Ne_rad = p.Results.clim_Ne_rad;
clim_Cz = p.Results.clim_Cz;
cz_scale = p.Results.cz_scale;
save_fig = logical(p.Results.save_fig);
save_path = p.Results.save_path;

%% 设置全局绘图参数
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 16);
set(0, 'DefaultTextFontSize', 16);
set(0, 'DefaultLineLineWidth', 1.5);

%% 检查输入数据有效性
num_cases = length(all_radiationData);
if num_cases < 1
    error('At least 1 case data is required');
end

%% 根据 domain 设置坐标范围和文本位置
% 预先定义不同区域的显示范围，避免后续重复判断
if domain == 1
    % 上偏滤器区域
    xlim_range = [1.30, 2.00];
    ylim_range = [0.50, 1.20];
    text_x_pos = 0.95;
    x_ticks = [];
    y_ticks = [];
elseif domain == 2
    % 下偏滤器区域
    xlim_range = [1.30, 2.05];
    ylim_range = [-1.15, -0.40];
    text_x_pos = 0.75;
    x_ticks = [];
    y_ticks = [];
else
    % 全域（domain == 0 或其他值）
    xlim_range = [1.20, 2.40];
    ylim_range = [-0.80, 1.20];
    text_x_pos = 0.75;
    
    % 固定全域时，设置合适的标尺并确保首尾都有数值
    x_ticks = 1.20:0.40:2.40;
    y_ticks = -0.80:0.40:1.20;
end

%% 预定义算例标签
% 前两个为常用的磁场方向标签，后续自动生成
case_labels = {'fav. $B_{\mathrm{T}}$', 'unfav. $B_{\mathrm{T}}$'};
for i = 3:num_cases
    case_labels{i} = sprintf('Case %d', i);
end

%% 加载自定义colormap
custom_cmap = [];
if use_custom_colormap
    try
        load('mycontour.mat', 'mycontour');
        custom_cmap = mycontour;
    catch
        % 加载失败时使用默认jet colormap
        warning('Failed to load mycontour.mat, using default jet colormap');
        use_custom_colormap = false;
    end
end

%% 定义三个子图的配置信息
% 使用结构体数组存储每个子图的参数，减少重复代码
subplot_config = struct();

% 子图1：总辐射分布
subplot_config(1).title_str = '$P_{rad}$ (W/m$^3$)';
subplot_config(1).clim = clim_totrad;
subplot_config(1).use_log = true;

% 子图2：Ne辐射分布
subplot_config(2).title_str = '$P_{rad,Ne}$ (W/m$^3$)';
subplot_config(2).clim = clim_Ne_rad;
subplot_config(2).use_log = true;

% 子图3：杂质浓度分布
subplot_config(3).title_str = '$c_{Ne}$';
subplot_config(3).clim = clim_Cz;
subplot_config(3).use_log = strcmp(cz_scale, 'log');

%% 遍历每个算例进行绘图
for iDir = 1:num_cases
    
    radInfo = all_radiationData{iDir};
    
    %% 数据预处理
    % 计算杂质离子浓度: c_ne = sum(Ne1+ to Ne10+) / ne
    % na(:,:,4:13) 对应 Ne1+ 到 Ne10+ 的密度
    impurity_ion_density = sum(radInfo.plasma.na(:,:,4:13), 3);
    cz_ratio = impurity_ion_density ./ radInfo.plasma.ne;
    
    % 处理无效值（除零、负值等）
    cz_ratio(~isfinite(cz_ratio) | cz_ratio <= 0) = NaN;
    
    % 准备三个子图的绘图数据
    % 对辐射数据取对数，并限制最小值以避免 log(0)
    plot_data = cell(1, 3);
    plot_data{1} = log10(max(radInfo.totrad_ns, clim_totrad(1)));  % 总辐射
    plot_data{2} = log10(max(radInfo.totrad_Ne, clim_Ne_rad(1)));  % Ne辐射
    
    % 杂质浓度根据标尺类型处理
    if strcmp(cz_scale, 'log')
        plot_data{3} = log10(max(cz_ratio, clim_Cz(1)));
    else
        plot_data{3} = cz_ratio;
    end
    
    %% 创建figure
    fig_width = 18;   % 1行3列布局，宽度18英寸
    fig_height = 5;   % 高度5英寸
    
    figure('Name', sprintf('Radiation Distribution - Case %d', iDir), ...
           'NumberTitle', 'off', ...
           'Color', 'w', ...
           'Units', 'inches', ...
           'Position', [1, 1, fig_width, fig_height]);
    
    %% 绘制三个子图
    % 修改原因：
    % - 不同子图的 colorbar 刻度数字长度可能不同（例如 100.00 vs 10.00），MATLAB 会据此调整
    %   各 subplot 的有效绘图区尺寸，导致导出矢量图后子图画布宽度不一致。
    % - 这里记录每个子图的 colorbar tick label，并在绘制完成后用“白色占位数字”补齐宽度，
    %   从而稳定导出时的外接矩形尺寸，方便 PPT/TeX 排版对齐。
    cb_handles = gobjects(1, 3);
    cb_tick_labels = cell(1, 3);
    for iSub = 1:3
        
        subplot(1, 3, iSub);
        
        % 绘制2D分布图
        surfplot(radInfo.gmtry, plot_data{iSub});
        shading interp;
        view(2);
        hold on;
        
        % 绘制分离面（separatrix）
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        
        % 设置colormap
        if use_custom_colormap && ~isempty(custom_cmap)
            colormap(gca, custom_cmap);
        else
            colormap(gca, jet);
        end
        
        % 获取当前子图的配置
        cfg = subplot_config(iSub);
        
        % 设置色标范围和colorbar
        if cfg.use_log
            % 对数标尺模式
            caxis([log10(cfg.clim(1)), log10(cfg.clim(2))]);
            
            % 创建colorbar并设置刻度
            cb = colorbar;
            cb_handles(iSub) = cb;
            
            % 计算缩放因子，使刻度标签更易读
            % 对于辐射量（子图1、2），使用最大值-2作为指数
            % 对于浓度（子图3），使用最小值作为指数
            if iSub <= 2
                exp_display = floor(log10(cfg.clim(2)) - 2);
            else
                exp_display = floor(log10(cfg.clim(1)));
            end
            scale_factor = 10^exp_display;
            
            % 生成4个均匀分布的刻度
            log_ticks = linspace(log10(cfg.clim(1)), log10(cfg.clim(2)), 4);
            real_ticks = 10.^log_ticks / scale_factor;
            
            % 设置colorbar刻度和标签
            tick_labels = cell(1, 4);
            for iTick = 1:4
                tick_labels{iTick} = sprintf('%.2f', real_ticks(iTick));
            end
            set(cb, 'Ticks', log_ticks, 'TickLabels', tick_labels, ...
                    'FontName', 'Times New Roman', 'FontSize', 14);
            cb_tick_labels{iSub} = tick_labels;
            
            % 添加指数标题
            title(cb, ['$\times10^{', num2str(exp_display), '}$'], ...
                  'FontSize', 14, 'Interpreter', 'latex');
        else
            % 线性标尺模式（仅用于杂质浓度）
            caxis(cfg.clim);
            cb = colorbar;
            set(cb, 'FontName', 'Times New Roman', 'FontSize', 14);
            cb_handles(iSub) = cb;
            
            % 线性模式下刻度由 MATLAB 自动生成，这里读取当前 tick label 用于后续统一补齐宽度
            raw_tick_labels = get(cb, 'TickLabels');
            if isstring(raw_tick_labels)
                raw_tick_labels = cellstr(raw_tick_labels);
            elseif ischar(raw_tick_labels)
                raw_tick_labels = cellstr(raw_tick_labels);
            end
            cb_tick_labels{iSub} = raw_tick_labels;
        end
        
        % 设置坐标轴格式
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, ...
                 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'FontSize', 18, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontSize', 18, 'Interpreter', 'latex');
        title(cfg.title_str, 'FontSize', 16, 'Interpreter', 'latex');
        
        % 设置坐标范围（必须在 axis equal 之后）
        axis equal;
        box on;
        xlim(xlim_range);
        ylim(ylim_range);
        
        % 固定全域时，手动设置刻度，确保首尾都有刻度值
        if ~isempty(x_ticks)
            set(gca, 'XTick', x_ticks);
        end
        if ~isempty(y_ticks)
            set(gca, 'YTick', y_ticks);
        end
        
        % 绘制装置结构
        plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        
        % 算例标签已移除，用户将在PPT中后期处理
        % if iSub == 1
        %     text(text_x_pos, 0.95, case_labels{iDir}, ...
        %          'Units', 'normalized', ...
        %          'FontSize', 16, 'FontWeight', 'bold', ...
        %          'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        %          'Interpreter', 'latex');
        % end
        
        %% 设置自定义 DataCursor 回调函数
        % 为当前子图配置 DataCursor，使其显示 R、Z 和物理量值
        % 准备数据信息结构体，传递给回调函数
        data_info_struct = struct();
        if iSub == 1
            data_info_struct.data_name = 'P_rad';
            data_info_struct.data_unit = 'W/m^3';
            data_info_struct.is_log = true;
        elseif iSub == 2
            data_info_struct.data_name = 'P_rad,Ne';
            data_info_struct.data_unit = 'W/m^3';
            data_info_struct.is_log = true;
        else
            data_info_struct.data_name = 'c_Ne';
            data_info_struct.data_unit = '';
            data_info_struct.is_log = cfg.use_log;
        end
        
        % 将数据信息存储到当前 axes 的 UserData 中
        % 这样 DataCursor 回调函数可以访问到这些信息
        set(gca, 'UserData', data_info_struct);
        
    end  % 子图循环结束
    
    %% 统一各子图 colorbar 刻度文字宽度（避免导出矢量图时子图尺寸不一致）
    % 修改原因：某些子图的最大刻度可能是 100.00（6字符），而另一些为 10.00（5字符），
    %           会导致导出矢量图外接矩形宽度不同。这里用白色占位数字补齐到相同字符数。
    target_len = 0;
    for iSub = 1:3
        labels_i = cb_tick_labels{iSub};
        if isempty(labels_i)
            continue;
        end
        if isstring(labels_i)
            labels_i = cellstr(labels_i);
        elseif ischar(labels_i)
            labels_i = cellstr(labels_i);
        end
        for iLab = 1:numel(labels_i)
            lab_str = labels_i{iLab};
            if isstring(lab_str)
                lab_str = char(lab_str);
            end
            target_len = max(target_len, length(lab_str));
        end
    end
    
    for iSub = 1:3
        if ~isgraphics(cb_handles(iSub))
            continue;
        end
        labels_i = cb_tick_labels{iSub};
        if isempty(labels_i)
            continue;
        end
        if isstring(labels_i)
            labels_i = cellstr(labels_i);
        elseif ischar(labels_i)
            labels_i = cellstr(labels_i);
        end
        
        padded_labels = cell(size(labels_i));
        for iLab = 1:numel(labels_i)
            lab_str = labels_i{iLab};
            if isstring(lab_str)
                lab_str = char(lab_str);
            end
            pad_count = target_len - length(lab_str);
            if pad_count > 0
                padded_labels{iLab} = ['\color{black}', lab_str, '\color{white}', repmat('0', 1, pad_count)];
            else
                padded_labels{iLab} = ['\color{black}', lab_str];
            end
        end
        
        % 注意：必须使用 'tex' 解释器以支持 \color{...}，且背景默认白色（figure Color='w'）
        set(cb_handles(iSub), 'TickLabels', padded_labels, 'TickLabelInterpreter', 'tex');
    end
    
    %% 启用 DataCursor 模式并设置回调函数
    % 为整个 figure 设置 DataCursor 回调
    dcm = datacursormode(gcf);
    set(dcm, 'Enable', 'on');
    set(dcm, 'UpdateFcn', @customDataCursorCallback);
    
    %% 保存figure为.fig文件（如果需要）
    if save_fig
        % 确保保存路径存在
        if ~exist(save_path, 'dir')
            mkdir(save_path);
        end
        
        % 生成时间戳字符串，格式：yyyyMMdd_HHmmss
        time_stamp = datestr(now, 'yyyymmdd_HHMMSS');
        
        % 生成文件名：radiation_distribution_case_X_时间戳.fig
        fig_filename = sprintf('radiation_distribution_case_%d_%s.fig', iDir, time_stamp);
        full_path = fullfile(save_path, fig_filename);
        
        % 保存为.fig格式
        savefig(gcf, full_path);
        fprintf('Saved figure to: %s\n', full_path);
    end
    
    fprintf('Completed plotting for Case %d\n', iDir);
    
end  % 算例循环结束

fprintf('\nAll cases plotting completed\n');

end


%% ========================================================================
% 局部函数：自定义 DataCursor 回调
% =========================================================================
function txt = customDataCursorCallback(~, event_obj)
% customDataCursorCallback - DataCursor 回调函数
%
% 功能：当用户点击图形数据点时，显示 R、Z 坐标和对应的物理量值
%
% 输入：
%   ~           - 未使用（DataCursor 对象）
%   event_obj   - DataCursor 事件对象
%
% 输出：
%   txt         - 要显示的文本（cell 数组）

%% 获取点击位置坐标
pos = get(event_obj, 'Position');
R_val = pos(1);  % R 坐标
Z_val = pos(2);  % Z 坐标

%% 获取物理量值
target = get(event_obj, 'Target');

% 尝试从 CData 获取物理量值
try
    data_idx = get(event_obj, 'DataIndex');
    cdata = get(target, 'CData');
    
    if numel(data_idx) == 1
        data_val = cdata(data_idx);
    else
        data_val = cdata(data_idx(1), data_idx(2));
    end
catch
    % 备用方案：使用 Z 坐标
    if length(pos) >= 3
        data_val = pos(3);
    else
        data_val = NaN;
    end
end

%% 获取当前 axes 的数据信息
ax = get(target, 'Parent');
data_info = get(ax, 'UserData');

%% 根据数据信息格式化输出
if isstruct(data_info) && isfield(data_info, 'data_name')
    data_name = data_info.data_name;
    data_unit = data_info.data_unit;
    is_log = data_info.is_log;
    
    % 如果是对数标尺，转换回原始值
    if is_log && isfinite(data_val)
        original_val = 10^data_val;
        val_str = sprintf('%.3e', original_val);
    else
        val_str = sprintf('%.4g', data_val);
    end
else
    % 默认设置
    data_name = 'Value';
    data_unit = '';
    val_str = sprintf('%.4g', data_val);
end

%% 构建显示文本
txt = {sprintf('R: %.4f m', R_val), ...
       sprintf('Z: %.4f m', Z_val)};

if isempty(data_unit)
    txt{end+1} = sprintf('%s: %s', data_name, val_str);
else
    txt{end+1} = sprintf('%s: %s %s', data_name, val_str, data_unit);
end

end
