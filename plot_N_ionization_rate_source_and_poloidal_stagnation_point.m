function plot_N_ionization_rate_source_and_poloidal_stagnation_point(all_radiationData, domain, ionization_mode)
% =========================================================================
% plot_N_ionization_rate_source_and_poloidal_stagnation_point - N杂质电离速率源与极向停滞点分布
% =========================================================================
%
% 功能描述：
%   - 绘制N杂质电离速率源的2D分布（对数标尺colormap）
%   - 检测并标注极向速度停滞点（u_pol = 0 或符号变化处）
%   - 沿通量管绘制连线，根据极向速度正负使用不同颜色
%
% 输入：
%   all_radiationData : cell数组，每个元素包含：
%       .dirName (string)   - 算例名称/目录名
%       .gmtry   (struct)   - 几何结构（crx, cry, bb, hx, vol等）
%       .plasma  (struct)   - 等离子体数据（na, fna_mdf, sna, rsana等）
%       .neut    (struct)   - 中性粒子数据（dab2等）
%   domain            : 绘图区域 (0=全域, 1=EAST上偏滤器, 2=EAST下偏滤器)
%   ionization_mode   : 电离速率电荷态 (0-7, 对应N0到N7+)
%
% 输出：
%   - 每个算例生成一个figure，保存为.fig文件（带时间戳）
%
% 使用示例：
%   plot_N_ionization_rate_source_and_poloidal_stagnation_point(all_radiationData, 0, 0)
%   plot_N_ionization_rate_source_and_poloidal_stagnation_point(all_radiationData, 2, 1)
%
% 依赖函数/工具箱：
%   - surfplot.m（外部绘图函数）
%   - plot3sep.m（分离面绘制）
%   - plotstructure.m（装置结构绘制）
%
% 注意事项：
%   - R2019a兼容（特别处理了MATLAB 2017b的colorbar设置方式）
%   - N杂质体系：D(粒子1,2) + N(粒子3-10, 即N0到N7+)
%   - rsana索引：模式0对应rsana(:,:,3), 模式7对应rsana(:,:,10)
%   - rsana单位为s^-1，除以体积得到电离密度 [m^-3 s^-1]
%   - N0电离源特殊处理：使用neut.dab2(:,:,2)密度进行修正
%   - 本文件包含9个辅助函数（compute_ionizationRate_and_uPol_2D等）；
%     拆分的唯一理由：主逻辑涉及复杂的停滞点检测、PFR区域网格拼接、
%     通量管连线绘制，不拆分会导致主函数极其冗长（>500行）且难以维护。
% =========================================================================

%% ========================== 全局参数设置 ================================
fontSize = 32;          % 统一字体大小 (坐标轴/标题/颜色栏等)，增大字体
markerSize = 9;         % 停滞点标记尺寸，增大标记尺寸
% 定义线条颜色和宽度 - 移到全局参数，确保图例和实际绘图使用相同颜色
positiveVelColor = [1.0, 0.5, 0.0];   % 明亮橙色
negativeVelColor = [0.0, 0.9, 0.9];   % 鲜亮青色
lineWidth = 2.0;                      % 增大线宽

% 检查MATLAB版本是否为2017b或更早
isMATLAB2017b = verLessThan('matlab', '9.3'); % R2017b是9.3版本

% PFR区域网格范围定义
jPFRmin = 1;           % PFR区域径向最小索引
jPFRmax = 13;          % PFR区域径向最大索引
iPFR_seg1 = 1:25;      % PFR区域第一段极向网格
iPFR_seg2 = 74:98;     % PFR区域第二段极向网格

%% ======================== 遍历所有算例并绘图 ============================
totalDirs = length(all_radiationData);
for iDir = 1 : totalDirs
    
    % ------------------- 1) 获取当前算例数据 -------------------
    dataStruct   = all_radiationData{iDir};
    gmtry_tmp    = dataStruct.gmtry;   % 几何信息 (已在主脚本中读取并存入)
    plasma_tmp   = dataStruct.plasma;  % 等离子体信息 (同上)
    neut_tmp     = dataStruct.neut;    % 中性粒子信息 (同上)
    currentLabel = dataStruct.dirName; % 目录名/算例标识，用于图窗/标题/标注
    
    % ------------------- 2) 计算电离速率源和极向速度 -------------------
    [ionRateSource2D, uPol2D] = compute_ionizationRate_and_uPol_2D(plasma_tmp, gmtry_tmp, neut_tmp, ionization_mode);
    
    % ------------------- 3) 创建图窗并设置全局字体 -------------------
    figName = sprintf('N%d+ Ionization Rate Source & Stagnation: %s', ionization_mode, currentLabel);
    
    figure('Name', figName, 'NumberTitle','off', 'Color','w',...
        'Units','pixels','Position',[100 50 1600 1200]); % 预设大图尺寸
    
    % 设置全局字体为Times New Roman(使用更兼容的方式)
    set(gcf, 'DefaultTextFontName', 'Times New Roman');
    set(gcf, 'DefaultAxesFontName', 'Times New Roman');
    
    % 设置坐标轴和文本字体大小
    set(gcf, 'DefaultAxesFontSize', fontSize);
    set(gcf, 'DefaultTextFontSize', fontSize);
    
    hold on;
    
    % (3.0) 对电离速率源数据取对数 (处理小于等于 0 的值)
    ionRateSource2D_log = log10(max(ionRateSource2D, eps)); % 使用 eps 避免 log10(0)
    
    % (3.1) 调用 surfplot 绘制电离速率源彩色图 (使用对数数据)
    surfplot(gmtry_tmp, ionRateSource2D_log);
    shading interp;
    view(2);
    colormap(jet);
    
    % 创建colorbar并获取句柄
    h_colorbar = colorbar;
    
    % (3.2) 设置colorbar显示范围和格式
    % 范围从1e21到150e21 (即1e21到1.5e23)
    minLog = 21;                    % 1e21
    maxLog = log10(150e21);         % 150e21 = 1.5e23
    caxis([minLog, maxLog]);
    logTicks = linspace(minLog, maxLog, 6);  % 增加刻度数量以更好显示范围
    baseExp = 21;
    
    % 为MATLAB 2017b兼容设置colorbar属性
    if isMATLAB2017b
        % MATLAB 2017b兼容方式
        set(h_colorbar, 'Ticks', logTicks);
        
        % 根据指数范围创建刻度标签
        tickLabels = cell(length(logTicks), 1);
        for i = 1:length(logTicks)
            % 计算相对于基准指数的系数
            coefficient = 10^(logTicks(i) - baseExp);
            
            % 以紧凑的格式显示系数（最多一位小数）
            if abs(coefficient - round(coefficient)) < 1e-10
                % 系数是整数，不显示小数点
                tickLabels{i} = sprintf('%d', round(coefficient));
            else
                % 系数不是整数，显示一位小数
                tickLabels{i} = sprintf('%.1f', coefficient);
            end
        end
        
        % 应用刻度标签
        set(h_colorbar, 'TickLabels', tickLabels);
        
        % 设置colorbar属性
        set(h_colorbar, 'FontName', 'Times New Roman');
        set(h_colorbar, 'FontSize', fontSize-6);
        set(h_colorbar, 'LineWidth', 1.5);
        
        % 设置colorbar标签
        ylabel(h_colorbar, 'Ionization Rate [m^{-3}s^{-1}]', ...
            'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
        
        % 在colorbar上方添加指数部分
        text(0.5, 1.05, ['{\times}10^{', num2str(baseExp), '}'], ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
    else
        % 新版MATLAB设置方式
        h_colorbar.Ticks = logTicks;
        
        % 根据指数范围创建刻度标签
        tickLabels = cell(length(logTicks), 1);
        for i = 1:length(logTicks)
            % 计算相对于基准指数的系数
            coefficient = 10^(logTicks(i) - baseExp);
            
            % 以紧凑的格式显示系数（最多一位小数）
            if abs(coefficient - round(coefficient)) < 1e-10
                % 系数是整数，不显示小数点
                tickLabels{i} = sprintf('%d', round(coefficient));
            else
                % 系数不是整数，显示一位小数
                tickLabels{i} = sprintf('%.1f', coefficient);
            end
        end
        
        % 应用刻度标签
        h_colorbar.TickLabels = tickLabels;
        
        % 在colorbar上方添加指数部分作为标题
        % 使用latex格式确保数学符号正确显示
        expStr = sprintf('$\\mathbf{\\times 10^{%d}}$', baseExp);
        title(h_colorbar, expStr, 'FontSize', fontSize-2, 'Interpreter', 'latex');
        
        % 修改标签文本
        h_colorbar.Label.String = 'Ionization Rate [m$^{-3}$s$^{-1}$]';
        h_colorbar.Label.Interpreter = 'latex';
        h_colorbar.Label.FontSize = fontSize-2;
        h_colorbar.Label.FontWeight = 'bold';
        
        % 设置colorbar属性
        h_colorbar.FontName = 'Times New Roman';
        h_colorbar.FontSize = fontSize-6;
        h_colorbar.LineWidth = 1.5;  % 增加线宽
    end
    
    % (3.3) 叠加分离器/结构 (可选)
    plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);
    
    % (3.4) 设置标题及坐标轴标签
    xlabel('$R$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontSize', fontSize, 'Interpreter', 'latex');
    
    % (3.5) 设置坐标轴属性
    axis equal tight; % 合并等效命令
    box on;
    grid on;
    set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5); % 确保坐标轴字体应用统一设置
    
    % ------------------- 4) 根据 domain 裁剪绘制区域 -------------------
    if domain~=0
        switch domain
            case 1  % 上偏滤器示例区域
                xlim([1.30, 2.00]);
                ylim([0.50, 1.20]);
            case 2  % 下偏滤器示例区域
                xlim([1.30, 2.05]);
                ylim([-1.15, -0.40]);
        end
        
        % 添加结构绘制，类似于plot_ne_te_ti_distribution.m中的调用
        if isfield(dataStruct, 'structure')
            plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
        end
    end
    
    % ------------------- 5) 检测并标注极向速度停滞点 -------------------
    jSOLmin = 14;       % 外SOL区域最小径向索引，包含分离面外第一个径向网格
    jSOLmax = 27;       % 外SOL区域最大径向索引，不使用最外层guard cell
    
    % 传递PFR区域参数到停滞点检测函数
    [stagnationMask, stagPoints] = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax, jPFRmin, jPFRmax, iPFR_seg1, iPFR_seg2);
    
    % (5.1) 计算网格中心坐标
    [rCenter, zCenter] = computeCellCentersFromCorners(gmtry_tmp.crx, gmtry_tmp.cry);
    
    % (5.2) 绘制停滞点 (白色圆圈)
    [iPosVec, jPosVec] = find(stagnationMask == 1);
    for k = 1 : length(iPosVec)
        ii = iPosVec(k);
        jj = jPosVec(k);
        rr = rCenter(ii, jj);
        zz = zCenter(ii, jj);
        valZ = ionRateSource2D_log(ii, jj); % Z方向值取自**对数**电离速率源数据
        plot3(rr, zz, valZ, 'o', 'Color', 'w', 'MarkerSize', markerSize, 'LineWidth', 1.5);
    end
    
    % (5.3) 沿通量管连接停滞点，并根据极向速度正负值使用不同颜色
    connectStagnationPointsAlongFluxTubes(stagPoints, gmtry_tmp, rCenter, zCenter, ionRateSource2D_log, jSOLmin, jSOLmax, uPol2D, positiveVelColor, negativeVelColor, lineWidth);
    
    % (5.4) 添加固定的图例，只显示两个条目 - 使用更清晰的格式
    h1 = plot(NaN, NaN, '-', 'Color', positiveVelColor, 'LineWidth', lineWidth*2);
    h2 = plot(NaN, NaN, '-', 'Color', negativeVelColor, 'LineWidth', lineWidth*2);
    if isMATLAB2017b
        % MATLAB 2017b兼容的图例设置
        leg_handles = [h1, h2];
        leg_text = {'Positive u_{pol}', 'Negative u_{pol}'};
        lgd = legend(leg_handles, leg_text, 'Location', 'northeast');
        set(lgd, 'FontSize', fontSize-8, 'FontName', 'Times New Roman');
        set(lgd, 'Box', 'on', 'LineWidth', 1.2);
    else
        % 新版MATLAB的图例设置
        lgd = legend([h1, h2], 'Positive $u_{pol}$', 'Negative $u_{pol}$', 'Location', 'northeast');
        set(lgd, 'FontSize', fontSize-8, 'TextColor', 'black', 'Box', 'on');
        set(lgd, 'Interpreter', 'latex', 'FontName', 'Times New Roman');
        lgd.LineWidth = 1.2;
    end
    
    % ------------------- 6) 保存带时间戳的图窗 -------------------
    saveFigureWithTimestamp(sprintf('N%d_IonizationRate_Stagnation_logScale', ionization_mode));
    
    hold off;
end

fprintf('\n>>> Completed: N%d+ ionization rate (log scale) and poloidal stagnation point distribution for all cases.\n', ionization_mode);

end % 主函数结束


%% =========================================================================
%% (A) 计算二维电离速率源及极向速度分布
%% =========================================================================
function [ionRateSource2D, uPol2D] = compute_ionizationRate_and_uPol_2D(plasma_tmp, gmtry_tmp, neut_tmp, ionization_mode)
% 说明：
%   - 电离速率源计算基于等离子体rsana数据，使用N0+到N7+的电离速率
%   - 支持特定价态电离速率(模式0-7，对应N0+到N7+)
%   - N0+电离源使用neut.dab2(:,:,2)密度进行修正
%   - rsana单位为s-1，需要除以体积得到电离密度
%   - 极向速度通过粒子通量(fna_mdf)与密度比值计算

[nx, ny, ~] = size(gmtry_tmp.crx);
ionRateSource2D = zeros(nx, ny);
uPol2D      = zeros(nx, ny);

for jPos = 1 : ny
    for iPos = 1 : nx
        % ----- 电离速率源计算 -----
        rateVal = 0;
        if isfield(plasma_tmp, 'rsana') && ndims(plasma_tmp.rsana) >= 3
            % 计算特定价态的电离速率 (0-7对应N0+到N7+)
            if ionization_mode >= 0 && ionization_mode <= 7
                compIndex = ionization_mode + 3; % 模式0对应rsana(:,:,3), 模式1对应rsana(:,:,4), 等等
                if compIndex <= size(plasma_tmp.rsana, 3)
                    if ionization_mode == 0
                        % N0+电离源特殊处理：使用neut.dab2(:,:,2)密度修正
                        % 注意：rsana是98×28网格（包含保护单元），dab2是96×26网格（裁剪后）
                        % dab2对应rsana的(2:97, 2:27)区域
                        iPos_trimmed = iPos - 1;  % 转换为裁剪网格索引
                        jPos_trimmed = jPos - 1;  % 转换为裁剪网格索引
                        
                        if isfield(neut_tmp, 'dab2') && size(neut_tmp.dab2, 3) >= 2 && ...
                                iPos_trimmed >= 1 && iPos_trimmed <= size(neut_tmp.dab2, 1) && ...
                                jPos_trimmed >= 1 && jPos_trimmed <= size(neut_tmp.dab2, 2)
                            % rsana除以na(:,:,3)再乘以dab2(:,:,2)
                            if plasma_tmp.na(iPos, jPos, 3) > 0
                                rateVal = plasma_tmp.rsana(iPos, jPos, compIndex) * ...
                                    neut_tmp.dab2(iPos_trimmed, jPos_trimmed, 2) / plasma_tmp.na(iPos, jPos, 3);
                            else
                                rateVal = 0;
                            end
                        else
                            % 如果没有dab2数据或索引超出范围，直接使用rsana
                            rateVal = plasma_tmp.rsana(iPos, jPos, compIndex);
                        end
                    else
                        % N1+到N7+直接使用rsana数据
                        rateVal = plasma_tmp.rsana(iPos, jPos, compIndex);
                    end
                end
            end
        end
        
        % rsana单位为s-1，除以体积得到电离密度 [m^-3 s^-1]
        ionRateSource2D(iPos, jPos) = rateVal / gmtry_tmp.vol(iPos, jPos);
        
        % ----- 极向速度计算 -----
        % 对于N杂质体系：D(粒子1,2) + N(粒子3-10)
        gammaPol = sum(plasma_tmp.fna_mdf(iPos, jPos, 1, 3:10)); % 3-10为N杂质离子组分
        nImp = sum(plasma_tmp.na(iPos, jPos, 3:10));            % 总N杂质离子密度
        if nImp ~= 0
            uPol2D(iPos, jPos) = gammaPol / nImp;
        else
            uPol2D(iPos, jPos) = 0;
        end
    end
end
end


%% =========================================================================
%% (B) 检测极向速度停滞点 (修改以处理PFR区域)
%% =========================================================================
function [stagnationMask, stagPoints] = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax, jPFRmin, jPFRmax, iPFR_seg1, iPFR_seg2)
% 说明：
%   - 在指定径向范围检测速度符号变化点:
%     * SOL区域: jSOLmin-jSOLmax, 极向连续编号
%     * PFR区域: jPFRmin-jPFRmax, 极向由两段拼接(iPFR_seg1和iPFR_seg2)
%   - 返回逻辑掩码矩阵，1表示停滞点
%   - 返回分组的停滞点结构体数组，按通量管组织

[nx, ny] = size(uPol2D);
stagnationMask = zeros(nx, ny);

% 存储按通量管组织的停滞点信息
% 使用cell数组，每个元素对应一个通量管
stagPoints = cell(ny, 1);

% 1. 处理SOL区域(连续极向网格)
jLo = max(jSOLmin, 1);
jHi = min(jSOLmax, ny);

for jPos = jLo : jHi % 遍历SOL通量管
    tubeStagnations = [];  % 当前通量管的停滞点
    
    for iPos = 1 : (nx - 1)
        % 检测相邻网格速度符号变化
        if uPol2D(iPos, jPos) * uPol2D(iPos+1, jPos) < 0
            stagnationMask(iPos, jPos) = 1;
            
            % 记录当前通量管的停滞点
            tubeStagnations = [tubeStagnations; iPos, jPos];
        end
    end
    
    % 按极向位置(iPos)排序
    if ~isempty(tubeStagnations)
        [~, sortIdx] = sort(tubeStagnations(:, 1));
        stagPoints{jPos} = tubeStagnations(sortIdx, :);
    end
end

% 2. 处理PFR区域(拼接极向网格)
for jPos = jPFRmin : jPFRmax % 遍历PFR通量管
    tubeStagnations = [];  % 当前通量管的停滞点
    
    % 首先处理第一段极向网格(1:25)内的停滞点
    for i = 1 : (length(iPFR_seg1) - 1)
        iPos = iPFR_seg1(i);
        iNext = iPFR_seg1(i+1);
        if uPol2D(iPos, jPos) * uPol2D(iNext, jPos) < 0
            stagnationMask(iPos, jPos) = 1;
            tubeStagnations = [tubeStagnations; iPos, jPos];
        end
    end
    
    % 处理第二段极向网格(74:98)内的停滞点
    for i = 1 : (length(iPFR_seg2) - 1)
        iPos = iPFR_seg2(i);
        iNext = iPFR_seg2(i+1);
        if uPol2D(iPos, jPos) * uPol2D(iNext, jPos) < 0
            stagnationMask(iPos, jPos) = 1;
            tubeStagnations = [tubeStagnations; iPos, jPos];
        end
    end
    
    % 特殊处理跨段停滞点: 检查第一段末尾(25)和第二段开始(74)之间
    if ~isempty(iPFR_seg1) && ~isempty(iPFR_seg2)
        iLast_seg1 = iPFR_seg1(end);
        iFirst_seg2 = iPFR_seg2(1);
        if uPol2D(iLast_seg1, jPos) * uPol2D(iFirst_seg2, jPos) < 0
            % 在两段交界处标记停滞点(选择第一段末尾)
            stagnationMask(iLast_seg1, jPos) = 1;
            tubeStagnations = [tubeStagnations; iLast_seg1, jPos];
        end
    end
    
    % 按拼接后的逻辑顺序排序停滞点
    if ~isempty(tubeStagnations)
        % 创建排序键: 给第二段极向点更高的排序值
        sortKeys = zeros(size(tubeStagnations, 1), 1);
        for idx = 1:size(tubeStagnations, 1)
            iPos = tubeStagnations(idx, 1);
            if ismember(iPos, iPFR_seg1)
                sortKeys(idx) = find(iPFR_seg1 == iPos); % 第一段索引转换为序号
            else
                sortKeys(idx) = length(iPFR_seg1) + find(iPFR_seg2 == iPos); % 第二段索引转换为延续的序号
            end
        end
        [~, sortIdx] = sort(sortKeys);
        stagPoints{jPos} = tubeStagnations(sortIdx, :);
    end
end
end

%% =========================================================================
%% (C) 计算网格中心坐标
%% =========================================================================
function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
% 说明：
%   - 通过四角坐标平均计算网格中心

rCenter = mean(crx, 3); % 第三维度平均
zCenter = mean(cry, 3);
end


%% =========================================================================
%% (D) 带时间戳保存图窗
%% =========================================================================
function saveFigureWithTimestamp(baseName)
% 说明：
%   - 保存为.fig格式，文件名包含生成时间戳
%   - 自动调整窗口尺寸避免裁剪

% 确保图窗尺寸适合学术出版要求
set(gcf,'Units','pixels','Position',[100 50 1600 1200]); % 增大图像尺寸
set(gcf,'PaperPositionMode','auto');

% 生成时间戳
timestampStr = datestr(now,'yyyymmdd_HHMMSS');

% 保存.fig格式(用于后续编辑)
figFile = sprintf('%s_%s.fig', baseName, timestampStr);
savefig(figFile);
fprintf('Figure saved: %s\n', figFile);
end

%% =========================================================================
%% (E) 沿通量管连接停滞点 - 改进版，支持PFR区域拼接网格
%% =========================================================================
function connectStagnationPointsAlongFluxTubes(stagPoints, gmtry, rCenter, zCenter, zValues, jSOLmin, jSOLmax, uPol2D, positiveVelColor, negativeVelColor, lineWidth)
% 说明：
%   - 在每个通量管内，按照极向顺序连接停滞点
%   - 沿通量管路径绘制连线，而非直线
%   - 根据极向速度的正负值使用不同颜色
%   - 支持PFR区域网格拓扑(1:25和74:98拼接)

[nx, ~] = size(rCenter);

% 定义PFR区域参数
jPFRmin = 1;
jPFRmax = 13;
iPFR_seg1 = 1:25;
iPFR_seg2 = 74:98;

% 遍历SOL区通量管
for jPos = jSOLmin : jSOLmax
    connectStagnationsInNormalTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
        positiveVelColor, negativeVelColor, lineWidth, nx);
end

% 遍历PFR区通量管
for jPos = jPFRmin : jPFRmax
    connectStagnationsInPFRTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
        positiveVelColor, negativeVelColor, lineWidth, iPFR_seg1, iPFR_seg2);
end
end

% 处理普通通量管(连续极向网格)的停滞点连接
function connectStagnationsInNormalTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
    positiveVelColor, negativeVelColor, lineWidth, nx)
% 获取当前通量管的停滞点
tubeStagPoints = stagPoints{jPos};

% 如果这个通量管有停滞点
if ~isempty(tubeStagPoints)
    % 获取停滞点的极向索引
    iPositions = tubeStagPoints(:, 1);
    numStags = length(iPositions);
    
    % 在通量管内按顺序连接停滞点
    for k = 1 : (numStags - 1)
        iStart = iPositions(k);
        iEnd = iPositions(k+1);
        
        % 判断连线区域的极向速度符号
        midPos = floor((iStart + iEnd) / 2);
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        % 绘制当前两个停滞点之间的通量管路径
        drawFluxTubeSegment(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
    
    % 连接到边界
    if numStags > 0
        % 连接第一个停滞点到内靶板
        if iPositions(1) > 1
            if uPol2D(round(iPositions(1)/2), jPos) >= 0
                lineColor = positiveVelColor;
            else
                lineColor = negativeVelColor;
            end
            drawFluxTubeSegment(1, iPositions(1), jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
        end
        
        % 连接最后一个停滞点到外靶板
        if iPositions(end) < nx
            midPos = floor((iPositions(end) + nx) / 2);
            midPos = min(midPos, nx);
            if uPol2D(midPos, jPos) >= 0
                lineColor = positiveVelColor;
            else
                lineColor = negativeVelColor;
            end
            drawFluxTubeSegment(iPositions(end), nx, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
        end
    end
else
    % 如果通量管上没有停滞点，检查整个通量管的速度符号
    if any(~isnan(uPol2D(:, jPos)))
        midPoint = floor(nx/2);
        if uPol2D(midPoint, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        drawFluxTubeSegment(1, nx, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
end
end

% 处理PFR区域通量管(拼接极向网格)的停滞点连接
function connectStagnationsInPFRTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
    positiveVelColor, negativeVelColor, lineWidth, iPFR_seg1, iPFR_seg2)
% 获取当前PFR通量管的停滞点
tubeStagPoints = stagPoints{jPos};

% 分别处理前半段和后半段的停滞点
% 前半段：1:25, 后半段：74:98
seg1_stag = [];
seg2_stag = [];

% 如果有停滞点，按段分类
if ~isempty(tubeStagPoints)
    for i = 1:size(tubeStagPoints, 1)
        iPos = tubeStagPoints(i, 1);
        if ismember(iPos, iPFR_seg1)
            seg1_stag = [seg1_stag; tubeStagPoints(i, :)];
        else
            seg2_stag = [seg2_stag; tubeStagPoints(i, :)];
        end
    end
end

% 获取前后段的边界点
first_point_seg1 = iPFR_seg1(1);  % 第一段起点 (外靶板)
last_point_seg1 = iPFR_seg1(end); % 第一段终点 (分割点)
first_point_seg2 = iPFR_seg2(1);  % 第二段起点 (分割点)
last_point_seg2 = iPFR_seg2(end); % 第二段终点 (内靶板)

%% 处理第一段 (1:25)
if ~isempty(seg1_stag)
    % 排序
    [~, sortIdx] = sort(seg1_stag(:, 1));
    seg1_stag = seg1_stag(sortIdx, :);
    
    % 1. 如果有停滞点，连接它们
    for k = 1:(size(seg1_stag, 1)-1)
        iStart = seg1_stag(k, 1);
        iEnd = seg1_stag(k+1, 1);
        
        % 判断这段区域的极向速度符号
        midPos = floor((iStart + iEnd)/2);
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        % 绘制线段
        drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
    
    % 2. 连接起点到第一个停滞点
    if seg1_stag(1, 1) > first_point_seg1
        iStart = first_point_seg1;
        iEnd = seg1_stag(1, 1);
        midPos = floor((iStart + iEnd)/2);
        
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
    
    % 3. 连接最后一个停滞点到第一段终点
    if seg1_stag(end, 1) < last_point_seg1
        iStart = seg1_stag(end, 1);
        iEnd = last_point_seg1;
        midPos = floor((iStart + iEnd)/2);
        
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
else
    % 如果第一段没有停滞点，直接连接整段
    midPos = iPFR_seg1(ceil(length(iPFR_seg1)/2));
    
    if uPol2D(midPos, jPos) >= 0
        lineColor = positiveVelColor;
    else
        lineColor = negativeVelColor;
    end
    
    drawPFRSegmentPath(first_point_seg1, last_point_seg1, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
end

%% 处理第二段 (74:98)
if ~isempty(seg2_stag)
    % 排序
    [~, sortIdx] = sort(seg2_stag(:, 1));
    seg2_stag = seg2_stag(sortIdx, :);
    
    % 1. 如果有停滞点，连接它们
    for k = 1:(size(seg2_stag, 1)-1)
        iStart = seg2_stag(k, 1);
        iEnd = seg2_stag(k+1, 1);
        
        % 判断这段区域的极向速度符号
        midPos = floor((iStart + iEnd)/2);
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        % 绘制线段
        drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
    
    % 2. 连接第二段起点到第一个停滞点
    if seg2_stag(1, 1) > first_point_seg2
        iStart = first_point_seg2;
        iEnd = seg2_stag(1, 1);
        midPos = floor((iStart + iEnd)/2);
        
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
    
    % 3. 连接最后一个停滞点到内靶板
    if seg2_stag(end, 1) < last_point_seg2
        iStart = seg2_stag(end, 1);
        iEnd = last_point_seg2;
        midPos = floor((iStart + iEnd)/2);
        
        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end
        
        drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end
else
    % 如果第二段没有停滞点，直接连接整段
    midPos = iPFR_seg2(ceil(length(iPFR_seg2)/2));
    
    if uPol2D(midPos, jPos) >= 0
        lineColor = positiveVelColor;
    else
        lineColor = negativeVelColor;
    end
    
    drawPFRSegmentPath(first_point_seg2, last_point_seg2, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
end

% 连接两段之间的虚线
r1 = rCenter(last_point_seg1, jPos);
z1 = zCenter(last_point_seg1, jPos);
val1 = zValues(last_point_seg1, jPos);

r2 = rCenter(first_point_seg2, jPos);
z2 = zCenter(first_point_seg2, jPos);
val2 = zValues(first_point_seg2, jPos);

% 使用前半段末尾的极向速度确定连接线颜色
if uPol2D(last_point_seg1, jPos) >= 0
    lineColor = positiveVelColor;
else
    lineColor = negativeVelColor;
end

% 绘制两段间的虚线连接
plot3([r1, r2], [z1, z2], [val1, val2], '--', 'Color', lineColor, 'LineWidth', lineWidth);
end

% 专门为PFR区域绘制通量管段的辅助函数
function drawPFRSegmentPath(iStart, iEnd, jChannel, rCenter, zCenter, zValues, color, width)
% 说明：
%   - 在PFR区域沿着通量管(jChannel)绘制从iStart到iEnd的路径段

% 确保起点小于终点
iMin = min(iStart, iEnd);
iMax = max(iStart, iEnd);

% 提取路径所有点的坐标
iPoints = iMin:iMax;
r_path = rCenter(iPoints, jChannel);
z_path = zCenter(iPoints, jChannel);
valZ_path = zValues(iPoints, jChannel);

% 绘制3D路径
plot3(r_path, z_path, valZ_path, '-', 'Color', color, 'LineWidth', width);
end

%% =========================================================================
%% (F) 绘制通量管段
%% =========================================================================
function drawFluxTubeSegment(iStart, iEnd, jChannel, rCenter, zCenter, zValues, color, width)
% 说明：
%   - 沿着通量管(jChannel)绘制从iStart到iEnd的路径段
%   - 使用传入的颜色参数（基于速度符号）

% 确保起点小于终点
iMin = min(iStart, iEnd);
iMax = max(iStart, iEnd);

% 提取路径所有点的坐标
iPoints = iMin:iMax;
r_path = rCenter(iPoints, jChannel);
z_path = zCenter(iPoints, jChannel);

% 确保z坐标值来自zValues（这里是ionRateSource_log）
valZ_path = zValues(iPoints, jChannel);

% 绘制3D路径
plot3(r_path, z_path, valZ_path, '-', 'Color', color, 'LineWidth', width);
end
