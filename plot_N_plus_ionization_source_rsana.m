function plot_N_plus_ionization_source_rsana(all_radiationData, domain, charge_state_groups)
% =========================================================================
% 功能：
%   针对每个算例，在 2D 平面上绘制基于rsana计算的N离子电离源分布
%     1) N1+ 至 N7+ 各价态电离源分布 (使用rsana计算) - **支持灵活价态选择**
%     2) 支持三种模式：
%        - 模式1: 单独绘制指定价态（每个价态一张图）
%        - 模式2: 绘制指定价态范围的总和（一张图）
%        - 模式3: 绘制默认N1+到N7+的总和（一张图）
%
% 电离源计算方式（基于rsana）：
%   - 使用 plasma.rsana 数据计算电离源强度（密度形式）
%   - rsana(:,:,3) = 电离至N1+ (N0+ → N1+, 需要用中性粒子密度修正)
%   - rsana(:,:,4) = 电离至N2+ (N1+ → N2+)
%   - ...
%   - rsana(:,:,9) = 电离至N7+ (N6+ → N7+)
%   - 电离至N1+特殊处理: rsana_corrected = rsana × neut.dab2(:,:,2) / na(:,:,3)
%   - rsana单位为s^-1，需要除以体积得到电离源密度 [m^-3 s^-1]
%
% 输入参数：
%   all_radiationData : cell 数组，每个元素包含至少：
%       .dirName (string)   : 当前算例名称/目录名
%       .gmtry   (struct)   : 几何结构(包含 crx, cry, bb, hx, vol 等)
%       .plasma  (struct)   : 等离子体数据(包含 na, rsana 等)
%       .neut    (struct)   : 中性粒子数据(包含 dab2 等)
%
%   domain            : 用户选择的绘图区域 (0=全域,1=EAST上偏滤器,2=EAST下偏滤器)
%
%   charge_state_groups : cell 数组，每个元素为需要绘制的价态索引向量
%       - 例如: {1, 2, 3} 表示分别绘制N1+, N2+, N3+（三张图）
%       - 例如: {[1 2 3]} 表示绘制N1+到N3+的总和（一张图）
%       - 例如: {1:7} 表示绘制N1+到N7+的总和（一张图）
%
% 依赖函数：
%   - surfplot.m     (外部已存在的绘图函数)
%   - plot3sep.m     (可选, 在图上叠加分离器/壁结构)
%   - compute_N_ionSource_rsana_for_charge_state (本脚本中附带)
%   - saveFigureWithTimestamp       (本脚本中附带)
%
% 更新说明：
%   - 2025-11-02: 基于plot_N_plus_ionization_source.m创建
%   - 使用rsana计算电离源强度，参考plot_core_region_ionization_fraction_by_charge_state.m
%   - 支持灵活价态选择功能
% =========================================================================

% 参数检查和默认值设置
if nargin < 3 || isempty(charge_state_groups)
    % 默认行为：分别绘制N1+到N7+
    charge_state_groups = num2cell(1:7);
end

%% ========================== 全局参数设置 ================================
fontSize = 32;          % 统一字体大小 (坐标轴/标题/颜色栏等)，增大字体

% 检查MATLAB版本兼容性
isMATLAB2017b = verLessThan('matlab', '9.3'); % MATLAB 2017b对应版本9.3

%% ========================== 主循环：遍历算例 ============================
numCases = length(all_radiationData);
for iDir = 1 : numCases
    dataStruct = all_radiationData{iDir};
    currentLabel = dataStruct.dirName;
    fprintf('\n>>> Processing case: %s\n', currentLabel);
    
    % 提取当前算例的几何和等离子体数据
    gmtry_tmp  = dataStruct.gmtry;
    plasma_tmp = dataStruct.plasma;
    neut_tmp   = dataStruct.neut;
    
    % 检查必要的数据字段
    if ~isfield(plasma_tmp, 'rsana')
        warning('Case %s: No rsana data found, skipping...', currentLabel);
        continue;
    end
    
    [nx, ny, ~] = size(gmtry_tmp.crx);
    
    % ==================== 遍历价态组合 ====================
    for iGroup = 1:length(charge_state_groups)
        % 获取当前组合的价态列表
        current_charge_states = charge_state_groups{iGroup};
        
        % 判断是单价态还是多价态组合
        is_single_state = (length(current_charge_states) == 1);
        
        % 初始化电离源矩阵
        ionSource2D_combined = zeros(nx, ny);
        
        % 累加当前组合中所有价态的电离源
        for chargeState = current_charge_states
            ionSource2D_single = compute_N_ionSource_rsana_for_charge_state(...
                plasma_tmp, neut_tmp, gmtry_tmp, chargeState);
            ionSource2D_combined = ionSource2D_combined + ionSource2D_single;
        end
        
        % 计算芯部区域的电离源统计（可选）
        % 芯部区域定义(去除保护单元后的索引)
        core_pol_start = 25;
        core_pol_end = 72;
        core_rad_start = 1;
        core_rad_end = 12;
        
        % 转换为包含保护单元的索引
        core_pol_start_full = core_pol_start + 1;
        core_pol_end_full = core_pol_end + 1;
        core_rad_start_full = core_rad_start + 1;
        core_rad_end_full = core_rad_end + 1;
        
        % 提取芯部区域数据
        if core_pol_end_full <= nx && core_rad_end_full <= ny
            core_ionSource = ionSource2D_combined(core_pol_start_full:core_pol_end_full, ...
                core_rad_start_full:core_rad_end_full);
            core_vol = gmtry_tmp.vol(core_pol_start_full:core_pol_end_full, core_rad_start_full:core_rad_end_full);
            total_ion_source_inside_sep = sum(core_ionSource(:) .* core_vol(:));
        else
            total_ion_source_inside_sep = 0;
        end
        
        % 生成图窗名称和标签
        if is_single_state
            % 单价态模式
            figName = sprintf('N%d+ IonSource (rsana): %s', current_charge_states(1), currentLabel);
            colorbar_label = sprintf('N$^{{%d+}}$ Ionization Source [m$^{-3}$s$^{-1}$]', current_charge_states(1));
            save_filename = sprintf('N%dplus_IonSource_rsana_logScale', current_charge_states(1));
        else
            % 多价态组合模式
            if isequal(current_charge_states, 1:7)
                figName = sprintf('N1-7+ Total IonSource (rsana): %s', currentLabel);
                colorbar_label = 'N$^{1-7+}$ Total Ionization Source [m$^{-3}$s$^{-1}$]';
                save_filename = 'N_Total_IonSource_rsana_logScale';
            else
                figName = sprintf('N%d-%d+ Total IonSource (rsana): %s', min(current_charge_states), max(current_charge_states), currentLabel);
                colorbar_label = sprintf('N$^{{%d-%d+}}$ Total Ionization Source [m$^{-3}$s$^{-1}$]', ...
                    min(current_charge_states), max(current_charge_states));
                save_filename = sprintf('N%d-%dplus_Total_IonSource_rsana_logScale', ...
                    min(current_charge_states), max(current_charge_states));
            end
        end
        
        % ------------------- 3) 绘制电离源分布 -------------------
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
            'Units','pixels','Position',[100 50 1600 1200]);
        
        % 设置全局字体为Times New Roman
        set(gcf, 'DefaultTextFontName', 'Times New Roman');
        set(gcf, 'DefaultAxesFontName', 'Times New Roman');
        set(gcf, 'DefaultAxesFontSize', fontSize);
        set(gcf, 'DefaultTextFontSize', fontSize);
        
        hold on;
        
        % (3.0) 对电离源数据取对数
        ionSource2D_log = log10(max(ionSource2D_combined, eps));
        
        % (3.1) 调用 surfplot 绘制电离源彩色图
        surfplot(gmtry_tmp, ionSource2D_log);
        shading interp;
        view(2);
        colormap(jet);
        
        % 创建colorbar并获取句柄
        h_colorbar = colorbar;
        
        % (3.2) 设置色轴范围
        if is_single_state
            % 单价态模式：固定范围 1e19 到 100e19 (与sna脚本保持一致)
            caxis_min_log = 19; % 对应 10^19 = 1e19
            caxis_max_log = 21; % 对应 10^21 = 100e19
            baseExp = 19;       % 指数项
        else
            % 多价态组合模式：根据价态范围自动调整
            if max(current_charge_states) <= 5
                % 低价态 (N1+ 到 N5+)
                caxis_min_log = 17; % 对应 10^17
                caxis_max_log = 20; % 对应 10^20
                baseExp = 17;       % 指数项
            else
                % 高价态 (N6+ 到 N7+)
                caxis_min_log = 19; % 对应 10^19
                caxis_max_log = 22; % 对应 10^22
                baseExp = 19;       % 指数项
            end
        end
        caxis([caxis_min_log, caxis_max_log]);
        
        % 创建5个均匀分布的刻度
        logTicks = linspace(caxis_min_log, caxis_max_log, 5);
        
        % 为MATLAB 2017b兼容设置colorbar属性
        if isMATLAB2017b
            % MATLAB 2017b兼容方式
            set(h_colorbar, 'Ticks', logTicks);
            
            % 根据指数范围创建刻度标签
            tickLabels = cell(length(logTicks), 1);
            for i = 1:length(logTicks)
                coefficient = 10^(logTicks(i) - baseExp);
                if abs(coefficient - round(coefficient)) < 1e-10
                    tickLabels{i} = sprintf('%d', round(coefficient));
                else
                    tickLabels{i} = sprintf('%.1f', coefficient);
                end
            end
            
            set(h_colorbar, 'TickLabels', tickLabels);
            set(h_colorbar, 'FontName', 'Times New Roman');
            set(h_colorbar, 'FontSize', fontSize-6);
            set(h_colorbar, 'LineWidth', 1.5);
            
            % 设置colorbar标签（使用动态生成的标签）
            ylabel(h_colorbar, colorbar_label, ...
                'Interpreter', 'latex', ...
                'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
            
            % 在colorbar上方添加指数部分
            text(0.5, 1.05, ['{\\times}10^{', num2str(baseExp), '}'], ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
        else
            % 新版MATLAB设置方式
            h_colorbar.Ticks = logTicks;
            
            % 根据指数范围创建刻度标签
            tickLabels = cell(length(logTicks), 1);
            for i = 1:length(logTicks)
                coefficient = 10^(logTicks(i) - baseExp);
                if abs(coefficient - round(coefficient)) < 1e-10
                    tickLabels{i} = sprintf('%d', round(coefficient));
                else
                    tickLabels{i} = sprintf('%.1f', coefficient);
                end
            end
            
            h_colorbar.TickLabels = tickLabels;
            
            % 在colorbar上方添加指数部分作为标题
            expStr = ['$\times 10^{', num2str(baseExp), '}$'];
            title(h_colorbar, expStr, 'FontSize', fontSize-2, 'Interpreter', 'latex', 'FontWeight', 'bold');
            
            % 修改标签文本（使用动态生成的标签）
            h_colorbar.Label.Interpreter = 'latex';
            h_colorbar.Label.String = colorbar_label;
            h_colorbar.Label.FontSize = fontSize-2;
            h_colorbar.Label.FontWeight = 'bold';
            
            % 设置colorbar属性
            h_colorbar.FontName = 'Times New Roman';
            h_colorbar.FontSize = fontSize-6;
            h_colorbar.LineWidth = 1.5;
        end
        
        % (3.3) 叠加分离器/结构 (可选)
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);
        
        % (3.4) 设置标题及坐标轴标签
        xlabel('$R$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
        ylabel('$Z$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
        
        % (3.5) 设置坐标轴属性
        axis equal tight;
        box on;
        grid on;
        set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5);
        
        % ------------------- 4) 根据 domain 裁剪绘制区域 -------------------
        if domain == 0
            xlim([1.2, 2.4]);
            ylim([-0.8, 1.2]);
            set(gca, 'XTick', 1.2:0.4:2.4, 'YTick', -0.8:0.4:1.2);
        else
            switch domain
                case 1  % 上偏滤器示例区域
                    xlim([1.30, 2.00]);
                    ylim([0.50, 1.20]);
                case 2  % 下偏滤器示例区域
                    xlim([1.30, 2.05]);
                    ylim([-1.15, -0.40]);
            end
        end
        
        % 添加结构绘制
        if isfield(dataStruct, 'structure')
            plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
        end
        
        % ------------------- 5) 保存带时间戳的图窗 -------------------
        saveFigureWithTimestamp(save_filename);
        
        hold off;
    end % 结束价态组合循环
end % 结束算例循环
end % 结束主函数



% =========================================================================
% 辅助函数：使用rsana计算指定价态的N离子电离源密度
% =========================================================================
function ionSource2D_N_ion = compute_N_ionSource_rsana_for_charge_state(plasma_tmp, neut_tmp, gmtry_tmp, chargeState)
% 说明：
%   - 电离源计算基于等离子体rsana数据, 针对指定的N价态
%   - rsana单位为s^-1，除以体积得到电离源密度 [m^-3 s^-1]
%   - 电离至N1+需要特殊处理：使用中性粒子密度修正
% 输入参数:
%   plasma_tmp  : 等离子体数据结构体
%   neut_tmp    : 中性粒子数据结构体
%   gmtry_tmp   : 几何数据结构体
%   chargeState : 整数, 1 代表电离至N1+, 2 代表电离至N2+, ..., 7 代表电离至N7+

[nx, ny, ~] = size(gmtry_tmp.crx);
ionSource2D_N_ion = zeros(nx, ny);

% 确定rsana中对应的索引
% rsana(:,:,3) = 电离至N1+ (N0+ → N1+)
% rsana(:,:,4) = 电离至N2+ (N1+ → N2+)
% ...
% rsana(:,:,9) = 电离至N7+ (N6+ → N7+)
rsana_idx = 3 + chargeState - 1;

% 检查rsana数据是否有效
if ~isfield(plasma_tmp, 'rsana') || size(plasma_tmp.rsana, 3) < rsana_idx
    warning('Insufficient rsana data for ionization to N%d+', chargeState);
    return;
end

% 获取该价态的电离速率数据(原始网格,包含保护单元)
rsana_full = plasma_tmp.rsana(:, :, rsana_idx);

% 电离至N1+特殊处理：使用中性粒子密度修正
if chargeState == 1
    if isfield(neut_tmp, 'dab2') && size(neut_tmp.dab2, 3) >= 2
        % 创建修正后的电离速率矩阵
        rsana_corrected = zeros(size(rsana_full));
        
        for iPos = 1:size(rsana_full, 1)
            for jPos = 1:size(rsana_full, 2)
                iPos_trimmed = iPos - 1;  % 转换为裁剪网格索引
                jPos_trimmed = jPos - 1;
                
                if iPos_trimmed >= 1 && iPos_trimmed <= size(neut_tmp.dab2, 1) && ...
                        jPos_trimmed >= 1 && jPos_trimmed <= size(neut_tmp.dab2, 2)
                    % rsana除以na(:,:,3)再乘以dab2(:,:,2)
                    % na(:,:,3)对应N0中性粒子密度（在plasma.na中的索引）
                    if isfield(plasma_tmp, 'na') && size(plasma_tmp.na, 3) >= 3
                        if plasma_tmp.na(iPos, jPos, 3) > 0
                            rsana_corrected(iPos, jPos) = rsana_full(iPos, jPos) * ...
                                neut_tmp.dab2(iPos_trimmed, jPos_trimmed, 2) / plasma_tmp.na(iPos, jPos, 3);
                        else
                            rsana_corrected(iPos, jPos) = 0;
                        end
                    else
                        rsana_corrected(iPos, jPos) = rsana_full(iPos, jPos);
                    end
                else
                    % 边界区域直接使用rsana
                    rsana_corrected(iPos, jPos) = rsana_full(iPos, jPos);
                end
            end
        end
        
        rsana_full = rsana_corrected;
    else
        warning('No neut.dab2 data found for ionization to N1+ correction, using uncorrected rsana');
    end
end

% 转换为电离源密度 [m^-3 s^-1]
% rsana单位为s^-1，除以体积得到密度
for jPos = 1 : ny
    for iPos = 1 : nx
        % 单元体积归一化，并检查vol字段和值的有效性
        if isfield(gmtry_tmp, 'vol') && ...
                iPos <= size(gmtry_tmp.vol,1) && jPos <= size(gmtry_tmp.vol,2) && ...
                gmtry_tmp.vol(iPos, jPos) > 0
            ionSource2D_N_ion(iPos, jPos) = rsana_full(iPos, jPos) / gmtry_tmp.vol(iPos, jPos);
        else
            ionSource2D_N_ion(iPos, jPos) = 0;
        end
    end
end
end


%% =========================================================================
%% 带时间戳保存图窗
%% =========================================================================
function saveFigureWithTimestamp(baseName)
% 说明：
%   - 保存为.fig格式，文件名包含生成时间戳
%   - 自动调整窗口尺寸避免裁剪

% 确保图窗尺寸适合学术出版要求
set(gcf,'Units','pixels','Position',[100 50 1600 1200]);
set(gcf,'PaperPositionMode','auto');

% 生成时间戳
timestampStr = datestr(now,'yyyymmdd_HHMMSS');

% 保存.fig格式(用于后续编辑)
figFile = sprintf('%s_%s.fig', baseName, timestampStr);
savefig(figFile);
fprintf('MATLAB图形文件已保存: %s\n', figFile);

end
