function plot_ionization_source_and_poloidal_stagnation_point(all_radiationData, domain)
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
    %   - 添加全局字体大小控制参数和Times New Roman字体设置
    %   - 优化颜色栏显示，将10^x作为整体后缀放在colorbar上方
    %   - 修改colorbar显示为5个刻度值，使用科学计数法
    %   - 增大字体和线宽，提高可读性和辨识度
    %   - 改进标签文本，使用LaTeX格式显示数学符号
    %   - 确保与MATLAB 2017b兼容
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
        currentLabel = dataStruct.dirName; % 目录名/算例标识，用于图窗/标题/标注

        % ------------------- 2) 计算电离源和极向速度 -------------------
        [ionSource2D, uPol2D] = compute_ionSource_and_uPol_2D(plasma_tmp, gmtry_tmp);

        % ------------------- 3) 创建图窗并设置全局字体 -------------------
        figName = sprintf('IonSource & Stagnation: %s', currentLabel);
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
               'Units','pixels','Position',[100 50 1600 1200]); % 预设大图尺寸
        
        % 设置全局字体为Times New Roman(使用更兼容的方式)
        set(gcf, 'DefaultTextFontName', 'Times New Roman');
        set(gcf, 'DefaultAxesFontName', 'Times New Roman');
        
        % 设置坐标轴和文本字体大小
        set(gcf, 'DefaultAxesFontSize', fontSize);
        set(gcf, 'DefaultTextFontSize', fontSize);
        
        hold on;

        % (3.0) 对电离源数据取对数 (处理小于等于 0 的值)
        ionSource2D_log = log10(max(ionSource2D, eps)); % 使用 eps 避免 log10(0)

        % (3.1) 调用 surfplot 绘制电离源彩色图 (使用对数数据)
        surfplot(gmtry_tmp, ionSource2D_log);
        shading interp;
        view(2);
        colormap(jet);
        
        % 创建colorbar并获取句柄
        h_colorbar = colorbar;
        
        % (3.2) 设置colorbar显示范围和格式
        caxis([21, 23]);
        
        % 创建5个均匀分布的刻度
        logTicks = linspace(21, 23, 5);
        
        % 提取最小指数值作为基准指数
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
            ylabel(h_colorbar, 'Ionization Source [m^{-3}s^{-1}]', ...
                   'FontSize', fontSize-2, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
            
            % 在colorbar上方添加指数部分
            ax_colorbar = axes('Position', get(h_colorbar, 'Position'), 'Visible', 'off');
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
            h_colorbar.Label.String = 'Ionization Source [m$^{-3}$s$^{-1}$]';
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
        % title('Log_{10}(Ionization Source) (Ne1+ to Ne10+) and Poloidal Stagnation','FontSize', fontSize+2); % 标题稍大
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

        % (4.1) 在图窗顶部添加算例标识文本 - 兼容2017b的写法
        % text(0.5, 0.98, currentLabel, 'Units', 'normalized', ...
        %      'HorizontalAlignment', 'center', 'FontSize', fontSize-6, ...
        %      'FontName', 'Times New Roman', 'FontWeight', 'bold');

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
            valZ = ionSource2D_log(ii, jj); % Z方向值取自**对数**电离源数据
            plot3(rr, zz, valZ, 'o', 'Color', 'w', 'MarkerSize', markerSize, 'LineWidth', 1.5);
        end
        
        % (5.3) 沿通量管连接停滞点，并根据极向速度正负值使用不同颜色
        connectStagnationPointsAlongFluxTubes(stagPoints, gmtry_tmp, rCenter, zCenter, ionSource2D_log, jSOLmin, jSOLmax, uPol2D, positiveVelColor, negativeVelColor, lineWidth);

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
    
    % 初始化未归一化的电离源矩阵
    rawIonSource2D = zeros(nx, ny);
    
    % 创建一个矩阵来存储Ne1+的电离源
    Ne1_ionization = zeros(nx, ny);

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
                    
                    % 存储Ne1+的电离源
                    if iComp == 4
                        Ne1_ionization(iPos, jPos) = sVal_iComp / gmtry_tmp.vol(iPos, jPos);
                    end
                    
                    sVal = sVal + sVal_iComp; % 累加电离源
                end
            end
            ionSource2D(iPos, jPos) = sVal;
            
            % 保存未归一化的电离源数据（在除以体积之前）
            rawIonSource2D(iPos, jPos) = sVal;
            
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
    
    % 打印Ne1+的电离源矩阵
    fprintf('\n=== Ne1+ 电离源分布 (单位: m^-3s^-1) ===\n');
    % 使用format long显示更多小数位
    format long;
    % 转置矩阵以使显示更符合直观理解（行对应Z方向，列对应R方向）
    Ne1_ionization = Ne1_ionization';
    disp(Ne1_ionization);
    % 恢复默认格式
    format short;
    
    % 打印未经单元体积归一化的总电离源矩阵
    fprintf('\n=== 未归一化总电离源分布 (Ne1+ 到 Ne10+) ===\n');
    format long;
    % 转置矩阵以保持一致性
    rawIonSource2D = rawIonSource2D';
    disp(rawIonSource2D);
    format short;
    
    % 保存Ne1+电离源数据到文件
    % 生成时间戳
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    % 创建文件名
    filename = sprintf('Ne1_ionization_%s.mat', timestampStr);
    
    % 保存数据
    save(filename, 'Ne1_ionization', '-v7.3');
    fprintf('\nNe1+ 电离源数据已保存到文件: %s\n', filename);
    
    % 同时保存为文本文件，方便查看
    txt_filename = sprintf('Ne1_ionization_%s.txt', timestampStr);
    fid = fopen(txt_filename, 'w');
    fprintf(fid, '=== Ne1+ 电离源分布 (单位: m^-3s^-1) ===\n');
    fprintf(fid, '矩阵大小: [%d x %d]\n', size(Ne1_ionization, 1), size(Ne1_ionization, 2));
    fprintf(fid, '行对应Z方向，列对应R方向\n\n');
    
    % 使用format long写入数据
    for i = 1:size(Ne1_ionization, 1)
        for j = 1:size(Ne1_ionization, 2)
            fprintf(fid, '%.10e\t', Ne1_ionization(i,j));
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
    fprintf('Ne1+ 电离源数据已保存到文本文件: %s\n', txt_filename);

    % 同时保存未归一化的总电离源数据
    raw_filename = sprintf('raw_total_ionization_%s.mat', timestampStr);
    save(raw_filename, 'rawIonSource2D', '-v7.3');
    fprintf('\n未归一化总电离源数据已保存到文件: %s\n', raw_filename);
    
    % 保存为文本文件
    raw_txt_filename = sprintf('raw_total_ionization_%s.txt', timestampStr);
    fid = fopen(raw_txt_filename, 'w');
    fprintf(fid, '=== 未归一化总电离源分布 (Ne1+ 到 Ne10+) ===\n');
    fprintf(fid, '矩阵大小: [%d x %d]\n', size(rawIonSource2D, 1), size(rawIonSource2D, 2));
    fprintf(fid, '行对应Z方向，列对应R方向\n\n');
    
    % 使用format long写入数据
    for i = 1:size(rawIonSource2D, 1)
        for j = 1:size(rawIonSource2D, 2)
            fprintf(fid, '%.10e\t', rawIonSource2D(i,j));
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
    fprintf('未归一化总电离源数据已保存到文本文件: %s\n', raw_txt_filename);
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
%% (C) 计算网格中心坐标 (子函数保持不变)
%% =========================================================================
function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
    % 说明：
    %   - 通过四角坐标平均计算网格中心

    rCenter = mean(crx, 3); % 第三维度平均
    zCenter = mean(cry, 3);
end


%% =========================================================================
%% (D) 带时间戳保存图窗 (修改为支持更多格式)
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 说明：
    %   - 保存为多种格式，包括.fig、.png和.eps，文件名包含生成时间戳
    %   - 自动调整窗口尺寸避免裁剪
    %   - 支持高分辨率输出，适合学术论文使用

    % 确保图窗尺寸适合学术出版要求
    set(gcf,'Units','pixels','Position',[100 50 1600 1200]); % 增大图像尺寸
    set(gcf,'PaperPositionMode','auto');
    
    % 生成时间戳
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    
    % 保存.fig格式(用于后续编辑)
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(figFile);
    fprintf('MATLAB图形文件已保存: %s\n', figFile);
    
    % 保存高分辨率PNG格式(用于快速预览)
    pngFile = sprintf('%s_%s.png', baseName, timestampStr);
    print(pngFile, '-dpng', '-r300');
    fprintf('PNG图像已保存: %s (300 dpi)\n', pngFile);
    
    % 保存EPS矢量图(用于学术论文出版)
    try
        epsFile = sprintf('%s_%s.eps', baseName, timestampStr);
        print(epsFile, '-depsc2', '-painters');
        fprintf('EPS矢量图已保存: %s (适用于学术出版)\n', epsFile);
    catch
        fprintf('警告: EPS格式保存失败，可能是MATLAB版本限制\n');
    end
end

%% =========================================================================
%% (NEW) 沿通量管连接停滞点 - 改进版，支持PFR区域拼接网格
%% =========================================================================
function connectStagnationPointsAlongFluxTubes(stagPoints, gmtry, rCenter, zCenter, zValues, jSOLmin, jSOLmax, uPol2D, positiveVelColor, negativeVelColor, lineWidth)
    % 说明：
    %   - 在每个通量管内，按照极向顺序连接停滞点
    %   - 沿通量管路径绘制连线，而非直线
    %   - 根据极向速度的正负值使用不同颜色
    %   - 支持PFR区域网格拓扑(1:25和74:98拼接)

    [nx, ny] = size(rCenter);
    % 颜色和线宽现在从函数参数传入，不再在此定义
    
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

% 处理PFR区域通量管(拼接极向网格)的停滞点连接 - 修改版
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
%% (E) 绘制通量管段 - 修改版以适应颜色参数
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
    
    % 确保z坐标值来自zValues（这里是ionSource_log）
    valZ_path = zValues(iPoints, jChannel);
    
    % 绘制3D路径
    plot3(r_path, z_path, valZ_path, '-', 'Color', color, 'LineWidth', width);
end