function plot_flux_tube_forces(all_radiationData, radial_index_for_nearSOL, varargin)
    % =========================================================================
    % 功能：
    %   沿选定通量管绘制杂质平行受力分布，包括：
    %       1) 摩擦力（smfr - Ne1+到Ne10+的总和）
    %       2) 温度梯度力（smpt）
    %       3) 全域分布、内偏滤器局部分布、外偏滤器局部分布
    %
    % 输入参数：
    %   all_radiationData         - cell 数组，每个元素含有:
    %                                .dirName (string)
    %                                .gmtry   (b2fgmtry 解析结果)
    %                                .plasma  (b2fplasmf解析结果)
    %   radial_index_for_nearSOL  - 指定径向索引，可以指定多个，用空格分隔
    %                                 例如：'17 18 19' 或 [17, 18, 19]
    %   varargin                  - 可选参数，用于设置图例类型
    %       'legend_mode', 'default' 或 'simple' (默认: 'default')
    %           'default': 使用目录名作为图例，并用颜色区分每个算例，线型区分物理量
    %           'simple': 使用预定义图例名称，顺序对应目录顺序
    %                    预定义名称为: 'favorable Bt', 'unfavorable Bt', 'w/o drift'
    %       'usePredefinedLegend', true 或 false (兼容旧版本)
    %           true:  等同于 legend_mode='simple'
    %           false: 等同于 legend_mode='default'
    %
    % 作者：xxx
    % 日期：2025-01-16
    % 修改备注：
    %   - 新增沿通量管受力分析功能
    %   - 支持多算例对比
    %   - 2025-03-04: 移除b2npmo_smaf，统计Ne1+到Ne10+的smfr
    %   - 2025-05-20: 修改smpt为三维数组，统计4:13；添加预定义图例选项
    %   - 2025-05-21: 修改全部字体为Times New Roman并优化学术出版样式
    %   - 2025-05-22: 新增内外偏滤器区域拆分绘制功能
    %   - 2025-05-23: 修改为强制同时绘制三种图（全域、内偏区域、外偏区域）
    %   - 2025-05-25: 修改图例样式，使用颜色区分算例，线型区分物理量
    %   - 2025-05-26: 添加对旧版本参数'usePredefinedLegend'的支持
    %   - 2025-06-10: 修改简化图例模式，参考plot_nearSOL_distributions_pol.m的实现
    % =========================================================================

    % 设置全局字体为Times New Roman并增大默认字体大小
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 22);
    set(0, 'DefaultTextFontSize', 22);
    set(0, 'DefaultLineLineWidth', 2.0);
    % 额外设置其他UI元素的字体
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    % 设置数学公式的解释器为latex
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex'); 
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    % 检测MATLAB版本（用于处理2017b兼容性问题）
    isMATLAB2017b = verLessThan('matlab', '9.3'); % R2017b是9.3版本

    % 输入参数处理
    if ischar(radial_index_for_nearSOL)
        radial_indices = str2num(radial_index_for_nearSOL);
    elseif isnumeric(radial_index_for_nearSOL)
        radial_indices = radial_index_for_nearSOL;
    else
        error('Input type error: string or numeric array required');
    end

    % 处理可选参数 (同时支持新旧两种参数格式)
    p = inputParser;
    addParameter(p, 'legend_mode', 'default', @(x) ischar(x) && ismember(lower(x), {'default', 'simple'}));
    addParameter(p, 'usePredefinedLegend', [], @(x) islogical(x) || isempty(x));
    parse(p, varargin{:});
    
    % 参数兼容性处理
    usePredefinedLegend = p.Results.usePredefinedLegend;
    legend_mode = p.Results.legend_mode;
    
    % 如果提供了旧参数 usePredefinedLegend，则覆盖 legend_mode
    if ~isempty(usePredefinedLegend)
        if usePredefinedLegend
            legend_mode = 'simple';
        else
            legend_mode = 'default';
        end
        fprintf('注意: 使用旧参数"usePredefinedLegend"，已自动转换为新参数格式\n');
    end
    
    % 预定义图例名称 - 用于简单模式
    predefined_legend_names = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};

    % X点位置定义 - 用于内外偏滤器区域拆分
    iXpoint_inner = 74;       % 内偏滤器 X点在 poloidal index = 74
    iXpoint_outer = 25;       % 外偏滤器 X点
    
    % 主循环处理每个径向索引
    for j_index = radial_indices
        fprintf('\n>>> Processing radial index j = %d...\n', j_index);
        
        % ========== (1) 绘制通量管全域受力分布 ==========
        plot_flux_tube_forces_full(all_radiationData, j_index, legend_mode, predefined_legend_names, iXpoint_inner, iXpoint_outer);
        
        % ========== (2) 内偏滤器局部放大图 ==========
        margin_inner = 8;
        i_start_inner = iXpoint_inner - margin_inner;  % 74 - 8 = 66
        if i_start_inner < 2
            i_start_inner = 2;
        end
        i_end_inner = 97;  % 这里与参考脚本一致
        
        plot_flux_tube_forces_partial(all_radiationData, j_index, i_start_inner, i_end_inner, iXpoint_inner, ...
            sprintf('InnerDiv. region (iy=%d)', j_index), legend_mode, predefined_legend_names);
        
        % ========== (3) 外偏滤器局部放大图 ==========
        margin_outer = 8;
        i_start_outer = 2;  % 直接从头开始
        i_end_outer = iXpoint_outer + margin_outer;  % 25 + 8 = 33
        if i_end_outer > 96
            i_end_outer = 96;
        end
        
        plot_flux_tube_forces_partial(all_radiationData, j_index, i_start_outer, i_end_outer, iXpoint_outer, ...
            sprintf('OuterDiv. region (iy=%d)', j_index), legend_mode, predefined_legend_names);
    end
    
    fprintf('\n>>> Analysis completed: Force distribution plots generated\n');
end

%% ========== 全域受力分布子函数 ==========
function plot_flux_tube_forces_full(all_radiationData, j_index, legend_mode, predefined_legend_names, iXpoint_inner, iXpoint_outer)
    % 绘制全域的通量管受力分布
    
    % 创建图窗，设置为符合学术出版要求的尺寸
    figure('Name', sprintf('Flux Tube Forces Full Domain (iy=%d)', j_index),...
          'NumberTitle','off','Color','w',...
          'Units', 'inches', 'Position', [1, 1, 9, 7]);
    hold on;
    
    % 获取极向坐标
    gmtry_ref = all_radiationData{1}.gmtry;
    pol_len = gmtry_ref.hx(:, j_index);
    x_edge = [0; cumsum(pol_len)];
    x_center = 0.5*(x_edge(1:end-1) + x_edge(2:end));

    % 颜色定义
    line_colors = lines(length(all_radiationData));
    dir_names = cell(length(all_radiationData),1);  % 存储图例名称
    
    % 线型定义：摩擦力(fric)用实线'-'，温度梯度力(therm)用短虚线'-.'
    lineStyles = {'-', '-.'};  % 实线、短虚线
    
    % 创建图例句柄和标签数组
    if strcmp(legend_mode, 'default')
        % 默认模式：按目录和物理量分类
        dummyDirHandles = gobjects(length(all_radiationData), 1);
        dirLegendStrings = cell(length(all_radiationData), 1);
        
        % 创建目录图例
        for iDir = 1:length(all_radiationData)
            ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
            dummyDirHandles(iDir) = plot(nan, nan, 'LineStyle', '-', ...
                'Color', ccol, 'LineWidth', 3.0, 'Marker', 'none', 'HandleVisibility', 'off');
            dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
        end
        
        % 创建物理量（线型）图例
        dummyStyleHandles = gobjects(2, 1);  % 2种物理量
        styleLegendStrings = {
            'Fric.', ...    % 摩擦力，使用实线
            'Therm.'          % 温度梯度力，使用短虚线
        };
        
        for sIdx = 1:2
            dummyStyleHandles(sIdx) = plot(nan, nan, 'LineStyle', lineStyles{sIdx}, ...
                'Color', 'k', 'LineWidth', 3.0, 'Marker', 'none', 'HandleVisibility', 'off');
        end
    else
        % --- 简化图例模式 ---
        % 准备不同物理量和不同磁场条件的组合
        nCases = min(3, length(all_radiationData));
        
        % 定义磁场条件标签
        if length(all_radiationData) == 3
            caseStrings = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
        elseif length(all_radiationData) == 2
            caseStrings = {'fav. $B_T$', 'w/o drift'};
        else
            caseStrings = {'w/o drift'};
        end
        
        % 定义物理量标签及对应线型
        physicalQuantities = {
            'Fric.', 
            'Therm.'
        };
        
        % 创建图例元素，横向排列（每个磁场条件一列，物理量依次排列）
        hLeg = gobjects(nCases * 2, 1);
        strLeg = cell(nCases * 2, 1);
        
        % 直接在标签中显示磁场条件+物理量组合
        for iCase = 1:nCases
            caseColor = line_colors(mod(iCase-1, size(line_colors,1))+1, :);
            for iQuantity = 1:2
                idx = (iCase-1)*2 + iQuantity;
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
        
        % 创建图例，设置为多列布局
        leg_h = legend(hLeg, strLeg, 'Location', 'best', 'NumColumns', nCases);
        set(leg_h, 'FontName', 'Times New Roman', 'FontSize', 24, 'Interpreter', 'latex', 'Box', 'on');
        
        % 调整图例位置
        leg_pos = get(leg_h, 'Position');
        if leg_pos(1) > 0.7  % 如果图例在右侧
            set(leg_h, 'Location', 'northeast');
        else
            set(leg_h, 'Location', 'northwest');
        end
    end
    
    % 循环处理每个算例
    for iDir = 1:length(all_radiationData)
        plasma = all_radiationData{iDir}.plasma;
        
        % 生成图例名称
        if strcmp(legend_mode, 'simple')
            legend_index = mod(iDir-1, length(predefined_legend_names)) + 1;
            simplifiedDirName = predefined_legend_names{legend_index};
        else
            simplifiedDirName = all_radiationData{iDir}.dirName;
        end
        dir_names{iDir} = simplifiedDirName;
        
        % 颜色
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        
        % 计算Ne1+到Ne10+的摩擦力总和 (粒子种类索引4:13)
        ne_smfr = sum(plasma.smfr(:, j_index, 4:13), 3);
        
        % 计算温度梯度力总和 (粒子种类索引4:13)
        ne_smpt = sum(plasma.smpt(:, j_index, 4:13), 3);
        
        % 绘制摩擦力 (实线)
        plot(x_center, ne_smfr, '-', 'Color', ccol, 'LineWidth', 2.5, 'HandleVisibility', 'off');
        
        % 绘制温度梯度力 (短虚线)
        plot(x_center, ne_smpt, '-.', 'Color', ccol, 'LineWidth', 2.5, 'HandleVisibility', 'off');
    end

    % 创建图例
    if strcmp(legend_mode, 'default')
        % 默认模式：按目录和物理量分类
        for iDir = 1:length(all_radiationData)
            set(dummyDirHandles(iDir), 'HandleVisibility', 'on');
        end
        for sIdx = 1:2
            set(dummyStyleHandles(sIdx), 'HandleVisibility', 'on');
        end
        
        allDummies = [dummyDirHandles(:); dummyStyleHandles(:)];
        allLegStr = [dirLegendStrings(:); styleLegendStrings(:)];
        
        leg_h = legend(allDummies, allLegStr, 'Location', 'best', ...
                'FontName', 'Times New Roman', 'FontSize', 24, 'Interpreter', 'latex', 'Box', 'on', 'NumColumns', 3);
    end

    % 确保图例在图内部显示
    leg_pos = get(leg_h, 'Position');
    if leg_pos(1) > 0.7  % 如果图例在右侧
        set(leg_h, 'Location', 'northeast');
    else
        set(leg_h, 'Location', 'northwest');
    end

    % 绘制X点位置
    try
        % 获取当前图形的Y轴范围
        ylims = ylim;
        ymin = ylims(1);
        ymax = ylims(2);
        
        % 计算X点位置
        gmtry_tmp_1 = all_radiationData{1}.gmtry;
        pol_len_1 = gmtry_tmp_1.hx(:, j_index);
        x_edge_1 = zeros(length(pol_len_1)+1, 1);
        for iPos = 1:length(pol_len_1)
            x_edge_1(iPos+1) = x_edge_1(iPos) + pol_len_1(iPos);
        end
        x_center_1 = 0.5 * (x_edge_1(1:end-1) + x_edge_1(2:end));
        
        % 绘制内外偏滤器X点位置参考线
        xXpt_inner = x_center_1(iXpoint_inner);
        xXpt_outer = x_center_1(iXpoint_outer);
        
        % 绘制内侧X点
        plot([xXpt_inner xXpt_inner], [ymin, ymax], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        % 绘制外侧X点
        plot([xXpt_outer xXpt_outer], [ymin, ymax], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    catch
        warning('Cannot draw X point lines in full domain plot');
    end

    % 坐标设置
    xlabel('Poloidal distance (m)','FontName', 'Times New Roman', 'FontSize', 26, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('Force density (N/m$^3$)','FontName', 'Times New Roman', 'FontSize', 26, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title('Force Balance (Full Domain)','FontName', 'Times New Roman', 'FontSize', 28, 'FontWeight', 'bold', 'Interpreter', 'latex');
    grid on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 24, 'LineWidth', 1.5, 'Box', 'on');
    
    % 保存结果
    saveFigureWithTimestamp(sprintf('ForceBalance_FullDomain_j%d',j_index));
end

%% ========== 局部区域受力分布子函数 ==========
function plot_flux_tube_forces_partial(all_radiationData, j_index, i_start, i_end, iXpoint, figureTag, legend_mode, predefined_legend_names)
    % 绘制指定 poloidal index 范围 [i_start..i_end] 的局部放大图
    % 并在图上标出 X 点
    
    % 创建图窗，设置为符合学术出版要求的尺寸
    figure('Name', figureTag,...
          'NumberTitle','off','Color','w',...
          'Units', 'inches', 'Position', [1, 1, 9, 7]);
    hold on;
    
    % 颜色定义
    line_colors = lines(length(all_radiationData));
    
    % 线型定义：摩擦力(fric)用实线'-'，温度梯度力(therm)用短虚线'-.'
    lineStyles = {'-', '-.'};  % 实线、短虚线
    
    % 创建图例句柄和标签数组
    if strcmp(legend_mode, 'default')
        % 默认模式：按目录和物理量分类
        dummyDirHandles = gobjects(length(all_radiationData), 1);
        dirLegendStrings = cell(length(all_radiationData), 1);
        
        % 创建目录图例
        for iDir = 1:length(all_radiationData)
            ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
            dummyDirHandles(iDir) = plot(nan, nan, 'LineStyle', '-', ...
                'Color', ccol, 'LineWidth', 3.0, 'Marker', 'none', 'HandleVisibility', 'off');
            dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
        end
        
        % 创建物理量（线型）图例
        dummyStyleHandles = gobjects(2, 1);  % 2种物理量
        styleLegendStrings = {
            'fric.', ...    % 摩擦力，使用实线
            'therm.'          % 温度梯度力，使用短虚线
        };
        
        for sIdx = 1:2
            dummyStyleHandles(sIdx) = plot(nan, nan, 'LineStyle', lineStyles{sIdx}, ...
                'Color', 'k', 'LineWidth', 3.0, 'Marker', 'none', 'HandleVisibility', 'off');
        end
    else
        % --- 简化图例模式 ---
        % 准备不同物理量和不同磁场条件的组合
        nCases = min(3, length(all_radiationData));
        
        % 定义磁场条件标签
        if length(all_radiationData) == 3
            caseStrings = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
        elseif length(all_radiationData) == 2
            caseStrings = {'fav. $B_T$', 'w/o drift'};
        else
            caseStrings = {'w/o drift'};
        end
        
        % 定义物理量标签及对应线型
        physicalQuantities = {
            'Fric.', 
            'Therm.'
        };
        
        % 创建图例元素，横向排列（每个磁场条件一列，物理量依次排列）
        hLeg = gobjects(nCases * 2, 1);
        strLeg = cell(nCases * 2, 1);
        
        % 直接在标签中显示磁场条件+物理量组合
        for iCase = 1:nCases
            caseColor = line_colors(mod(iCase-1, size(line_colors,1))+1, :);
            for iQuantity = 1:2
                idx = (iCase-1)*2 + iQuantity;
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
        
        % 创建图例，设置为多列布局
        leg_h = legend(hLeg, strLeg, 'Location', 'best', 'NumColumns', nCases);
        set(leg_h, 'FontName', 'Times New Roman', 'FontSize', 24, 'Interpreter', 'latex', 'Box', 'on');
        
        % 调整图例位置
        leg_pos = get(leg_h, 'Position');
        if leg_pos(1) > 0.7  % 如果图例在右侧
            set(leg_h, 'Location', 'northeast');
        else
            set(leg_h, 'Location', 'northwest');
        end
    end
    
    % ========== 逐算例截取 & 绘制数据 ==========
    for iDir = 1:length(all_radiationData)
        dataStruct = all_radiationData{iDir};
        gmtry_tmp = dataStruct.gmtry;
        plasma = dataStruct.plasma;
        
        % 构造 poloidal 方向距离
        pol_len = gmtry_tmp.hx(:, j_index);
        [nxd_tmp, ~] = size(gmtry_tmp.crx(:,:,1));
        x_edge = zeros(nxd_tmp+1,1);
        for iPos = 1:nxd_tmp
            x_edge(iPos+1) = x_edge(iPos) + pol_len(iPos);
        end
        x_center = 0.5*(x_edge(1:end-1) + x_edge(2:end));
        
        % 计算Ne1+到Ne10+的摩擦力总和 (粒子种类索引4:13)
        ne_smfr = sum(plasma.smfr(:, j_index, 4:13), 3);
        
        % 计算温度梯度力总和 (粒子种类索引4:13)
        ne_smpt = sum(plasma.smpt(:, j_index, 4:13), 3);
            
        % 截取子区间
        if i_start < 1, i_start = 1; end
        if i_end > nxd_tmp, i_end = nxd_tmp; end
        idxRange = i_start:i_end;
        
        xSub = x_center(idxRange);
        fric_smfr_sub = ne_smfr(idxRange);
        therm_smpt_sub = ne_smpt(idxRange);
        
        % 颜色
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        
        % 绘制摩擦力 (实线)
        plot(xSub, fric_smfr_sub, '-', 'Color', ccol, 'LineWidth', 2.5, 'HandleVisibility', 'off');
        
        % 绘制温度梯度力 (短虚线)
        plot(xSub, therm_smpt_sub, '-.', 'Color', ccol, 'LineWidth', 2.5, 'HandleVisibility', 'off');
    end
    
    % 创建图例
    if strcmp(legend_mode, 'default')
        % 默认模式：按目录和物理量分类
        for iDir = 1:length(all_radiationData)
            set(dummyDirHandles(iDir), 'HandleVisibility', 'on');
        end
        for sIdx = 1:2
            set(dummyStyleHandles(sIdx), 'HandleVisibility', 'on');
        end
        
        allDummies = [dummyDirHandles(:); dummyStyleHandles(:)];
        allLegStr = [dirLegendStrings(:); styleLegendStrings(:)];
        
        leg_h = legend(allDummies, allLegStr, 'Location', 'best', ...
                'FontName', 'Times New Roman', 'FontSize', 24, 'Interpreter', 'latex', 'Box', 'on', 'NumColumns', 3);
    end
    
    % 确保图例在图内部显示
    leg_pos = get(leg_h, 'Position');
    if leg_pos(1) > 0.7  % 如果图例在右侧
        set(leg_h, 'Location', 'northeast');
    else
        set(leg_h, 'Location', 'northwest');
    end
    
    % 标记 X 点
    try
        dataStruct_1 = all_radiationData{1};
        gmtry_tmp_1 = dataStruct_1.gmtry;
        pol_len_1 = gmtry_tmp_1.hx(:, j_index);
        x_edge_1 = zeros(length(pol_len_1)+1,1);
        for iPos = 1:length(pol_len_1)
            x_edge_1(iPos+1) = x_edge_1(iPos) + pol_len_1(iPos);
        end
        x_center_1 = 0.5*(x_edge_1(1:end-1) + x_edge_1(2:end));
        xXpt = x_center_1(iXpoint);
        
        % 获取当前图形的Y轴范围
        ylims = ylim;
        ymin = ylims(1);
        ymax = ylims(2);
        
        % 绘制X点位置
        plot([xXpt xXpt], [ymin, ymax], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    catch
        warning('Cannot draw X line for %s', figureTag);
    end
    
    % 若为内偏滤器，需要翻转 X 轴
    if contains(lower(figureTag), 'innerdiv')
        set(gca, 'XDir', 'reverse');
    end
    
    % 坐标设置
    xlabel('Poloidal distance (m)','FontName', 'Times New Roman', 'FontSize', 26, 'FontWeight', 'bold', 'Interpreter', 'latex');
    ylabel('Force density (N/m$^3$)','FontName', 'Times New Roman', 'FontSize', 26, 'FontWeight', 'bold', 'Interpreter', 'latex');
    title(figureTag,'FontName', 'Times New Roman', 'FontSize', 28, 'FontWeight', 'bold', 'Interpreter', 'latex');
    grid on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 24, 'LineWidth', 1.5, 'Box', 'on');
    
    % 保存结果
    figureTag_noSpace = strrep(figureTag, ' ', '_');
    saveFigureWithTimestamp(figureTag_noSpace);
end

%% ========== 辅助函数 ==========
function saveFigureWithTimestamp(baseName)
    % 带时间戳保存图片，优化为符合学术出版要求
    % 将当前 figure 保存为多种格式，包括.fig（MATLAB原生格式）
    % 和高分辨率图像格式（PNG和EPS）用于学术论文
    
    % 确保图窗尺寸适合学术出版要求
    set(gcf,'Units','inches','Position',[1, 1, 9, 7]); % 适合学术出版的尺寸比例
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