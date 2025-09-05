function plot_nearSOL_distributions_pol_scd96(all_radiationData, radial_index_for_nearSOL, varargin)
    % =========================================================================
    % 功能：
    %   绘制近SOL的极向速度(u_pol)、平行速度投影(parallelVelProj)与电离源(S)分布，包括：
    %       1) 全域分布
    %       2) 内偏滤器局部放大
    %       3) 外偏滤器局部放大
    %       4) 选定 flux tube 的可视化
    %
    % 线型说明：
    %   - 极向速度(u_pol)：实线 '-'
    %   - 电离源(S)：长虚线 '--'
    %   - 平行速度投影(parallelVelProj)：短虚线 '-.'
    %
    % 说明：
    %   1) 不再从文件读取 b2fplasmf / b2fgmtry，而是从 all_radiationData
    %      中直接获取 .gmtry 与 .plasma 等数据；
    %   2) 保留原脚本绘图思路与流程，只减少重复读文件的次数；
    %   3) 其他辅助函数 (surfplot, plot3sep, 等) 保持不变；
    %
    % 输入参数：
    %   all_radiationData         - cell 数组，每个元素含有:
    %                                .dirName (string)
    %                                .gmtry   (b2fgmtry 解析结果)
    %                                .plasma  (b2fplasmf解析结果)
    %   radial_index_for_nearSOL  - 指定近SOL的径向索引，可以指定多个，用空格分隔
    %                                 例如：'17 18 19' 或 [17, 18, 19]
    %   varargin                  - 可选参数：
    %                                'legend_mode' - 图例显示模式，可以是：
    %                                  'default': 按目录和物理量分类显示
    %                                  'simple' (默认): 直接显示3个固定标签
    %                                  (favorable B_T, unfavorable B_T, w/o drift)
    %                                'domain' - 绘图区域选择 (0/1/2)
    %                                  0 (默认): 全图
    %                                  1: 上偏滤器
    %                                  2: 下偏滤器
    %
    % 作者：xxx
    % 日期：2025-01-16
    %
    % 修改备注：
    %   - 去除文件读取，使用已有的 gmtry, plasma 数据
    %   - 保持原有逻辑与绘图步骤
    %   - radial_index_for_nearSOL 可以接受多个索引值
    %   - 添加平行速度投影 (parallelVelProj) 的绘制
    %   - 修改杂质统计范围，仅考虑 Ne 1+ 到 10+ (种类编号 4-13)
    %   - 修改平行速度投影计算方式，为杂质电荷态平方加权平均
    %   - **[修改] 电离源仅统计 Ne1+ (种类编号 4)**
    %   - **[修改] 平行速度投影重新计算，为杂质电荷态平方加权平均**
    %   - **[修正] 平行速度直接使用 ua，无需 upara 检查 (ua 为平行速度)**
    %   - **[新增] 增加图例显示方式选择，可在'default'和'simple'之间切换**
    %   - **[新增] 增加区域选择参数'domain'，控制绘图区域范围**
    %   - **[新增] 修改通量管绘制，支持同时显示多个通量管**
    %   - **[改进] 所有字体使用Times New Roman学术规范字体**
    %   - **[改进] 增大字体和线条粗细，更符合学术论文要求**
    %   - **[改进] 优化colorbar显示，使用科学计数法**
    %   - **[修复] 移除不兼容的DefaultTitleInterpreter设置，改为在每个title处显式设置'Interpreter','tex'**
    %   - **[修复] 确保所有标题、标签和图例都在各自的设置中显式使用tex解释器**
    %   - **[更新] 将默认图例模式从'default'改为'simple'，简化图例显示**
    % =========================================================================

    % 设置全局字体为Times New Roman并增大默认字体大小
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 28);  % 增大默认字体大小
    set(0, 'DefaultTextFontSize', 28);  % 增大默认字体大小
    set(0, 'DefaultLineLineWidth', 2.0);
    % 额外设置其他UI元素的字体
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 40);  % 增大默认图例字体大小
    % 设置数学公式的解释器为latex
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex'); 
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    % 检测MATLAB版本（用于处理2017b兼容性问题）
    isMATLAB2017b = verLessThan('matlab', '9.3'); % R2017b是9.3版本

    % 解析可选参数
    p = inputParser;
    addParameter(p, 'legend_mode', 'simple', @(x) ischar(x) && ismember(lower(x), {'default', 'simple'}));
    addParameter(p, 'domain', 1, @(x) isnumeric(x) && ismember(x, [0,1,2]));
    parse(p, varargin{:});
    
    legend_mode = lower(p.Results.legend_mode);
    domain = p.Results.domain;
    
    % 检查 radial_index_for_nearSOL 输入类型，并转换为数值数组
    if ischar(radial_index_for_nearSOL)
        radial_indices = str2num(radial_index_for_nearSOL); % 字符串转数值数组
    elseif isnumeric(radial_index_for_nearSOL)
        radial_indices = radial_index_for_nearSOL;          % 直接使用数值数组
    else
        error('Invalid input type for radial_index_for_nearSOL, should be a string or numeric array');
    end

    % 循环处理每个径向索引
    for iy_index = radial_indices
        fprintf('\n>>> Processing radial index iy = %d...\n', iy_index);

        % ========== (1) 全域近SOL分布 ==========
        plot_nearSOL_distributions_fullDomain(all_radiationData, iy_index, legend_mode);

        % ========== (2) 内偏滤器局部放大图 ==========
        iXpoint_inner = 74;       % 内偏滤器 X点在 poloidal index = 74
        margin_inner  = 8;
        i_start_inner = iXpoint_inner - margin_inner;  % 74 - 8 = 66
        if i_start_inner < 2
            i_start_inner = 2;
        end
        i_end_inner   = 97;       % 这里与原脚本一致

        plot_nearSOL_distributions_partial(...
            all_radiationData, ...
            iy_index,...
            i_start_inner, i_end_inner, iXpoint_inner,...
            sprintf('InnerDiv region (iy=%d)', iy_index), ...
            legend_mode); % 图名带上 iy 索引，传递图例模式

        % ========== (3) 外偏滤器局部放大图 ==========
        iXpoint_outer = 25;    % 外偏滤器 X点
        margin_outer  = 8;
        i_start_outer = 2;     % 直接从头开始
        i_end_outer   = iXpoint_outer + margin_outer;  % 25 + 8 = 33
        if i_end_outer > 96
            i_end_outer = 96;
        end

        plot_nearSOL_distributions_partial(...
            all_radiationData,...
            iy_index,...
            i_start_outer, i_end_outer, iXpoint_outer,...
            sprintf('OuterDiv region (iy=%d)', iy_index), ...
            legend_mode); % 图名带上 iy 索引，传递图例模式

    end
    
    % ========== (4) 绘制选中的全部通量管 ==========
    % 创建一个仅显示所有选定通量管线条的图
    % 从第一个算例拿来 gmtry 做可视化
    gmtry_first = all_radiationData{1}.gmtry;
    [nx, ny] = size(gmtry_first.crx(:,:,1)); % 获取网格尺寸
    
    % 计算网格中心坐标
    rCenter = mean(gmtry_first.crx, 3);
    zCenter = mean(gmtry_first.cry, 3);
    
    % 创建图窗，设置为符合学术出版要求的尺寸
    figure('Name', sprintf('Selected flux tubes (iy=%s)', num2str(radial_indices)), ...
           'NumberTitle', 'off', 'Color', 'w', ...
           'Units', 'inches', 'Position', [1, 1, 12, 10]);  % 增大图窗尺寸
    
    % 设置坐标轴和背景
    hold on;
    
    % 添加分离器线和结构，但不显示在图例中
    h_sep = plot3sep(gmtry_first, 'color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
    % 确保分离器线不出现在图例中
    for i = 1:length(h_sep)
        set(h_sep(i), 'HandleVisibility', 'off');
    end
    
    if isfield(all_radiationData{1}, 'structure')
        h_struct = plotstructure(all_radiationData{1}.structure, 'color', 'k', 'LineWidth', 2.5);
        % 确保结构线不出现在图例中
        if ~isempty(h_struct)
            for i = 1:length(h_struct)
                set(h_struct(i), 'HandleVisibility', 'off');
            end
        end
    end
    
    % --- 绘制通量管的线条表示 ---
    % 使用较粗的线条以便清晰显示
    fluxTubeLineColor = lines(length(radial_indices)); % 根据通量管数量生成不同颜色
    lineWidth = 4.0; % 增加线条粗细，更符合学术出版要求
    
    % 为每个选定的通量管绘制一条线，收集所有线的句柄
    fluxTubeHandles = gobjects(length(radial_indices), 1);
    fluxTubeLabels = cell(length(radial_indices), 1);
    
    for idx = 1:length(radial_indices)
        iy_index = radial_indices(idx);
        if iy_index <= ny
            % 沿着通量管的每个极向位置绘制线条
            r_path = rCenter(:, iy_index);
            z_path = zCenter(:, iy_index);
            
            % 绘制路径，使用不同颜色区分不同通量管
            fluxTubeHandles(idx) = plot(r_path, z_path, '-', ...
                'Color', fluxTubeLineColor(mod(idx-1, size(fluxTubeLineColor,1))+1, :), ...
                'LineWidth', lineWidth);
            fluxTubeLabels{idx} = sprintf('iy=%d', iy_index);
        end
    end
    
    % 设置坐标轴和标题
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'LineWidth', 2.0, 'Box', 'on');
    xlabel('$R$ (m)', 'FontName', 'Times New Roman', 'FontSize', 40, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontName', 'Times New Roman', 'FontSize', 40, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title('Selected flux tubes', 'FontName', 'Times New Roman', 'FontSize', 42, 'FontWeight', 'bold', 'Interpreter', 'latex');
    
    % 根据domain参数设置显示区域
    if domain ~= 0
        if domain == 1  % 上偏滤器
            xlim([1.30, 2.00]); 
            ylim([0.50, 1.20]);
            title('Selected flux tubes (Upper Div.)', 'FontName', 'Times New Roman', 'FontSize', 42, 'FontWeight', 'bold', 'Interpreter', 'latex');
        elseif domain == 2  % 下偏滤器
            xlim([1.30, 2.05]); 
            ylim([-1.15, -0.40]);
            title('Selected flux tubes (Lower Div.)', 'FontName', 'Times New Roman', 'FontSize', 42, 'FontWeight', 'bold', 'Interpreter', 'latex');
        end
    end
    
    % 添加图例，仅显示通量管线条
    lgd = legend(fluxTubeHandles, fluxTubeLabels, 'Location', 'best');
    set(lgd, 'FontName', 'Times New Roman', 'FontSize', 40, 'Interpreter', 'latex');
    
    axis square;
    box on;
    grid on;
    
    % 保存图片，文件名包含所有选择的通量管索引
    indices_str = regexprep(num2str(radial_indices), '\s+', '_');
    saveFigureWithTimestamp(sprintf('Selected_flux_tubes_iy%s_domain%d', indices_str, domain));

    fprintf('\n>>> Finished: Figures with Full, InnerDiv, OuterDiv for iy=[%s] with Y=0 aligned.\n', num2str(radial_indices));
    fprintf('>>> Domain setting: %d (0=Full, 1=Upper Divertor, 2=Lower Divertor)\n', domain);

end % end of main function


%% ========== (A) 全域近SOL分布 ==========
function plot_nearSOL_distributions_fullDomain(all_radiationData, radial_index_for_nearSOL, legend_mode)
    % 绘制全域的近SOL分布 (u_pol & S)，并固定左右 Y 轴范围等
    % legend_mode: 'default' 或 'simple' - 控制图例显示方式
    
    %figTitle = sprintf('Near-SOL Full Domain (j=%d)', radial_index_for_nearSOL); % 图名带上 j 索引，注释掉，以后可恢复
    figTitle = sprintf('Near-SOL Full Domain'); % 图名不再显示 j 索引

    % 创建图窗，设置为符合学术出版要求的尺寸
    figure('Name',sprintf('Near-SOL Full Domain (iy=%d)', radial_index_for_nearSOL),'NumberTitle','off','Color','w',... % 图名带上 iy 索引
           'Units', 'inches', 'Position', [1, 1, 10, 8]);
    hold on;

    % 颜色、线型
    line_colors = lines(20);

    totalDirs = length(all_radiationData);

    % --- 准备图例显示所需的对象 ---
    % 根据 legend_mode 决定图例创建方式
    if strcmp(legend_mode, 'default')
        % 默认模式：按目录和物理量分类
        % --- 先创建"假"绘图对象，用于生成 Legend 中对各目录的标识 ---
        dummyDirHandles = gobjects(totalDirs,1);
        dirLegendStrings= cell(totalDirs,1);
        for iDir = 1:totalDirs
            ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
            dummyDirHandles(iDir) = plot(nan,nan,'LineStyle','-',...
                'Color',ccol,'LineWidth',3.0, 'Marker', 'none', 'HandleVisibility','off'); % 增加线宽
            dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
        end

        % --- 物理量(线型)的假对象 ---
        dummyStyleHandles = gobjects(3,1); % 修改为 3 个物理量
        styleLegendStrings = {
            '$u_{pol}$', ... % 极向速度，使用实线
            '$S$', ... % 电离源，使用长虚线
            '$u_{||}$ Proj'  % 平行速度投影，使用短虚线
        };
        
        % 使用直观的线型，不用文字描述线型
        lineStyle_ordered = {'-', '--', '-.'};  % 实线、长虚线、短虚线
        
        for sIdx = 1:3
            dummyStyleHandles(sIdx) = plot(nan,nan,'LineStyle',lineStyle_ordered{sIdx},...
                'Color','k','LineWidth',3.0, 'Marker', 'none', 'HandleVisibility','off'); % 增加线宽
        end
    else
        % --- 简化图例模式 ---
        % 准备不同物理量和不同磁场条件的组合
        nCases = min(3, totalDirs);
        
        % 定义磁场条件标签
        if totalDirs == 3
            caseStrings = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
        elseif totalDirs == 2
            caseStrings = {'fav. $B_T$', 'w/o drift'};
        else
            caseStrings = {'w/o drift'};
        end
        
        % 定义物理量标签及对应线型
        physicalQuantities = {
            '$u_{pol}$', 
            '$S$', 
            '$u_{||}$ Proj'
        };
        lineStyles = {'-', '--', '-.'};  % 实线、长虚线、短虚线
        
        % 创建图例元素，横向排列（每个磁场条件一列，物理量依次排列）
        hLeg = gobjects(nCases * 3, 1);
        strLeg = cell(nCases * 3, 1);
        
        % 直接在标签中显示磁场条件+物理量组合
        for iCase = 1:nCases
            caseColor = line_colors(mod(iCase-1, size(line_colors,1))+1, :);
            for iQuantity = 1:3
                idx = (iCase-1)*3 + iQuantity;
                lineStyle = lineStyles{iQuantity};
                
                hLeg(idx) = plot(nan, nan, 'LineStyle', lineStyle, ...
                    'Color', caseColor, 'LineWidth', 3.0);
                
                % 简化标签显示
                if iQuantity == 1
                    % 第一行只显示磁场条件
                    strLeg{idx} = caseStrings{iCase};
                elseif iCase == 1
                    % 第一列显示物理量
                    strLeg{idx} = physicalQuantities{iQuantity};
                else
                    % 其他位置留空
                    strLeg{idx} = '';
                end
            end
        end
        
        % 创建图例，设置为3列布局
        L = legend(hLeg, strLeg, 'Location', 'northeast', 'NumColumns', 3);
        set(L, 'FontName', 'Times New Roman', 'FontSize', 40, 'Interpreter', 'latex');
        
        % 调整图例位置和大小
        set(L, 'Position', [0.45, 0.75, 0.50, 0.20]);
    end

    % ========== 逐算例绘图 ==========
    for iDir = 1:totalDirs

        % 从 all_radiationData 中获取 gmtry & plasma
        dataStruct = all_radiationData{iDir};
        gmtry_tmp   = dataStruct.gmtry;
        plasma_tmp  = dataStruct.plasma;

        % 获取网格维度
        [nxd_tmp, nyd_tmp] = size(gmtry_tmp.crx(:,:,1));

        % 判断径向索引是否越界
        if radial_index_for_nearSOL > nyd_tmp
            fprintf('Out of range iy=%d for %s (nyd_tmp=%d)\n', ...
                radial_index_for_nearSOL, dataStruct.dirName, nyd_tmp);
            continue;
        end

        % 计算极向距离(中心)
        pol_len = gmtry_tmp.hx(:, radial_index_for_nearSOL);
        x_edge  = zeros(nxd_tmp+1,1);
        for iPos = 1:nxd_tmp
            x_edge(iPos+1) = x_edge(iPos) + pol_len(iPos);
        end
        x_center = 0.5*(x_edge(1:end-1) + x_edge(2:end));

        % 调用子函数，算出 parallelVelProj, uPol, sVal
        [parallelVelProj, uPol, sVal] = compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL, dataStruct);

        % === 新增：保存ionSource数据到文件 ===
        safeDirName = regexprep(dataStruct.dirName, '\W', '_');
        filename = sprintf('ionSource_iy%d_dir_%s.txt', radial_index_for_nearSOL, safeDirName);

        % 使用 fprintf 写入数据（兼容 2017b）
        fileID = fopen(filename, 'w');
        fprintf(fileID, '%.6e\n', sVal);  % 每行一个数值，指数形式保留6位小数
        fclose(fileID);


        % 颜色
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);

        % ========== 左轴：parallelVelProj & u_pol ==========
        yyaxis left
        h_paraV = plot(x_center, parallelVelProj, 'LineStyle','-.', ... % '-.' for parallelVelProj (短虚线)
            'Color',ccol,'LineWidth',2.5, 'Marker', 'none', 'HandleVisibility','off'); % 增加线宽
        set(h_paraV,'UserData', dataStruct.dirName);

        h_u= plot(x_center, uPol, ...
        'LineStyle', '-', ... % '-' for u_pol (实线)
        'Color', ccol, ...
        'LineWidth', 2.5, ...  % 增加线宽
        'Marker', 'none', ...
        'HandleVisibility', 'off');
        set(h_u,'UserData', dataStruct.dirName);

        % ========== 右轴：S ==========
        yyaxis right
        ylim([-4.5e23,4.5e23]); % 扩大右侧Y轴显示范围
        yticks(-4.5e23:1.5e23:4.5e23); % 相应调整刻度
        h_s= plot(x_center, sVal, ...
            'LineStyle', '--', ... % '--' for S (长虚线)
            'Color', ccol, ...
            'LineWidth', 2.5, ...  % 增加线宽
            'Marker', 'none', ...
            'HandleVisibility', 'off');
        set(h_s,'UserData', dataStruct.dirName);

        fprintf('电离源数据范围: 最小值=%e, 最大值=%e\n', min(sVal), max(sVal));

    end

    % ========== 设置坐标范围、轴标签等 ==========
    yyaxis left
    ylim([-1200,1200]); % 修改 Y 轴范围为 [-1200, 1200]
    yticks(-1200:400:1200); % 修改 Y 轴刻度，间隔为400
    ylabel('Velocity (m/s)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'bold', 'Interpreter', 'latex');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 28, 'LineWidth', 1.5, 'Box', 'on');

    yyaxis right
    ylim([-4.5e23,4.5e23]); % 扩大右侧Y轴显示范围
    yticks(-4.5e23:1.5e23:4.5e23); % 相应调整刻度
    ylabel('Ion Source ($\mathrm{m}^{-3}\mathrm{s}^{-1}$)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'bold', 'Interpreter', 'latex');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 28, 'LineWidth', 1.5, 'Box', 'on', 'YColor', 'k'); % 添加YColor设置为黑色

    xlabel('Poloidal distance (m)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title(figTitle, 'FontName', 'Times New Roman', 'FontSize', 34, 'FontWeight', 'bold', 'Interpreter', 'latex');
    grid on;

    % 在全域图中绘制分离面 (X点)
    try
        % 内侧X点
        iXpoint_inner = 74; % 内偏滤器 X点在 poloidal index = 74
        
        % 外侧X点
        iXpoint_outer = 25; % 外偏滤器 X点
        
        % 获取第一个算例的几何结构
        dataStruct_1 = all_radiationData{1};
        gmtry_tmp_1 = dataStruct_1.gmtry;
        
        % 计算极向距离
        pol_len_1 = gmtry_tmp_1.hx(:, radial_index_for_nearSOL);
        x_edge_1 = zeros(length(pol_len_1)+1, 1);
        for iPos = 1:length(pol_len_1)
            x_edge_1(iPos+1) = x_edge_1(iPos) + pol_len_1(iPos);
        end
        x_center_1 = 0.5 * (x_edge_1(1:end-1) + x_edge_1(2:end));
        
        % 计算X点位置
        xXpt_inner = x_center_1(iXpoint_inner);
        xXpt_outer = x_center_1(iXpoint_outer);
        
        % 获取左右两轴的范围
        yyaxis left;
        yLimsLeft = ylim;
        
        yyaxis right;
        yLimsRight = ylim;
        
        % 计算覆盖两个轴的范围
        yMin = min(yLimsLeft(1), yLimsRight(1));
        yMax = max(yLimsLeft(2), yLimsRight(2));
        
        % 绘制内侧分离面
        hold on;
        plot([xXpt_inner xXpt_inner], [yMin, yMax], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        % 绘制外侧分离面
        plot([xXpt_outer xXpt_outer], [yMin, yMax], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        % 恢复到左轴，方便后续操作
        yyaxis left;
    catch
        warning('Cannot draw X lines in full domain plot');
    end

    % --- 添加图例 ---
    if strcmp(legend_mode, 'default')
        % --- 默认图例模式 ---
        for iDir=1:totalDirs
            set(dummyDirHandles(iDir),'HandleVisibility','on');
        end
        for sIdx=1:3 % 修改循环次数为 3
            set(dummyStyleHandles(sIdx),'HandleVisibility','on');
        end
        allDummies = [dummyDirHandles(:); dummyStyleHandles(:)];
        allLegStr  = [dirLegendStrings(:); styleLegendStrings(:)];
        L= legend(allDummies, allLegStr,'Location','best', 'FontName', 'Times New Roman', 'FontSize', 40, 'Interpreter', 'latex');
        % title(L,'(Color=Dir, LineStyle=Quantity)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'normal');
    end

    % 设置 DataCursor
    dcm = datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);

    % 保存带时间戳, 文件名带上 iy 索引
    saveFigureWithTimestamp(sprintf('FullDomain_iy%d', radial_index_for_nearSOL)); % 文件名带上 iy 索引
end


%% ========== (B) 局部放大图 (Inner/Outer) ==========
function plot_nearSOL_distributions_partial(all_radiationData, radial_index_for_nearSOL,...
                i_start, i_end, iXpoint, figureTag, legend_mode)
    % 绘制指定 poloidal index 范围 [i_start..i_end] 的局部放大图
    % 并在图上标出 X 点
    % legend_mode: 'default' 或 'simple' - 控制图例显示方式
    
    % 修改图名，去掉j索引显示
    if contains(figureTag, 'InnerDiv region')
        figureTag_display = sprintf('InnerDiv. region (iy=%d)', radial_index_for_nearSOL); % 注释掉，以后可恢复
        % figureTag_display = 'InnerDiv region'; % 不显示j索引
    elseif contains(figureTag, 'OuterDiv region')
        figureTag_display = sprintf('OuterDiv. region (iy=%d)', radial_index_for_nearSOL); % 注释掉，以后可恢复
        % figureTag_display = 'OuterDiv region'; % 不显示j索引
    else
        figureTag_display = figureTag; % 保持原样
    end

    % 创建图窗，设置为符合学术出版要求的尺寸
    figure('Name', figureTag, 'NumberTitle','off','Color','w',...
           'Units', 'inches', 'Position', [1, 1, 10, 8]);
    hold on;

    line_colors = lines(20);

    totalDirs= length(all_radiationData);

    % --- 准备图例显示所需的对象 ---
    % 根据 legend_mode 决定图例创建方式
    if strcmp(legend_mode, 'default')
        % 默认模式：按目录和物理量分类
        % --- Dummy Legend 对象，用以区分目录(color) ---
        dummyDirHandles= gobjects(totalDirs,1);
        dirLegendStrings= cell(totalDirs,1);
        for iDir = 1:totalDirs
            ccol= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
            dummyDirHandles(iDir)= plot(nan,nan,'LineStyle','-',...
                'Color',ccol,'LineWidth',3.0, 'Marker', 'none', 'HandleVisibility','off'); % 添加 'Marker', 'none'
            dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
        end

        % --- Dummy Legend 对象，用以区分物理量(line style) ---
        dummyStyleHandles= gobjects(3,1); % 修改为 3 个物理量
        styleLegendStrings= {
            '$u_{pol}$', ... % 极向速度，使用实线
            '$S$', ... % 电离源，使用长虚线
            '$u_{||}$ Proj'  % 平行速度投影，使用短虚线
        };
        
        % 使用直观的线型，不用文字描述线型
        lineStyle_ordered = {'-', '--', '-.'};  % 实线、长虚线、短虚线
        
        for sIdx=1:3 % 修改循环次数为 3
            dummyStyleHandles(sIdx)= plot(nan,nan,'LineStyle',lineStyle_ordered{sIdx},...
                'Color','k','LineWidth',3.0, 'Marker', 'none', 'HandleVisibility','off'); % 添加 'Marker', 'none'
        end
    else
        % --- 简化图例模式 ---
        % 准备不同物理量和不同磁场条件的组合
        nCases = min(3, totalDirs);
        
        % 定义磁场条件标签
        if totalDirs == 3
            caseStrings = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
        elseif totalDirs == 2
            caseStrings = {'fav. $B_T$', 'w/o drift'};
        else
            caseStrings = {'w/o drift'};
        end
        
        % 定义物理量标签及对应线型
        physicalQuantities = {
            '$u_{pol}$', 
            '$S$', 
            '$u_{||}$ Proj'
        };
        lineStyles = {'-', '--', '-.'};  % 实线、长虚线、短虚线
        
        % 创建图例元素，横向排列（每个磁场条件一列，物理量依次排列）
        hLeg = gobjects(nCases * 3, 1);
        strLeg = cell(nCases * 3, 1);
        
        % 直接在标签中显示磁场条件+物理量组合
        for iCase = 1:nCases
            caseColor = line_colors(mod(iCase-1, size(line_colors,1))+1, :);
            for iQuantity = 1:3
                idx = (iCase-1)*3 + iQuantity;
                lineStyle = lineStyles{iQuantity};
                
                hLeg(idx) = plot(nan, nan, 'LineStyle', lineStyle, ...
                    'Color', caseColor, 'LineWidth', 3.0);
                
                % 简化标签显示
                if iQuantity == 1
                    % 第一行只显示磁场条件
                    strLeg{idx} = caseStrings{iCase};
                elseif iCase == 1
                    % 第一列显示物理量
                    strLeg{idx} = physicalQuantities{iQuantity};
                else
                    % 其他位置留空
                    strLeg{idx} = '';
                end
            end
        end
        
        % 创建图例，设置为3列布局
        L = legend(hLeg, strLeg, 'Location', 'northeast', 'NumColumns', 3);
        set(L, 'FontName', 'Times New Roman', 'FontSize', 40, 'Interpreter', 'latex');
        
        % 调整图例位置和大小
        set(L, 'Position', [0.45, 0.75, 0.50, 0.20]);
    end

    % ========== 逐算例读取 & 截取数据 ==========
    for iDir=1:totalDirs
        dataStruct = all_radiationData{iDir};
        gmtry_tmp  = dataStruct.gmtry;
        plasma_tmp = dataStruct.plasma;

        [nxd_tmp, nyd_tmp] = size(gmtry_tmp.crx(:,:,1));

        % 检查索引
        if radial_index_for_nearSOL > nyd_tmp
            fprintf('Out of range iy=%d for %s\n', radial_index_for_nearSOL, dataStruct.dirName);
            continue;
        end

        % 构造 poloidal 方向距离
        pol_len= gmtry_tmp.hx(:, radial_index_for_nearSOL);
        x_edge= zeros(nxd_tmp+1,1);
        for iPos=1:nxd_tmp
            x_edge(iPos+1)= x_edge(iPos) + pol_len(iPos);
        end
        x_center= 0.5*(x_edge(1:end-1) + x_edge(2:end));

        [parallelVelProj, uPol, sVal] = compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL, dataStruct);

        % 截取子区间
        if i_start<1, i_start=1; end
        if i_end>nxd_tmp, i_end=nxd_tmp; end
        idxRange = i_start : i_end;

        xSub = x_center(idxRange);
        parallelVSub = parallelVelProj(idxRange); % 截取平行速度投影
        uSub = uPol(idxRange);
        sSub = sVal(idxRange);

        ccol= line_colors(mod(iDir-1,size(line_colors,1))+1,:);

        yyaxis left
        h_paraV= plot(xSub, parallelVSub, 'LineStyle', '-.', ... % '-.' for parallelVelProj (短虚线)
                  'Color', ccol,'LineWidth',2.5, 'Marker', 'none', 'HandleVisibility','off'); % 增加线宽
        set(h_paraV,'UserData', dataStruct.dirName);

        h_u= plot(xSub, uSub, ...
        'LineStyle', '-', ... % '-' for u_pol (实线)
        'Color', ccol, ...
        'LineWidth', 2.5, ...  % 增加线宽
        'Marker', 'none', ...
        'HandleVisibility', 'off');
        set(h_u,'UserData', dataStruct.dirName);

        yyaxis right
        ylim([-4.5e23,4.5e23]); % 扩大右侧Y轴显示范围
        yticks(-4.5e23:1.5e23:4.5e23); % 相应调整刻度
        h_s= plot(xSub, sSub, ...
            'LineStyle', '--', ... % '--' for S (长虚线)
            'Color', ccol, ...
            'LineWidth', 2.5, ...  % 增加线宽
            'Marker', 'none', ...
            'HandleVisibility', 'off');
        set(h_s,'UserData', dataStruct.dirName);

        fprintf('电离源数据范围: 最小值=%e, 最大值=%e\n', min(sSub), max(sSub));
    end

    % ========== 设置坐标、标注等 ==========
    yyaxis left
    ylabel('Velocity (m/s)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'bold', 'Interpreter', 'latex');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 28, 'LineWidth', 1.5, 'Box', 'on');

    yyaxis right
    ylim([-4.5e23,4.5e23]); % 扩大右侧Y轴显示范围
    yticks(-4.5e23:1.5e23:4.5e23); % 相应调整刻度
    ylabel('Ion Source ($\mathrm{m}^{-3}\mathrm{s}^{-1}$)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'bold', 'Interpreter', 'latex');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 28, 'LineWidth', 1.5, 'Box', 'on', 'YColor', 'k'); % 添加YColor设置为黑色

    xlabel('Poloidal distance (m)', 'FontName', 'Times New Roman', 'FontSize', 32, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title(figureTag_display, 'FontName', 'Times New Roman', 'FontSize', 34, 'FontWeight', 'bold', 'Interpreter', 'latex');
    grid on;

    % 标记 X 点
    try
        dataStruct_1 = all_radiationData{1};
        gmtry_tmp_1  = dataStruct_1.gmtry;
        pol_len_1 = gmtry_tmp_1.hx(:, radial_index_for_nearSOL);
        x_edge_1  = zeros(length(pol_len_1)+1,1);
        for iPos=1:length(pol_len_1)
            x_edge_1(iPos+1) = x_edge_1(iPos) + pol_len_1(iPos);
        end
        x_center_1 = 0.5*(x_edge_1(1:end-1) + x_edge_1(2:end));
        xXpt= x_center_1(iXpoint);

        % 获取当前图形的所有绘图区域范围，确保分离面覆盖整个图形
        ax = gca;
        
        % 先获取左轴范围
        yyaxis left;
        yLimsLeft = ylim;
        
        % 获取右轴范围
        yyaxis right;
        yLimsRight = ylim;
        
        % 计算覆盖两个轴的范围
        yMin = min(yLimsLeft(1), yLimsRight(1));
        yMax = max(yLimsLeft(2), yLimsRight(2));
        
        % 在更大的范围内绘制分离面
        hold on;
        plot([xXpt xXpt], [yMin, yMax], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        % 恢复到左轴，方便后续操作
        yyaxis left;
    catch
        warning('Cannot draw X line for %s', figureTag);
    end

    % 若为内偏滤器，需要翻转 X 轴 (与原脚本一致)
    if contains(lower(figureTag), 'innerdiv')
        set(gca,'XDir','reverse');
    end

    % 和全域图保持一致的 Y 轴范围 => 0 对齐
    yyaxis left
    ylim([-1200,1200]); % 修改 Y 轴范围为 [-1200, 1200]
    yticks(-1200:400:1200); % 修改 Y 轴刻度，间隔为400

    yyaxis right
    ylim([-4.5e23,4.5e23]); % 扩大右侧Y轴显示范围
    yticks(-4.5e23:1.5e23:4.5e23); % 相应调整刻度
    set(gca, 'YColor', 'k'); % 设置右侧Y轴为黑色

    % --- 添加图例 ---
    if strcmp(legend_mode, 'default')
        % --- 默认图例模式 ---
        for iDir=1:totalDirs
            set(dummyDirHandles(iDir),'HandleVisibility','on');
        end
        for sIdx=1:3 % 修改循环次数为 3
            set(dummyStyleHandles(sIdx),'HandleVisibility','on');
        end
        allDummies = [dummyDirHandles(:); dummyStyleHandles(:)];
        allLegStr  = [dirLegendStrings(:); styleLegendStrings(:)];
        L= legend(allDummies, allLegStr,'Location','best', 'FontName', 'Times New Roman', 'FontSize', 40, 'Interpreter', 'latex');
    end

    % DataCursor
    dcm= datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);

    % 保存，文件名带上 iy 索引
    figureTag_noSpace= strrep(figureTag,' ','_');
    saveFigureWithTimestamp(sprintf('%s_iy%d', figureTag_noSpace, radial_index_for_nearSOL)); % 文件名带上 iy 索引
end


%% ========== compute_SOLprofiles 子函数 ==========
function [parallelVelProj, poloidalVelocity, ionSource] = ...
    compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL, dataStruct)
    % 计算近SOL在给定 j=radial_index_for_nearSOL 截面的：
    %   - 平行速度投影 parallelVelProj =  <u_{parallel | imp}> = sum(Za^2 * na * upara_a) / sum(Za^2 * na)
    %   - 极向速度 poloidalVelocity    = (GammaPol) / (ImpDensity)
    %   - 电离源 ionSource             = (coeff0 + coeff1 * n) / vol
    %
    % 注：
    %   1) 杂质统计范围已修改为仅考虑 Ne 1+ 到 10+，对应种类编号 sp=4:13
    %   2) 若各结构维度与索引有变化，请自行调整
    %   3) 平行速度投影 parallelVelProj 的计算方式已修改为电荷态平方加权平均
    %   4) **[修改] 电离源仅统计 Ne1+ (种类编号 4)**
    %   5) **[修改] 平行速度投影为杂质电荷态平方加权平均**
    %   6) **[修正] 平行速度直接使用 ua，无需 upara 检查 (ua 为平行速度)**
    %   7) **[新增] 添加dataStruct参数，用于获取电离源数据**

    [nxd_tmp, ~] = size(gmtry_tmp.hx);
    parallelVelProj= zeros(nxd_tmp,1);
    poloidalVelocity= zeros(nxd_tmp,1);
    ionSource= zeros(nxd_tmp,1);

    for iPos=1:nxd_tmp
        % ========== 1) 平行速度投影 (杂质电荷态平方加权平均) ==========
        B  = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,4);
        Bx = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,1);
        if B==0
            b_x=0;
        else
            b_x= Bx / B;
        end

        weighted_vel_sum = 0;
        weighted_density_sum = 0;

        for sp=4:13  % 循环遍历 Ne 1+ 到 Ne 10+ 杂质
            if sp > size(plasma_tmp.na, 3)
                continue; % 种类索引越界，跳过
            end

            Za = sp - 3; % Ne 1+ => Z=1, Ne 10+ => Z=10
            na = plasma_tmp.na(iPos, radial_index_for_nearSOL, sp);
            ua = 0;
            if isfield(plasma_tmp,'ua') && sp <= size(plasma_tmp.ua, 3)
                ua = plasma_tmp.ua(iPos, radial_index_for_nearSOL, sp);
            end

            % 直接使用 ua 作为平行速度
            u_para_imp = ua;


            weighted_vel_sum   = weighted_vel_sum   + Za^2 * na * u_para_imp;
            weighted_density_sum = weighted_density_sum + Za^2 * na;
        end

        if weighted_density_sum > 0
            parallelVelProj(iPos) = b_x * (weighted_vel_sum / weighted_density_sum);
        else
            parallelVelProj(iPos) = 0; % 避免除以零
        end


        % ========== 2) 极向速度 (GammaPol / ImpDensity) ==========
        gammaPol=0;
        nImp=0;
        for sp=4:13  % 循环遍历 Ne 1+ 到 Ne 10+ 杂质
            % GammaPol => fna_mdf(:,:,1,sp)
            if isfield(plasma_tmp,'fna_mdf')
                gammaPol= gammaPol + plasma_tmp.fna_mdf(iPos, radial_index_for_nearSOL,1,sp);
            end
            % 杂质密度累加
            if sp<= size(plasma_tmp.na,3)
                nImp= nImp + plasma_tmp.na(iPos, radial_index_for_nearSOL, sp);
            end
        end
        area_perp= gmtry_tmp.gs(iPos, radial_index_for_nearSOL, 1) * gmtry_tmp.qz(iPos, radial_index_for_nearSOL, 2);  %垂直于通量管的面积
        if nImp>0
            poloidalVelocity(iPos)= gammaPol / nImp / area_perp;
        end

        % ========== 3) 电离源 ==========
        % 检查是否已读取电离源数据
        if isfield(dataStruct, 'ionSourceData')
            % 如果已读取，直接使用
            ionSource(iPos) = dataStruct.ionSourceData(iPos, radial_index_for_nearSOL);
        else
            % 尝试从文件读取电离源数据
            try
                % 构建完整的电离源文件路径
                filename = fullfile(dataStruct.dirName, 'scd96_SionNe0.txt');
                
                % 读取文件，跳过前3行头部
                data = importdata(filename, ' ', 3);
                
                % 提取数值数据
                numData = data.data;
                
                % 获取几何信息的尺寸
                [nx_orig, ny_orig, ~] = size(gmtry_tmp.crx);
                
                % 初始化96×96的电离源矩阵（不包含guardcells）
                ionSourceMatrix = zeros(nx_orig-2, ny_orig-2);
                
                % 将数据填入矩阵
                for i = 1:size(numData, 1)
                    ix = numData(i, 1) + 1;  % MATLAB索引从1开始
                    iy = numData(i, 2) + 1;
                    z01 = numData(i, 5);     % 电离源数据在第5列(已归一化)
                    
                    % 存储电离源值到对应网格位置
                    if ix >= 1 && ix <= nx_orig-2 && iy >= 1 && iy <= ny_orig-2
                        ionSourceMatrix(ix, iy) = z01;
                    end
                end
                
                % 网格扩展：从96到98
                % 处理特殊的网格点：1=2, end=end-1
                % 创建扩展后的矩阵（初始全为0）
                expandedIonSourceMatrix = zeros(nx_orig, ny_orig);
                
                % 复制原有数据到扩展矩阵中心区域（偏移一个网格）                
                expandedIonSourceMatrix(2:end-1, 2:end-1) = ionSourceMatrix(1:end, 1:end);
                
                % 特殊处理：第1个网格 = 第2个网格，最后一个网格 = 倒数第二个网格
                expandedIonSourceMatrix(1, :) = expandedIonSourceMatrix(2, :);
                expandedIonSourceMatrix(nx_orig, :) = expandedIonSourceMatrix(nx_orig-1, :);
                
                % 存储扩展后的电离源数据到dataStruct中
                dataStruct.ionSourceData = expandedIonSourceMatrix;
                
                % 获取当前位置的电离源
                ionSource(iPos) = expandedIonSourceMatrix(iPos, radial_index_for_nearSOL);
                
            catch ME
                % 如果读取文件失败，直接报错而不使用备选方法
                warning(ME.identifier, '%s', ME.message);
                ionSource(iPos) = 0; % 读取失败时将电离源设为0
            end
        end

    end
end


%% ========== DataCursor 回调函数 ==========
function txt= myDataCursorUpdateFcn(~, event_obj)
    pos= get(event_obj,'Position');
    target= get(event_obj,'Target');
    dirPath= get(target,'UserData');
    if ~isempty(dirPath)
        txt= {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))],...
            ['Directory: ', dirPath]
        };
    else
        txt= {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))]
        };
    end
end


%% ========== 保存带时间后缀的图子函数 ==========
function saveFigureWithTimestamp(baseName)
    % 将当前 figure 保存为多种格式，包括.fig（MATLAB原生格式）
    % 和高分辨率图像格式（PNG和EPS）用于学术论文
    % 保存时自动添加时间戳，避免覆盖
    % 对图形设置合适的尺寸，以避免被裁剪
    
    % 确保图窗尺寸适合学术出版要求
    set(gcf,'Units','inches','Position',[100 50 9 7]); % 适合学术出版的尺寸比例
    set(gcf,'PaperPositionMode','auto');
    
    % 临时修改解释器以避免保存时的错误
    hc = findobj(gcf, 'Type', 'ColorBar');
    if ~isempty(hc) && isfield(hc, 'Label')
        origInterp = hc.Label.Interpreter;
        hc.Label.Interpreter = 'latex';
    end
    
    % 对标题和标签设置解释器为latex
    h_title = get(gca, 'Title');
    h_xlabel = get(gca, 'XLabel');
    h_ylabel = get(gca, 'YLabel');
    if ~isempty(h_title), set(h_title, 'Interpreter', 'latex'); end
    if ~isempty(h_xlabel), set(h_xlabel, 'Interpreter', 'latex'); end
    if ~isempty(h_ylabel), set(h_ylabel, 'Interpreter', 'latex'); end
    
    % 对图例对象设置解释器为latex
    h_legend = findobj(gcf, 'Type', 'Legend');
    if ~isempty(h_legend)
        for i = 1:length(h_legend)
            set(h_legend(i), 'Interpreter', 'latex');
        end
    end
    
    % 确保所有文本对象都使用'latex'解释器
    all_texts = findall(gcf, 'Type', 'text');
    for i = 1:length(all_texts)
        set(all_texts(i), 'Interpreter', 'latex');
    end
    
    % 生成时间戳
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    
    % 保存.fig格式(用于后续编辑)
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(figFile);
    fprintf('MATLAB图形文件已保存: %s\n', figFile);
    
    % 保存高分辨率PNG格式(用于快速预览)
    pngFile = sprintf('%s_%s.png', baseName, timestampStr);
    try
        % 尝试使用OpenGL渲染器，兼容2017b
        print(pngFile, '-dpng', '-r300', '-opengl');
        fprintf('PNG图像已保存: %s (300 dpi)\n', pngFile);
    catch ME
        fprintf('标准高分辨率PNG保存失败，尝试替代方法...\n');
        try
            % 使用更基本的选项
            print(pngFile, '-dpng');
            fprintf('PNG图像已保存: %s (使用默认选项)\n', pngFile);
        catch ME
            fprintf('警告: PNG格式保存失败. 错误: %s\n', ME.message);
        end
    end
    
    % 尝试保存EPS矢量图(用于学术论文出版)
    try
        epsFile = sprintf('%s_%s.eps', baseName, timestampStr);
        print(epsFile, '-depsc', '-painters');
        fprintf('EPS矢量图已保存: %s (适用于学术出版)\n', epsFile);
    catch ME
        fprintf('警告: EPS格式保存失败，尝试替代方法. 错误: %s\n', ME.message);
        try
            % 对于MATLAB 2017b的替代选项
            epsFile = sprintf('%s_%s.eps', baseName, timestampStr);
            print(epsFile, '-depsc', '-loose');
            fprintf('EPS矢量图已保存: %s (使用替代选项)\n', epsFile);
        catch
            fprintf('警告: 无法保存EPS格式。请检查MATLAB版本或使用其他格式。\n');
        end
    end
    
    % 恢复原始解释器设置
    if ~isempty(hc) && isfield(hc, 'Label') && exist('origInterp', 'var')
        hc.Label.Interpreter = origInterp;
    end
end