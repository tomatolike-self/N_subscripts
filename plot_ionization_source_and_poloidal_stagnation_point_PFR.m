function plot_ionization_source_and_poloidal_stagnation_point_PFR(all_radiationData, domain, plotPFRStagnation)
    % =========================================================================
    % 功能：
    %   针对每个算例(已在 all_radiationData 中存有 gmtry/plasma 等信息)，在 2D 平面上绘制：
    %     1) 电离源分布 (ionSource2D) - 修改为 Ne1+ 到 Ne10+ 的总和, **使用对数标尺显示**
    %     2) 极向速度停滞点 (u_pol = 0 或符号变换)
    %     3) 沿通量管绘制连线，正负速度用不同颜色表示
    %
    % 输入参数：
    %   all_radiationData : cell 数组，每个元素包含至少：
    %       .dirName (string)   : 当前算例名称/目录名
    %       .gmtry   (struct)   : 与 read_b2fgmtry 类似的几何结构(包含 crx, cry, bb, hx 等)
    %       .plasma  (struct)   : 与 read_b2fplasmf 类似的等离子体数据(包含 na, fna_mdf, sna 等)
    %
    %   domain            : 用户选择的绘图区域 (0=全域,1=EAST上偏滤器,2=EAST下偏滤器)
    %   plotPFRStagnation (logical, optional): 是否绘制 PFR 区域的停滞点和连线 (默认: true)
    %                       设置为 false 时，仅绘制 SOL 区域的停滞点和连线
    %
    % 依赖函数：
    %   - surfplot.m     (外部已存在的绘图函数)
    %   - plot3sep.m     (可选, 在图上叠加分离器/壁结构)
    %   - compute_ionSource_and_uPol_2D (本脚本中附带)
    %   - detect_poloidal_stagnation    (本脚本中附带)
    %   - computeCellCentersFromCorners (本脚本中附带)
    %   - saveFigureWithTimestamp       (本脚本中附带)
    %
    % 更新说明：
    %   - 添加全局字体大小控制参数 fontSize
    %   - 移除图例显示以提高图像简洁性
    %   - 增强颜色栏和标题的字体控制
    %   - 修改 colorbar 的颜色映射上下限为 **对数标尺下的 [22, 23]** (对应线性标尺 1e22 到 1e23)
    %   - 修改电离源计算，统计 Ne1+ 到 Ne10+ 的总和
    %   - **修改电离源的绘制使用对数标尺**
    %   - **改进通量管连接，根据极向速度正负使用不同颜色绘制连线**
    %   - **新增 plotPFRStagnation 参数，控制是否绘制 PFR 区域停滞点**
    % =========================================================================

    %% --- 增强的输入参数处理 ---
    % 处理 all_radiationData 类型
    if iscell(all_radiationData) && length(all_radiationData) == 1 && iscell(all_radiationData{1})
        all_radiationData = all_radiationData{1};
    end
    
    % 确保 domain 是数值标量
    if iscell(domain)
        if isnumeric(domain{1})
            domain = domain{1};
        else
            % 如果仍不是数值，使用默认值
            domain = 0;
            warning('Invalid domain parameter. Using default value 0 (whole domain).');
        end
    elseif ~isnumeric(domain)
        domain = 0;
        warning('Invalid domain parameter. Using default value 0 (whole domain).');
    end
    
    % 确保 plotPFRStagnation 是逻辑标量
    if nargin < 3 || isempty(plotPFRStagnation)
        plotPFRStagnation = true; % 默认绘制 PFR 区域停滞点
    elseif iscell(plotPFRStagnation)
        if islogical(plotPFRStagnation{1}) || isnumeric(plotPFRStagnation{1})
            plotPFRStagnation = logical(plotPFRStagnation{1});
        else
            plotPFRStagnation = true;
            warning('Invalid plotPFRStagnation parameter. Using default value true.');
        end
    elseif ~islogical(plotPFRStagnation) && ~isnumeric(plotPFRStagnation)
        plotPFRStagnation = true;
        warning('Invalid plotPFRStagnation parameter. Using default value true.');
    else
        plotPFRStagnation = logical(plotPFRStagnation);
    end
    
    % 参数验证完成后打印确认信息
    fprintf('Parameters processed: domain=%d, plotPFRStagnation=%d\n', domain, plotPFRStagnation);

    %% ========================== 全局参数设置 ================================
    fontSize = 26;          % 统一字体大小 (坐标轴/标题/颜色栏等)
    markerSize = 3;         % 停滞点标记尺寸

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
        currentLabel = dataStruct.dirName; % 目录名/算例标识，用于图窗/标题/标注

        % ------------------- 2) 计算电离源和极向速度 -------------------
        [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp);

        % ------------------- 3) 创建图窗并设置全局字体 -------------------
        figName = sprintf('IonSource & Stagnation: %s', currentLabel);
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
               'DefaultAxesFontSize', fontSize, 'DefaultTextFontSize', fontSize);
        hold on;

        % (3.0) 对电离源数据取对数 (处理小于等于 0 的值)
        ionSource2D_log = log10(max(ionSource2D, eps)); % 使用 eps 避免 log10(0)

        % (3.1) 调用 surfplot 绘制电离源彩色图 (使用对数数据)
        surfplot(gmtry_tmp, ionSource2D_log);
        shading interp;
        view(2);
        colormap(jet);
        colorbarHandle = colorbar;

        % (3.2) 设置颜色栏标签及字体 (修改为对数标尺)
        colorbarHandle.Label.String = 'log_{10}(Ionization Source) [log_{10}(s^{-1}m^{-3})]';
        colorbarHandle.Label.FontSize = fontSize;

        % (3.3) 叠加分离器/结构 (可选)
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.0);

        % (3.4) 设置标题及坐标轴标签 (标题中注明对数标尺)
        title('Log_{10}(Ionization Source) (Ne1+ to Ne10+) and Poloidal Stagnation','FontSize', fontSize+2); % 标题稍大
        xlabel('R (m)', 'FontSize', fontSize);
        ylabel('Z (m)', 'FontSize', fontSize);

        % (3.5) 设置坐标轴属性
        axis equal tight; % 合并等效命令
        box on;
        grid on;
        set(gca, 'FontSize', fontSize); % 确保坐标轴字体应用统一设置

        % (3.6) 设置颜色映射的上下限 -  固定为 [22, 23] in log scale
        caxis([22, 23]);


        % ------------------- 4) 根据 domain 裁剪绘制区域 -------------------
        if isequal(domain, 1) % EAST上偏滤器
            xlim([1.30, 2.00]);
            ylim([0.50, 1.20]);
            
            % 添加结构绘制
            if isfield(dataStruct, 'structure')
                plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
            end
        elseif isequal(domain, 2) % EAST下偏滤器
            xlim([1.30, 2.05]);
            ylim([-1.15, -0.40]);
            
            % 添加结构绘制
            if isfield(dataStruct, 'structure')
                plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
            end
        end

        % (4.1) 在图窗顶部添加算例标识文本
        uicontrol('Style','text',...
                  'String', currentLabel,...
                  'Units','normalized',...
                  'Position',[0.25 0.96 0.5 0.03],...
                  'BackgroundColor','w','ForegroundColor','k','FontSize',fontSize-2);

        % ------------------- 5) 检测并标注极向速度停滞点 -------------------
        jSOLmin = 14;       % 外SOL区域最小径向索引，包含分离面外第一个径向网格
        jSOLmax = 27;       % 外SOL区域最大径向索引，不使用最外层guard cell

        % 传递PFR区域参数和 plotPFRStagnation 标志到停滞点检测函数
        [stagnationMask, stagPoints] = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax, jPFRmin, jPFRmax, iPFR_seg1, iPFR_seg2, plotPFRStagnation);

        % (5.1) 计算网格中心坐标
        [rCenter, zCenter] = computeCellCentersFromCorners(gmtry_tmp.crx, gmtry_tmp.cry);

        % (5.2) 绘制停滞点 (白色圆圈)
        [iPosVec, jPosVec] = find(stagnationMask == 1);
        for k = 1 : length(iPosVec)
            ii = iPosVec(k);
            jj = jPosVec(k);
            rr = rCenter(ii, jj);
            zz = zCenter(ii, jj);
            valZ = ionSource2D_log(ii, jj); % Z方向值取自**对数**电离源数据
            plot3(rr, zz, valZ, 'o', 'Color', 'w', 'MarkerSize', markerSize);
        end

        % (5.3) 沿通量管连接停滞点，并根据极向速度正负值使用不同颜色
        connectStagnationPointsAlongFluxTubes(stagPoints, gmtry_tmp, rCenter, zCenter, ionSource2D_log, jSOLmin, jSOLmax, uPol2D, plotPFRStagnation, jPFRmin, jPFRmax, iPFR_seg1, iPFR_seg2);

        % (5.4) 添加固定的图例，只显示两个条目
        positiveVelColor = [0, 0.7, 1.0];    % 亮蓝色(较明显区别于背景)
        negativeVelColor = [1.0, 0.2, 0.2];  % 红色
        lineWidth = 1.5;
        h1 = plot(NaN, NaN, '-', 'Color', positiveVelColor, 'LineWidth', lineWidth*1.5);
        h2 = plot(NaN, NaN, '-', 'Color', negativeVelColor, 'LineWidth', lineWidth*1.5);
        lgd = legend([h1, h2], 'Positive poloidal velocity', 'Negative poloidal velocity', 'Location', 'northeast');
        set(lgd, 'FontSize', 12, 'TextColor', 'black', 'Box', 'on');

        % ------------------- 6) 保存带时间戳的图窗 -------------------
        saveFigureWithTimestamp('IonSource_Stagnation_logScale'); % 修改保存文件名以区分线性标尺和对数标尺

        hold off;
    end

    fprintf('\n>>> Completed: Ionization source (log scale) and poloidal stagnation point distribution for all cases (Ne1+ to Ne10+ ion source).\n');

end % 主函数结束


%% =========================================================================
%% (A) 计算二维电离源及极向速度分布 (子函数保持不变)
%% =========================================================================
function [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp)
    % 说明：
    %   - 电离源计算基于等离子体源项(sna)和密度(na)数据, 修改为 Ne1+ 到 Ne10+ 的总和
    %   - 极向速度通过粒子通量(fna_mdf)与密度比值计算

    [nx, ny, ~] = size(gmtry_tmp.crx);
    ionSource2D = zeros(nx, ny);
    uPol2D      = zeros(nx, ny);

    for jPos = 1 : ny
        for iPos = 1 : nx
            % ----- 电离源计算 (Ne1+ to Ne10+) -----
            sVal = 0;
            if isfield(plasma_tmp, 'sna') && ndims(plasma_tmp.sna) >= 4
                for iComp = 4:13 % na(:,:,4:13) 对应 Ne1+ 到 Ne10+
                    coeff0_iComp = plasma_tmp.sna(iPos, jPos, 1, iComp);
                    coeff1_iComp = plasma_tmp.sna(iPos, jPos, 2, iComp);
                    n_iComp = plasma_tmp.na(iPos, jPos, iComp);
                    sVal_iComp = (coeff0_iComp + coeff1_iComp * n_iComp);
                    sVal = sVal + sVal_iComp; % 累加电离源
                end
            end
            ionSource2D(iPos, jPos) = sVal;
            ionSource2D(iPos, jPos) = ionSource2D(iPos, jPos) / gmtry_tmp.vol(iPos, jPos); % 单元体积归一化

            % ----- 极向速度计算 -----
            gammaPol = sum(plasma_tmp.fna_mdf(iPos, jPos, 1, 4:13)); % 4-13为杂质离子组分
            nImp = sum(plasma_tmp.na(iPos, jPos, 4:13));            % 总杂质离子密度
            if nImp ~= 0
                uPol2D(iPos, jPos) = gammaPol / nImp;
            else
                uPol2D(iPos, jPos) = 0;
            end
        end
    end
end


%% =========================================================================
%% (B) 检测极向速度停滞点 (修改以处理PFR区域, 并添加 plotPFRStagnation 开关)
%% =========================================================================
function [stagnationMask, stagPoints] = detect_poloidal_stagnation(uPol2D, jSOLmin, jSOLmax, jPFRmin, jPFRmax, iPFR_seg1, iPFR_seg2, plotPFRStagnation)
    % 说明：
    %   - 在指定径向范围检测速度符号变化点:
    %     * SOL区域: jSOLmin-jSOLmax, 极向连续编号
    %     * PFR区域: jPFRmin-jPFRmax, 极向由两段拼接(iPFR_seg1和iPFR_seg2)
    %   - 返回逻辑掩码矩阵，1表示停滞点
    %   - 返回分组的停滞点结构体数组，按通量管组织
    %   - plotPFRStagnation: 控制是否检测 PFR 区域停滞点，为 false 时跳过 PFR 检测

    [nx, ny] = size(uPol2D);
    stagnationMask = zeros(nx, ny);
    stagPoints = cell(ny, 1); % 存储按通量管组织的停滞点信息

    % 1. 处理SOL区域(连续极向网格)
    jLo = max(jSOLmin, 1);
    jHi = min(jSOLmax, ny);

    for jPos = jLo : jHi % 遍历SOL通量管
        tubeStagnations = [];  % 当前通量管的停滞点

        for iPos = 1 : (nx - 1)
            % 检测相邻网格速度符号变化
            if uPol2D(iPos, jPos) * uPol2D(iPos+1, jPos) < 0
                stagnationMask(iPos, jPos) = 1;
                tubeStagnations = [tubeStagnations; iPos, jPos];
            end
        end

        % 按极向位置(iPos)排序
        if ~isempty(tubeStagnations)
            [~, sortIdx] = sort(tubeStagnations(:, 1));
            stagPoints{jPos} = tubeStagnations(sortIdx, :);
        end
    end

    % 2. 处理PFR区域(拼接极向网格) -  仅当 plotPFRStagnation 为 true 时执行
    if plotPFRStagnation
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
    end % end of PFR region processing
end

%% =========================================================================
%% (C) 计算网格中心坐标 (子函数保持不变)
%% =========================================================================
function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
    % 说明：
    %   - 通过四角坐标平均计算网格中心

    rCenter = mean(crx, 3); % 第三维度平均
    zCenter = mean(cry, 3);
end


%% =========================================================================
%% (D) 带时间戳保存图窗 (子函数保持不变)
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 说明：
    %   - 保存为.fig格式，文件名包含生成时间戳
    %   - 自动调整窗口尺寸避免裁剪

    set(gcf,'Units','pixels','Position',[100 50 1200 800]);
    set(gcf,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end

%% =========================================================================
%% (NEW) 沿通量管连接停滞点 - 改进版，支持PFR区域拼接网格 和 plotPFRStagnation 开关
%% =========================================================================
function connectStagnationPointsAlongFluxTubes(stagPoints, gmtry, rCenter, zCenter, zValues, jSOLmin, jSOLmax, uPol2D, plotPFRStagnation, jPFRmin, jPFRmax, iPFR_seg1, iPFR_seg2)
    % 说明：
    %   - 在每个通量管内，按照极向顺序连接停滞点
    %   - 沿通量管路径绘制连线，而非直线
    %   - 根据极向速度的正负值使用不同颜色
    %   - 支持PFR区域网格拓扑(1:25和74:98拼接)
    %   - plotPFRStagnation: 控制是否连接 PFR 区域停滞点，为 false 时跳过 PFR 连接

    [nx, ny] = size(rCenter);
    positiveVelColor = [0, 0.7, 1.0];    % 亮蓝色
    negativeVelColor = [1.0, 0.2, 0.2];  % 红色
    lineWidth = 1.5;                     % 线宽

    % 遍历SOL区通量管
    for jPos = jSOLmin : jSOLmax
        connectStagnationsInNormalTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
            positiveVelColor, negativeVelColor, lineWidth, nx);
    end

    % 遍历PFR区通量管 - 仅当 plotPFRStagnation 为 true 时执行
    if plotPFRStagnation
        for jPos = jPFRmin : jPFRmax
            connectStagnationsInPFRTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
                positiveVelColor, negativeVelColor, lineWidth, iPFR_seg1, iPFR_seg2);
        end
    end
end

% 处理普通通量管(连续极向网格)的停滞点连接 (子函数保持不变)
function connectStagnationsInNormalTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
                                        positiveVelColor, negativeVelColor, lineWidth, nx)
    % (函数内容保持不变 - 与之前的版本相同)
    tubeStagPoints = stagPoints{jPos};

    if ~isempty(tubeStagPoints)
        iPositions = tubeStagPoints(:, 1);
        numStags = length(iPositions);

        for k = 1 : (numStags - 1)
            iStart = iPositions(k);
            iEnd = iPositions(k+1);
            midPos = floor((iStart + iEnd) / 2);
            if uPol2D(midPos, jPos) >= 0
                lineColor = positiveVelColor;
            else
                lineColor = negativeVelColor;
            end
            drawFluxTubeSegment(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
        end

        if numStags > 0
            if iPositions(1) > 1
                if uPol2D(round(iPositions(1)/2), jPos) >= 0
                    lineColor = positiveVelColor;
                else
                    lineColor = negativeVelColor;
                end
                drawFluxTubeSegment(1, iPositions(1), jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
            end

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

% 处理PFR区域通量管(拼接极向网格)的停滞点连接 - 修改版 (子函数保持不变)
function connectStagnationsInPFRTube(jPos, stagPoints, rCenter, zCenter, zValues, uPol2D, ...
    positiveVelColor, negativeVelColor, lineWidth, iPFR_seg1, iPFR_seg2)
    % (函数内容保持不变 - 与之前的版本相同)
    tubeStagPoints = stagPoints{jPos};

    seg1_stag = [];
    seg2_stag = [];

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

    first_point_seg1 = iPFR_seg1(1);
    last_point_seg1 = iPFR_seg1(end);
    first_point_seg2 = iPFR_seg2(1);
    last_point_seg2 = iPFR_seg2(end);

    %% 处理第一段 (1:25)
    if ~isempty(seg1_stag)
        [~, sortIdx] = sort(seg1_stag(:, 1));
        seg1_stag = seg1_stag(sortIdx, :);

        for k = 1:(size(seg1_stag, 1)-1)
            iStart = seg1_stag(k, 1);
            iEnd = seg1_stag(k+1, 1);
            midPos = floor((iStart + iEnd)/2);
            if uPol2D(midPos, jPos) >= 0
                lineColor = positiveVelColor;
            else
                lineColor = negativeVelColor;
            end
            drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
        end

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
        [~, sortIdx] = sort(seg2_stag(:, 1));
        seg2_stag = seg2_stag(sortIdx, :);

        for k = 1:(size(seg2_stag, 1)-1)
            iStart = seg2_stag(k, 1);
            iEnd = seg2_stag(k+1, 1);
            midPos = floor((iStart + iEnd)/2);
            if uPol2D(midPos, jPos) >= 0
                lineColor = positiveVelColor;
            else
                lineColor = negativeVelColor;
            end
            drawPFRSegmentPath(iStart, iEnd, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
        end

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
        midPos = iPFR_seg2(ceil(length(iPFR_seg2)/2));

        if uPol2D(midPos, jPos) >= 0
            lineColor = positiveVelColor;
        else
            lineColor = negativeVelColor;
        end

        drawPFRSegmentPath(first_point_seg2, last_point_seg2, jPos, rCenter, zCenter, zValues, lineColor, lineWidth);
    end

    r1 = rCenter(last_point_seg1, jPos);
    z1 = zCenter(last_point_seg1, jPos);
    val1 = zValues(last_point_seg1, jPos);

    r2 = rCenter(first_point_seg2, jPos);
    z2 = zCenter(first_point_seg2, jPos);
    val2 = zValues(first_point_seg2, jPos);

    if uPol2D(last_point_seg1, jPos) >= 0
        lineColor = positiveVelColor;
    else
        lineColor = negativeVelColor;
    end
    plot3([r1, r2], [z1, z2], [val1, val2], '--', 'Color', lineColor, 'LineWidth', lineWidth);
end

% 专门为PFR区域绘制通量管段的辅助函数 (子函数保持不变)
function drawPFRSegmentPath(iStart, iEnd, jChannel, rCenter, zCenter, zValues, color, width)
    % (函数内容保持不变 - 与之前的版本相同)
    iMin = min(iStart, iEnd);
    iMax = max(iStart, iEnd);

    iPoints = iMin:iMax;
    r_path = rCenter(iPoints, jChannel);
    z_path = zCenter(iPoints, jChannel);
    valZ_path = zValues(iPoints, jChannel);

    plot3(r_path, z_path, valZ_path, '-', 'Color', color, 'LineWidth', width);
end

%% =========================================================================
%% (E) 绘制通量管段 - 修改版以适应颜色参数 (子函数保持不变)
%% =========================================================================
function drawFluxTubeSegment(iStart, iEnd, jChannel, rCenter, zCenter, zValues, color, width)
    % (函数内容保持不变 - 与之前的版本相同)
    iMin = min(iStart, iEnd);
    iMax = max(iStart, iEnd);

    iPoints = iMin:iMax;
    r_path = rCenter(iPoints, jChannel);
    z_path = zCenter(iPoints, jChannel);
    valZ_path = zValues(iPoints, jChannel);

    plot3(r_path, z_path, valZ_path, '-', 'Color', color, 'LineWidth', width);
end